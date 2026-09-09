part of '../../profile_settings_page.dart';

extension _ProfileSettingsSecuritySection
    on
        _ProfileSettingsPageState {
  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurity() {
    return _SettingsPanel(
      icon: Icons.shield_outlined,
      title: 'Segurança',
      subtitle: 'Gerencie senha, sessão e ações sensíveis da sua conta.',
      children: [
        // ======================================================
        // E-MAIL
        // ======================================================
        _SecurityRow(
          icon: Icons.alternate_email_rounded,
          title: 'E-mail da conta',
          subtitle: _email,
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // SENHA
        // ======================================================
        _SecurityRow(
          icon: Icons.lock_outline_rounded,
          title: 'Senha',
          subtitle: 'Altere sua senha de acesso.',
          trailing: FilledButton.tonalIcon(
            onPressed: _changingPassword
                ? null
                : _changePassword,
            icon: _changingPassword
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
            label: Text(
              _changingPassword
                  ? 'Alterando...'
                  : 'Alterar',
            ),
          ),
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // SESSÕES E DISPOSITIVOS
        // ======================================================
        _SecurityRow(
          icon: Icons.devices_outlined,
          title: 'Sessões e dispositivos',
          subtitle: _loadingAccountDevices
              ? 'Carregando dispositivos...'
              : _accountDevicesError ??
                    (_activeAccountDeviceCount ==
                            1
                        ? '1 dispositivo conectado'
                        : '$_activeAccountDeviceCount dispositivos conectados'),
          trailing: FilledButton.tonalIcon(
            onPressed: _loadingAccountDevices
                ? null
                : _showSessionsAndDevicesDialog,
            icon: _loadingAccountDevices
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.manage_accounts_outlined,
                    size: 17,
                  ),
            label: const Text(
              'Gerenciar',
            ),
          ),
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // RECUPERAÇÃO LOCAL (NÃO DESTRUTIVA)
        // ======================================================
        _SecurityRow(
          icon: Icons.settings_backup_restore_rounded,
          title: 'Backups e recuperação',
          subtitle: 'Verifique backups locais e exporte uma cópia dos dados.',
          trailing: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UpdateRecoveryPage(),
                ),
              );
            },
            icon: const Icon(Icons.folder_copy_outlined, size: 17),
            label: const Text('Abrir'),
          ),
        ),
        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // ZONA DE RISCO
        // ======================================================
        _buildDangerZoneHeader(),

        // ======================================================
        // CONTEÚDO EXPANSÍVEL
        // ======================================================
        AnimatedSize(
          duration: const Duration(
            milliseconds: 240,
          ),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _dangerZoneExpanded
              ? _buildDangerZoneContent()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ============================================================
  // DANGER ZONE HEADER
  // ============================================================

  Widget _buildDangerZoneHeader() {
    return Material(
      color: const Color(
        0xFFFFF7F5,
      ),
      child: InkWell(
        onTap: _toggleDangerZone,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            13,
            12,
            13,
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._danger.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: _ProfileSettingsPageState._danger,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // TEXT
              // ==================================================
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona de risco',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(
                      height: 2,
                    ),

                    Text(
                      'Ações permanentes relacionadas aos seus dados e à sua conta.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ==================================================
              // SHOW MORE / LESS
              // ==================================================
              TextButton.icon(
                onPressed: _toggleDangerZone,
                style: TextButton.styleFrom(
                  foregroundColor: _ProfileSettingsPageState._danger,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      9,
                    ),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: AnimatedRotation(
                  turns: _dangerZoneExpanded
                      ? 0.5
                      : 0,
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                ),
                label: Text(
                  _dangerZoneExpanded
                      ? 'Mostrar menos'
                      : 'Mostrar mais',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DANGER ZONE CONTENT
  // ============================================================

  Widget _buildDangerZoneContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // EXCLUIR DADOS
        // ======================================================
        _DangerZoneRow(
          icon: Icons.delete_sweep_outlined,
          title: 'Excluir meus dados',
          subtitle:
              'Remove os dados associados ao EVRYLUX, '
              'mas mantém sua conta ativa.',
          buttonLabel: 'Excluir dados',
          onPressed: _confirmDeleteAllData,
        ),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        // ======================================================
        // EXCLUIR CONTA
        // ======================================================
        _DangerZoneRow(
          icon: Icons.person_remove_alt_1_outlined,
          title: 'Excluir conta',
          subtitle:
              'Remove permanentemente sua conta '
              'e os dados associados.',
          buttonLabel: 'Excluir conta',
          strongest: true,
          onPressed: _confirmDeleteAccount,
        ),
      ],
    );
  }

  // ============================================================
  // TOGGLE DANGER ZONE
  // ============================================================

  void _toggleDangerZone() {
    _updateProfileState(
      () {
        _dangerZoneExpanded = !_dangerZoneExpanded;
      },
    );
  }

  // ============================================================
}
