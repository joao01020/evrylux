import base64
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sqlite3
import stat
import sys
import tarfile
import tempfile
import unittest
from unittest import mock

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

HELPER_PATH = Path(__file__).resolve().parents[1] / 'updater_helper.py'
spec = importlib.util.spec_from_file_location('evrylux_helper_tested', HELPER_PATH)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)



class _FakeProcess:
    def __init__(self, running=True):
        self.running = running

    def poll(self):
        return None if self.running else 0

    def terminate(self):
        self.running = False

    def wait(self, timeout=None):
        self.running = False
        return 0


class UpdaterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home'
        self.home.mkdir()
        self.root = self.home / '.local/share/evrylux/installation'
        self.root.mkdir(parents=True)
        self.home_patch = mock.patch.object(Path, 'home', return_value=self.home)
        self.home_patch.start()
        self.addCleanup(self.home_patch.stop)
        self.private = Ed25519PrivateKey.generate()
        self.public = base64.b64encode(self.private.public_key().public_bytes(
            serialization.Encoding.Raw, serialization.PublicFormat.Raw,
        )).decode()
        self.trust = {'channel': 'stable', 'keys': {'test': self.public}}

    def manifest(self, version='1.0.0', schema=7, bad=False):
        data = {
            'schema': 1, 'appId': 'evrylux', 'channel': 'stable',
            'version': version, 'dataSchema': schema,
            'minDataSchema': schema, 'maxDataSchema': schema,
            'assets': [],
        }
        return data

    def sign(self, manifest):
        payload = json.dumps(manifest, separators=(',', ':')).encode()
        return {
            'keyId': 'test',
            'payload': base64.b64encode(payload).decode(),
            'signature': base64.b64encode(self.private.sign(payload)).decode(),
        }

    def bundle(self, version='1.0.0', schema=7, healthy=True):
        script = f"""#!{sys.executable} -S
import json, pathlib, sys, time, os
if '--evrylux-update-preflight' in sys.argv:
    print('EVRYLUX_PREFLIGHT:' + json.dumps({{'version': '{version}', 'dataSchema': {schema}}}))
    sys.exit(0)
if {healthy!r}:
    args = [x for x in sys.argv if x.startswith('--evrylux-update-health=')]
    if args:
        nonce = args[0].split('=', 1)[1]
        root = pathlib.Path(__file__).resolve().parents[2]
        path = root / 'state' / 'health.json'
        temp = path.with_suffix('.tmp')
        temp.write_text(json.dumps({{'nonce': nonce, 'version': '{version}'}}))
        os.replace(temp, path)
        time.sleep(2)
sys.exit(0)
"""
        return {
            'app': (script.encode(), 0o755),
            'data/flutter_assets/AssetManifest.bin': (b'test', 0o644),
            'lib/libflutter_linux_gtk.so': (b'test', 0o644),
        }

    def package(self, manifest, files):
        path = self.home / ('package-' + manifest['version'] + '.tar.gz')
        with tarfile.open(path, 'w:gz') as tar:
            for name, (data, mode) in files.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                info.mode = mode
                tar.addfile(info, io.BytesIO(data))
        size, digest = helper.sha256_file(path)
        manifest['assets'] = [{
            'platform': 'linux', 'architecture': 'x64', 'format': 'tar.gz',
            'url': 'https://updates.example.com/package.tar.gz',
            'size': size, 'sha256': digest,
        }]
        return path, self.sign(manifest)

    def bootstrap(self, version='1.0.0', schema=7):
        manifest = self.manifest(version, schema)
        package, envelope = self.package(manifest, self.bundle(version, schema))
        helper.bootstrap(self.root, package, envelope, self.trust)
        return package, envelope

    def request(self, version='1.0.1', schema=7, healthy=True):
        manifest = self.manifest(version, schema)
        package, envelope = self.package(manifest, self.bundle(version, schema, healthy))
        staging = self.root / 'staging'
        staging.mkdir(exist_ok=True)
        target = staging / 'package.verified'
        package.replace(target)
        support = self.home / 'support'
        support.mkdir(exist_ok=True)
        with contextlib.closing(sqlite3.connect(support / 'ghost_core.db')) as db:
            db.execute('CREATE TABLE IF NOT EXISTS notes (value TEXT)')
        return {
            'envelope': envelope, 'package': str(target),
            'version': version, 'previous': '1.0.0',
            'pid': os.getpid(), 'nonce': 'a' * 64,
            'support': str(support),
            'documents': str(self.home / 'Documents/evrylux'),
        }

    def test_signature_and_tampering(self):
        manifest = self.manifest()
        envelope = self.sign(manifest)
        self.assertEqual(helper.verify_envelope(envelope, self.trust), manifest)
        envelope['payload'] = base64.b64encode(b'{"version":"9.9.9"}').decode()
        with self.assertRaises(Exception):
            helper.verify_envelope(envelope, self.trust)

    def test_semver(self):
        self.assertGreater(helper.compare_versions('1.0.1', '1.0.0'), 0)
        self.assertLess(helper.compare_versions('1.0.1-beta.1', '1.0.1'), 0)
        self.assertEqual(helper.compare_versions('1.0.1+2', '1.0.1+1'), 0)
        with self.assertRaises(RuntimeError):
            helper.version('1.0.1-01')

    def test_rejects_traversal_and_links(self):
        for name in ('../outside', '/tmp/outside', 'C:/outside'):
            with self.assertRaises(RuntimeError):
                helper.safe_name(name)
        package = self.home / 'evil.tar.gz'
        with tarfile.open(package, 'w:gz') as tar:
            entry = tarfile.TarInfo('link')
            entry.type = tarfile.SYMTYPE
            entry.linkname = '/tmp'
            tar.addfile(entry)
        with self.assertRaises(RuntimeError):
            helper.extract_package(package, self.root / 'bad')
        self.assertFalse((self.home / 'outside').exists())

    def test_bootstrap_and_successful_update(self):
        self.bootstrap()
        self.assertEqual(helper.current(self.root), '1.0.0')
        request = self.request()
        def fake_launch(root, version, health=None):
            process = _FakeProcess()
            if health is not None:
                helper.atomic_json(root / 'state' / 'health.json', {
                    'nonce': health,
                    'version': version,
                })
            return process

        with mock.patch.object(helper, 'wait_for_exit', return_value=None), \
             mock.patch.object(helper, 'launch', side_effect=fake_launch):
            helper.apply(self.root, request)
        self.assertEqual(helper.current(self.root), '1.0.1')
        self.assertEqual(helper.read_json(helper.transaction_path(self.root))['status'], 'healthy')
        self.assertTrue(Path(helper.read_json(helper.transaction_path(self.root))['backup']).exists())

    def test_failed_start_restores_previous_version(self):
        self.bootstrap()
        request = self.request(healthy=False)
        launched = []

        def fake_launch(root, version, health=None):
            launched.append((version, health))
            return _FakeProcess()

        with mock.patch.object(helper, 'wait_for_exit', return_value=None), \
             mock.patch.object(helper, 'launch', side_effect=fake_launch), \
             mock.patch.object(helper.time, 'sleep', return_value=None), \
             mock.patch.object(
                 helper.time,
                 'monotonic',
                 side_effect=iter([0, 91, 91, 91]),
             ):
            with self.assertRaises(RuntimeError):
                helper.apply(self.root, request)

        self.assertEqual(launched[0][0], '1.0.1')
        self.assertEqual(launched[-1][0], '1.0.0')
        self.assertEqual(helper.current(self.root), '1.0.0')
        self.assertEqual(helper.read_json(helper.transaction_path(self.root))['status'], 'rolled_back')

    def test_schema_change_is_blocked(self):
        self.bootstrap()
        request = self.request(schema=8)
        with self.assertRaises(RuntimeError):
            helper.apply(self.root, request)
        self.assertEqual(helper.current(self.root), '1.0.0')
        self.assertFalse(helper.transaction_path(self.root).exists())

    def test_sqlite_wal_backup(self):
        support = self.home / 'support'
        support.mkdir()
        path = support / 'ghost_core.db'
        db = sqlite3.connect(path)
        db.execute('PRAGMA journal_mode=WAL')
        db.execute('PRAGMA wal_autocheckpoint=0')
        db.execute('CREATE TABLE notes (value TEXT)')
        db.execute('INSERT INTO notes VALUES (?)', ('preservado',))
        db.commit()
        backup = helper.snapshot_data(self.root, support, None)
        with contextlib.closing(sqlite3.connect(backup / 'support/ghost_core.db')) as copy:
            self.assertEqual(copy.execute('SELECT value FROM notes').fetchone()[0], 'preservado')
            self.assertEqual(copy.execute('PRAGMA quick_check').fetchone()[0], 'ok')
        self.assertFalse((backup / 'support/ghost_core.db-wal').exists())
        db.close()

    def test_existing_release_tampering_is_rejected(self):
        self.bootstrap()
        binary = helper.binary(self.root, '1.0.0')
        binary.write_text('alterado')
        with self.assertRaises(RuntimeError):
            helper.verify_installed(self.root, '1.0.0')

    def test_health_ack_does_not_wait_for_install_lock(self):
        self.bootstrap()
        helper.atomic_json(helper.transaction_path(self.root), {
            'status': 'pending', 'target': '1.0.0',
            'previous': '1.0.0', 'nonce': 'b' * 64,
        })
        with mock.patch.object(helper, 'install_root', return_value=self.root), \
             mock.patch.object(sys, 'argv', ['helper', 'health', '--nonce', 'b' * 64,
                                          '--version', '1.0.0']):
            with helper.lock(self.root):
                helper.main()
        self.assertEqual(helper.read_json(self.root / 'state/health.json')['nonce'], 'b' * 64)


if __name__ == '__main__':
    unittest.main()
