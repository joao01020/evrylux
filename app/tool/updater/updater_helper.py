#!/usr/bin/env python3
"""EVRYLUX user-level release installer. No shell, sudo or remote commands."""
import argparse
import base64
import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import sqlite3
import stat
import sys
import subprocess
import tempfile
import tarfile
import time
import zipfile

import psutil
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

MAX_PACKAGE = 4 * 1024**3
MAX_UNPACKED = 8 * 1024**3
MAX_FILES = 30000
MAX_MANIFEST = 256 * 1024
VERSION = re.compile(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
                     r'(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$')
KEY_ID = re.compile(r'^[A-Za-z0-9_-]{1,64}$')


def install_root():
    if os.name == 'nt':
        base = os.environ.get('LOCALAPPDATA')
        if not base:
            raise RuntimeError('LOCALAPPDATA indisponível.')
        return Path(base) / 'EVRYLUX' / 'installation'
    return Path.home() / '.local' / 'share' / 'evrylux' / 'installation'


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name('.' + path.name + '-' + secrets.token_hex(8))
    try:
        with temp.open('x', encoding='utf-8') as out:
            json.dump(value, out, ensure_ascii=False, sort_keys=True)
            out.flush()
            os.fsync(out.fileno())
        os.replace(temp, path)
        if os.name != 'nt':
            fd = os.open(path.parent, os.O_RDONLY)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
    finally:
        temp.unlink(missing_ok=True)


def read_json(path, limit=MAX_MANIFEST):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
        raise RuntimeError('Arquivo de controle inválido ou excessivo.')
    return json.loads(path.read_text(encoding='utf-8'))


def safe_dir(path):
    path = Path(os.path.abspath(path))
    for ancestor in (path, *path.parents):
        if ancestor.is_symlink() or getattr(ancestor, 'is_junction', lambda: False)():
            raise RuntimeError('Link simbólico em diretório controlado.')
    path.mkdir(parents=True, exist_ok=True)
    if os.name != 'nt':
        os.chmod(path, 0o700)
    return path


def version(value):
    if not isinstance(value, str) or not VERSION.fullmatch(value):
        raise RuntimeError('Versão inválida.')
    pre = value.split('+', 1)[0].split('-', 1)
    if len(pre) > 1:
        for part in pre[1].split('.'):
            if part.isdigit() and len(part) > 1 and part.startswith('0'):
                raise RuntimeError('Pré-release inválida.')
    return value


def target_dir(root, value):
    return root / 'versions' / version(value)


def current(root):
    path = root / 'current.json'
    if not path.exists():
        return None
    return version(read_json(path)['version'])


def set_current(root, value):
    atomic_json(root / 'current.json', {'version': version(value)})


def sha256_file(path):
    digest = hashlib.sha256()
    size = 0
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            size += len(chunk)
            if size > MAX_PACKAGE:
                raise RuntimeError('Pacote excede 4 GiB.')
            digest.update(chunk)
    return size, digest.hexdigest()


def verify_envelope(envelope, trust):
    if not isinstance(envelope, dict):
        raise RuntimeError('Envelope inválido.')
    key_id = envelope.get('keyId')
    if not isinstance(key_id, str) or not KEY_ID.fullmatch(key_id):
        raise RuntimeError('Identificador de chave inválido.')
    key = trust['keys'].get(key_id)
    if not isinstance(key, str):
        raise RuntimeError('Chave de release não confiável.')
    encoded = envelope.get('payload')
    signature = envelope.get('signature')
    if not isinstance(encoded, str) or not isinstance(signature, str):
        raise RuntimeError('Assinatura ausente.')
    if len(encoded) > 350000 or len(signature) > 128:
        raise RuntimeError('Envelope excessivo.')
    payload = base64.b64decode(encoded, validate=True)
    if len(payload) > MAX_MANIFEST:
        raise RuntimeError('Manifesto excessivo.')
    Ed25519PublicKey.from_public_bytes(
        base64.b64decode(key, validate=True)
    ).verify(base64.b64decode(signature, validate=True), payload)
    manifest = json.loads(payload)
    if manifest.get('schema') != 1 or manifest.get('appId') != 'evrylux':
        raise RuntimeError('Manifesto incompatível.')
    version(manifest['version'])
    if type(manifest.get('dataSchema')) is not int or manifest['dataSchema'] < 1:
        raise RuntimeError('Release sem declaração de esquema de dados.')
    if manifest.get('channel') != trust.get('channel', 'stable'):
        raise RuntimeError('Canal de release incorreto.')
    if not isinstance(manifest.get('assets'), list):
        raise RuntimeError('Pacotes ausentes.')
    minimum = manifest.get('minDataSchema')
    maximum = manifest.get('maxDataSchema')
    if type(minimum) is not int or type(maximum) is not int or \
            not 1 <= minimum <= manifest['dataSchema'] <= maximum:
        raise RuntimeError('Compatibilidade de dados inválida.')
    return manifest


def platform_id():
    if sys.platform == 'win32':
        return 'windows'
    if sys.platform.startswith('linux'):
        return 'linux'
    raise RuntimeError('Sistema operacional não suportado.')


def architecture():
    import platform
    machine = platform.machine().lower()
    if machine in ('aarch64', 'arm64'):
        return 'arm64'
    if machine in ('x86_64', 'amd64'):
        return 'x64'
    raise RuntimeError('Arquitetura não suportada: ' + machine)


def selected_asset(manifest):
    matches = [a for a in manifest['assets']
               if a.get('platform') == platform_id()
               and a.get('architecture') == architecture()]
    if len(matches) != 1:
        raise RuntimeError('Pacote incompatível ou duplicado.')
    asset = matches[0]
    if asset.get('format') != ('zip' if os.name == 'nt' else 'tar.gz'):
        raise RuntimeError('Formato incompatível.')
    if type(asset.get('size')) is not int or not 0 < asset['size'] <= MAX_PACKAGE:
        raise RuntimeError('Tamanho inválido.')
    if not re.fullmatch(r'[a-fA-F0-9]{64}', str(asset.get('sha256', ''))):
        raise RuntimeError('Hash inválido.')
    return asset


def verify_package(path, asset):
    size, digest = sha256_file(path)
    if size != asset['size'] or digest != asset['sha256'].lower():
        raise RuntimeError('Integridade do pacote inválida.')


def safe_name(name):
    if not name or '\\' in name or '\x00' in name or name.startswith('/'):
        raise RuntimeError('Caminho inválido no pacote.')
    parts = name.rstrip('/').split('/')
    if any(p in ('', '.', '..') or ':' in p for p in parts):
        raise RuntimeError('Travessia de diretório no pacote.')
    if os.name == 'nt':
        for part in parts:
            if part.rstrip(' .') != part:
                raise RuntimeError('Nome incompatível com Windows.')
            stem = part.split('.')[0].upper()
            if stem in {'CON', 'PRN', 'AUX', 'NUL'} or re.fullmatch(r'(COM|LPT)[1-9]', stem):
                raise RuntimeError('Nome reservado do Windows.')
    return parts


def _extract_entry(source, target, size, executable=False):
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open('xb') as out:
        remaining = size
        while remaining:
            chunk = source.read(min(1024 * 1024, remaining))
            if not chunk:
                raise RuntimeError('Arquivo incompleto no pacote.')
            out.write(chunk)
            remaining -= len(chunk)
        out.flush()
        os.fsync(out.fileno())
    if os.name != 'nt':
        os.chmod(target, 0o755 if executable else 0o644)


def extract_package(package, destination):
    safe_dir(destination)
    seen = set()
    total = 0
    count = 0
    kinds = {}
    is_zip = os.name == 'nt'
    with (zipfile.ZipFile(package) if is_zip else
          tarfile.open(package, 'r:gz')) as archive:
        entries = archive.infolist() if is_zip else archive
        for entry in entries:
            name = entry.filename if is_zip else entry.name
            parts = safe_name(name)
            identity = '/'.join(parts).casefold()
            if identity == 'release-receipt.json':
                raise RuntimeError('Nome reservado no pacote.')
            if identity in seen:
                raise RuntimeError('Entrada duplicada no pacote.')
            seen.add(identity)
            count += 1
            if count > MAX_FILES:
                raise RuntimeError('Pacote contém arquivos demais.')
            if is_zip:
                mode = entry.external_attr >> 16
                kind = stat.S_IFMT(mode)
                if kind not in (0, stat.S_IFREG, stat.S_IFDIR):
                    raise RuntimeError('Tipo de arquivo proibido.')
                directory = entry.is_dir()
                size = entry.file_size
            else:
                if not (entry.isfile() or entry.isdir()):
                    raise RuntimeError('Links e arquivos especiais são proibidos.')
                directory = entry.isdir()
                size = entry.size
                mode = entry.mode
            if size < 0 or size > MAX_PACKAGE:
                raise RuntimeError('Arquivo excessivo.')
            for index in range(1, len(parts)):
                parent = '/'.join(parts[:index]).casefold()
                if kinds.get(parent) == 'file':
                    raise RuntimeError('Arquivo usado como diretório.')
            if not directory:
                prefix = identity + '/'
                if any(existing.startswith(prefix) for existing in seen if existing != identity):
                    raise RuntimeError('Diretório usado como arquivo.')
            kinds[identity] = 'directory' if directory else 'file'
            total += size
            if total > MAX_UNPACKED:
                raise RuntimeError('Pacote descompactado excessivo.')
            target = destination.joinpath(*parts)
            if directory:
                target.mkdir(parents=True, exist_ok=True)
            else:
                source = archive.open(entry) if is_zip else archive.extractfile(entry)
                if source is None:
                    raise RuntimeError('Entrada inválida.')
                with source:
                    _extract_entry(source, target, size, bool(mode & 0o111))
    executable = destination / ('EVRYLUX.exe' if os.name == 'nt' else 'app')
    if not executable.is_file() or executable.is_symlink():
        raise RuntimeError('Executável principal ausente.')
    if not (destination / 'data' / 'flutter_assets').is_dir():
        raise RuntimeError('Bundle Flutter incompleto.')
    return executable


def file_inventory(directory):
    inventory = {}
    for base, dirs, files in os.walk(directory, followlinks=False):
        if any((Path(base) / name).is_symlink() for name in dirs + files):
            raise RuntimeError('Link simbólico em versão instalada.')
        for name in files:
            item = Path(base) / name
            if not stat.S_ISREG(item.lstat().st_mode):
                raise RuntimeError('Arquivo especial em versão instalada.')
            relative = item.relative_to(directory).as_posix()
            if relative == 'release-receipt.json':
                continue
            inventory[relative] = sha256_file(item)[1]
    return inventory


def prepare(root, package, manifest, asset):
    value = version(manifest['version'])
    final = target_dir(root, value)
    receipt = {
        'version': value, 'sha256': asset['sha256'].lower(),
        'dataSchema': manifest['dataSchema'],
    }
    if final.is_symlink():
        raise RuntimeError('Versão instalada é um link simbólico.')
    if final.exists():
        stored = read_json(final / 'release-receipt.json', 8 * 1024 * 1024)
        expected_files = stored.pop('files', None)
        if stored != receipt or expected_files != file_inventory(final):
            raise RuntimeError('Versão existente não corresponde ao pacote.')
        return final
    incoming = root / 'versions' / ('.incoming-' + secrets.token_hex(8))
    try:
        extract_package(package, incoming)
        receipt['files'] = file_inventory(incoming)
        atomic_json(incoming / 'release-receipt.json', receipt)
        incoming.rename(final)
        return final
    finally:
        if incoming.exists():
            shutil.rmtree(incoming)


def binary(root, value):
    path = target_dir(root, value) / ('EVRYLUX.exe' if os.name == 'nt' else 'app')
    if not path.is_file() or path.is_symlink():
        raise RuntimeError('Executável instalado indisponível.')
    return path


def verify_installed(root, value):
    directory = target_dir(root, value)
    receipt = read_json(directory / 'release-receipt.json', 8 * 1024 * 1024)
    if receipt.get('version') != value:
        raise RuntimeError('Identidade da instalação inválida.')
    expected = receipt.get('files')
    if not isinstance(expected, dict) or expected != file_inventory(directory):
        raise RuntimeError('Arquivos da instalação foram alterados.')
    return receipt


def preflight(root, value):
    verify_installed(root, value)
    result = subprocess.run(
        [str(binary(root, value)), '--evrylux-update-preflight'],
        cwd=target_dir(root, value),
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        text=True, timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError('O bundle não passou na verificação inicial.')
    for line in result.stdout.splitlines():
        if line.startswith('EVRYLUX_PREFLIGHT:'):
            return json.loads(line.split(':', 1)[1])
    raise RuntimeError('O bundle não informou sua identidade.')

def compare_versions(left, right):
    def parts(value):
        match = re.fullmatch(
            r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
            r'(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?', value)
        if not match:
            raise RuntimeError('Versão inválida.')
        return tuple(int(match.group(i)) for i in (1, 2, 3)), match.group(4)
    a, ap = parts(left)
    b, bp = parts(right)
    if a != b:
        return (a > b) - (a < b)
    if ap is None or bp is None:
        return (ap is None) - (bp is None)
    aa, bb = ap.split('.'), bp.split('.')
    for x, y in zip(aa, bb):
        xn, yn = x.isdigit(), y.isdigit()
        if xn and yn:
            c = (int(x) > int(y)) - (int(x) < int(y))
        elif xn != yn:
            c = -1 if xn else 1
        else:
            c = (x > y) - (x < y)
        if c:
            return c
    return (len(aa) > len(bb)) - (len(aa) < len(bb))


def managed_processes(root):
    versions = str(root / 'versions').casefold()
    found = []
    for process in psutil.process_iter(['pid', 'exe']):
        try:
            exe = process.info['exe']
            if exe and str(Path(exe).resolve()).casefold().startswith(versions + os.sep):
                found.append(process)
        except (psutil.NoSuchProcess, psutil.AccessDenied, OSError):
            pass
    return found


def wait_for_exit(root, pid, timeout=90):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        live = managed_processes(root)
        if not live:
            return
        time.sleep(0.3)
    raise RuntimeError('EVRYLUX ainda está aberto. Feche todas as janelas.')


def snapshot_data(root, support, documents):
    backup = root / 'backups' / (time.strftime('%Y%m%dT%H%M%SZ') + '-' + secrets.token_hex(4))
    safe_dir(backup)
    sources = [('support', support), ('documents', documents)]
    record = []
    for label, source in sources:
        if source is None or not source.exists():
            continue
        source = Path(os.path.abspath(source))
        if source == root or root in source.parents or source in root.parents:
            raise RuntimeError('Diretório de dados sobrepõe a instalação.')
        if Path.home() not in source.parents:
            raise RuntimeError('Diretório de dados fora do perfil do usuário.')
        for path in (source, *source.parents):
            if path.is_symlink():
                raise RuntimeError('Link simbólico no diretório de dados.')
        dest = backup / label
        dest.mkdir()
        for base, dirs, files in os.walk(source, followlinks=False):
            if any((Path(base) / d).is_symlink() for d in dirs):
                raise RuntimeError('Link simbólico nos diretórios de dados.')
            dirs[:] = [d for d in dirs if not (
                label == 'support' and Path(base) == source and
                d == 'evrylux-updater'
            )]
            for name in files:
                if name.endswith(('-wal', '-shm', '-journal')) and Path(
                    base, name.rsplit('-', 1)[0]
                ).suffix.lower() in ('.db', '.sqlite', '.sqlite3'):
                    continue
                item = Path(base) / name
                if item.is_symlink():
                    raise RuntimeError('Link simbólico nos dados.')
                target = dest / item.relative_to(source)
                target.parent.mkdir(parents=True, exist_ok=True)
                if item.suffix.lower() in ('.db', '.sqlite', '.sqlite3'):
                    with contextlib.closing(
                        sqlite3.connect(item.resolve().as_uri() + '?mode=ro', uri=True)
                    ) as db:
                        with contextlib.closing(sqlite3.connect(target)) as copy:
                            db.backup(copy)
                            # The backup is a standalone database, not a raw
                            # copy of the source's WAL/SHM files.
                            copy.execute('PRAGMA journal_mode=DELETE').fetchone()
                            if copy.execute('PRAGMA quick_check').fetchone()[0] != 'ok':
                                raise RuntimeError('Backup SQLite não passou na verificação.')
                else:
                    shutil.copy2(item, target)
                with target.open('rb') as saved:
                    os.fsync(saved.fileno())
                if os.name != 'nt':
                    os.chmod(target, 0o600)
        record.append({'source': str(source), 'backup': label})
    atomic_json(backup / 'backup.json', {'sources': record})
    return backup


@contextlib.contextmanager
def lock(root):
    safe_dir(root / 'state')
    path = root / 'state' / 'updater.lock'
    with path.open('a+b') as file:
        if os.name == 'nt':
            import msvcrt
            file.seek(0)
            file.write(b'\0')
            file.flush()
            file.seek(0)
            msvcrt.locking(file.fileno(), msvcrt.LK_LOCK, 1)
        else:
            import fcntl
            fcntl.flock(file.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            if os.name == 'nt':
                file.seek(0)
                msvcrt.locking(file.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(file.fileno(), fcntl.LOCK_UN)


def transaction_path(root):
    return root / 'state' / 'transaction.json'


def rollback(root, transaction, reason):
    if managed_processes(root):
        raise RuntimeError('Feche todas as janelas antes do rollback.')
    previous = transaction.get('previous')
    if previous:
        set_current(root, previous)
    transaction['status'] = 'rolled_back'
    transaction['reason'] = reason
    atomic_json(transaction_path(root), transaction)


def app_environment():
    # Do not propagate PyInstaller's private onefile state to Flutter.
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith('_PYI_') and key != '_MEIPASS2'}
    environment.pop('PYINSTALLER_RESET_ENVIRONMENT', None)
    return environment


def launch(root, value=None, health=None):
    value = version(value or current(root))
    verify_installed(root, value)
    command = [str(binary(root, value))]
    if health:
        command.append('--evrylux-update-health=' + health)
    return subprocess.Popen(
        command, cwd=target_dir(root, value),
        env=app_environment(), close_fds=True,
    )


def progress(root, phase, fraction, message):
    atomic_json(root / 'state' / 'progress.json', {
        'phase': phase, 'fraction': fraction, 'message': message,
    })


def apply(root, request):
    progress(root, 'verifying', 0.05, 'Verificando assinatura e pacote...')
    trust = read_json(root / 'trust.json')
    manifest = verify_envelope(request['envelope'], trust)
    asset = selected_asset(manifest)
    value = version(manifest['version'])
    if value != request['version']:
        raise RuntimeError('Versão da solicitação não corresponde ao manifesto.')
    original_package = Path(request['package'])
    if original_package.is_symlink():
        raise RuntimeError('Pacote não pode ser um link simbólico.')
    package = original_package.resolve(strict=True)
    safe_dir(root / 'staging')
    if not package.is_file():
        raise RuntimeError('Pacote inválido.')
    if (root / 'staging') not in package.parents:
        raise RuntimeError('Pacote fora da área de atualização.')
    verify_package(package, asset)
    previous = current(root)
    if previous is None or previous != request['previous']:
        raise RuntimeError('Instalação atual mudou desde a solicitação.')
    if compare_versions(value, previous) <= 0:
        raise RuntimeError('A release não é mais recente.')
    current_identity = preflight(root, previous)
    current_schema = current_identity.get('dataSchema')
    if type(current_schema) is not int or current_schema < 1:
        raise RuntimeError('Esquema atual inválido.')
    if manifest['dataSchema'] != current_schema or not (
        manifest['minDataSchema'] <= current_schema <= manifest['maxDataSchema']
    ):
        raise RuntimeError(
            'Migração de banco bloqueada nesta etapa. '
            'É necessário um plano de migração e rollback dos dados.'
        )
    if not isinstance(request.get('nonce'), str) or not re.fullmatch(
        r'[a-f0-9]{64}', request['nonce']):
        raise RuntimeError('Identificador de saúde inválido.')
    if transaction_path(root).exists():
        transaction = read_json(transaction_path(root))
        if transaction.get('status') in ('pending', 'needs_recovery'):
            raise RuntimeError('Já existe uma atualização pendente.')

    progress(root, 'preparing', 0.20, 'Preparando nova versão...')
    prepare(root, package, manifest, asset)
    target_identity = preflight(root, value)
    if target_identity.get('version') != value or \
            target_identity.get('dataSchema') != current_schema:
        raise RuntimeError('Identidade do novo bundle incompatível.')
    atomic_json(root / 'state' / 'handoff.json', {
        'nonce': request['nonce'], 'status': 'prepared',
    })
    progress(root, 'waiting', 0.35, 'Aguardando o EVRYLUX fechar...')
    wait_for_exit(root, request['pid'])
    progress(root, 'backup', 0.45, 'Preservando a versão e os dados locais...')
    support = Path(request['support'])
    if not (support / 'ghost_core.db').is_file():
        raise RuntimeError('Banco local não encontrado; atualização cancelada.')
    backup = snapshot_data(
        root, support, Path(request['documents'])
    )
    transaction = {
        'status': 'pending', 'previous': previous, 'target': value,
        'nonce': request['nonce'], 'backup': str(backup),
    }
    (root / 'state' / 'health.json').unlink(missing_ok=True)
    atomic_json(transaction_path(root), transaction)
    progress(root, 'switching', 0.75, 'Ativando a nova versão...')
    set_current(root, value)
    try:
        progress(root, 'starting', 0.85, 'Reabrindo o EVRYLUX...')
        process = launch(root, value, request['nonce'])
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            ack = root / 'state' / 'health.json'
            if ack.exists():
                data = read_json(ack, 4096)
                if process.poll() is None and data.get('nonce') == request['nonce'] and data.get('version') == value:
                    transaction['status'] = 'healthy'
                    atomic_json(transaction_path(root), transaction)
                    progress(root, 'complete', 1.0, 'Atualização concluída.')
                    return
            if process.poll() is not None:
                break
            time.sleep(0.4)
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                transaction['status'] = 'needs_recovery'
                atomic_json(transaction_path(root), transaction)
                raise RuntimeError('Feche a nova versão para concluir a recuperação.')
        if managed_processes(root):
            transaction['status'] = 'needs_recovery'
            atomic_json(transaction_path(root), transaction)
            raise RuntimeError('Ainda existem janelas abertas; recuperação pendente.')
        rollback(root, transaction, 'Inicialização não confirmada.')
        launch(root, previous)
        raise RuntimeError('Nova versão não confirmou inicialização; rollback realizado.')
    except Exception:
        if read_json(transaction_path(root)).get('status') == 'pending':
            if managed_processes(root):
                transaction['status'] = 'needs_recovery'
                atomic_json(transaction_path(root), transaction)
            else:
                rollback(root, transaction, 'Falha ao iniciar a nova versão.')
                launch(root, previous)
        raise


def create_shortcut(root):
    helper = root / 'updater' / (
        'evrylux-updater-helper.exe' if os.name == 'nt' else 'evrylux-updater-helper')
    if not helper.is_file():
        return
    if os.name == 'nt':
        directory = Path(os.environ['APPDATA']) / 'Microsoft/Windows/Start Menu/Programs'
        directory.mkdir(parents=True, exist_ok=True)
        shortcut = directory / 'EVRYLUX.lnk'
        def quote(value):
            return "'" + str(value).replace("'", "''") + "'"
        script = (
            '$s=(New-Object -ComObject WScript.Shell).CreateShortcut('
            + quote(shortcut) + ');'
            '$s.TargetPath=' + quote(helper) + ';'
            '$s.Arguments="launch";'
            '$s.WorkingDirectory=' + quote(root) + ';'
            '$s.Save()'
        )
        subprocess.run(
            ['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', script],
            check=True, timeout=20, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    else:
        directory = Path.home() / '.local/share/applications'
        directory.mkdir(parents=True, exist_ok=True)
        icon = root / 'updater/icon.png'
        icon_value = str(icon) if icon.is_file() else 'applications-utilities'
        def desktop_quote(value):
            return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'
        text = (
            '[Desktop Entry]\nType=Application\nName=EVRYLUX\n'
            'Exec=' + desktop_quote(helper) + ' launch\n'
            'Path=' + desktop_quote(root) + '\n'
            'Icon=' + icon_value + '\nTerminal=false\nCategories=Utility;\n'
        )
        path = directory / 'evrylux.desktop'
        temp = path.with_name('.evrylux-' + secrets.token_hex(4))
        try:
            temp.write_text(text, encoding='utf-8')
            os.replace(temp, path)
            os.chmod(path, 0o644)
        finally:
            temp.unlink(missing_ok=True)


def run_apply(root, request):
    try:
        apply(root, request)
    except Exception as error:
        handoff = root / 'state' / 'handoff.json'
        try:
            previous = read_json(handoff) if handoff.exists() else {}
        except Exception:
            previous = {}
        if previous.get('nonce') != request.get('nonce') or \
                previous.get('status') != 'prepared':
            atomic_json(handoff, {
                'nonce': request.get('nonce'), 'status': 'failed',
                'message': str(error),
            })
        raise


def bootstrap(root, package, envelope, trust):
    if current(root) is not None:
        raise RuntimeError('Instalação já existe. Use o atualizador.')
    if not isinstance(trust.get('keys'), dict) or not trust['keys']:
        raise RuntimeError('Configuração de confiança inválida.')
    trust_path = root / 'trust.json'
    if trust_path.exists() and read_json(trust_path) != trust:
        raise RuntimeError('Já existe uma configuração de confiança diferente.')
    manifest = verify_envelope(envelope, trust)
    asset = selected_asset(manifest)
    verify_package(package, asset)
    prepare(root, package, manifest, asset)
    identity = preflight(root, manifest['version'])
    if identity.get('version') != manifest['version'] or \
            identity.get('dataSchema') != manifest['dataSchema']:
        raise RuntimeError('Identidade do bundle não corresponde à release.')
    if not (manifest['minDataSchema'] <= manifest['dataSchema'] <= manifest['maxDataSchema']):
        raise RuntimeError('Esquema da release fora do intervalo declarado.')
    if not trust_path.exists():
        atomic_json(trust_path, trust)
    if getattr(sys, 'frozen', False):
        helper = root / 'updater' / (
            'evrylux-updater-helper.exe' if os.name == 'nt' else 'evrylux-updater-helper')
        helper.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sys.executable, helper)
        if os.name != 'nt':
            os.chmod(helper, 0o755)
        icon = target_dir(root, manifest['version']) / (
            'data/flutter_assets/assets/images/branding/evrylux_logo.png')
        if icon.is_file():
            shutil.copy2(icon, root / 'updater/icon.png')
    set_current(root, manifest['version'])
    try:
        create_shortcut(root)
    except Exception:
        print('Aviso: não foi possível criar o atalho. Use o launcher instalado.',
              file=sys.stderr if sys.stderr is not None else sys.stdout)
    print('Instalação inicial preparada:', root)


def apply_with_ui(root, request):
    import threading
    try:
        import tkinter as tk
        from tkinter import ttk
        window = tk.Tk()
    except (ImportError, OSError, RuntimeError):
        run_apply(root, request)
        return

    window.title('Atualizando EVRYLUX')
    window.resizable(False, False)
    window.geometry('440x180')
    window.protocol('WM_DELETE_WINDOW', window.iconify)
    label = ttk.Label(window, text='Preparando atualização...', wraplength=400)
    label.pack(fill='x', padx=20, pady=(22, 12))
    bar = ttk.Progressbar(window, maximum=100, mode='determinate')
    bar.pack(fill='x', padx=20)
    details = ttk.Label(window, text='O aplicativo será reaberto automaticamente.')
    details.pack(fill='x', padx=20, pady=12)
    result = {'done': False, 'error': None}

    def worker():
        try:
            run_apply(root, request)
        except Exception as error:
            result['error'] = str(error)
            progress(root, 'failed', 0, result['error'])
        finally:
            result['done'] = True

    threading.Thread(target=worker, daemon=False).start()

    def refresh():
        try:
            state = read_json(root / 'state' / 'progress.json', 4096)
            label.configure(text=state.get('message', 'Atualizando...'))
            bar['value'] = max(0, min(100, float(state.get('fraction', 0)) * 100))
        except (FileNotFoundError, ValueError, KeyError):
            pass
        if result['done']:
            if result['error'] is None:
                window.after(1200, window.destroy)
            else:
                details.configure(text='A versão anterior foi preservada. '
                                      'Consulte o estado da atualização antes de tentar novamente.')
                ttk.Button(window, text='Fechar', command=window.destroy).pack(pady=4)
            return
        window.after(250, refresh)

    window.after(250, refresh)
    window.mainloop()
    if result['error'] is not None:
        raise RuntimeError(result['error'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['bootstrap', 'apply', 'launch', 'health'])
    parser.add_argument('--package')
    parser.add_argument('--envelope')
    parser.add_argument('--trust')
    parser.add_argument('--request')
    parser.add_argument('--nonce')
    parser.add_argument('--version')
    parser.add_argument('--ui', action='store_true')
    args = parser.parse_args()
    if os.name != 'nt':
        os.umask(0o077)
    root = install_root()
    safe_dir(root)
    if args.action == 'health':
        if not args.nonce or not args.version:
            parser.error('health requer nonce e version.')
        transaction = read_json(transaction_path(root))
        if transaction.get('status') != 'pending' or \
                transaction.get('nonce') != args.nonce or \
                transaction.get('target') != args.version:
            raise RuntimeError('Confirmação de saúde inválida.')
        atomic_json(root / 'state' / 'health.json',
                    {'nonce': args.nonce, 'version': args.version})
        return
    with lock(root):
        if args.action == 'bootstrap':
            if not all((args.package, args.envelope, args.trust)):
                parser.error('bootstrap requer package, envelope e trust.')
            bootstrap(root, Path(args.package), read_json(Path(args.envelope)),
                      read_json(Path(args.trust)))
        elif args.action == 'apply':
            if not args.request:
                parser.error('apply requer request.')
            request = Path(args.request).resolve(strict=True)
            if request.parent != root / 'state' / 'inbox':
                raise RuntimeError('Solicitação fora da pasta permitida.')
            request_data = read_json(request)
            if args.ui:
                apply_with_ui(root, request_data)
            else:
                run_apply(root, request_data)
        elif args.action == 'launch':
            transaction = transaction_path(root)
            if transaction.exists():
                state = read_json(transaction)
                if state.get('status') in ('pending', 'needs_recovery'):
                    if managed_processes(root):
                        raise RuntimeError('Feche todas as janelas antes da recuperação.')
                    rollback(root, state, 'Recuperação após interrupção.')
            launch(root)



if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        message = 'EVRYLUX updater: ' + str(error)
        if sys.stderr is not None:
            print(message, file=sys.stderr)
        elif os.name == 'nt':
            import ctypes
            ctypes.windll.user32.MessageBoxW(None, message, 'EVRYLUX', 0x10)
        sys.exit(1)
