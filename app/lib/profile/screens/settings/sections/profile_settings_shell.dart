part of '../../profile_settings_page.dart';

extension _ProfileSettingsShell
    on _ProfileSettingsPageState {
  // ============================================================
  // BRAIN DEVICES SECTION
  // ============================================================

  Widget _buildBrainDevicesSection() {
    if (_loadingBrainDevices &&
        _brainDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(
          18,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                'Carregando dispositivos autorizados...',
                style: TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_brainDevicesError !=
        null) {
      return Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _ProfileSettingsPageState._danger,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                _brainDevicesError!,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            TextButton.icon(
              onPressed: _loadBrainDevices,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      );
    }

    if (_brainDevices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Nenhum dispositivo do Cérebro foi encontrado.',
                style: TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loadBrainDevices,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            12,
            8,
            10,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispositivos do Cérebro',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Controle quais computadores podem sincronizar seus dados criptografados.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Atualizar dispositivos',
                onPressed: _loadingBrainDevices
                    ? null
                    : _loadBrainDevices,
                icon: _loadingBrainDevices
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                      ),
              ),
            ],
          ),
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        for (
          var index = 0;
          index <
              _brainDevices.length;
          index++
        ) ...[
          _buildBrainDeviceRow(
            _brainDevices[index],
          ),

          if (index <
              _brainDevices.length -
                  1)
            const Divider(
              height: 1,
              color: _ProfileSettingsPageState._border,
            ),
        ],
      ],
    );
  }

  // ============================================================
  // BRAIN DEVICE ROW
  // ============================================================

  Widget _buildBrainDeviceRow(
    BrainDeviceRecord device,
  ) {
    final isCurrent =
        device.deviceId ==
        _currentBrainDeviceId;

    final revoking =
        _revokingBrainDeviceId ==
        device.deviceId;

    final approving =
        _approvingBrainDeviceId ==
        device.deviceId;

    final statusColor = _brainDeviceStatusColor(
      device,
    );

    final noDeviceActionRunning =
        _revokingBrainDeviceId ==
            null &&
        _approvingBrainDeviceId ==
            null;

    final canApprove =
        !isCurrent &&
        device.isPending &&
        noDeviceActionRunning;

    final canRevoke =
        !isCurrent &&
        device.isAuthorized &&
        noDeviceActionRunning;

    final lastSeen = _formatBrainDeviceDate(
      device.lastSeenAt,
    );

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrent
                  ? _ProfileSettingsPageState._primary
                  : _ProfileSettingsPageState._surface,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: isCurrent
                    ? _ProfileSettingsPageState._primaryDark.withValues(
                        alpha: 0.25,
                      )
                    : _ProfileSettingsPageState._border,
              ),
            ),
            child: Icon(
              isCurrent
                  ? Icons.computer_rounded
                  : Icons.devices_other_rounded,
              size: 20,
              color: isCurrent
                  ? _ProfileSettingsPageState._primaryDark
                  : _ProfileSettingsPageState._muted,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _ProfileSettingsPageState._primary,
                          borderRadius: BorderRadius.circular(
                            999,
                          ),
                        ),
                        child: const Text(
                          'Este dispositivo',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                        border: Border.all(
                          color: statusColor.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: Text(
                        _brainDeviceStatusLabel(
                          device,
                        ),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Fingerprint: ${device.keyFingerprint}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Último acesso: $lastSeen',
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          if (revoking ||
              approving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          else if (canApprove)
            FilledButton.tonalIcon(
              onPressed: () {
                _confirmApproveBrainDevice(
                  device,
                );
              },
              icon: const Icon(
                Icons.verified_user_outlined,
                size: 16,
              ),
              label: const Text(
                'Aprovar',
              ),
            )
          else if (canRevoke)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ProfileSettingsPageState._danger,
                side: BorderSide(
                  color: _ProfileSettingsPageState._danger.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              onPressed: () {
                _confirmRevokeBrainDevice(
                  device,
                );
              },
              icon: const Icon(
                Icons.block_rounded,
                size: 16,
              ),
              label: const Text(
                'Revogar acesso',
              ),
            )
          else if (device.isRevoked)
            const Icon(
              Icons.block_rounded,
              color: _ProfileSettingsPageState._danger,
              size: 20,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  Widget _buildProfileSettingsShell(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _ProfileSettingsPageState._background,
      appBar: AppBar(
        backgroundColor: _ProfileSettingsPageState._background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Perfil e configurações',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 980,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: _buildNavigation(),
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _ProfileSettingsPageState._border,
        ),
      ),
      child: Column(
        children: [
          _SettingsNavItem(
            icon: Icons.tune_rounded,
            label: 'Preferências',
            selected:
                _section ==
                ProfileSettingsSection.preferences,
            onTap: () {
              _updateProfileState(
                () {
                  _section = ProfileSettingsSection.preferences;
                },
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.send_rounded,
            label: 'Telegram',
            selected:
                _section ==
                ProfileSettingsSection.telegram,
            onTap: () {
              _updateProfileState(
                () {
                  _section = ProfileSettingsSection.telegram;
                },
              );

              unawaited(
                telegramConnectionController.load(),
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.shield_outlined,
            label: 'Segurança',
            selected:
                _section ==
                ProfileSettingsSection.security,
            onTap: () {
              _updateProfileState(
                () {
                  _section = ProfileSettingsSection.security;
                },
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.psychology_alt_outlined,
            label: 'Cérebro',
            selected:
                _section ==
                ProfileSettingsSection.brain,
            onTap: () {
              _updateProfileState(
                () {
                  _section = ProfileSettingsSection.brain;
                },
              );

              _loadBrainSettings();
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.info_outline_rounded,
            label: 'Sobre',
            selected:
                _section ==
                ProfileSettingsSection.about,
            onTap: () {
              _updateProfileState(
                () {
                  _section = ProfileSettingsSection.about;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.only(
          right: 8,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message !=
                null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: _messageIsError
                      ? const Color(
                          0xFFFFECE9,
                        )
                      : _ProfileSettingsPageState._surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: _messageIsError
                        ? _ProfileSettingsPageState._danger.withValues(
                            alpha: 0.30,
                          )
                        : _ProfileSettingsPageState._border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _messageIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _messageIsError
                          ? _ProfileSettingsPageState._danger
                          : _ProfileSettingsPageState._primaryDark,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError
                              ? _ProfileSettingsPageState._danger
                              : _ProfileSettingsPageState._text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),
            ],

            if (_section ==
                ProfileSettingsSection.preferences)
              _buildPreferences(),

            if (_section ==
                ProfileSettingsSection.telegram)
              _buildTelegramSettings(),

            if (_section ==
                ProfileSettingsSection.security)
              _buildSecurity(),

            if (_section ==
                ProfileSettingsSection.brain)
              _buildBrainSettings(),

            if (_section ==
                ProfileSettingsSection.about)
              _buildAbout(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREFERENCES
  // ============================================================

  Widget _buildPreferences() {
    return _SettingsPanel(
      icon: Icons.tune_rounded,
      title: 'Preferências',
      subtitle: 'Personalize o comportamento da sua experiência.',
      children: [
        _PreferenceSwitch(
          icon: Icons.view_compact_outlined,
          title: 'Modo compacto',
          subtitle: 'Reduz espaços e deixa as telas mais densas.',
          value: _compactMode,
          onChanged:
              (
                value,
              ) {
                _updateProfileState(
                  () {
                    _compactMode = value;
                  },
                );

                _schedulePreferencesSave();
              },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _PreferenceSwitch(
          icon: Icons.animation_outlined,
          title: 'Reduzir animações',
          subtitle: 'Diminui transições e movimentos visuais.',
          value: _reduceMotion,
          onChanged:
              (
                value,
              ) {
                _updateProfileState(
                  () {
                    _reduceMotion = value;
                  },
                );

                _schedulePreferencesSave();
              },
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _PreferenceSwitch(
          icon: Icons.delete_sweep_outlined,
          title: 'Confirmar antes de apagar',
          subtitle: 'Pede confirmação antes de excluir registros.',
          value: _confirmBeforeDelete,
          onChanged:
              (
                value,
              ) {
                _updateProfileState(
                  () {
                    _confirmBeforeDelete = value;
                  },
                );

                _schedulePreferencesSave();
              },
        ),
      ],
    );
  }

  // ============================================================
}
