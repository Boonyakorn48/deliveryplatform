import '../../../core/network/api_client.dart';
import '../../../models/app_user.dart';

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

/// Calls the backend Auth API. Endpoints respond 501 until Phase 05 implements them.
class AuthService {
  Future<LoginResult> login({required String email, required String password}) async {
    final response = await ApiClient().post('/auth/login', {
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    return LoginResult(
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    await ApiClient().post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });
  }
}
