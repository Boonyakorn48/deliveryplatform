import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT + role + display name locally so the splash screen can
/// restore a session (name is needed by 1.2 home screen's "สวัสดี, {ชื่อ}").
class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _nameKey = 'auth_name';

  Future<void> saveSession({required String token, required String role, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    if (name != null) {
      await prefs.setString(_nameKey, name);
    }
  }

  Future<({String token, String role, String? name})?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final role = prefs.getString(_roleKey);
    if (token == null || role == null) return null;
    return (token: token, role: role, name: prefs.getString(_nameKey));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
  }
}
