import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:EVRYLUX/core/updater/update_download_coordinator.dart';
import 'package:EVRYLUX/core/updater/update_download_service.dart';
import 'package:EVRYLUX/core/updater/update_manifest.dart';
import 'package:EVRYLUX/core/updater/update_manifest_service.dart';
import 'package:EVRYLUX/profile/notifications/widgets/update_download_dialog.dart';

class _FakeCoordinator extends UpdateDownloadCoordinator {
  _FakeCoordinator()
    : super(
        verifier: UpdateManifestService(
          manifestUrl: Uri.parse('https://example.invalid/latest.json'),
          trustedPublicKeys: const {},
          allowedDownloadHosts: const {'example.invalid'},
        ),
        currentVersion: '1.0.0',
        currentDataSchema: 7,
        platform: 'linux',
        architecture: 'x64',
      );

  int starts = 0;
  int cancels = 0;
  bool cancelled = false;
  bool failDownload = false;
  Completer<void>? pending;
  UpdateDownloadPhase currentPhase = UpdateDownloadPhase.idle;
  String? currentMessage;
  UpdateDownloadResult? result;

  @override
  bool get busy => pending != null && !pending!.isCompleted;

  @override
  UpdateDownloadPhase get phase => currentPhase;

  @override
  String? get message => currentMessage;

  @override
  UpdateDownloadResult? get ready => result;

  @override
  UpdateDownloadProgress get progress => const UpdateDownloadProgress(50, 100);

  @override
  Future<void> start({required String notificationVersion}) async {
    starts++;
    cancelled = false;
    currentPhase = UpdateDownloadPhase.downloading;
    currentMessage = 'Baixando atualização...';
    pending = Completer<void>();
    notifyListeners();
    await pending!.future;
    if (cancelled) {
      currentPhase = UpdateDownloadPhase.cancelled;
      currentMessage = 'Download cancelado.';
    } else if (failDownload) {
      currentPhase = UpdateDownloadPhase.failed;
      currentMessage = 'Falha simulada.';
    } else {
      currentPhase = UpdateDownloadPhase.ready;
      currentMessage = 'Pacote verificado.';
      result = UpdateDownloadResult(
        file: File('/tmp/evrylux-widget-test-package'),
        version: notificationVersion,
        asset: UpdateAsset.fromMap(
          {
            'platform': 'linux',
            'architecture': 'x64',
            'format': 'tar.gz',
            'url': 'https://example.invalid/package.tar.gz',
            'size': 100,
            'sha256': 'a' * 64,
          },
          allowedHosts: const {'example.invalid'},
        ),
      );
    }
    notifyListeners();
  }

  void finish() {
    if (pending != null && !pending!.isCompleted) pending!.complete();
  }

  @override
  void cancel() {
    cancels++;
    cancelled = true;
    finish();
  }
}

Future<void> _open(
  WidgetTester tester,
  _FakeCoordinator coordinator, {
  required Future<bool> Function(String) managed,
  required Future<void> Function(UpdateDownloadCoordinator) install,
}) async {
  // Inject dependencies directly; no network or real helper is invoked.
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UpdateDownloadDialog(
          coordinator: coordinator,
          version: '1.0.1',
          managedCheck: managed,
          installAction: install,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirma antes de baixar e instala depois de verificar', (
    tester,
  ) async {
    final coordinator = _FakeCoordinator();
    var installations = 0;
    await _open(
      tester,
      coordinator,
      managed: (_) async => true,
      install: (_) async {
        installations++;
      },
    );
    expect(coordinator.starts, 0);
    await tester.tap(find.text('Baixar, instalar e reiniciar'));
    await tester.pumpAndSettle();
    expect(coordinator.starts, 1);
    expect(installations, 0);
    coordinator.finish();
    await tester.pumpAndSettle();
    expect(installations, 1);
  });

  testWidgets('cancelamento não inicia instalação', (tester) async {
    final coordinator = _FakeCoordinator();
    var installations = 0;
    await _open(
      tester,
      coordinator,
      managed: (_) async => true,
      install: (_) async {
        installations++;
      },
    );
    await tester.tap(find.text('Baixar, instalar e reiniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar download'));
    await tester.pumpAndSettle();
    expect(coordinator.cancels, 1);
    expect(installations, 0);
  });

  testWidgets('download falho não inicia instalação', (tester) async {
    final coordinator = _FakeCoordinator()..failDownload = true;
    var installations = 0;
    await _open(
      tester,
      coordinator,
      managed: (_) async => true,
      install: (_) async {
        installations++;
      },
    );
    await tester.tap(find.text('Baixar, instalar e reiniciar'));
    await tester.pumpAndSettle();
    coordinator.finish();
    await tester.pumpAndSettle();
    expect(installations, 0);
    expect(find.text('Falha simulada.'), findsOneWidget);
  });

  testWidgets('instalação não gerenciada é bloqueada', (tester) async {
    final coordinator = _FakeCoordinator();
    var installations = 0;
    await _open(
      tester,
      coordinator,
      managed: (_) async => false,
      install: (_) async {
        installations++;
      },
    );
    expect(coordinator.starts, 0);
    expect(installations, 0);
    expect(
      find.textContaining('Instalação gerenciada necessária'),
      findsOneWidget,
    );
  });

  testWidgets('falha no handoff mantém o diálogo aberto', (tester) async {
    final coordinator = _FakeCoordinator();
    await _open(
      tester,
      coordinator,
      managed: (_) async => true,
      install: (_) async {
        throw StateError('Handoff recusado');
      },
    );
    await tester.tap(find.text('Baixar, instalar e reiniciar'));
    await tester.pumpAndSettle();
    coordinator.finish();
    await tester.pumpAndSettle();
    expect(find.textContaining('Handoff recusado'), findsOneWidget);
    expect(find.text('Instalar e reiniciar'), findsOneWidget);
  });
}
