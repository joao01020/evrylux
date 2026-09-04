part of '../../profile_settings_page.dart';

class _AboutHero
    extends
        StatelessWidget {
  const _AboutHero();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(
              8,
            ),
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: _ProfileSettingsPageState._border,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                16,
              ),
              child: Image.asset(
                'assets/images/branding/evrylux_logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.auto_awesome_rounded,
                        size: 34,
                        color: _ProfileSettingsPageState._primaryDark,
                      );
                    },
              ),
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVRYLUX',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  AppInfo.versionLabel,
                  style: TextStyle(
                    color: _ProfileSettingsPageState._primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 12,
                ),

                Text(
                  'Sua plataforma de evolução pessoal.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Desenvolvido por João Vitor',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ABOUT ACTION ROW
// ============================================================

class _AboutActionRow
    extends
        StatelessWidget {
  const _AboutActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._primary,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _ProfileSettingsPageState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BACKUP INFO STEP
// ============================================================

class _BackupInfoStep
    extends
        StatelessWidget {
  const _BackupInfoStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ProfileSettingsPageState._primary,
            borderRadius: BorderRadius.circular(
              8,
            ),
            border: Border.all(
              color: _ProfileSettingsPageState._border,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _ProfileSettingsPageState._primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                text,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BACKUP SECURITY WARNING
// ============================================================

class _BackupSecurityWarning
    extends
        StatelessWidget {
  const _BackupSecurityWarning();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFF7E6,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(
            0xFFE6C56A,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(
              0xFF9A6700,
            ),
          ),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              'Guarde o arquivo .evbrain em um local confiável. '
              'Ele é um backup dos seus dados e não deve ser tratado '
              'como um arquivo público.',
              style: TextStyle(
                color: Color(
                  0xFF6F5200,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECOVERY INFO STEP
// ============================================================

class _RecoveryInfoStep
    extends
        StatelessWidget {
  const _RecoveryInfoStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;

  final String title;

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ProfileSettingsPageState._primary,
            borderRadius: BorderRadius.circular(
              8,
            ),
            border: Border.all(
              color: _ProfileSettingsPageState._border,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _ProfileSettingsPageState._primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                text,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RECOVERY SECURITY WARNING
// ============================================================

class _RecoverySecurityWarning
    extends
        StatelessWidget {
  const _RecoverySecurityWarning();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFF7E6,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(
            0xFFE6C56A,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(
              0xFF9A6700,
            ),
          ),

          SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              'Se você não reconhecer o dispositivo ou se o '
              'fingerprint não coincidir, não aprove a recuperação.',
              style: TextStyle(
                color: Color(
                  0xFF6F5200,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS NAV ITEM
// ============================================================

class _SettingsNavItem
    extends
        StatelessWidget {
  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;

  final String label;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileSettingsPageState._primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? _ProfileSettingsPageState._primaryDark
                    : _ProfileSettingsPageState._muted,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? _ProfileSettingsPageState._text
                        : _ProfileSettingsPageState._muted,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS PANEL
// ============================================================

class _SettingsPanel
    extends
        StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final List<
    Widget
  >
  children;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _ProfileSettingsPageState._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._primary,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._surfaceSoft,
              borderRadius: BorderRadius.circular(
                15,
              ),
              border: Border.all(
                color: _ProfileSettingsPageState._border,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PREFERENCE SWITCH
// ============================================================

class _PreferenceSwitch
    extends
        StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool value;

  final ValueChanged<
    bool
  >
  onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: _ProfileSettingsPageState._primaryDark,
      activeTrackColor: _ProfileSettingsPageState._primary,
      secondary: Icon(
        icon,
        color: _ProfileSettingsPageState._primaryDark,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _ProfileSettingsPageState._text,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: _ProfileSettingsPageState._muted,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ============================================================
// BRAIN MODE OPTION
// ============================================================

class _BrainModeOption
    extends
        StatelessWidget {
  const _BrainModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool selected;

  final bool enabled;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? onTap
            : null,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 160,
          ),
          padding: const EdgeInsets.all(
            13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileSettingsPageState._primary
                : _ProfileSettingsPageState._surface,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: selected
                  ? _ProfileSettingsPageState._primaryDark.withValues(
                      alpha: 0.35,
                    )
                  : _ProfileSettingsPageState._border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? _ProfileSettingsPageState._primaryDark
                    : _ProfileSettingsPageState._muted,
                size: 21,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: _ProfileSettingsPageState._text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selected
                              ? _ProfileSettingsPageState._primaryDark
                              : _ProfileSettingsPageState._muted,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BRAIN INFO ROW
// ============================================================

class _BrainInfoRow
    extends
        StatelessWidget {
  const _BrainInfoRow({
    required this.label,
    required this.value,
    this.good = false,
  });

  final String label;

  final String value;

  final bool good;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: _ProfileSettingsPageState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: good
                  ? _ProfileSettingsPageState._primaryDark
                  : _ProfileSettingsPageState._text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PHASE BADGE
// ============================================================

class _PhaseBadge
    extends
        StatelessWidget {
  const _PhaseBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: _ProfileSettingsPageState._border,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ProfileSettingsPageState._muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// CURRENT SESSION BADGE
// ============================================================

class _CurrentSessionBadge
    extends
        StatelessWidget {
  const _CurrentSessionBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._primary,
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: _ProfileSettingsPageState._primaryDark.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          SizedBox(
            width: 5,
          ),

          Text(
            'Ativo agora',
            style: TextStyle(
              color: _ProfileSettingsPageState._primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SESSIONS AND DEVICES DIALOG
// ============================================================

class _SessionsAndDevicesDialog
    extends
        StatefulWidget {
  const _SessionsAndDevicesDialog({
    required this.onDevicesChanged,
  });

  final VoidCallback onDevicesChanged;

  @override
  State<
    _SessionsAndDevicesDialog
  >
  createState() => _SessionsAndDevicesDialogState();
}

class _SessionsAndDevicesDialogState
    extends
        State<
          _SessionsAndDevicesDialog
        > {
  bool _loading = true;

  String? _error;

  String? _currentSessionId;

  String? _revokingDeviceId;

  List<
    AccountDevice
  >
  _devices = const <
    AccountDevice
  >[];

  @override
  void initState() {
    super.initState();

    unawaited(
      _load(),
    );
  }

  Future<
    void
  >
  _load() async {
    if (mounted) {
      setState(
        () {
          _loading = true;
          _error = null;
        },
      );
    }

    try {
      final currentDeviceId =
          await accountDeviceIdentityService.getOrCreateDeviceId();

      final currentSessionId =
          accountDeviceRepository.getCurrentSessionId();

      await accountDeviceRepository.registerDevice(
        deviceId: currentDeviceId,
        deviceName: accountDeviceIdentityService.deviceName,
        platform: accountDeviceIdentityService.platformLabel,
        appVersion: AppInfo.version,
      );

      final devices = await accountDeviceRepository.listActiveDevices();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _currentSessionId = currentSessionId;
          _devices = devices;
          _loading = false;
          _error = null;
        },
      );

      widget.onDevicesChanged();
    } catch (
      error
    ) {
      debugPrint(
        '[ACCOUNT DEVICES DIALOG] Erro: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;
          _error =
              'Não foi possível carregar os dispositivos. Verifique sua conexão e tente novamente.';
        },
      );
    }
  }

  Future<
    void
  >
  _confirmRevoke(
    AccountDevice device,
  ) async {
    if (device.sessionId ==
        _currentSessionId) {
      return;
    }

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: _ProfileSettingsPageState._surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                    side: const BorderSide(
                      color: _ProfileSettingsPageState._border,
                    ),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: _ProfileSettingsPageState._danger,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Encerrar sessão',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    child: Text(
                      'Deseja desconectar "${device.deviceName}" da sua conta? '
                      'Quando esse dispositivo se comunicar novamente com o EVRYLUX, '
                      'a sessão local será encerrada.',
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ProfileSettingsPageState._danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                      ),
                      label: const Text(
                        'Encerrar',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    setState(
      () {
        _revokingDeviceId = device.sessionId;
      },
    );

    try {
      await accountDeviceRepository.revokeSession(
        device.sessionId,
      );

      if (!mounted) {
        return;
      }

      await _load();
    } catch (
      error
    ) {
      debugPrint(
        '[ACCOUNT DEVICES DIALOG] Erro revogando dispositivo: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível encerrar essa sessão.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _revokingDeviceId = null;
          },
        );
      }
    }
  }

  String _lastSeenLabel(
    AccountDevice device,
  ) {
    if (device.sessionId ==
        _currentSessionId) {
      return 'Última atividade: agora';
    }

    final now = DateTime.now();

    var difference = now.difference(
      device.lastSeenAt,
    );

    if (difference.isNegative) {
      difference = Duration.zero;
    }

    if (difference.inMinutes <
        1) {
      return 'Última atividade: agora';
    }

    if (difference.inMinutes <
        60) {
      final minutes = difference.inMinutes;

      return 'Última atividade: há $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }

    if (difference.inHours <
        24) {
      final hours = difference.inHours;

      return 'Última atividade: há $hours ${hours == 1 ? 'hora' : 'horas'}';
    }

    final day = device.lastSeenAt.day.toString().padLeft(
      2,
      '0',
    );

    final month = device.lastSeenAt.month.toString().padLeft(
      2,
      '0',
    );

    final year = device.lastSeenAt.year;

    final hour = device.lastSeenAt.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = device.lastSeenAt.minute.toString().padLeft(
      2,
      '0',
    );

    return 'Última atividade: $day/$month/$year às $hour:$minute';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor: _ProfileSettingsPageState._surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: const BorderSide(
          color: _ProfileSettingsPageState._border,
        ),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.devices_outlined,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Text(
              'Sessões e dispositivos',
            ),
          ),

          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading
                ? null
                : () {
                    unawaited(
                      _load(),
                    );
                  },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 520,
          ),
          child: _buildContent(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          child: const Text(
            'Fechar',
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(
            32,
          ),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error !=
        null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: _ProfileSettingsPageState._muted,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  height: 1.45,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              FilledButton.tonalIcon(
                onPressed: () {
                  unawaited(
                    _load(),
                  );
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(
            28,
          ),
          child: Text(
            'Nenhum dispositivo ativo encontrado.',
            style: TextStyle(
              color: _ProfileSettingsPageState._muted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _devices.length == 1
              ? '1 dispositivo conectado à sua conta EVRYLUX.'
              : '${_devices.length} dispositivos conectados à sua conta EVRYLUX.',
          style: const TextStyle(
            color: _ProfileSettingsPageState._muted,
            fontSize: 12,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _devices.length,
            separatorBuilder:
                (
                  context,
                  index,
                ) {
                  return const SizedBox(
                    height: 10,
                  );
                },
            itemBuilder:
                (
                  context,
                  index,
                ) {
                  final device = _devices[index];

                  return _buildDeviceCard(
                    device,
                  );
                },
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        const Text(
          'A atividade é atualizada enquanto o EVRYLUX está aberto. '
          'Ao encerrar uma sessão, o dispositivo será desconectado '
          'quando voltar a se comunicar com o servidor.',
          style: TextStyle(
            color: _ProfileSettingsPageState._muted,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(
    AccountDevice device,
  ) {
    final isCurrent =
        device.sessionId ==
        _currentSessionId;

    final isRevoking =
        _revokingDeviceId ==
        device.sessionId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surfaceSoft,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: isCurrent
              ? _ProfileSettingsPageState._primaryDark.withValues(
                  alpha: 0.28,
                )
              : _ProfileSettingsPageState._border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              device.platform.toLowerCase().contains(
                    'android',
                  ) ||
                  device.platform.toLowerCase().contains(
                    'ios',
                  )
                  ? Icons.phone_android_rounded
                  : Icons.computer_rounded,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCurrent
                            ? 'Este dispositivo'
                            : device.deviceName,
                        style: const TextStyle(
                          color: _ProfileSettingsPageState._text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    if (isCurrent)
                      const _CurrentSessionBadge(),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                if (isCurrent) ...[
                  Text(
                    device.deviceName,
                    style: const TextStyle(
                      color: _ProfileSettingsPageState._muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),
                ],

                Text(
                  device.platform,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (device.appVersion !=
                    null) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    'EVRYLUX ${device.appVersion}',
                    style: const TextStyle(
                      color: _ProfileSettingsPageState._muted,
                      fontSize: 10,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _lastSeenLabel(
                    device,
                  ),
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          if (!isCurrent) ...[
            const SizedBox(
              width: 12,
            ),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ProfileSettingsPageState._danger,
                side: BorderSide(
                  color: _ProfileSettingsPageState._danger.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              onPressed: isRevoking
                  ? null
                  : () {
                      unawaited(
                        _confirmRevoke(
                          device,
                        ),
                      );
                    },
              icon: isRevoking
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.logout_rounded,
                      size: 16,
                    ),
              label: const Text(
                'Encerrar',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// DANGER ZONE HEADER
// ============================================================

class _DangerZoneHeader
    extends
        StatelessWidget {
  const _DangerZoneHeader();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        12,
      ),
      color: const Color(
        0xFFFFF7F5,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: _ProfileSettingsPageState._danger,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona de risco',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'Ações permanentes relacionadas aos seus dados e à sua conta.',
                  style: TextStyle(
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
    );
  }
}

// ============================================================
// DANGER ZONE ROW
// ============================================================

class _DangerZoneRow
    extends
        StatelessWidget {
  const _DangerZoneRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.strongest = false,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final String buttonLabel;

  final VoidCallback onPressed;

  final bool strongest;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      color: const Color(
        0xFFFFFBFA,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFECE9,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _ProfileSettingsPageState._danger.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: _ProfileSettingsPageState._danger,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          strongest
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ProfileSettingsPageState._danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onPressed,
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    size: 17,
                  ),
                  label: Text(
                    buttonLabel,
                  ),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ProfileSettingsPageState._danger,
                    side: BorderSide(
                      color: _ProfileSettingsPageState._danger.withValues(
                        alpha: 0.40,
                      ),
                    ),
                  ),
                  onPressed: onPressed,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),
                  label: Text(
                    buttonLabel,
                  ),
                ),
        ],
      ),
    );
  }
}

// ============================================================
// SECURITY ROW
// ============================================================

class _SecurityRow
    extends
        StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final Widget? trailing;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (trailing !=
              null) ...[
            const SizedBox(
              width: 10,
            ),
            trailing!,
          ],
        ],
      ),
    );
  }
}
