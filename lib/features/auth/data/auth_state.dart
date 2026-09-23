import 'package:flutter/foundation.dart';
import '../../../models/user_role.dart';
import 'auth_service.dart';
import 'auth_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide auth state: drives the splash redirect and gates role-specific screens.
class AuthState extends ChangeNotifier {
  AuthState({AuthService? authService, AuthStorage? authStorage})
      : _authService = authService ?? AuthService(),
        _authStorage = authStorage ?? AuthStorage();

  final AuthService _authService;
  final AuthStorage _authStorage;

  AuthStatus status = AuthStatus.unknown;
  String? token;
  UserRole? role;
  String? userName;
  String? errorMessage;

  Future<void> restoreSession() async {
    final session = await _authStorage.readSession();
    if (session == null) {
      status = AuthStatus.unauthenticated;
    } else {
      token = session.token;
      role = UserRoleJson.fromString(session.role);
      userName = session.name;
      status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    errorMessage = null;
    try {
      final result = await _authService.login(email: email, password: password);
      token = result.token;
      role = result.user.role;
      userName = result.user.name;
      await _authStorage.saveSession(
        token: result.token,
        role: result.user.role.value,
        name: result.user.name,
      );
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authStorage.clear();
    token = null;
    role = null;
    userName = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
