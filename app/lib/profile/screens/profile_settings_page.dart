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
// Sessões e dispositivos usam:
//
// AccountDeviceIdentityService
// AccountDeviceRepository
//
// definidos em:
//
// app/dependencies/app_dependencies.dart
//
// ============================================================

part 'settings/actions/preferences_actions.dart';
part 'settings/actions/security_actions.dart';
part 'settings/actions/brain_actions.dart';
part 'settings/sections/profile_settings_shell.dart';
part 'settings/sections/security_section.dart';
part 'settings/sections/brain_section.dart';
part 'settings/sections/about_section.dart';
part 'settings/widgets/profile_settings_widgets.dart';

enum ProfileSettingsSection {
  preferences,
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
  //
  // Esses valores NÃO são mais mockados.
  //
  // O contador é carregado através de:
  //
  // AccountDeviceRepository
  //
  // e representa os dispositivos/sessões ativos registrados
  // no Supabase.
  //
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

  // ============================================================
  // GLOBAL MESSAGE
  // ============================================================

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

    // ==========================================================
    // PREFERENCES
    // ==========================================================

    unawaited(
      _loadPreferences(),
    );

    // ==========================================================
    // ACCOUNT DEVICES
    // ==========================================================
    //
    // Registra/atualiza o dispositivo atual e carrega a
    // quantidade real de dispositivos ativos.
    //
    // ==========================================================

    unawaited(
      _loadAccountDevicesSummary(),
    );

    // ==========================================================
    // BRAIN
    // ==========================================================

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
  // Extensions não devem acessar diretamente o método protegido
  // State.setState().
  //
  // Este é o único ponto de entrada para mutações de UI feitas
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
  // Carrega os dados REAIS de sessões/dispositivos.
  //
  // Fluxo:
  //
  // 1. verifica usuário autenticado;
  // 2. recupera/cria o device_id desta instalação;
  // 3. registra/atualiza o dispositivo no Supabase;
  // 4. consulta dispositivos ativos;
  // 5. atualiza o contador da interface.
  //
  // ============================================================

  Future<
    void
  >
  _loadAccountDevicesSummary() async {
    // ==========================================================
    // EVITA REENTRÂNCIA
    // ==========================================================

    if (_loadingAccountDevices) {
      return;
    }

    // ==========================================================
    // USUÁRIO
    // ==========================================================

    final user = _user;

    if (user ==
        null) {
      _updateProfileState(
        () {
          _activeAccountDeviceCount = 0;

          _accountDevicesError = null;

          _loadingAccountDevices = false;
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
      // DEVICE ID LOCAL
      // ========================================================

      final deviceId = await accountDeviceIdentityService.getOrCreateDeviceId();

      // ========================================================
      // REGISTRA / ATUALIZA DISPOSITIVO ATUAL
      // ========================================================
      //
      // Fazemos isso também aqui porque a tela de Segurança pode
      // ser aberta antes do primeiro heartbeat global.
      //
      // ========================================================

      await accountDeviceRepository.registerDevice(
        deviceId: deviceId,
        deviceName: accountDeviceIdentityService.deviceName,
        platform: accountDeviceIdentityService.platformLabel,
        appVersion: AppInfo.version,
      );

      // ========================================================
      // LISTA DISPOSITIVOS ATIVOS
      // ========================================================

      final devices = await accountDeviceRepository.listActiveDevices();

      if (!mounted) {
        return;
      }

      // ========================================================
      // ATUALIZA CONTADOR REAL
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
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
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
