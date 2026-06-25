import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hane/providers/settings_provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/services/notification_service.dart';
import 'package:hane/theme/app_theme.dart';

class AyarlarView extends StatefulWidget {
  const AyarlarView({super.key});

  @override
  State<AyarlarView> createState() => _AyarlarViewState();
}

class _AyarlarViewState extends State<AyarlarView> {
  /// Bildirim ayarı değiştiğinde zamanlanmış hatırlatmaları senkronlar.
  Future<void> _onNotificationsChanged(bool value) async {
    final settings = context.read<SettingsProvider>();
    final fp = context.read<FinanceProvider>();
    await settings.setNotifications(value);
    if (value) {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.syncDueReminders(fp.getAllDuePayments());
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionTitle('Uygulama Tercihleri'),
          _buildSwitchTile(
            'Bildirimler',
            'Push bildirimlerini al',
            Icons.notifications_active_outlined,
            settings.notificationsEnabled,
            _onNotificationsChanged,
          ),
          _buildSwitchTile(
            'Karanlık Mod',
            'Uygulama temasını değiştir',
            Icons.dark_mode_outlined,
            settings.isDark,
            (val) => context.read<SettingsProvider>().setDarkMode(val),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Güvenlik'),
          _buildSwitchTile(
            'Biyometrik Giriş',
            'Face ID / Touch ID kullan',
            Icons.fingerprint_rounded,
            settings.biometricEnabled,
            (val) => context.read<SettingsProvider>().setBiometric(val),
          ),
          _buildActionTile('Şifre Değiştir', 'Hesap şifrenizi yenileyin', Icons.lock_outline, () {}),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Versiyon 1.0.0',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: context.colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: context.colors.brand,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.brand, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.brand, size: 20),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.colors.textSecondary),
      ),
    );
  }

}
