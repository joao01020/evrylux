import 'dart:convert';
import 'dart:io';

import 'package:EVRYLUX/core/updater/update_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory temporary;
  late Directory root;
  late Directory backup;
  late Directory exports;
  late UpdateRecoveryService service;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('evrylux-recovery-test-');
    root = Directory(p.join(temporary.path, 'installation'))..createSync();
    backup = Directory(p.join(root.path, 'backups', 'snapshot-1'))
      ..createSync(recursive: true);
    final support = Directory(p.join(backup.path, 'support'))..createSync();
    final documents = Directory(p.join(backup.path, 'documents'))..createSync();
    File(p.join(documents.path, 'note.txt')).writeAsStringSync('antes');
    final db = sqlite3.open(p.join(support.path, 'ghost_core.db'));
    try {
      db.execute('CREATE TABLE notes (value TEXT)');
      db.execute("INSERT INTO notes VALUES ('antes')");
    } finally {
      db.dispose();
    }
    File(p.join(backup.path, 'backup.json')).writeAsStringSync(jsonEncode({
      'sources': [
        {'source': '/temporary/support', 'backup': 'support'},
        {'source': '/temporary/documents', 'backup': 'documents'},
      ],
    }));
    exports = Directory(p.join(temporary.path, 'exports'))..createSync();
    service = UpdateRecoveryService(rootOverride: root.path);
  });

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  test('verifica e exporta sem alterar o backup', () async {
    if (!Platform.isLinux) return;
    final before = await service.inspect(backup.path);
    expect(before.fileCount, 2);
    final destination = await service.export(backup.path, exports.path);
    expect(File(p.join(destination, 'documents/note.txt')).readAsStringSync(),
        'antes');
    expect(File(p.join(backup.path, 'documents/note.txt')).readAsStringSync(),
        'antes');
    final copied = sqlite3.open(
      p.join(destination, 'support', 'ghost_core.db'),
      mode: OpenMode.readOnly,
    );
    try {
      expect(copied.select('SELECT value FROM notes').single['value'], 'antes');
    } finally {
      copied.dispose();
    }
    expect((await service.inspect(backup.path)).files, before.files);
    expect(File(p.join(destination, 'recovery-receipt.json')).existsSync(), true);
    expect(await service.export(backup.path, exports.path), isNot(destination));
  });

  test('recusa backup fora da instalação e destino sobreposto', () async {
    if (!Platform.isLinux) return;
    final outside = Directory(p.join(temporary.path, 'outside'))..createSync();
    await expectLater(service.inspect(outside.path), throwsStateError);
    await expectLater(service.export(backup.path, root.path), throwsStateError);
    await expectLater(
      service.export(backup.path, temporary.path),
      throwsStateError,
    );
  });

  test('recusa corrupção e link simbólico', () async {
    if (!Platform.isLinux) return;
    final db = File(p.join(backup.path, 'support', 'ghost_core.db'));
    final original = db.readAsBytesSync();
    db.writeAsBytesSync([1, 2, 3, 4]);
    await expectLater(service.inspect(backup.path), throwsA(isA<Exception>()));
    db.writeAsBytesSync(original);
    final link = Link(p.join(backup.path, 'documents', 'link'));
    link.createSync('/etc/passwd');
    await expectLater(service.inspect(backup.path), throwsStateError);
  });
}
