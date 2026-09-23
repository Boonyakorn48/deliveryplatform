import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/data/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/customer/presentation/customer_home_screen.dart';
import '../features/delivery/presentation/delivery_home_screen.dart';
import '../models/user_role.dart';

/// Single entry widget: shows splash while restoring session, then routes by role.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return switch (auth.role) {
          UserRole.delivery => const DeliveryHomeScreen(),
          UserRole.customer || null => const CustomerHomeScreen(),
        };
    }
  }
}
