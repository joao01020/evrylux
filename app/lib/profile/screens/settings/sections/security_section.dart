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
            label: const Text(
              'Alterar',
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
                  (_activeAccountDeviceCount == 1
                      ? '1 dispositivo conectado'
                      : '$_activeAccountDeviceCount dispositivos conectados'),
          trailing: FilledButton.tonalIcon(
            onPressed: _showSessionsAndDevicesDialog,
            icon: const Icon(
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
        // ZONA DE RISCO
        // ======================================================
        const _DangerZoneHeader(),

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
          subtitle: 'Remove os dados associados ao EVRYLUX, mas mantém sua conta ativa.',
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
          subtitle: 'Remove permanentemente sua conta e os dados associados.',
          buttonLabel: 'Excluir conta',
          strongest: true,
          onPressed: _confirmDeleteAccount,
        ),
      ],
    );
  }

  // ============================================================
}
