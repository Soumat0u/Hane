import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/firma_duzenle_view.dart';

/// Giriş yapıldıktan sonra, firma profili boşsa kurulum (onboarding) formunu;
/// doluysa [child]'ı (ana ekran) gösterir.
class OnboardingGate extends StatelessWidget {
  final Widget child;
  const OnboardingGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        if (fp.isLoading && fp.companyProfile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final name = fp.companyProfile?.companyName.trim() ?? '';
        if (name.isEmpty) {
          return const FirmaDuzenleView(isOnboarding: true);
        }
        return child;
      },
    );
  }
}
