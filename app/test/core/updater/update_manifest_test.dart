import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/updater/update_manifest.dart';
import 'package:EVRYLUX/core/updater/update_manifest_service.dart';

void main() {
  const allowedHosts = <String>{'updates.example.com'};

  String payload({
    String version = '1.0.1',
    String url = 'https://updates.example.com/releases/1.0.1/app.tar.gz',
  }) {
    return jsonEncode({
      'schema': 1,
      'appId': 'evrylux',
      'channel': 'stable',
      'version': version,
      'publishedAt': '2026-09-08T18:00:00Z',
      'minDataSchema': 1,
      'maxDataSchema': 7,
      'assets': [
        {
          'platform': 'linux',
          'architecture': 'x64',
          'format': 'tar.gz',
          'url': url,
          'size': 100,
          'sha256': 'a' * 64,
        },
      ],
    });
  }

  test('Compara versões SemVer', () {
    expect(
      ReleaseVersion('1.0.1').compareTo(ReleaseVersion('1.0.0')),
      greaterThan(0),
    );
    expect(
      ReleaseVersion('1.0.1-beta.1').compareTo(ReleaseVersion('1.0.1')),
      lessThan(0),
    );
    expect(ReleaseVersion('1.0.1+2').compareTo(ReleaseVersion('1.0.1+1')), 0);
    expect(() => ReleaseVersion('1.0.1-01'), throwsFormatException);
  });

  test('Seleciona somente a plataforma compatível', () {
    final manifest = UpdateManifest.fromJson(
      payload(),
      allowedHosts: allowedHosts,
    );
    expect(
      manifest.assetFor(platform: 'linux', architecture: 'x64'),
      isNotNull,
    );
    expect(manifest.assetFor(platform: 'windows', architecture: 'x64'), isNull);
  });

  test('Rejeita domínio de download não autorizado', () {
    expect(
      () => UpdateManifest.fromJson(
        payload(url: 'https://outro.example.com/app.tar.gz'),
        allowedHosts: allowedHosts,
      ),
      throwsFormatException,
    );
  });

  test('Verifica assinatura e rejeita alteração do payload', () async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final bytes = utf8.encode(payload());
    final signature = await algorithm.sign(bytes, keyPair: keyPair);

    final service = UpdateManifestService(
      manifestUrl: Uri.parse('https://updates.example.com/latest.json'),
      trustedPublicKeys: {'test-key': base64Encode(publicKey.bytes)},
      allowedDownloadHosts: allowedHosts,
    );

    String envelope(List<int> payloadBytes) => jsonEncode({
      'keyId': 'test-key',
      'payload': base64Encode(payloadBytes),
      'signature': base64Encode(signature.bytes),
    });

    final valid = await service.verifyEnvelope(envelope(bytes));
    expect(valid.version.value, '1.0.1');

    await expectLater(
      service.verifyEnvelope(envelope(utf8.encode(payload(version: '9.9.9')))),
      throwsFormatException,
    );
  });

  test('Verifica o tamanho e SHA-256 do pacote', () async {
    final bytes = utf8.encode('pacote de teste');
    final digest = await Sha256().hash(bytes);
    final hash = digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    final asset = UpdateAsset.fromMap({
      'platform': 'linux',
      'architecture': 'x64',
      'format': 'tar.gz',
      'url': 'https://updates.example.com/test.tar.gz',
      'size': bytes.length,
      'sha256': hash,
    }, allowedHosts: allowedHosts);

    final directory = await Directory.systemTemp.createTemp('evrylux-test-');
    try {
      final file = File('${directory.path}/package');
      await file.writeAsBytes(bytes);
      final service = UpdateManifestService(
        manifestUrl: Uri.parse('https://updates.example.com/latest.json'),
        trustedPublicKeys: const {},
        allowedDownloadHosts: allowedHosts,
      );
      await service.verifyDownloadedFile(file: file, asset: asset);
      await file.writeAsString('alterado');
      await expectLater(
        service.verifyDownloadedFile(file: file, asset: asset),
        throwsFormatException,
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
