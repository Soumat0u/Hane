import 'package:flutter/material.dart';


import 'package:hane/theme/app_theme.dart';
class AyarlarView extends StatefulWidget {
  const AyarlarView({super.key});

  @override
  State<AyarlarView> createState() => _AyarlarViewState();
}

class _AyarlarViewState extends State<AyarlarView> {
  bool _bildirimlerAcik = true;
  bool _karanlikMod = false;
  bool _biyometrikGiris = true;
  String _seciliDil = 'Türkçe';
  String _seciliParaBirimi = 'TRY (₺)';

  @override
  Widget build(BuildContext context) {
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
            _bildirimlerAcik,
            (val) => setState(() => _bildirimlerAcik = val),
          ),
          _buildSwitchTile(
            'Karanlık Mod',
            'Uygulama temasını değiştir',
            Icons.dark_mode_outlined,
            _karanlikMod,
            (val) => setState(() => _karanlikMod = val),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Güvenlik'),
          _buildSwitchTile(
            'Biyometrik Giriş',
            'Face ID / Touch ID kullan',
            Icons.fingerprint_rounded,
            _biyometrikGiris,
            (val) => setState(() => _biyometrikGiris = val),
          ),
          _buildActionTile('Şifre Değiştir', 'Hesap şifrenizi yenileyin', Icons.lock_outline, () {}),

          const SizedBox(height: 24),
          _buildSectionTitle('Bölgesel Ayarlar'),
          _buildDropdownTile(
            'Dil',
            Icons.language_outlined,
            _seciliDil,
            ['Türkçe', 'English', 'Deutsch'],
            (val) => setState(() => _seciliDil = val!),
          ),
          _buildDropdownTile(
            'Para Birimi',
            Icons.payments_outlined,
            _seciliParaBirimi,
            ['TRY (₺)', 'USD (\$)', 'EUR (€)'],
            (val) => setState(() => _seciliParaBirimi = val!),
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Versiyon 1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildDropdownTile(String title, IconData icon, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textPrimary)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.brand, size: 20),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
