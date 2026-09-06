part of '../../profile_settings_page.dart';

extension _ProfileSettingsTelegramSection on _ProfileSettingsPageState {
  Widget _buildTelegramSettings() {
    return AnimatedBuilder(
      animation: telegramConnectionController,
      builder: (context, _) {
        final controller = telegramConnectionController;
        final connection = controller.connection;
        final connected = controller.isConnected;

        return _SettingsPanel(
          icon: Icons.send_rounded,
          title: 'Telegram',
          subtitle: 'Receba seus lembretes diretamente no Telegram.',
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: connected
                          ? _ProfileSettingsPageState._primary.withValues(
                              alpha: 0.20,
                            )
                          : _ProfileSettingsPageState._surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _ProfileSettingsPageState._border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: connected
                                ? _ProfileSettingsPageState._primary
                                : _ProfileSettingsPageState._surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _ProfileSettingsPageState._border,
                            ),
                          ),
                          child: Icon(
                            connected
                                ? Icons.check_rounded
                                : Icons.send_outlined,
                            color: connected
                                ? _ProfileSettingsPageState._primaryDark
                                : _ProfileSettingsPageState._muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                connected
                                    ? 'Telegram conectado'
                                    : 'Telegram não conectado',
                                style: const TextStyle(
                                  color: _ProfileSettingsPageState._text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                connected
                                    ? connection!.displayName
                                    : 'Conecte uma vez para usar o Telegram nos seus lembretes.',
                                style: const TextStyle(
                                  color: _ProfileSettingsPageState._muted,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage!,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (!connected)
                    FilledButton.icon(
                      onPressed: controller.connecting
                          ? null
                          : () async {
                              final result = await TelegramConnectDialog.show(
                                context,
                                controller: controller,
                              );

                              if (!mounted || result != true) {
                                return;
                              }

                              _updateProfileState(() {
                                _message = 'Telegram conectado com sucesso.';
                                _messageIsError = false;
                              });
                            },
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 17,
                      ),
                      label: const Text('Conectar Telegram'),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: controller.testing
                              ? null
                              : () async {
                                  final success = await controller.sendTest();

                                  if (!mounted) {
                                    return;
                                  }

                                  _updateProfileState(() {
                                    _message = success
                                        ? 'Mensagem de teste enviada para o Telegram.'
                                        : controller.errorMessage ??
                                            'Não foi possível enviar a mensagem de teste.';
                                    _messageIsError = !success;
                                  });
                                },
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 17,
                          ),
                          label: Text(
                            controller.testing
                                ? 'Enviando...'
                                : 'Enviar mensagem de teste',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: controller.disconnecting
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Desconectar Telegram?'),
                                        content: const Text(
                                          'Novos lembretes não poderão ser enviados pelo Telegram até você conectar novamente.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop(false);
                                            },
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(dialogContext).pop(true);
                                            },
                                            child: const Text('Desconectar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed != true) {
                                    return;
                                  }

                                  final success = await controller.disconnect();

                                  if (!mounted) {
                                    return;
                                  }

                                  _updateProfileState(() {
                                    _message = success
                                        ? 'Telegram desconectado.'
                                        : controller.errorMessage ??
                                            'Não foi possível desconectar o Telegram.';
                                    _messageIsError = !success;
                                  });
                                },
                          icon: const Icon(
                            Icons.link_off_rounded,
                            size: 17,
                          ),
                          label: Text(
                            controller.disconnecting
                                ? 'Desconectando...'
                                : 'Desconectar',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'Quando você ativar Telegram ao criar um lembrete e ainda não estiver conectado, o EVRYLUX mostrará a conexão automaticamente antes de salvar.',
                    style: TextStyle(
                      color: _ProfileSettingsPageState._muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
