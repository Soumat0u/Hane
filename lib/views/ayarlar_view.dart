import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF032B5E)),
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF032B5E),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF032B5E), size: 20),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF032B5E), size: 20),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildDropdownTile(String title, IconData icon, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF032B5E), size: 20),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
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
