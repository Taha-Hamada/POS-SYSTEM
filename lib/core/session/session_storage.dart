import 'package:shared_preferences/shared_preferences.dart';

/// بيحفظ توكنات الجلسة على الجهاز عشان المستخدم مايسجّلش دخول كل مرة يفتح فيها.
class SessionStorage {
  static const String _accessKey = 'pos.access_token';
  static const String _refreshKey = 'pos.refresh_token';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<({String? access, String? refresh})> read() async {
    final SharedPreferences prefs = await _prefs;
    return (
      access: prefs.getString(_accessKey),
      refresh: prefs.getString(_refreshKey),
    );
  }

  Future<void> save({required String access, required String refresh}) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
