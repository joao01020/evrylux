import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'update_installation_service.dart';

/// Local backup inspection/export only. Never restores into a live app.
class RecoveryBackup {
  const RecoveryBackup(this.path, this.createdAt);
  final String path;
  final DateTime createdAt;
  String get name => p.basename(path);
}

class RecoveryInspection {
  const RecoveryInspection(this.fileCount, this.bytes, this.files);
  final int fileCount;
  final int bytes;
  final Map<String, String> files;
}

class UpdateRecoveryService {
  const UpdateRecoveryService({this.rootOverride});
  final String? rootOverride;

  String get root => p.normalize(
    p.absolute(rootOverride ?? UpdateInstallationService.installRoot.path),
  );

  Future<List<RecoveryBackup>> listBackups() async =>
      Isolate.run(() => _list(root));

  Future<RecoveryInspection> inspect(String backup) async =>
      Isolate.run(() => _inspect(root, backup));

  /// Creates a NEW directory in [parent]. Never overwrites the live data.
  Future<String> export(String backup, String parent) async =>
      Isolate.run(() => _export(root, backup, parent));
}

void _requireDirectory(String path) {
  var current = p.normalize(p.absolute(path));
  while (true) {
    final type = FileSystemEntity.typeSync(current, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      throw StateError('Diretório ausente ou link simbólico: $current');
    }
    final next = p.dirname(current);
    if (next == current) return;
    current = next;
  }
}

void _requireRegular(String path) {
  if (FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw StateError('Arquivo inválido ou link simbólico: $path');
  }
}

bool _within(String path, String parent) =>
    path == parent || p.isWithin(parent, path);

String _backupPath(String root, String backup) {
  _requireDirectory(root);
  final base = p.join(root, 'backups');
  _requireDirectory(base);
  final selected = p.normalize(p.absolute(backup));
  if (p.dirname(selected) != base) {
    throw StateError('Backup fora da instalação selecionada.');
  }
  _requireDirectory(selected);
  return selected;
}

List<RecoveryBackup> _list(String root) {
  if (!Platform.isLinux) return [];
  final base = p.join(root, 'backups');
  if (!Directory(base).existsSync()) return [];
  _requireDirectory(base);
  final result = <RecoveryBackup>[];
  for (final entry in Directory(base).listSync(followLinks: false)) {
    if (entry is! Directory) continue;
    try {
      final path = _backupPath(root, entry.path);
      _requireRegular(p.join(path, 'backup.json'));
      result.add(RecoveryBackup(path, entry.statSync().modified));
    } catch (_) {
      // An incomplete backup is not presented as a recovery candidate.
    }
  }
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

Set<String> _labels(String backup) {
  final metadata = File(p.join(backup, 'backup.json'));
  _requireRegular(metadata.path);
  if (metadata.lengthSync() > 1024 * 1024) {
    throw StateError('Metadados de backup excessivos.');
  }
  final data = jsonDecode(metadata.readAsStringSync());
  if (data is! Map || data['sources'] is! List) {
    throw StateError('Metadados de backup inválidos.');
  }
  final labels = <String>{};
  final sources = data['sources'] as List;
  if (sources.isEmpty) throw StateError('Backup sem fontes.');
  for (final item in sources) {
    if (item is! Map ||
        item['source'] is! String ||
        !{'support', 'documents'}.contains(item['backup']) ||
        !labels.add(item['backup'] as String)) {
      throw StateError('Fonte de backup inválida ou duplicada.');
    }
  }
  return labels;
}

bool _isSqlite(String path) =>
    {'.db', '.sqlite', '.sqlite3'}.contains(p.extension(path).toLowerCase());

void _checkSqlite(String path) {
  for (final suffix in ['-wal', '-shm', '-journal']) {
    if (FileSystemEntity.typeSync('$path$suffix', followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw StateError('Snapshot SQLite com arquivo auxiliar.');
    }
  }
  final db = sqlite3.open(
    '${Uri.file(path)}?mode=ro&immutable=1',
    mode: OpenMode.readOnly,
    uri: true,
  );
  try {
    // Read-only quick_check; no migration or write is performed.
    if (db.select('PRAGMA quick_check').first.values.first != 'ok') {
      throw StateError('Integridade SQLite inválida.');
    }
  } finally {
    db.dispose();
  }
}

String _hash(String path) {
  _requireRegular(path);
  final digest = Sha256().toSync().newHashSink();
  final input = File(path).openSync();
  try {
    final buffer = List<int>.filled(1024 * 1024, 0);
    while (true) {
      final count = input.readIntoSync(buffer);
      if (count == 0) break;
      digest.add(buffer.sublist(0, count));
    }
    digest.close();
    return digest
        .hashSync()
        .bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  } finally {
    input.closeSync();
  }
}

RecoveryInspection _inventory(String backup, Set<String> labels) {
  final files = <String, String>{};
  var bytes = 0;
  for (final label in labels) {
    final base = p.join(backup, label);
    _requireDirectory(base);
    for (final entry in Directory(
      base,
    ).listSync(recursive: true, followLinks: false)) {
      final type = FileSystemEntity.typeSync(entry.path, followLinks: false);
      if (type == FileSystemEntityType.directory) continue;
      if (type != FileSystemEntityType.file) {
        throw StateError('Backup contém link ou arquivo especial.');
      }
      final relative = p.relative(entry.path, from: backup);
      if (_isSqlite(entry.path)) _checkSqlite(entry.path);
      bytes += File(entry.path).lengthSync();
      files[relative] = _hash(entry.path);
    }
  }
  return RecoveryInspection(files.length, bytes, files);
}

RecoveryInspection _inspect(String root, String backup) {
  if (!Platform.isLinux) {
    throw UnsupportedError('Recuperação disponível somente no Linux.');
  }
  final selected = _backupPath(root, backup);
  return _inventory(selected, _labels(selected));
}

String _export(String root, String backup, String parent) {
  final selected = _backupPath(root, backup);
  final original = _inspect(root, selected);
  final destinationParent = p.normalize(p.absolute(parent));
  _requireDirectory(destinationParent);
  if (_within(destinationParent, root) || _within(root, destinationParent)) {
    throw StateError('Escolha uma pasta fora da instalação.');
  }
  // createTempSync atomically allocates a fresh directory; never reuse one.
  final destination = Directory(
    destinationParent,
  ).createTempSync('evrylux-recuperacao-');
  // The root must be private before any sensitive bytes are copied.
  final protect = Process.runSync('chmod', ['0700', '--', destination.path]);
  if (protect.exitCode != 0 || (destination.statSync().mode & 0x3f) != 0) {
    throw StateError('Não foi possível proteger a pasta de recuperação.');
  }
  try {
    for (final entry in original.files.entries) {
      final source = p.join(selected, entry.key);
      _requireDirectory(p.dirname(source));
      _requireRegular(source);
      final target = File(p.join(destination.path, entry.key));
      target.parent.createSync(recursive: true);
      final input = File(source).openSync();
      final output = target.openSync(mode: FileMode.writeOnly);
      try {
        final buffer = List<int>.filled(1024 * 1024, 0);
        while (true) {
          final count = input.readIntoSync(buffer);
          if (count == 0) break;
          output.writeFromSync(buffer, 0, count);
        }
        output.flushSync();
      } finally {
        output.closeSync();
        input.closeSync();
      }
      if (_hash(target.path) != entry.value) {
        throw StateError('Cópia não corresponde ao backup.');
      }
    }
    final copied = _inventory(destination.path, _labels(selected));
    if (copied.files.length != original.files.length ||
        copied.files.entries.any((e) => original.files[e.key] != e.value)) {
      throw StateError('Inventário da cópia não corresponde ao backup.');
    }
    final receipt = File(
      p.join(destination.path, 'recovery-receipt.json'),
    ).openSync(mode: FileMode.writeOnly);
    try {
      receipt.writeStringSync(
        jsonEncode({
          'format': 1,
          'mode': 'non-destructive-export',
          'sourceBackup': selected,
          'files': copied.files,
        }),
      );
      receipt.flushSync();
    } finally {
      receipt.closeSync();
    }
    final protectFiles = Process.runSync('chmod', [
      '-R',
      'go-rwx',
      '--',
      destination.path,
    ]);
    if (protectFiles.exitCode != 0) {
      throw StateError('Não foi possível restringir as permissões da cópia.');
    }
    return destination.path;
  } catch (_) {
    // Keep a partial export for inspection. Never touch its source.
    rethrow;
  }
}
