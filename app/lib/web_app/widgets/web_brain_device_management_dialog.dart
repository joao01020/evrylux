import 'package:flutter/material.dart';

import '../../study/brain/devices/models/brain_device_record.dart';
import '../services/web_brain_device_management_service.dart';
import '../services/web_brain_secure_storage.dart';

class WebBrainDeviceManagementDialog extends StatefulWidget {
  const WebBrainDeviceManagementDialog({
    super.key,
    required this.vaultId,
  });

  final String vaultId;

  static Future<void> show(
    BuildContext context, {
    required String vaultId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => WebBrainDeviceManagementDialog(
        vaultId: vaultId,
      ),
    );
  }

  @override
  State<WebBrainDeviceManagementDialog> createState() =>
      _WebBrainDeviceManagementDialogState();
}

class _WebBrainDeviceManagementDialogState
    extends State<WebBrainDeviceManagementDialog> {
  static const Color _surface = Color(0xFFF8FBF2);
  static const Color _border = Color(0xFFD6DFCE);
  static const Color _text = Color(0xFF293126);
  static const Color _muted = Color(0xFF687264);
  static const Color _primary = Color(0xFF5C8F52);
  static const Color _danger = Color(0xFFB44747);
  static const Color _pending = Color(0xFF9A6700);

  late final WebBrainDeviceManagementService _service;

  bool _loading = true;
  String? _error;
  String? _currentDeviceId;
  String? _busyDeviceId;
  List<BrainDeviceRecord> _devices =
      const <BrainDeviceRecord>[];

  @override
  void initState() {
    super.initState();

    _service = WebBrainDeviceManagementService(
      storage: WebBrainSecureStorage(),
    );

    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentId = await _service.currentDeviceId();

      final devices = await _service.listDevices(
        vaultId: widget.vaultId,
      );

      if (!mounted) return;

      setState(() {
        _currentDeviceId = currentId;
        _devices = devices;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
            'Não foi possível carregar os dispositivos do Cérebro.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmApprove(
    BrainDeviceRecord device,
  ) async {
    if (!device.isPending || _busyDeviceId != null) {
      return;
    }

    final controller = TextEditingController();

    final fingerprint = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Aprovar dispositivo'),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No novo dispositivo, confira o fingerprint '
                  'mostrado na tela e digite-o abaixo exatamente '
                  'como aparece.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText:
                        'Fingerprint do novo dispositivo',
                    hintText:
                        'AA:BB:CC:DD:EE:FF:...',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.fingerprint_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop(value);
              },
              icon: const Icon(
                Icons.check_rounded,
                size: 18,
              ),
              label: const Text('Aprovar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (fingerprint == null ||
        fingerprint.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      _busyDeviceId = device.deviceId;
      _error = null;
    });

    try {
      await _service.approvePendingDevice(
        vaultId: widget.vaultId,
        target: device,
        expectedFingerprint: fingerprint,
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Dispositivo "${device.deviceName}" aprovado.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
            'Não foi possível aprovar o dispositivo.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyDeviceId = null;
        });
      }
    }
  }

  Future<void> _confirmRevoke(
    BrainDeviceRecord device,
  ) async {
    if (_busyDeviceId != null ||
        device.isRevoked) {
      return;
    }

    final isCurrent =
        device.deviceId == _currentDeviceId;

    if (isCurrent) {
      setState(() {
        _error =
            'Este dispositivo não pode ser revogado por esta tela.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.phonelink_erase_rounded,
                color: _danger,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Revogar acesso'),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 440),
            child: Text(
              'Revogar o acesso de "${device.deviceName}"?\n\n'
              'Este dispositivo não poderá mais sincronizar '
              'novos dados do Cérebro pela nuvem.\n\n'
              'Dados e chaves que já existam localmente nesse '
              'computador não podem ser apagados remotamente.',
              style: const TextStyle(
                color: _muted,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(
                Icons.block_rounded,
                size: 18,
              ),
              label: const Text(
                'Revogar acesso',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busyDeviceId = device.deviceId;
      _error = null;
    });

    try {
      await _service.revokeDevice(
        vaultId: widget.vaultId,
        target: device,
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Acesso de "${device.deviceName}" revogado.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
            'Não foi possível revogar o dispositivo.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyDeviceId = null;
        });
      }
    }
  }

  String _statusLabel(
    BrainDeviceRecord device,
  ) {
    if (device.isAuthorized) {
      return 'Autorizado';
    }

    if (device.isPending) {
      return 'Pendente';
    }

    return 'Revogado';
  }

  Color _statusColor(
    BrainDeviceRecord device,
  ) {
    if (device.isAuthorized) {
      return _primary;
    }

    if (device.isPending) {
      return _pending;
    }

    return _danger;
  }

  Widget _deviceRow(
    BrainDeviceRecord device,
  ) {
    final isCurrent =
        device.deviceId == _currentDeviceId;

    final busy =
        _busyDeviceId == device.deviceId;

    final statusColor =
        _statusColor(device);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.50,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border:
            Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              device.isAuthorized
                  ? Icons.computer_rounded
                  : device.isPending
                      ? Icons
                          .devices_other_rounded
                      : Icons
                          .phonelink_erase_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color: _primary
                              .withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            999,
                          ),
                        ),
                        child:
                            const Text(
                          'Este dispositivo',
                          style:
                              TextStyle(
                            color:
                                _primary,
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment:
                      WrapCrossAlignment.center,
                  children: [
                    Text(
                      _statusLabel(device),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    Text(
                      device.keyFingerprint,
                      style:
                          const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontFamily:
                            'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          else if (device.isPending &&
              !isCurrent)
            FilledButton.icon(
              onPressed: () =>
                  _confirmApprove(device),
              icon: const Icon(
                Icons.check_rounded,
                size: 17,
              ),
              label:
                  const Text('Aprovar'),
            )
          else if (!isCurrent &&
              !device.isRevoked)
            TextButton.icon(
              onPressed: () =>
                  _confirmRevoke(device),
              icon: const Icon(
                Icons.block_rounded,
                size: 17,
              ),
              label:
                  const Text('Revogar'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor: _surface,
      surfaceTintColor:
          Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
        side: const BorderSide(
          color: _border,
        ),
      ),
      titlePadding:
          const EdgeInsets.fromLTRB(
        22,
        20,
        14,
        0,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        22,
        18,
        22,
        16,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons
                  .admin_panel_settings_outlined,
              color: _primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispositivos do Cérebro',
                  style: TextStyle(
                    color: _text,
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gerencie quem pode acessar este Vault.',
                  style: TextStyle(
                    color: _muted,
                    fontWeight:
                        FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
                _loading ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        height: 440,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: _danger
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: _danger
                        .withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: _danger,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _loading &&
                      _devices.isEmpty
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      ),
                    )
                  : _devices.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum dispositivo do Cérebro foi encontrado.',
                            style:
                                TextStyle(
                              color:
                                  _muted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              _devices.length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            height: 9,
                          ),
                          itemBuilder:
                              (context,
                                  index) {
                            return _deviceRow(
                              _devices[
                                  index],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child:
              const Text('Fechar'),
        ),
      ],
    );
  }
}
