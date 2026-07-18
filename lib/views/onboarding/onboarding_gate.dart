import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/firma_duzenle_view.dart';
import 'package:hane/views/onboarding/onboarding_welcome_view.dart';
import 'package:hane/services/notification_service.dart';

/// Giriş yapıldıktan sonra, firma profili boşsa önce kaydırmalı tanıtım
/// ekranını, ardından kurulum (onboarding) formunu; profil doluysa
/// [child]'ı (ana ekran) gösterir.
class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _welcomeSeen = false;
  bool _skipped = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        if (fp.isLoading && fp.companyProfile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final name = fp.companyProfile?.companyName.trim() ?? '';
        if (name.isEmpty && !_skipped) {
          if (!_welcomeSeen) {
            return OnboardingWelcomeView(onDone: () => setState(() => _welcomeSeen = true));
          }
          return FirmaDuzenleView(
            isOnboarding: true,
            onSkip: () {
              // Formu doldurmadan atlansa da onboarding sona eriyor demektir;
              // gerekli izinler (bildirim vb.) burada istenir.
              NotificationService.instance.requestPermission();
              setState(() => _skipped = true);
            },
          );
        }
        return widget.child;
      },
    );
  }
}
