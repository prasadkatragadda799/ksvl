import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

import 'admin_login_screen.dart';
import 'home_shell.dart';

/// Blocks access to the admin dashboard until the device has verified an
/// allow-listed admin phone number.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  late Future<bool> _adminCheck;

  @override
  void initState() {
    super.initState();
    _adminCheck = _check();
  }

  Future<bool> _check() async {
    await AuthService.instance.ensureSignedIn();
    final isAdmin = await AuthService.instance.isAdmin();
    if (isAdmin) await _seedStoreConfig();
    return isAdmin;
  }

  Future<void> _seedStoreConfig() {
    return StoreConfigRepository.instance.ensureSeeded(
      const StoreConfig(
        storeName: 'KSVL Naturals',
        isStoreOpen: true,
        location: StoreLocation(
          label: 'Set your store location',
          latitude: 0,
          longitude: 0,
          radiusKm: 10,
        ),
        deliverySettings: DeliverySettings(),
      ),
    );
  }

  void _onVerified() {
    setState(() {
      _adminCheck = _seedStoreConfig().then((_) => true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return const HomeShell();
        return AdminLoginScreen(onAdminVerified: _onVerified);
      },
    );
  }
}
