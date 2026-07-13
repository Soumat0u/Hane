import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:hane/theme/app_theme.dart';
import 'package:hane/services/pin_service.dart';
import 'package:hane/views/widgets/pin_keypad.dart';
import 'package:local_auth/local_auth.dart';

/// Uygulama kilidi kapısı. [pinEnabled] true ise özel PIN giriş ekranı
/// gösterilir (biyometrik de açıksa ekranda ayrıca hızlı erişim ikonu sunulur);
/// sadece [biometricEnabled] açıksa mevcut tam ekran biyometrik akış çalışır.
/// Kilit hem soğuk açılışta hem uygulama arka plandan dönünce tetiklenir.
class AppLockGate extends StatefulWidget {
  final bool biometricEnabled;
  final bool pinEnabled;
  final Widget child;
  const AppLockGate({
    super.key,
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.child,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authenticating = false;
  String _pinEntered = '';
  String? _pinError;

  bool get _enabled => widget.biometricEnabled || widget.pinEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb || !_enabled) {
      // Web'de biyometrik/PIN desteklenmez; kilidi açık geç.
      _unlocked = true;
    } else if (!widget.pinEnabled) {
      // Sadece biyometrik açıksa, önceki davranış gibi otomatik tetikle.
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
    // PIN açıksa kullanıcı tuşlamasını bekleriz, otomatik tetiklemeyiz.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || !_enabled) return;
    if (state == AppLifecycleState.paused) {
      // Yalnızca tam arka plana geçişte kilitle; kısa sistem diyalogları
      // (izin istemi, biyometrik prompt vb.) tetiklenen `inactive` durumunda
      // yanlışlıkla tekrar kilitlemeyiz.
      if (mounted) {
        setState(() {
          _unlocked = false;
          _pinEntered = '';
          _pinError = null;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_unlocked && !widget.pinEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      final canCheck = await _auth.isDeviceSupported();
      if (!canCheck) {
        // Cihaz desteklemiyorsa ve PIN de yoksa kilidi açık geç (kullanıcıyı dışarıda bırakma).
        if (!widget.pinEnabled) setState(() => _unlocked = true);
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (mounted && ok) setState(() => _unlocked = true);
    } catch (e) {
      // Hata durumunda kilitli kal, tekrar dene butonu/PIN ekranı gösterilir.
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  void _onPinDigit(int digit) {
    if (_pinEntered.length >= 4) return;
    setState(() {
      _pinError = null;
      _pinEntered += '$digit';
    });
    if (_pinEntered.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _verifyPin);
    }
  }

  void _onPinBackspace() {
    if (_pinEntered.isEmpty) return;
    setState(() => _pinEntered = _pinEntered.substring(0, _pinEntered.length - 1));
  }

  Future<void> _verifyPin() async {
    final ok = await PinService.instance.verifyPin(_pinEntered);
    if (!mounted) return;
    if (ok) {
      setState(() => _unlocked = true);
    } else {
      setState(() {
        _pinError = 'Yanlış PIN kodu.';
        _pinEntered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    if (widget.pinEnabled) return _buildPinLock(context);
    return _buildBiometricLock(context);
  }

  Widget _buildPinLock(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, color: context.colors.brand, size: 48),
            const SizedBox(height: 16),
            Text('Uygulama Kilitli',
                style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Devam etmek için PIN kodunuzu girin',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
            if (_pinError != null) ...[
              const SizedBox(height: 12),
              Text(_pinError!, style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 28),
            PinKeypad(enteredLength: _pinEntered.length, onDigit: _onPinDigit, onBackspace: _onPinBackspace),
            if (widget.biometricEnabled) ...[
              const SizedBox(height: 24),
              IconButton(
                onPressed: _authenticating ? null : _authenticate,
                icon: Icon(Icons.fingerprint, size: 32, color: context.colors.brand),
                tooltip: 'Biyometrik ile aç',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricLock(BuildContext context) {
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
