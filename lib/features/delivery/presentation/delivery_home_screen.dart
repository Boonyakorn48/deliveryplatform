import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/data/auth_state.dart';

/// Placeholder home for the Delivery role; Jobs/Accept/Status/GPS land in Phase 07.
class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: const Center(child: Text('Available Jobs / Accept / Status / GPS — Phase 07')),
    );
  }
}
