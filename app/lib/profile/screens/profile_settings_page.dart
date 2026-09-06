import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_info.dart';

import '../../app/dependencies/app_dependencies.dart';
import '../../study/brain/devices/models/brain_device_record.dart';
import '../security/devices/models/account_device.dart';
import '../data/profile_repository.dart';
import '../models/profile_preferences.dart';
import '../../telegram/widgets/telegram_connect_dialog.dart';
import 'legal/privacy_policy_page.dart';
import 'legal/terms_of_use_page.dart';

// ============================================================
// PROFILE SETTINGS PAGE
// ============================================================
//
// Página dedicada para:
//
// - Preferências;
// - Segurança da conta;
// - Sessões e dispositivos;
// - Cérebro;
// - Sobre o aplicativo.
//
// Preferências são salvas no user_metadata do Supabase.
// Senha é alterada pelo Supabase Auth.
//
// ============================================================

part 'settings/actions/preferences_actions.dart';
part 'settings/actions/security_actions.dart';
part 'settings/actions/brain_actions.dart';
part 'settings/actions/brain_mode_actions.dart';
part 'settings/sections/profile_settings_shell.dart';
part 'settings/sections/security_section.dart';
part 'settings/sections/telegram_section.dart';
part 'settings/sections/brain_section.dart';
part 'settings/sections/about_section.dart';
part 'settings/widgets/profile_settings_widgets.dart';

enum ProfileSettingsSection {
  preferences,
  telegram,
  security,
  brain,
  about,
}

class ProfileSettingsPage
    extends
        StatefulWidget {
  const ProfileSettingsPage({
    super.key,
    this.initialSection = ProfileSettingsSection.preferences,
  });

  final ProfileSettingsSection initialSection;

  @override
  State<
    ProfileSettingsPage
  >
  createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState
    extends
        State<
          ProfileSettingsPage
        > {
  // ============================================================
  // DANGER ZONE
  // ============================================================

  bool _dangerZoneExpanded = false;
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _danger = Color(
    0xFFB3261E,
  );

  // ============================================================
  // STATE
  // ============================================================

  late ProfileSettingsSection _section;

  late final ProfileRepository _profileRepository;

  bool _compactMode = false;

  bool _reduceMotion = false;

  bool _confirmBeforeDelete = true;

  bool _savingPreferences = false;

  Timer? _preferencesSaveTimer;

  bool _changingPassword = false;

  // ============================================================
  // ACCOUNT DEVICES / SESSIONS
  // ============================================================

  bool _loadingAccountDevices = false;

  int _activeAccountDeviceCount = 0;

  String? _accountDevicesError;

  // ============================================================
  // BRAIN BACKUP
  // ============================================================

  bool _importingBrainBackup = false;

  bool _exportingBrainBackup = false;

  // ============================================================
  // BRAIN SETTINGS
  // ============================================================

  bool _loadingBrainSettings = false;

  bool _switchingBrainMode = false;

  String? _brainModeProgressText;

  bool _brainCloudMode = false;

  String? _brainVaultId;

  int? _brainKeyVersion;

  bool _brainMasterKeyAvailable = false;

  // ============================================================
  // BRAIN DEVICES
  // ============================================================

  bool _loadingBrainDevices = false;

  String? _brainDevicesError;

  String? _currentBrainDeviceId;

  String? _revokingBrainDeviceId;

  String? _approvingBrainDeviceId;

  bool _requestingBrainRecovery = false;

  bool _completingBrainRecovery = false;

  List<
    BrainDeviceRecord
  >
  _brainDevices =
      const <
        BrainDeviceRecord
      >[];

  String? _message;

  bool _messageIsError = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _section = widget.initialSection;

    _profileRepository = ProfileRepository();

    unawaited(
      _loadPreferences(),
    );

    unawaited(
      _loadAccountDevicesSummary(),
    );

    _loadBrainSettings();
  }

  // ============================================================
  // USER
  // ============================================================

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _email =>
      _user?.email ??
      'E-mail não disponível';

  // ============================================================
  // STATE UPDATE GATE
  // ============================================================
  //
  // Os arquivos `part` usam extensions para separar
  // responsabilidades.
  //
  // Extensions não devem acessar diretamente State.setState().
  //
  // Este método é o ponto de entrada para mutações de UI feitas
  // pelas partes refatoradas.
  //
  // ============================================================

  void _updateProfileState(
    VoidCallback callback,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      callback,
    );
  }

  // ============================================================
  // LOAD ACCOUNT DEVICES SUMMARY
  // ============================================================
  //
  // Carrega os dispositivos reais associados à conta.
  //
  // Fluxo:
  //
  // 1. verifica autenticação;
  // 2. obtém/cria o device_id local;
  // 3. registra a sessão atual;
  // 4. consulta os dispositivos ativos;
  // 5. atualiza o contador da interface.
  //
  // ============================================================

  Future<
    void
  >
  _loadAccountDevicesSummary() async {
    // ==========================================================
    // EVITA DUAS CARGAS AO MESMO TEMPO
    // ==========================================================

    if (_loadingAccountDevices) {
      return;
    }

    // ==========================================================
    // AUTH
    // ==========================================================

    final user = _user;

    final session = Supabase.instance.client.auth.currentSession;

    if (user ==
            null ||
        session ==
            null) {
      _updateProfileState(
        () {
          _loadingAccountDevices = false;

          _activeAccountDeviceCount = 0;

          _accountDevicesError = null;
        },
      );

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _updateProfileState(
      () {
        _loadingAccountDevices = true;

        _accountDevicesError = null;
      },
    );

    try {
      // ========================================================
      // DEVICE ID
      // ========================================================

      final deviceId = await accountDeviceIdentityService.getOrCreateDeviceId();

      // ========================================================
      // REGISTER CURRENT SESSION
      // ========================================================
      //
      // O repository usa o session_id real presente no JWT
      // atual do Supabase.
      //
      // ========================================================

      final registered = await accountDeviceRepository.registerDevice(
        deviceId: deviceId,
        deviceName: accountDeviceIdentityService.deviceName,
        platform: accountDeviceIdentityService.platformLabel,
        appVersion: AppInfo.version,
      );

      if (!registered) {
        throw StateError(
          'A sessão atual foi recusada pelo registro de dispositivos.',
        );
      }

      // ========================================================
      // ACTIVE DEVICES
      // ========================================================

      final List<
        AccountDevice
      >
      devices = await accountDeviceRepository.listActiveDevices();

      if (!mounted) {
        return;
      }

      // ========================================================
      // UPDATE REAL COUNT
      // ========================================================

      _updateProfileState(
        () {
          _activeAccountDeviceCount = devices.length;

          _accountDevicesError = null;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro carregando dispositivos da conta: $error',
      );

      debugPrint(
        '[PROFILE SETTINGS] '
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _activeAccountDeviceCount = 0;

          _accountDevicesError = 'Não foi possível carregar os dispositivos agora.';
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _loadingAccountDevices = false;
          },
        );
      }
    }
  }

  // ============================================================
  // ORCHESTRATION ONLY
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return _buildProfileSettingsShell(
      context,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _preferencesSaveTimer?.cancel();

    super.dispose();
  }
}
