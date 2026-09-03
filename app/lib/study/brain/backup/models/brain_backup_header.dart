class BrainBackupHeader {
  const BrainBackupHeader({
    required this.format,
    required this.formatVersion,
    required this.vaultId,
    required this.cryptoVersion,
    required this.keyVersion,
    required this.objectCount,
    required this.createdAt,
  });

  static const String currentFormat = 'evrylux-brain-backup';

  static const int currentFormatVersion = 1;

  final String format;
  final int formatVersion;
  final String vaultId;
  final int cryptoVersion;
  final int keyVersion;
  final int objectCount;
  final DateTime createdAt;

  factory BrainBackupHeader.create({
    required String vaultId,
    required int cryptoVersion,
    required int keyVersion,
    required int objectCount,
    DateTime? createdAt,
  }) {
    final header = BrainBackupHeader(
      format: currentFormat,
      formatVersion: currentFormatVersion,
      vaultId: vaultId.trim(),
      cryptoVersion: cryptoVersion,
      keyVersion: keyVersion,
      objectCount: objectCount,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
    );

    header.validate();

    return header;
  }

  factory BrainBackupHeader.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString().trim() ?? '';

    final createdAt = DateTime.tryParse(createdAtRaw);

    if (createdAt == null) {
      throw const FormatException('created_at inválido no header do backup.');
    }

    final header = BrainBackupHeader(
      format: json['format']?.toString().trim() ?? '',
      formatVersion: _parseInt(
        json['format_version'],
        fieldName: 'format_version',
      ),
      vaultId: json['vault_id']?.toString().trim() ?? '',
      cryptoVersion: _parseInt(
        json['crypto_version'],
        fieldName: 'crypto_version',
      ),
      keyVersion: _parseInt(json['key_version'], fieldName: 'key_version'),
      objectCount: _parseInt(json['object_count'], fieldName: 'object_count'),
      createdAt: createdAt.toUtc(),
    );

    header.validate();

    return header;
  }

  Map<String, dynamic> toJson() {
    validate();

    return <String, dynamic>{
      'format': format,
      'format_version': formatVersion,
      'vault_id': vaultId,
      'crypto_version': cryptoVersion,
      'key_version': keyVersion,
      'object_count': objectCount,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  void validate() {
    if (format != currentFormat) {
      throw FormatException('Formato .evbrain inválido: $format');
    }

    if (formatVersion != currentFormatVersion) {
      throw FormatException(
        'Versão de .evbrain não suportada: '
        '$formatVersion',
      );
    }

    if (vaultId.trim().isEmpty) {
      throw const FormatException('vault_id ausente no backup.');
    }

    if (cryptoVersion <= 0) {
      throw const FormatException('crypto_version inválida no backup.');
    }

    if (keyVersion <= 0) {
      throw const FormatException('key_version inválida no backup.');
    }

    if (objectCount < 0) {
      throw const FormatException('object_count inválido no backup.');
    }
  }

  static int _parseInt(dynamic value, {required String fieldName}) {
    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString().trim() ?? '');

    if (parsed == null) {
      throw FormatException('$fieldName inválido no header do backup.');
    }

    return parsed;
  }
}
