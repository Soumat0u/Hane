import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hano/views/widgets/zeynep_logo.dart';
import 'package:hano/views/kasa_view.dart';
import 'package:hano/views/widgets/bank_logo.dart';
import 'package:hano/views/ayarlar_view.dart';
import 'package:hano/views/yardim_view.dart';
import 'package:hano/models/company_profile.dart';
import 'package:hano/models/account.dart';
import 'package:hano/services/database_helper.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  CompanyProfile? _companyProfile;
  List<Account> _accounts = [];
  bool _isLoading = true;

  bool _isKasaExpanded = false;
  bool _isIbanExpanded = false;
  bool _isKrediKartiExpanded = false;
  bool _isAdresExpanded = false;
  bool _isIletisimExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await DatabaseHelper.instance.getCompanyProfile();
    final db = await DatabaseHelper.instance.database;
    final accountMaps = await db.query('accounts');
    final accounts = accountMaps.map((m) => Account.fromMap(m)).toList();
    
    if (mounted) {
      setState(() {
        _companyProfile = profile;
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label başarıyla kopyalandı!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF032B5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Company Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Logo Symbol Frame
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(6.0),
                    child: const CustomPaint(
                      painter: LogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _companyProfile?.companyName ?? 'Şirket Adı',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF032B5E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetaRow('Vergi Dairesi', _companyProfile?.taxOffice ?? ''),
                        _buildMetaRow('Vergi No', _companyProfile?.taxNumber ?? ''),
                        _buildMetaRow('Ticari Sicil No', _companyProfile?.commercialRegistry ?? ''),
                        _buildMetaRow('Mersis No', _companyProfile?.mersisNo ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildOptionItem(
              icon: Icons.analytics_outlined,
              title: 'Kasa Özeti',
              isExpanded: _isKasaExpanded,
              onTap: () {
                setState(() {
                  _isKasaExpanded = !_isKasaExpanded;
                });
              },
              expandedContent: _buildKasaDetails(),
            ),


            // List Options
            _buildOptionItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Banka Iban',
              isExpanded: _isIbanExpanded,
              onTap: () {
                setState(() {
                  _isIbanExpanded = !_isIbanExpanded;
                });
              },
              expandedContent: _buildIbanDetails(),
            ),
            _buildOptionItem(
              icon: Icons.credit_card_outlined,
              title: 'Kredi Kartı',
              isExpanded: _isKrediKartiExpanded,
              onTap: () {
                setState(() {
                  _isKrediKartiExpanded = !_isKrediKartiExpanded;
                });
              },
              expandedContent: _buildKrediKartiDetails(),
            ),
            _buildOptionItem(
              icon: Icons.assignment_ind_outlined,
              title: 'Adres ve Kimlik',
              isExpanded: _isAdresExpanded,
              onTap: () {
                setState(() {
                  _isAdresExpanded = !_isAdresExpanded;
                });
              },
              expandedContent: _buildAdresDetails(),
            ),
            _buildOptionItem(
              icon: Icons.contact_phone_outlined,
              title: 'İletişim bilgileri',
              isExpanded: _isIletisimExpanded,
              onTap: () {
                setState(() {
                  _isIletisimExpanded = !_isIletisimExpanded;
                });
              },
              expandedContent: _buildIletisimDetails(),
            ),

              _buildSimpleOptionItem(
                icon: Icons.settings_outlined,
                title: 'Ayarlar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AyarlarView()),
                  );
                },
              ),
              _buildSimpleOptionItem(
                icon: Icons.help_outline_rounded,
                title: 'Yardım & Destek',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const YardimDestekView()),
                  );
                },
              ),
            _buildSimpleOptionItem(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              isDanger: true,
              onTap: () {
                _showLogoutDialog();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isExpanded
              ? [
                  const BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    Icon(icon, color: const Color(0xFF1E293B), size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: expandedContent,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final Color color = isDanger ? Colors.red : const Color(0xFF1E293B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDanger ? Colors.red.withAlpha(128) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Kasa Details Builders ---
  Widget _buildKasaCard(String title, String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKasaFlowItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildKasaDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF032B5E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'KASA ÖZETİ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                _buildKasaCard('TOPLAM KASA', '₺8.450.000'),
                const SizedBox(width: 12),
                _buildKasaCard('BANKALAR', '₺6.950.000'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKasaCard('NAKİT', '₺500.000'),
                const SizedBox(width: 12),
                _buildKasaCard('BORSA', '₺1.000.000'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildKasaFlowItem('alacak (bu ay)', '₺12.700.000', const Color(0xFF10B981)),
                  _buildKasaFlowItem('ödenen (bu ay)', '₺9.250.000', const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Banka Iban Builders ---
  Widget _buildIbanDetails() {
    final bankAccounts = _accounts.where((a) => a.type == 'Banka').toList();
    if (bankAccounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Kayıtlı banka hesabı bulunamadı.', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF032B5E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'BANKA IBAN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: bankAccounts.asMap().entries.map((entry) {
              int idx = entry.key;
              var acc = entry.value;
              return Column(
                children: [
                  _buildIbanRow(acc.name, acc.accountDetails),
                  if (idx < bankAccounts.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIbanRow(String bankName, String iban) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4.0),
            child: BankLogoWidget(bankName: bankName, width: 85, height: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  iban,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF94A3B8), size: 18),
            onPressed: () => _copyToClipboard(context, '$bankName IBAN numarası', iban),
            tooltip: 'Kopyala',
          ),
        ],
      ),
    );
  }

  // --- Kredi Kartı Builders ---
  Widget _buildKrediKartiDetails() {
    final cardAccounts = _accounts.where((a) => a.type == 'Kredi Kartı').toList();
    if (cardAccounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Kayıtlı kredi kartı bulunamadı.', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF032B5E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'KREDİ KARTI NO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: cardAccounts.asMap().entries.map((entry) {
              int idx = entry.key;
              var acc = entry.value;
              return Column(
                children: [
                  _buildIbanRow(acc.name, acc.accountDetails),
                  if (idx < cardAccounts.length - 1)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Adres Details Builders ---
  Widget _buildAdresDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF032B5E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'ADRES KİMLİK BİLGİLERİ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                _companyProfile?.addressTitle ?? 'Adres',
                '${_companyProfile?.addressLine1 ?? ''} ${_companyProfile?.addressLine2 ?? ''} ${_companyProfile?.city ?? ''} / ${_companyProfile?.country ?? ''}',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.credit_card_outlined,
                'TC Kimlik No',
                '12345678901', // Since we don't have TC Kimlik No in the DB schema, leave as is or remove
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.business_outlined,
                'Vergi No',
                _companyProfile?.taxNumber ?? '',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.article_outlined,
                'Ticari Sicil No',
                _companyProfile?.commercialRegistry ?? '',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.assignment_outlined,
                'Mersis No',
                _companyProfile?.mersisNo ?? '',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- İletişim Details Builders ---
  Widget _buildIletisimDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF032B5E),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'İLETİŞİM BİLGİLERİ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.phone_outlined,
                'Telefon',
                _companyProfile?.phone1 ?? '',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.mail_outline_rounded,
                'E-posta',
                _companyProfile?.email ?? '',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildInfoRow(
                Icons.language_rounded,
                'Web Sitesi',
                'www.hano.com', // No website in DB schema, hardcoded example
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF94A3B8), size: 16),
          onPressed: () => _copyToClipboard(context, label, value),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Kopyala',
        ),
      ],
    );
  }

  // --- Actions and Dialogs ---
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF032B5E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF032B5E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Çıkış yapıldı!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
