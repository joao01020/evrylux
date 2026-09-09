#!/usr/bin/env python3
"""Build a local, signed EVRYLUX release on its target operating system."""
import argparse
import base64
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import zipfile

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

APP = Path(__file__).resolve().parents[2]
HELPER = Path(__file__).with_name('updater_helper.py')


def run(command, cwd=APP):
    subprocess.run(command, cwd=cwd, check=True)


def read_private(path):
    data = json.loads(Path(path).read_text())
    key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(data['seed']))
    public = key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    if base64.b64encode(public).decode() != data['publicKey']:
        raise RuntimeError('A chave pública não corresponde à privada.')
    return data['keyId'], key, data['publicKey']


def sign_manifest(manifest, key):
    payload = json.dumps(manifest, ensure_ascii=False, separators=(',', ':')).encode()
    return {
        'keyId': key[0],
        'payload': base64.b64encode(payload).decode(),
        'signature': base64.b64encode(key[1].sign(payload)).decode(),
    }


def configuration(path, key):
    config = json.loads(Path(path).read_text())
    if (config.get('EVRYLUX_UPDATE_KEY_ID') != key[0] or
            config.get('EVRYLUX_UPDATE_PUBLIC_KEY') != key[2]):
        raise RuntimeError('A configuração do build não corresponde à chave de release.')
    from urllib.parse import urlparse
    manifest_url = config.get('EVRYLUX_UPDATE_MANIFEST_URL', '')
    host = config.get('EVRYLUX_UPDATE_DOWNLOAD_HOST', '')
    url = urlparse(manifest_url)
    if url.scheme != 'https' or not url.hostname or url.port or url.username:
        raise RuntimeError('Configure uma URL HTTPS real para o manifesto.')
    if not host or any(c in host for c in '/:') or host == 'updates.example.com':
        raise RuntimeError('Configure o domínio público real do R2.')
    if url.hostname == 'updates.example.com' or 'SUBSTITUA' in manifest_url:
        raise RuntimeError('URL de exemplo não permitida.')
    if 'SUBSTITUA' in config.get('EVRYLUX_UPDATE_PUBLIC_KEY', ''):
        raise RuntimeError('Chave pública de exemplo não permitida.')
    return config


def source_version():
    app_info = (APP / 'lib/core/constants/app_info.dart').read_text()
    db = (APP / 'lib/core/database/app_database.dart').read_text()
    version = re.search(r"static const String version = '([^']+)';", app_info)
    schema = re.search(r'static const int _schemaVersion = (\d+);', db)
    if not version or not schema:
        raise RuntimeError('Não foi possível identificar versão/esquema do código.')
    return version.group(1), int(schema.group(1))


def audit_public_env():
    path = APP / '.env'
    if not path.exists():
        raise RuntimeError('O asset .env não foi encontrado.')
    allowed = {'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_ANON_KEY'}
    keys = set()
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            keys.add(line.split('=', 1)[0].strip())
    unexpected = sorted(keys - allowed)
    if unexpected:
        raise RuntimeError('Variáveis não autorizadas no asset .env: ' +
                           ', '.join(unexpected) +
                           '. Remova segredos antes de gerar uma release.')


def host_platform():
    system = platform.system().lower()
    machine = platform.machine().lower()
    if system not in ('linux', 'windows'):
        raise RuntimeError('Build suportado somente em Linux/Windows.')
    if machine not in ('x86_64', 'amd64'):
        raise RuntimeError('Este script prepara builds x64. ARM64 requer pipeline específico.')
    return system, 'x64'


def bundle_files(bundle):
    for path in sorted(bundle.rglob('*')):
        if path.is_symlink():
            raise RuntimeError('Symlink no bundle; prepare arquivos regulares: ' + str(path))
        if not (path.is_file() or path.is_dir()):
            raise RuntimeError('Arquivo especial no bundle.')
        relative = path.relative_to(bundle).as_posix()
        if relative == 'release-receipt.json':
            raise RuntimeError('Nome reservado no bundle.')
        yield path, relative


def package_bundle(bundle, output, system):
    if system == 'linux':
        with tarfile.open(output, 'w:gz') as archive:
            for path, relative in bundle_files(bundle):
                info = archive.gettarinfo(str(path), arcname=relative)
                info.uid = info.gid = 0
                info.uname = info.gname = ''
                info.mode &= 0o755 if path.is_dir() else 0o755
                with path.open('rb') if path.is_file() else __import__('contextlib').nullcontext() as source:
                    archive.addfile(info, source)
    else:
        with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, allowZip64=True) as archive:
            for path, relative in bundle_files(bundle):
                if path.is_file():
                    archive.write(path, relative)
                else:
                    archive.writestr(relative + '/', b'')


def build(args):
    system, arch = host_platform()
    version, schema = source_version()
    key = read_private(args.key)
    config = configuration(args.config, key)
    audit_public_env()
    if args.version != version:
        raise RuntimeError('A versão solicitada difere de AppInfo.version.')
    if not shutil.which('flutter'):
        raise RuntimeError('Flutter não encontrado no PATH.')
    try:
        import PyInstaller.__main__
        import tkinter
    except ImportError as error:
        raise RuntimeError('Instale requirements.txt e o suporte Tk antes do build.') from error

    out = Path(args.out).expanduser().resolve()
    out.mkdir(parents=True, exist_ok=True)
    build_dir = out / 'build-helper'
    helper_out = out / 'helper'
    helper_out.mkdir(exist_ok=True)
    name = 'evrylux-updater-helper'

    run([
        sys.executable, '-m', 'PyInstaller', '--clean', '--noconfirm',
        '--onefile', '--name', name,
        '--distpath', str(helper_out),
        '--workpath', str(build_dir),
        '--specpath', str(build_dir),
        *(['--windowed'] if system == 'windows' else []),
        str(HELPER),
    ])
    helper_exe = helper_out / (name + ('.exe' if system == 'windows' else ''))
    if not helper_exe.is_file():
        raise RuntimeError('Executável auxiliar não foi gerado.')

    run([
        'flutter', 'build', system, '--release',
        '--dart-define-from-file=' + str(Path(args.config).resolve()),
        '--dart-define=EVRYLUX_MANAGED_RELEASE=true',
    ])

    if system == 'linux':
        bundle = APP / 'build/linux/x64/release/bundle'
    else:
        bundle = APP / 'build/windows/x64/runner/Release'
    if not bundle.is_dir():
        raise RuntimeError('Bundle Flutter não encontrado: ' + str(bundle))

    # Windows runner names can differ; normalize the packaged executable.
    staging = out / 'bundle'
    if staging.exists():
        shutil.rmtree(staging)
    # Reject symlinks before copying; never follow an unexpected build link.
    list(bundle_files(bundle))
    shutil.copytree(bundle, staging, symlinks=False)
    if system == 'windows':
        binaries = list(staging.glob('*.exe'))
        if len(binaries) != 1:
            raise RuntimeError('Esperado exatamente um executável Flutter Windows.')
        if binaries[0].name != 'EVRYLUX.exe':
            binaries[0].rename(staging / 'EVRYLUX.exe')

    package_name = f'evrylux-{version}-{system}-{arch}.' + (
        'zip' if system == 'windows' else 'tar.gz'
    )
    package = out / package_name
    package_bundle(staging, package, system)
    hasher = hashlib.sha256()
    with package.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(chunk)
    digest = hasher.hexdigest()
    asset = {
        'platform': system, 'architecture': arch,
        'format': 'zip' if system == 'windows' else 'tar.gz',
        'url': args.base_url.rstrip('/') + '/releases/' + version + '/' + package_name,
        'size': package.stat().st_size, 'sha256': digest,
    }
    from urllib.parse import urlparse
    parsed = urlparse(asset['url'])
    if (parsed.scheme != 'https' or
            parsed.hostname != config['EVRYLUX_UPDATE_DOWNLOAD_HOST'] or
            parsed.port or parsed.username or parsed.password or
            parsed.fragment or parsed.query):
        raise RuntimeError('URL do pacote não corresponde ao domínio autorizado.')
    (out / 'asset.json').write_text(json.dumps(asset, indent=2) + '\n')
    manifest = {
        'schema': 1, 'appId': 'evrylux', 'channel': 'stable',
        'version': version,
        'publishedAt': datetime.now(timezone.utc).isoformat(),
        'minDataSchema': schema, 'maxDataSchema': schema,
        'dataSchema': schema,
        'assets': [asset],
    }
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (out / 'manifest.signed.json').write_text(
        json.dumps(sign_manifest(manifest, key), indent=2) + '\n')
    (out / 'trust.json').write_text(json.dumps({
        'channel': 'stable', 'keys': {key[0]: key[2]},
    }, indent=2) + '\n')
    print('Release local gerada:', out)
    print('Não publique o manifesto de uma plataforma sobre o de outra.')
    print('Una os assets Linux/Windows antes de publicar um manifesto global.')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', required=True)
    parser.add_argument('--key', required=True)
    parser.add_argument('--config', required=True)
    parser.add_argument('--base-url', required=True)
    parser.add_argument('--out', required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()
