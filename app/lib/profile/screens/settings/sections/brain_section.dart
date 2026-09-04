part of '../../profile_settings_page.dart';

extension _ProfileSettingsBrainSection
    on _ProfileSettingsPageState {
  // BRAIN SETTINGS
  // ============================================================

  Widget _buildBrainSettings() {
    return _SettingsPanel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle: 'Controle onde seus conhecimentos ficam, como são sincronizados e como são protegidos.',
      children: [
        _buildBrainDataModeSection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainVaultSection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainDevicesSection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainBackupSection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainSecuritySection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainRecoverySection(),
      ],
    );
  }

  // ============================================================
  // BRAIN DATA MODE
  // ============================================================

  Widget _buildBrainDataModeSection() {
    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
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

              SizedBox(
                width: 10,
              ),

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
                    SizedBox(
                      height: 2,
                    ),
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

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child: _BrainModeOption(
                  icon: Icons.laptop_rounded,
                  title: 'Local',
                  subtitle: 'Seus dados permanecem neste dispositivo. Nenhum sync do Cérebro é realizado.',
                  selected: !_brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudMode(
                      false,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _BrainModeOption(
                  icon: Icons.cloud_done_outlined,
                  title: 'Cloud',
                  subtitle: 'Local-first + sincronização E2EE somente entre dispositivos autorizados.',
                  selected: _brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudMode(
                      true,
                    );
                  },
                ),
              ),
            ],
          ),

          if (_switchingBrainMode) ...[
            const SizedBox(
              height: 12,
            ),

            const LinearProgressIndicator(
              minHeight: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN VAULT
  // ============================================================

  Widget _buildBrainVaultSection() {
    final vaultId =
        _brainVaultId ??
        'Carregando...';

    final keyVersion =
        _brainKeyVersion?.toString() ??
        '-';

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
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

              const SizedBox(
                width: 10,
              ),

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
                    SizedBox(
                      height: 2,
                    ),
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
                onPressed: _loadingBrainSettings
                    ? null
                    : _loadBrainSettings,
                icon: _loadingBrainSettings
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

          const SizedBox(
            height: 12,
          ),

          _BrainInfoRow(
            label: 'Vault ID',
            value: vaultId,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Versão da chave',
            value: keyVersion,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Master Key',
            value: _brainMasterKeyAvailable
                ? 'Disponível no secure storage'
                : 'Indisponível',
            good: _brainMasterKeyAvailable,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Sincronização',
            value: _brainCloudMode
                ? 'Cloud E2EE'
                : 'Somente local',
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

  Future<
    void
  >
  _showBrainBackupInfo() async {
    await showDialog<
      void
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
                  20,
                ),
                side: const BorderSide(
                  color: _ProfileSettingsPageState._border,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _ProfileSettingsPageState._primaryDark,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Como funciona o Backup .evbrain',
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O arquivo .evbrain é um backup portátil do seu Vault. '
                      'Ele permite manter uma cópia dos dados do Cérebro sem '
                      'colocar a Master Key em plaintext dentro do arquivo.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    _BackupInfoStep(
                      number: '1',
                      title: 'Exportar',
                      text:
                          'Cria um arquivo .evbrain portátil com os dados '
                          'do Vault preparados para backup.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _BackupInfoStep(
                      number: '2',
                      title: 'Master Key protegida',
                      text:
                          'A Master Key não é colocada em plaintext dentro '
                          'do arquivo de backup.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _BackupInfoStep(
                      number: '3',
                      title: 'Importar',
                      text:
                          'Permite restaurar um backup .evbrain compatível quando '
                          'a Master Key correspondente ao Vault está disponível.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _BackupInfoStep(
                      number: '4',
                      title: 'Backup e Recovery são diferentes',
                      text:
                          'O backup preserva os dados do Vault. O Recovery Device '
                          'é o fluxo usado para recuperar o acesso criptográfico '
                          'em outro dispositivo.',
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _BackupSecurityWarning(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Entendi',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildBrainBackupSection() {
    final busy =
        _importingBrainBackup ||
        _exportingBrainBackup;

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.backup_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Backup .evbrain',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    IconButton(
                      tooltip: 'Como funciona o Backup .evbrain',
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

                const SizedBox(
                  height: 2,
                ),

                const Text(
                  'Backup portátil criptografado do Vault. '
                  'O arquivo não contém a Master Key em plaintext.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          OutlinedButton.icon(
            onPressed: busy
                ? null
                : _importBrainBackup,
            icon: _importingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.file_open_outlined,
                    size: 17,
                  ),
            label: Text(
              _importingBrainBackup
                  ? 'Importando...'
                  : 'Importar',
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          FilledButton.tonalIcon(
            onPressed: busy
                ? null
                : _exportBrainBackup,
            icon: _exportingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.download_outlined,
                    size: 17,
                  ),
            label: Text(
              _exportingBrainBackup
                  ? 'Exportando...'
                  : 'Exportar',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN SECURITY
  // ============================================================

  Widget _buildBrainSecuritySection() {
    return const Padding(
      padding: EdgeInsets.all(
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.enhanced_encryption_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proteção dos dados',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  '• O Vault usa criptografia local.\n'
                  '• A Master Key fica no secure storage do sistema operacional.\n'
                  '• O Banco de dados recebe somente objetos criptografados do Cérebro.\n'
                  '• Cloud exige conta autenticada, Master Key e dispositivo autorizado.',
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
      ),
    );
  }

  // ============================================================
  // BRAIN RECOVERY
  // ============================================================

  // ============================================================
  // RECOVERY DEVICE INFO
  // ============================================================

  Future<
    void
  >
  _showRecoveryDeviceInfo() async {
    await showDialog<
      void
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
                  20,
                ),
                side: const BorderSide(
                  color: _ProfileSettingsPageState._border,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _ProfileSettingsPageState._primaryDark,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      'Como funciona o Recovery Device',
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O Recovery Device permite recuperar o seu Cérebro '
                      'em um novo dispositivo sem enviar a Master Key em '
                      'texto puro.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),

                    SizedBox(
                      height: 14,
                    ),

                    _RecoveryInfoStep(
                      number: '1',
                      title: 'Novo dispositivo',
                      text:
                          'O novo computador gera uma identidade criptográfica '
                          'própria e solicita acesso ao Vault existente.',
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    _RecoveryInfoStep(
                      number: '2',
                      title: 'Aprovação',
                      text:
                          'Um dispositivo que já está autorizado precisa aprovar '
                          'o novo computador.',
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    _RecoveryInfoStep(
                      number: '3',
                      title: 'Fingerprint',
                      text:
                          'Antes da aprovação, compare o fingerprint mostrado '
                          'nos dois dispositivos. Eles precisam ser idênticos.',
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    _RecoveryInfoStep(
                      number: '4',
                      title: 'Master Key protegida',
                      text:
                          'A Master Key é transferida somente dentro de um '
                          'envelope criptografado E2EE e depois armazenada '
                          'localmente no secure storage do novo dispositivo.',
                    ),

                    SizedBox(
                      height: 16,
                    ),

                    _RecoverySecurityWarning(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Entendi',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildBrainRecoverySection() {
    final alreadyHasAccess =
        _brainVaultId !=
            null &&
        _brainVaultId!.trim().isNotEmpty &&
        _brainMasterKeyAvailable;

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
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

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recovery Device',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    IconButton(
                      tooltip: 'Como funciona o Recovery Device',
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

                const SizedBox(
                  height: 2,
                ),

                Text(
                  alreadyHasAccess
                      ? 'Este dispositivo já possui a Master Key. '
                            'Para recuperar outro computador, aprove o '
                            'dispositivo pendente na lista acima após conferir '
                            'o fingerprint.'
                      : 'Recupere este Cérebro usando um dispositivo que '
                            'já esteja autorizado. A Master Key é transportada '
                            'somente dentro de um envelope E2EE.',
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

          if (!alreadyHasAccess) ...[
            OutlinedButton.icon(
              onPressed:
                  _requestingBrainRecovery ||
                      _completingBrainRecovery
                  ? null
                  : _requestBrainRecovery,
              icon: _requestingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_to_home_screen_rounded,
                      size: 17,
                    ),
              label: const Text(
                'Solicitar',
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            FilledButton.tonalIcon(
              onPressed:
                  _requestingBrainRecovery ||
                      _completingBrainRecovery
                  ? null
                  : _completeBrainRecovery,
              icon: _completingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.lock_open_rounded,
                      size: 17,
                    ),
              label: const Text(
                'Concluir',
              ),
            ),
          ] else
            const _PhaseBadge(
              text: 'Protegido',
            ),
        ],
      ),
    );
  }

  // ============================================================
}
