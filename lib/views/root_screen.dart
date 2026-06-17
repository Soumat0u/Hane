import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/settings_provider.dart';
import 'package:hane/views/main_navigation_view.dart';
import 'package:hane/views/auth/app_lock_gate.dart';
import 'package:hane/views/onboarding/onboarding_gate.dart';

/// Giriş yapıldıktan sonraki kök ekran:
/// biyometrik kilit → onboarding kapısı → ana navigasyon.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AppLockGate(
      enabled: settings.biometricEnabled,
      child: const OnboardingGate(child: MainNavigationPage()),
    );
  }
}
