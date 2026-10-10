import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../study/brain/screen/brain_screen.dart';
import '../services/web_brain_device_service.dart';
import '../services/web_brain_secure_storage.dart';
import '../widgets/web_brain_device_management_dialog.dart';
import '../services/web_brain_recovery_key_service.dart';
import '../utils/web_brain_recovery_download.dart';

/// Gate Web do Cérebro.
///
/// Comportamento final:
///
/// navegador sem identidade
///   -> cria device + pending -> mostra fingerprint
///
/// navegador pending
///   -> mantém o mesmo fingerprint
///
/// navegador autorizado
///   -> verifica no backend
///   -> se continua autorizado e possui a chave local, entra direto
///
/// navegador revogado
///   -> backend recusa a identidade
///   -> cria nova identidade/fingerprint e solicita nova aprovação
///
/// Não existe expiração local automática por 30 dias.
class WebBrainAccessGate extends StatefulWidget {
  const WebBrainAccessGate({super.key});

  @override
  State<WebBrainAccessGate> createState() => _WebBrainAccessGateState();
}

class _WebBrainAccessGateState extends State<WebBrainAccessGate> {
  late final WebBrainSecureStorage _storage;
  late final WebBrainDeviceService _devices;
  late final WebBrainRecoveryKeyService _recovery;

  bool _loading = true;
  bool _ready = false;
  String? _error;
  String? _vaultId;
  String _fingerprint = '';

  @override
  void initState() {
    super.initState();
    _storage = WebBrainSecureStorage();
    _devices = WebBrainDeviceService(storage: _storage);
    _recovery = WebBrainRecoveryKeyService(storage: _storage);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final bootstrap = await _devices.bootstrapAccess();
      final state = bootstrap.state;

      _vaultId = state.vaultId;
      _fingerprint = state.localSecrets.keyFingerprint;

      if (state.ready) {
        if (mounted) {
          setState(() {
            _ready = true;
            _error = null;
          });
        }

        if (bootstrap.firstDeviceBootstrap) {
          try {
            final recovery = await _recovery.createOrRotateRecoveryKey(
              vaultId: state.vaultId,
            );

            if (mounted) {
              await _showRecoveryKeyDialog(recovery);
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cérebro criado, mas não foi possível gerar a '
                      'chave de recuperação agora: $error',
                    ),
                  ),
                );
            }
          }
        }

        return;
      }

      if (state.record.isAuthorized) {
        if (mounted) {
          setState(() {
            _ready = false;
            _error =
                'Este navegador está autorizado, mas não possui a chave local '
                'necessária para abrir seu Cérebro.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _ready = false;
          _error = null;
        });

        await _showAccessOptionsDialog();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível preparar o acesso ao Cérebro. '
              'Sua identidade local foi preservada.\n\n$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showRecoveryKeyDialog(
    WebBrainRecoveryKeyResult recovery,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Guarde sua chave de recuperação'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Esta chave foi gerada aleatoriamente e permite recuperar '
                  'seu Cérebro se você perder todos os dispositivos autorizados.',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  recovery.recoveryKey,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'O EVRYLUX não envia esta chave em texto puro ao servidor. '
                  'Guarde uma cópia fora deste navegador.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: recovery.recoveryKey),
                );

                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Chave de recuperação copiada.'),
                    ),
                  );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar'),
            ),
            TextButton.icon(
              onPressed: () async {
                await downloadBrainRecoveryKeyFile(
                  filename: 'EVRYLUX_RECOVERY_KEY.txt',
                  content: recovery.toTextFile(),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Baixar chave'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Já guardei'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAccessOptionsDialog() async {
    if (!mounted || _vaultId == null) return;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Este dispositivo ainda não tem acesso'),
          content: const Text(
            'Você pode aprovar este navegador usando outro dispositivo '
            'confiável ou recuperar o acesso com sua chave de recuperação.',
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop('device');
              },
              icon: const Icon(Icons.devices_rounded),
              label: const Text('Aprovar usando outro dispositivo'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop('recovery');
              },
              icon: const Icon(Icons.key_rounded),
              label: const Text('Usar chave de recuperação'),
            ),
          ],
        );
      },
    );

    if (action == 'recovery' && mounted) {
      await _recoverWithRecoveryKey();
    }
  }

  Future<void> _recoverWithRecoveryKey() async {
    final vaultId = _vaultId;

    if (vaultId == null || vaultId.trim().isEmpty) {
      return;
    }

    final controller = TextEditingController();

    final recoveryKey = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chave de recuperação'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Recovery Key',
                hintText: 'Cole aqui a chave que você guardou',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('Recuperar acesso'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (recoveryKey == null || recoveryKey.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _recovery.recoverCurrentDevice(
        vaultId: vaultId,
        recoveryKey: recoveryKey,
      );

      if (!mounted) return;

      setState(() {
        _ready = true;
        _error = null;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Acesso recuperado. Este dispositivo agora é confiável.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _ready = false;
        _error =
            'Não foi possível recuperar o Cérebro. '
            'Confira a chave de recuperação e tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _ensurePending(String vaultId) async {
    final state = await _devices.registerOrRefresh(vaultId: vaultId);

    _fingerprint = state.localSecrets.keyFingerprint;

    if (state.record.isAuthorized) {
      if (state.hasMasterKey) {
        if (mounted) {
          setState(() {
            _ready = true;
            _error = null;
          });
        }
        return;
      }

      final imported = await _devices.tryImportApprovedKey(vaultId: vaultId);

      if (imported) {
        if (mounted) {
          setState(() {
            _ready = true;
            _error = null;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _ready = false;
      });
    }
  }

  Future<void> _verifyApproval() async {
    final vaultId = _vaultId;
    if (vaultId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authorized = await _devices.isAuthorized(vaultId: vaultId);

      if (!authorized) {
        // Também renova um pending expirado, sem trocar fingerprint quando
        // a identidade ainda é válida.
        await _ensurePending(vaultId);

        if (mounted && !_ready) {
          setState(() {
            _error = 'Este navegador ainda está aguardando autorização.';
          });
        }
        return;
      }

      final hasKey = await _devices.hasLocalMasterKey(vaultId: vaultId);

      if (!hasKey) {
        final imported = await _devices.tryImportApprovedKey(vaultId: vaultId);

        if (!imported) {
          if (mounted) {
            setState(() {
              _error =
                  'O dispositivo está autorizado, mas a chave ainda não '
                  'está disponível para este navegador.';
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _ready = true;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível verificar a autorização. '
              'Tente novamente.\n\n$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openDeviceManagement() async {
    final vaultId = _vaultId;

    if (vaultId == null || vaultId.trim().isEmpty) {
      return;
    }

    await WebBrainDeviceManagementDialog.show(
      context,
      vaultId: vaultId,
    );
  }

  Future<void> _copyFingerprint() async {
    final fingerprint = _fingerprint.trim();
    if (fingerprint.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: fingerprint));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Fingerprint copiado.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _informVault() async {
    final controller = TextEditingController(text: _vaultId ?? '');

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar ao Cérebro'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Vault ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty) return;

    await _storage.saveVaultId(value);
    _vaultId = value;

    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return Stack(
          children: [
            const BrainScreen(),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    tooltip: 'Dispositivos do Cérebro',
                    onPressed: _openDeviceManagement,
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cérebro')),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 48),
                        const SizedBox(height: 14),
                        Text(
                          _vaultId == null
                              ? 'Conecte este navegador ao seu Cérebro'
                              : 'Autorize este navegador',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _vaultId == null
                              ? 'Informe o Vault ID usado pelo EVRYLUX.'
                              : 'Depois de autorizado, este navegador entra '
                                    'direto enquanto o acesso continuar ativo. '
                                    'Um novo fingerprint só será solicitado '
                                    'se este dispositivo for revogado.',
                          textAlign: TextAlign.center,
                        ),
                        if (_fingerprint.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: SelectableText(
                                  _fingerprint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _copyFingerprint,
                                icon: const Icon(
                                  Icons.copy_all_rounded,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (_vaultId == null)
                          FilledButton.icon(
                            onPressed: _loading ? null : _informVault,
                            icon: const Icon(Icons.link_rounded),
                            label: const Text('Informar Vault ID'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _loading ? null : _verifyApproval,
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Já aprovei — verificar'),
                          ),
                        if (_vaultId != null)
                          TextButton(
                            onPressed: _loading ? null : _informVault,
                            child: const Text('Trocar Vault ID'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
