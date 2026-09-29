import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AccountDeviceIdentityService {
  AccountDeviceIdentityService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String _deviceIdKey = 'evrylux.account.web_device_identity.v1';

  final Uuid _uuid;

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey)?.trim();

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _uuid.v4();
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }

  String get deviceName => 'EVRYLUX Web';

  String get platformLabel => 'Web Browser';
}
