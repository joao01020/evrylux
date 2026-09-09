import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'update_manifest.dart';

class UpdateManifestService {
  UpdateManifestService({
    required this.manifestUrl,
    required this.trustedPublicKeys,
    required this.allowedDownloadHosts,
  });

  final Uri manifestUrl;
  final Map<String, String> trustedPublicKeys;
  final Set<String> allowedDownloadHosts;

  static const int _maxEnvelopeBytes = 1024 * 1024;
  static const int _maxPayloadBytes = 256 * 1024;

  Future<UpdateManifest> fetchAndVerify() async {
    return verifyEnvelope(await fetchSignedEnvelope());
  }

  Future<String> fetchSignedEnvelope() async {
    if (manifestUrl.scheme != 'https' ||
        manifestUrl.host.isEmpty ||
        manifestUrl.userInfo.isNotEmpty ||
        manifestUrl.hasPort ||
        manifestUrl.fragment.isNotEmpty) {
      throw const FormatException('URL do manifesto não permitida.');
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(manifestUrl);
      request.followRedirects = false;
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Não foi possível consultar o manifesto.',
          uri: manifestUrl,
        );
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > _maxEnvelopeBytes) {
          throw const FormatException('Manifesto excede o tamanho permitido.');
        }
      }
      return utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  }

  Future<UpdateManifest> verifyEnvelope(String envelopeJson) async {
    final decoded = jsonDecode(envelopeJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Envelope de atualização inválido.');
    }

    final keyId = decoded['keyId'];
    final payloadBase64 = decoded['payload'];
    final signatureBase64 = decoded['signature'];

    if (keyId is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(keyId) ||
        payloadBase64 is! String ||
        signatureBase64 is! String) {
      throw const FormatException('Campos de assinatura inválidos.');
    }

    final trustedKey = trustedPublicKeys[keyId];
    if (trustedKey == null) {
      throw const FormatException('Chave de assinatura não confiável.');
    }

    // Reject oversized encoded fields before allocating decoded buffers.
    if (payloadBase64.length > ((_maxPayloadBytes + 2) ~/ 3) * 4 ||
        signatureBase64.length > 128 ||
        trustedKey.length > 128) {
      throw const FormatException('Envelope excede o tamanho permitido.');
    }

    final publicKeyBytes = base64Decode(trustedKey);
    final payloadBytes = base64Decode(payloadBase64);
    final signatureBytes = base64Decode(signatureBase64);

    if (publicKeyBytes.length != 32 ||
        signatureBytes.length != 64 ||
        payloadBytes.length > _maxPayloadBytes) {
      throw const FormatException('Assinatura ou manifesto inválido.');
    }

    final valid = await Ed25519().verify(
      payloadBytes,
      signature: Signature(
        signatureBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      ),
    );

    if (!valid) {
      throw const FormatException('A assinatura da atualização é inválida.');
    }

    return UpdateManifest.fromJson(
      utf8.decode(payloadBytes),
      allowedHosts: allowedDownloadHosts,
    );
  }

  Future<void> verifyDownloadedFile({
    required File file,
    required UpdateAsset asset,
  }) async {
    final actualSize = await file.length();
    if (actualSize != asset.size) {
      throw const FormatException(
        'O tamanho do pacote não corresponde ao manifesto.',
      );
    }

    final sink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    final digest = await sink.hash();
    final actualHash = digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    if (actualHash != asset.sha256) {
      throw const FormatException(
        'O SHA-256 do pacote não corresponde ao manifesto.',
      );
    }
  }
}
