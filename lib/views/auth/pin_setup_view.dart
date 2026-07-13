import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/providers/settings_provider.dart';
import 'package:hane/services/pin_service.dart';
import 'package:hane/views/widgets/pin_keypad.dart';

enum _Step { loading, menu, verifyOldForChange, verifyOldForRemove, enterNew, confirmNew }

/// PIN kodu kurma/değiştirme/kaldırma ekranı. Ayarlar'dan açılır.
/// PIN zaten kuruluysa önce bir menü (Değiştir/Kaldır) gösterir; her ikisi
/// de eski PIN'in doğrulanmasını ister. PIN yoksa doğrudan yeni PIN girişine geçer.
class PinSetupView extends StatefulWidget {
  const PinSetupView({super.key});

  @override
  State<PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends State<PinSetupView> {
  _Step _step = _Step.loading;
  String _entered = '';
  String _firstNewPin = '';
  String? _error;
  bool _forRemoval = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPin = await PinService.instance.hasPin();
    if (!mounted) return;
    setState(() => _step = hasPin ? _Step.menu : _Step.enterNew);
  }

  void _onDigit(int digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _error = null;
      _entered += '$digit';
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _onPinComplete);
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _onPinComplete() async {
    final pin = _entered;
    switch (_step) {
      case _Step.verifyOldForChange:
        final ok = await PinService.instance.verifyPin(pin);
        if (!mounted) return;
        if (ok) {
          setState(() {
            _step = _Step.enterNew;
            _entered = '';
          });
        } else {
          setState(() {
            _error = 'Mevcut PIN yanlış.';
            _entered = '';
          });
        }
        break;
      case _Step.verifyOldForRemove:
        final ok = await PinService.instance.verifyPin(pin);
        if (!mounted) return;
        if (ok) {
          await PinService.instance.clearPin();
          if (!mounted) return;
          await context.read<SettingsProvider>().setPinEnabled(false);
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          setState(() {
            _error = 'Mevcut PIN yanlış.';
            _entered = '';
          });
        }
        break;
      case _Step.enterNew:
        setState(() {
          _firstNewPin = pin;
          _entered = '';
          _step = _Step.confirmNew;
        });
        break;
      case _Step.confirmNew:
        if (pin == _firstNewPin) {
          await PinService.instance.setPin(pin);
          if (!mounted) return;
          await context.read<SettingsProvider>().setPinEnabled(true);
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          setState(() {
            _error = 'PIN kodları eşleşmiyor. Tekrar deneyin.';
            _entered = '';
            _step = _Step.enterNew;
          });
        }
        break;
      case _Step.menu:
      case _Step.loading:
        break;
    }
  }

  String get _title {
    switch (_step) {
      case _Step.verifyOldForChange:
      case _Step.verifyOldForRemove:
        return 'Mevcut PIN Kodunu Girin';
      case _Step.enterNew:
        return 'Yeni PIN Kodu Oluşturun';
      case _Step.confirmNew:
        return 'Yeni PIN Kodunu Onaylayın';
      case _Step.menu:
      case _Step.loading:
        return 'PIN Kodu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _step == _Step.loading
            ? const Center(child: CircularProgressIndicator())
            : _step == _Step.menu
                ? _buildMenu(context)
                : _buildKeypadStep(context),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'PIN Kodunu Değiştir',
            onTap: () => setState(() {
              _forRemoval = false;
              _step = _Step.verifyOldForChange;
            }),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context,
            icon: Icons.lock_open_rounded,
            title: 'PIN Kodunu Kaldır',
            color: context.colors.danger,
            onTap: () => setState(() {
              _forRemoval = true;
              _step = _Step.verifyOldForRemove;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    final c = color ?? context.colors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _buildKeypadStep(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _forRemoval && (_step == _Step.verifyOldForRemove)
              ? 'PIN kodunu kaldırmak için mevcut kodu girin'
              : (_step == _Step.enterNew || _step == _Step.confirmNew)
                  ? '4 haneli bir kod belirleyin'
                  : 'Devam etmek için mevcut PIN kodunuzu girin',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 28),
        PinKeypad(enteredLength: _entered.length, onDigit: _onDigit, onBackspace: _onBackspace),
      ],
    );
  }
}
