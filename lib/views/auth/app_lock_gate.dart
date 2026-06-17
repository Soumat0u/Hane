import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:local_auth/local_auth.dart';

/// Biyometrik kilit kapısı. [enabled] true ise, [child] gösterilmeden önce
/// cihaz biyometrik/PIN doğrulaması ister. Başarısız olursa tekrar deneme sunar.
class AppLockGate extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const AppLockGate({super.key, required this.enabled, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _unlocked = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      final canCheck = await _auth.isDeviceSupported();
      if (!canCheck) {
        // Cihaz desteklemiyorsa kilidi açık geç (kullanıcıyı dışarıda bırakma).
        setState(() => _unlocked = true);
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (mounted) setState(() => _unlocked = ok);
    } catch (e) {
      // Hata durumunda kilitli kal, tekrar dene butonu göster.
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (_unlocked) return widget.child;
    return Scaffold(
      backgroundColor: context.colors.brand,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, color: context.colors.surface, size: 64),
            const SizedBox(height: 20),
            Text('Uygulama Kilitli',
                style: TextStyle(color: context.colors.surface, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Devam etmek için kimliğinizi doğrulayın',
                style: TextStyle(color: context.colors.surface.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _authenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: Text(_authenticating ? 'Doğrulanıyor...' : 'Kilidi Aç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.surface,
                foregroundColor: context.colors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
