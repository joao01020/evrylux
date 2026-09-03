import 'dart:convert';

import '../models/brain_backup_package.dart';

class BrainBackupSerializer {
  const BrainBackupSerializer();

  String serializePackage(BrainBackupPackage package) {
    return jsonEncode(package.toJson());
  }

  BrainBackupPackage deserializePackage(String raw) {
    final normalized = raw.trim();

    if (normalized.isEmpty) {
      throw const FormatException('Arquivo .evbrain vazio.');
    }

    final decoded = jsonDecode(normalized);

    if (decoded is! Map) {
      throw const FormatException('Estrutura .evbrain inválida.');
    }

    return BrainBackupPackage.fromJson(Map<String, dynamic>.from(decoded));
  }

  String serializeArchive({
    required String vaultId,
    required List<String> objects,
  }) {
    final normalizedVaultId = vaultId.trim();

    if (normalizedVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    return jsonEncode(<String, dynamic>{
      'format': 'evrylux-brain-backup-archive',
      'format_version': 1,
      'vault_id': normalizedVaultId,
      'objects': objects,
    });
  }

  BrainBackupArchive deserializeArchive(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw const FormatException('Archive interno do .evbrain inválido.');
    }

    final map = Map<String, dynamic>.from(decoded);

    if (map['format'] != 'evrylux-brain-backup-archive') {
      throw const FormatException('Formato do archive interno inválido.');
    }

    final formatVersion = map['format_version'];

    if (formatVersion != 1) {
      throw FormatException(
        'Versão do archive interno não suportada: '
        '$formatVersion',
      );
    }

    final vaultId = map['vault_id']?.toString().trim() ?? '';

    if (vaultId.isEmpty) {
      throw const FormatException('vault_id ausente no archive interno.');
    }

    final rawObjects = map['objects'];

    if (rawObjects is! List) {
      throw const FormatException(
        'Lista de objetos ausente no archive interno.',
      );
    }

    final objects = <String>[];

    for (final item in rawObjects) {
      final value = item?.toString() ?? '';

      if (value.trim().isEmpty) {
        throw const FormatException('Objeto vazio no archive interno.');
      }

      objects.add(value);
    }

    return BrainBackupArchive(vaultId: vaultId, objects: objects);
  }
}

class BrainBackupArchive {
  const BrainBackupArchive({required this.vaultId, required this.objects});

  final String vaultId;
  final List<String> objects;
}
