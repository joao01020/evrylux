import 'brain_backup_header.dart';

class BrainBackupPackage {
  const BrainBackupPackage({
    required this.header,
    required this.encryptedPayloadObject,
  });

  final BrainBackupHeader header;

  /// BrainVaultObject serializado contendo o blob comprimido
  /// do backup já criptografado.
  ///
  /// A Master Key nunca é colocada neste arquivo.
  final String encryptedPayloadObject;

  factory BrainBackupPackage.fromJson(Map<String, dynamic> json) {
    final rawHeader = json['header'];

    if (rawHeader is! Map) {
      throw const FormatException('Header ausente no .evbrain.');
    }

    final rawPayload = json['encrypted_payload_object']?.toString() ?? '';

    if (rawPayload.trim().isEmpty) {
      throw const FormatException('Payload criptografado ausente no .evbrain.');
    }

    return BrainBackupPackage(
      header: BrainBackupHeader.fromJson(Map<String, dynamic>.from(rawHeader)),
      encryptedPayloadObject: rawPayload,
    );
  }

  Map<String, dynamic> toJson() {
    header.validate();

    if (encryptedPayloadObject.trim().isEmpty) {
      throw const FormatException('Payload criptografado vazio.');
    }

    return <String, dynamic>{
      'header': header.toJson(),
      'encrypted_payload_object': encryptedPayloadObject,
    };
  }
}
