import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/backup/services/brain_backup_compression_service.dart';

void main() {
  group('BrainBackupCompressionService', () {
    const service = BrainBackupCompressionService();

    test('round-trip preserva Unicode', () {
      const original =
          'C++ ponteiros 🧠🔐 — '
          'Português — Привет — 日本語';

      final compressed = service.compressString(original);

      final restored = service.decompressString(compressed);

      expect(restored, original);
    });

    test('entrada vazia falha ao descomprimir', () {
      expect(() {
        service.decompressString('   ');
      }, throwsFormatException);
    });
  });
}
