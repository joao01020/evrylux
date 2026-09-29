import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_data_mode.dart';
import 'brain_data_mode_storage.dart';

/// Persistência do modo de dados específica para Web.
///
/// No navegador, o Brain depende da nuvem/Supabase para o Vault E2EE.
/// Por isso:
/// - a preferência é isolada por usuário;
/// - a escolha é espelhada no metadata da conta;
/// - contas que já existiam antes desta migração recebem `cloud`
///   automaticamente uma única vez, sem reabrir o onboarding;
/// - novos navegadores da mesma conta recuperam a escolha da conta.
class WebBrainDataModeStorage
    extends
        BrainDataModeStorage {
  WebBrainDataModeStorage({
    Future<
      SharedPreferences
    >
    Function()?
    preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ??
           SharedPreferences.getInstance;

  static const String _localPrefix = 'evrylux.brain.data_mode.web.v1';
  static const String _remoteKey = 'brain_data_mode';

  final Future<
    SharedPreferences
  >
  Function()
  _preferencesProvider;

  String? get _userId {
    final value = Supabase.instance.client.auth.currentUser?.id.trim();
    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }
    return value;
  }

  String get _localKey {
    final userId = _userId;
    return userId ==
            null
        ? '$_localPrefix.anonymous'
        : '$_localPrefix.$userId';
  }

  BrainDataMode? _remoteMode() {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    return BrainDataMode.tryParse(
      metadata?[_remoteKey]?.toString(),
    );
  }

  Future<
    void
  >
  _saveLocal(
    BrainDataMode mode,
  ) async {
    final preferences = await _preferencesProvider();
    final ok = await preferences.setString(
      _localKey,
      mode.storageValue,
    );

    if (!ok) {
      throw StateError(
        'Não foi possível salvar o modo de dados do Cérebro na Web.',
      );
    }
  }

  Future<
    void
  >
  _saveRemoteBestEffort(
    BrainDataMode mode,
  ) async {
    if (_userId ==
        null) {
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data:
              <
                String,
                dynamic
              >{
                _remoteKey: mode.storageValue,
              },
        ),
      );
    } catch (
      _
    ) {
      // O estado local continua válido. Uma sessão futura tenta
      // reconciliar novamente.
    }
  }

  @override
  Future<
    BrainDataMode?
  >
  load() async {
    final preferences = await _preferencesProvider();

    final local = BrainDataMode.tryParse(
      preferences.getString(
        _localKey,
      ),
    );
    if (local !=
        null) {
      return local;
    }

    final remote = _remoteMode();
    if (remote !=
        null) {
      await _saveLocal(
        remote,
      );
      return remote;
    }

    // A versão Web só consegue operar com o Brain em modo Cloud.
    //
    // Antes desta correção o modo ficava apenas no browser. Ao abrir
    // a mesma conta em outro navegador/domínio, `load()` retornava null
    // e o Brain interpretava isso como "primeira configuração",
    // reabrindo o modal Local / Cloud.
    //
    // Para contas autenticadas existentes, fazemos a migração segura
    // para Cloud e persistimos tanto localmente quanto na conta.
    if (_userId !=
        null) {
      const mode = BrainDataMode.cloud;
      await _saveLocal(
        mode,
      );
      await _saveRemoteBestEffort(
        mode,
      );
      return mode;
    }

    return null;
  }

  @override
  Future<
    void
  >
  save(
    BrainDataMode mode,
  ) async {
    // Na Web, Local não é uma modalidade funcional equivalente ao
    // desktop. Normalizamos para Cloud para evitar um estado impossível.
    const normalized = BrainDataMode.cloud;
    await _saveLocal(
      normalized,
    );
    await _saveRemoteBestEffort(
      normalized,
    );
  }

  @override
  Future<
    void
  >
  clear() async {
    final preferences = await _preferencesProvider();
    await preferences.remove(
      _localKey,
    );

    if (_userId ==
        null) {
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data:
              <
                String,
                dynamic
              >{
                _remoteKey: null,
              },
        ),
      );
    } catch (
      _
    ) {
      // Best effort.
    }
  }
}
