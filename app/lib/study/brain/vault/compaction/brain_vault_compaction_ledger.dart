import 'dart:convert';

class BrainVaultCompactionFloor {
  const BrainVaultCompactionFloor({
    required this.objectId,
    required this.vaultId,
    required this.objectVersion,
    required this.deletedAt,
    required this.compactedAt,
  });

  final String objectId;
  final String vaultId;
  final int objectVersion;
  final DateTime deletedAt;
  final DateTime compactedAt;

  void validate() {
    if (objectId.trim().isEmpty) {
      throw const FormatException('Compaction floor sem objectId.');
    }
    if (vaultId.trim().isEmpty) {
      throw const FormatException('Compaction floor sem vaultId.');
    }
    if (objectVersion <= 0) {
      throw const FormatException('Compaction floor com objectVersion inválida.');
    }
    if (compactedAt.toUtc().isBefore(deletedAt.toUtc())) {
      throw const FormatException('compactedAt não pode ser anterior a deletedAt.');
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return <String, dynamic>{
      'object_id': objectId,
      'vault_id': vaultId,
      'object_version': objectVersion,
      'deleted_at': deletedAt.toUtc().toIso8601String(),
      'compacted_at': compactedAt.toUtc().toIso8601String(),
    };
  }

  factory BrainVaultCompactionFloor.fromJson(Map<String, dynamic> json) {
    final floor = BrainVaultCompactionFloor(
      objectId: json['object_id']?.toString().trim() ?? '',
      vaultId: json['vault_id']?.toString().trim() ?? '',
      objectVersion: _positiveInt(json['object_version'], 'object_version'),
      deletedAt: _date(json['deleted_at'], 'deleted_at'),
      compactedAt: _date(json['compacted_at'], 'compacted_at'),
    );
    floor.validate();
    return floor;
  }
}

class BrainVaultCompactionLedger {
  const BrainVaultCompactionLedger({
    required this.vaultId,
    required this.updatedAt,
    required this.floors,
  });

  static const String format = 'evrylux_brain_compaction_ledger';
  static const int formatVersion = 1;

  final String vaultId;
  final DateTime updatedAt;
  final Map<String, BrainVaultCompactionFloor> floors;

  factory BrainVaultCompactionLedger.empty({
    required String vaultId,
    DateTime? now,
  }) {
    return BrainVaultCompactionLedger(
      vaultId: vaultId,
      updatedAt: (now ?? DateTime.now()).toUtc(),
      floors: const <String, BrainVaultCompactionFloor>{},
    );
  }

  void validate() {
    if (vaultId.trim().isEmpty) {
      throw const FormatException('Compaction ledger sem vaultId.');
    }
    for (final entry in floors.entries) {
      entry.value.validate();
      if (entry.key != entry.value.objectId) {
        throw const FormatException('Chave do compaction ledger difere do objectId.');
      }
      if (entry.value.vaultId != vaultId) {
        throw const FormatException('Compaction floor pertence a outro Vault.');
      }
    }
  }

  BrainVaultCompactionFloor? floorFor(String objectId) => floors[objectId];

  BrainVaultCompactionLedger record(BrainVaultCompactionFloor incoming) {
    validate();
    incoming.validate();

    if (incoming.vaultId != vaultId) {
      throw ArgumentError('Compaction floor pertence a outro Vault.');
    }

    final existing = floors[incoming.objectId];
    if (existing != null && existing.objectVersion > incoming.objectVersion) {
      return this;
    }

    final next = <String, BrainVaultCompactionFloor>{...floors};
    if (existing == null || incoming.objectVersion >= existing.objectVersion) {
      next[incoming.objectId] = incoming;
    }

    return BrainVaultCompactionLedger(
      vaultId: vaultId,
      updatedAt: incoming.compactedAt.toUtc(),
      floors: Map<String, BrainVaultCompactionFloor>.unmodifiable(next),
    );
  }

  Map<String, dynamic> toJson() {
    validate();
    final orderedKeys = floors.keys.toList()..sort();
    return <String, dynamic>{
      'format': format,
      'format_version': formatVersion,
      'vault_id': vaultId,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'floors': <Map<String, dynamic>>[
        for (final key in orderedKeys) floors[key]!.toJson(),
      ],
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory BrainVaultCompactionLedger.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Compaction ledger inválido.');
    }
    final json = Map<String, dynamic>.from(decoded);
    if (json['format'] != format || json['format_version'] != formatVersion) {
      throw const FormatException('Formato do compaction ledger não suportado.');
    }
    final rawFloors = json['floors'];
    if (rawFloors is! List) {
      throw const FormatException('Lista de floors inválida.');
    }
    final floors = <String, BrainVaultCompactionFloor>{};
    for (final raw in rawFloors) {
      if (raw is! Map) {
        throw const FormatException('Entrada do compaction ledger inválida.');
      }
      final floor = BrainVaultCompactionFloor.fromJson(
        Map<String, dynamic>.from(raw),
      );
      final previous = floors[floor.objectId];
      if (previous != null && previous.objectVersion > floor.objectVersion) {
        continue;
      }
      floors[floor.objectId] = floor;
    }
    final ledger = BrainVaultCompactionLedger(
      vaultId: json['vault_id']?.toString().trim() ?? '',
      updatedAt: _date(json['updated_at'], 'updated_at'),
      floors: Map<String, BrainVaultCompactionFloor>.unmodifiable(floors),
    );
    ledger.validate();
    return ledger;
  }
}

int _positiveInt(Object? raw, String fieldName) {
  final value = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (value == null || value <= 0) {
    throw FormatException('$fieldName deve ser maior que zero.');
  }
  return value;
}

DateTime _date(Object? raw, String fieldName) {
  final value = DateTime.tryParse(raw?.toString() ?? '')?.toUtc();
  if (value == null) {
    throw FormatException('$fieldName inválido.');
  }
  return value;
}
