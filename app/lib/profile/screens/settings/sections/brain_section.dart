part of '../../profile_settings_page.dart';

extension _ProfileSettingsBrainSection on _ProfileSettingsPageState {
  // BRAIN SETTINGS
  // ============================================================

  Widget _buildBrainSettings() {
    return _SettingsPanel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle:
          'Controle onde seus conhecimentos ficam, como são protegidos e como podem ser recuperados.',
      children: [
        _buildBrainDataModeSection(),

        const Divider(height: 1, color: _ProfileSettingsPageState._border),

        _buildBrainVaultSection(),

        // --------------------------------------------------------
        // CLOUD
        // --------------------------------------------------------
        // Dispositivos e recuperação fazem sentido apenas quando
        // existe sincronização em nuvem.
        // --------------------------------------------------------
        if (_brainCloudMode) ...[
          const Divider(height: 1, color: _ProfileSettingsPageState._border),

          _buildBrainDevicesSection(),
        ],

        // --------------------------------------------------------
        // LOCAL
        // --------------------------------------------------------
        // Backup manual fica em destaque quando o usuário escolhe
        // assumir a responsabilidade pelos próprios arquivos.
        // --------------------------------------------------------
        if (!_brainCloudMode) ...[
          const Divider(height: 1, color: _ProfileSettingsPageState._border),

          _buildBrainBackupSection(),
        ],

        const Divider(height: 1, color: _ProfileSettingsPageState._border),

        _buildBrainSecuritySection(),

        if (_brainCloudMode) ...[
          const Divider(height: 1, color: _ProfileSettingsPageState._border),

          _buildBrainRecoverySection(),
        ],
      ],
    );
  }

  // ============================================================
  // BRAIN DATA MODE
  // ============================================================

  Widget _buildBrainDataModeSection() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sync_alt_rounded,
                size: 20,
                color: _ProfileSettingsPageState._primaryDark,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo de dados',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Escolha se o Cérebro fica somente neste dispositivo ou também sincroniza pela nuvem.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _BrainModeOption(
                  icon: Icons.laptop_rounded,
                  title: 'Local',
                  subtitle:
                      'Somente neste dispositivo. Você é responsável pelos seus backups.',
                  selected: !_brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudModeManaged(false);
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _BrainModeOption(
                  icon: Icons.cloud_done_outlined,
                  title: 'Cloud  •  Recomendado',
                  subtitle:
                      'Local + cópia criptografada na nuvem. Proteção automática.',
                  selected: _brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudModeManaged(true);
                  },
                ),
              ),
            ],
          ),

          if (_switchingBrainMode) ...[
            const SizedBox(height: 12),

            const LinearProgressIndicator(minHeight: 2),

            if (_brainModeProgressText != null) ...[
              const SizedBox(height: 8),
              Text(
                _brainModeProgressText!,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN VAULT
  // ============================================================

  Widget _buildBrainVaultSection() {
    final vaultId = _brainVaultId ?? 'Carregando...';

    final keyVersion = _brainKeyVersion?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: _ProfileSettingsPageState._primaryDark,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vault',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Identidade e estado criptográfico do seu Cérebro local.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Atualizar',
                onPressed: _loadingBrainSettings ? null : _loadBrainSettings,
                icon: _loadingBrainSettings
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _BrainInfoRow(label: 'Vault ID', value: vaultId),

          const SizedBox(height: 8),

          _BrainInfoRow(label: 'Versão da chave', value: keyVersion),

          const SizedBox(height: 8),

          _BrainInfoRow(
            label: 'Master Key',
            value: _brainMasterKeyAvailable
                ? 'Disponível no secure storage'
                : 'Indisponível',
            good: _brainMasterKeyAvailable,
          ),

          const SizedBox(height: 8),

          _BrainInfoRow(
            label: 'Sincronização',
            value: _brainCloudMode ? 'Cloud E2EE' : 'Somente local',
            good: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN BACKUP
  // ============================================================

  // ============================================================
  // BRAIN BACKUP INFO DIALOG
  // ============================================================

  Future<void> _showBrainBackupInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _ProfileSettingsPageState._surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _ProfileSettingsPageState._border),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _ProfileSettingsPageState._primaryDark,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Seu backup do Cérebro')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O arquivo .evbrain guarda uma cópia dos seus dados '
                  'do Cérebro para você poder restaurá-los depois.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 16),
                _BackupInfoStep(
                  number: '1',
                  title: 'Criar backup',
                  text:
                      'Gera um arquivo .evbrain com uma cópia dos seus '
                      'dados do Cérebro.',
                ),
                SizedBox(height: 10),
                _BackupInfoStep(
                  number: '2',
                  title: 'Guardar',
                  text:
                      'Salve o arquivo .evbrain em um local seguro, '
                      'como outro disco ou um armazenamento de sua confiança.',
                ),
                SizedBox(height: 10),
                _BackupInfoStep(
                  number: '3',
                  title: 'Restaurar',
                  text:
                      'Quando precisar, importe o arquivo .evbrain para '
                      'recuperar os dados do seu Cérebro.',
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: _ProfileSettingsPageState._primaryDark,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sua chave secreta não é incluída dentro do arquivo '
                        'de backup.',
                        style: TextStyle(
                          color: _ProfileSettingsPageState._text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _BackupSecurityWarning(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrainBackupSection() {
    final busy = _importingBrainBackup || _exportingBrainBackup;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(
            Icons.backup_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Backup do Cérebro',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(width: 4),

                    IconButton(
                      tooltip: 'Como funciona o backup',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _showBrainBackupInfo,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                const Text(
                  'Crie uma cópia dos seus dados para restaurar quando precisar.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          OutlinedButton.icon(
            onPressed: busy ? null : _importBrainBackup,
            icon: _importingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open_outlined, size: 17),
            label: Text(_importingBrainBackup ? 'Restaurando...' : 'Restaurar'),
          ),

          const SizedBox(width: 8),

          FilledButton.tonalIcon(
            onPressed: busy ? null : _exportBrainBackup,
            icon: _exportingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined, size: 17),
            label: Text(_exportingBrainBackup ? 'Criando...' : 'Criar backup'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN SECURITY
  // ============================================================

  Widget _buildBrainSecuritySection() {
    final cloud = _brainCloudMode;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.enhanced_encryption_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proteção dos dados',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  cloud
                      ? '• Seus dados continuam salvos localmente.\n'
                            '• Uma cópia criptografada é mantida na nuvem automaticamente.\n'
                            '• Somente dispositivos autorizados podem acessar o Cérebro.\n'
                            '• O banco recebe apenas objetos criptografados.'
                      : '• Seus dados permanecem somente neste dispositivo.\n'
                            '• Nada novo do Cérebro é enviado para a nuvem.\n'
                            '• Você é responsável por guardar seus próprios backups.\n'
                            '• Use o arquivo .evbrain para manter uma cópia segura.',
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN RECOVERY
  // ============================================================

  // ============================================================
  // RECOVERY DEVICE INFO
  // ============================================================

  Future<void> _showRecoveryDeviceInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _ProfileSettingsPageState._surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _ProfileSettingsPageState._border),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _ProfileSettingsPageState._primaryDark,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Recuperar em outro dispositivo')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use esta opção quando quiser acessar o seu Cérebro em um novo computador.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 16),
                _RecoveryInfoStep(
                  number: '1',
                  title: 'Solicite no novo dispositivo',
                  text:
                      'No computador novo, abra o EVRYLUX e toque em "Solicitar" para pedir acesso ao seu Cérebro.',
                ),
                SizedBox(height: 10),
                _RecoveryInfoStep(
                  number: '2',
                  title: 'Vá até Segurança',
                  text:
                      'No dispositivo que já possui acesso, abra Segurança → Sessão e dispositivos → Gerenciar.',
                ),
                SizedBox(height: 10),
                _RecoveryInfoStep(
                  number: '3',
                  title: 'Confira e aprove',
                  text:
                      'Encontre o novo dispositivo na lista, confirme que ele é seu e aprove a solicitação.',
                ),
                SizedBox(height: 10),
                _RecoveryInfoStep(
                  number: '4',
                  title: 'Conclua no novo dispositivo',
                  text:
                      'Volte ao computador novo e toque em "Concluir". Depois disso, ele poderá acessar o seu Cérebro.',
                ),
                SizedBox(height: 16),
                _RecoverySecurityWarning(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrainRecoverySection() {
    final alreadyHasAccess =
        _brainVaultId != null &&
        _brainVaultId!.trim().isNotEmpty &&
        _brainMasterKeyAvailable;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            alreadyHasAccess
                ? Icons.verified_user_outlined
                : Icons.settings_backup_restore_rounded,
            size: 20,
            color: alreadyHasAccess
                ? _ProfileSettingsPageState._primaryDark
                : _ProfileSettingsPageState._muted,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recuperar em outro dispositivo',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(width: 4),

                    IconButton(
                      tooltip: 'Como recuperar em outro dispositivo',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _showRecoveryDeviceInfo,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  alreadyHasAccess
                      ? 'Este dispositivo já possui acesso ao seu Cérebro. '
                            'Para autorizar outro, vá em Segurança → '
                            'Sessão e dispositivos → Gerenciar.'
                      : 'Solicite acesso neste dispositivo e aprove a '
                            'solicitação em um dispositivo que já esteja '
                            'autorizado.',
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          if (!alreadyHasAccess) ...[
            OutlinedButton.icon(
              onPressed: _requestingBrainRecovery || _completingBrainRecovery
                  ? null
                  : _requestBrainRecovery,
              icon: _requestingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_to_home_screen_rounded, size: 17),
              label: const Text('Solicitar'),
            ),

            const SizedBox(width: 8),

            FilledButton.tonalIcon(
              onPressed: _requestingBrainRecovery || _completingBrainRecovery
                  ? null
                  : _completeBrainRecovery,
              icon: _completingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_open_rounded, size: 17),
              label: const Text('Concluir'),
            ),
          ] else
            const _PhaseBadge(text: 'Protegido'),
        ],
      ),
    );
  }

  // ============================================================
}
