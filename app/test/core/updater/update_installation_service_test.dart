import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:EVRYLUX/core/updater/update_installation_service.dart';
import 'package:EVRYLUX/core/updater/update_manifest.dart';

void main() {
  test('O contrato declara o esquema de dados da release', () {
    final manifest = UpdateManifest.fromJson(
      jsonEncode({
        'schema': 1,
        'appId': 'evrylux',
        'channel': 'stable',
        'version': '1.0.1',
        'publishedAt': '2026-09-08T18:00:00Z',
        'minDataSchema': 7,
        'maxDataSchema': 7,
        'dataSchema': 7,
        'assets': [
          {
            'platform': 'linux',
            'architecture': 'x64',
            'format': 'tar.gz',
            'url': 'https://updates.example.com/test.tar.gz',
            'size': 100,
            'sha256': 'a' * 64,
          },
        ],
      }),
      allowedHosts: const {'updates.example.com'},
    );
    expect(manifest.dataSchema, 7);
    expect(manifest.supportsDataSchema(8), isFalse);
  });

  test('Build de desenvolvimento não habilita instalação', () async {
    if (!UpdateInstallationService.managedRelease) {
      expect(
        await UpdateInstallationService.isManagedInstallation('1.0.0'),
        isFalse,
      );
    }
  });
}
