import 'dart:convert';
import 'dart:io';

class BrainBackupCompressionService {
  const BrainBackupCompressionService();

  String compressString(String value) {
    final bytes = utf8.encode(value);

    final compressed = gzip.encode(bytes);

    return base64Encode(compressed);
  }

  String decompressString(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw const FormatException('Blob comprimido vazio.');
    }

    final compressed = base64Decode(normalized);

    final bytes = gzip.decode(compressed);

    return utf8.decode(bytes);
  }
}
