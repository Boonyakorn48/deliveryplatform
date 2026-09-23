import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/data/auth_state.dart';
import 'features/customer/data/cart_state.dart';
import 'features/customer/presentation/customer_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DeliveryPlatformApp());
}

class DeliveryPlatformApp extends StatelessWidget {
  const DeliveryPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => CartState()),
      ],
      child: MaterialApp(
        title: 'Delivery Platform',
        theme: AppTheme.light,
        home: const CustomerHomeScreen(),
      ),
    );
  }
}
