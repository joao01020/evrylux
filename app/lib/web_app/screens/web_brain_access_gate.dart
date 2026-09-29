import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../study/brain/screen/brain_screen.dart';
import '../services/web_brain_device_service.dart';
import '../services/web_brain_secure_storage.dart';

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
      final vaultId = await _devices.discoverVaultId();

      if (vaultId == null) {
        if (mounted) {
          setState(() {
            _vaultId = null;
            _fingerprint = '';
            _ready = false;
          });
        }
        return;
      }

      _vaultId = vaultId;

      final local = await _storage.loadDevice();

      if (local == null) {
        await _ensurePending(vaultId);
        return;
      }

      _fingerprint = local.keyFingerprint;

      // Sempre consulta o servidor. A autorização remota é a fonte da verdade.
      final authorized = await _devices.isAuthorized(vaultId: vaultId);

      if (authorized) {
        final hasKey = await _devices.hasLocalMasterKey(vaultId: vaultId);

        if (hasKey) {
          // Este é o caminho normal após a primeira aprovação.
          // Nenhum fingerprint é pedido novamente.
          if (mounted) {
            setState(() {
              _ready = true;
              _error = null;
            });
          }
          return;
        }

        // Pode acontecer logo após a aprovação, antes de o navegador ter
        // consumido o envelope da Master Key.
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

        // O backend diz que este device continua autorizado. Não geramos
        // fingerprint novo só porque houve uma inconsistência local.
        if (mounted) {
          setState(() {
            _ready = false;
            _error =
                'Este navegador perdeu a chave local usada para acessar seu Cérebro.';
          });
        }
        return;
      }

      // Se não está autorizado, registerOrRefresh diferencia pending de
      // revogado. Pending reutiliza a identidade. Revogado cria fingerprint
      // novo, que é exatamente quando queremos pedir autorização novamente.
      await _ensurePending(vaultId);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível verificar a autorização do Cérebro. '
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
      return const BrainScreen();
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
