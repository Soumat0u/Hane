import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:hane/views/widgets/zeynep_logo.dart';
import 'package:hane/views/kasa_view.dart';
import 'package:hane/views/widgets/bank_logo.dart';
import 'package:hane/views/ayarlar_view.dart';
import 'package:hane/views/yardim_view.dart';
import 'package:hane/models/company_profile.dart';
import 'package:hane/models/account.dart';
import 'package:hane/services/api_service.dart';
import 'package:hane/views/auth/login_view.dart';
import 'package:hane/views/yeni_hesap_view.dart';

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
    final profile = await ApiService.instance.getCompanyProfile();
    final accounts = await ApiService.instance.readAllAccounts();
    
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
            Icon(Icons.check_circle_rounded, color: context.colors.surface, size: 20),
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
        backgroundColor: context.colors.brand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          title: Text('Profil', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: context.colors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: context.colors.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Company Info Card
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
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
                      color: context.colors.scaffold,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.border),
                    ),
                    padding: EdgeInsets.all(6.0),
                    child: CustomPaint(
                      painter: LogoPainter(brandColor: context.colors.brand),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.brand,
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


            // List Options
            _buildOptionItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Banka Hesapları',
              isExpanded: _isIbanExpanded,
              onTap: () {
                setState(() {
                  _isIbanExpanded = !_isIbanExpanded;
                });
              },
              actionWidget: Material(
                color: context.colors.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const YeniHesapView(initialType: 'Banka'))).then((_) => _loadData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: context.colors.brand, size: 14),
                        const SizedBox(width: 4),
                        Text('Ekle', style: TextStyle(color: context.colors.brand, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              expandedContent: _buildIbanDetails(),
            ),
            _buildOptionItem(
              icon: Icons.credit_card_outlined,
              title: 'Kredi Kartları',
              isExpanded: _isKrediKartiExpanded,
              onTap: () {
                setState(() {
                  _isKrediKartiExpanded = !_isKrediKartiExpanded;
                });
              },
              actionWidget: Material(
                color: context.colors.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const YeniHesapView(initialType: 'Kredi Kartı'))).then((_) => _loadData());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: context.colors.brand, size: 14),
                        const SizedBox(width: 4),
                        Text('Ekle', style: TextStyle(color: context.colors.brand, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
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
            const SizedBox(height: 12),
            _buildSimpleOptionItem(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              onTap: _showLogoutDialog,
              isDanger: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
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
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textPrimary,
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
    Widget? actionWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
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
                    Icon(icon, color: context.colors.textPrimary, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    if (actionWidget != null) ...[
                      actionWidget,
                      const SizedBox(width: 12),
                    ],
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: context.colors.textSecondary,
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
    final Color color = isDanger ? Colors.red : context.colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
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
                  color: isDanger ? Colors.red.withAlpha(128) : context.colors.textSecondary,
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
          color: context.colors.scaffold,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
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
            SizedBox(height: 16),
            Divider(height: 1, color: context.colors.border),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bankAccounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Kayıtlı banka hesabı bulunamadı.', style: TextStyle(color: Colors.grey)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border),
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
                      Divider(height: 1, color: context.colors.surfaceVariant),
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
              color: context.colors.scaffold,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  iban,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_copy_rounded, color: context.colors.textSecondary, size: 18),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cardAccounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Kayıtlı kredi kartı bulunamadı.', style: TextStyle(color: Colors.grey)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border),
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
                      Divider(height: 1, color: context.colors.surfaceVariant),
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
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.border),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                _companyProfile?.addressTitle ?? 'Adres',
                '${_companyProfile?.addressLine1 ?? ''} ${_companyProfile?.addressLine2 ?? ''} ${_companyProfile?.city ?? ''} / ${_companyProfile?.country ?? ''}',
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
              _buildInfoRow(
                Icons.credit_card_outlined,
                'TC Kimlik No',
                '12345678901', // Since we don't have TC Kimlik No in the DB schema, leave as is or remove
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
              _buildInfoRow(
                Icons.business_outlined,
                'Vergi No',
                _companyProfile?.taxNumber ?? '',
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
              _buildInfoRow(
                Icons.article_outlined,
                'Ticari Sicil No',
                _companyProfile?.commercialRegistry ?? '',
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
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
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.border),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.phone_outlined,
                'Telefon',
                _companyProfile?.phone1 ?? '',
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
              _buildInfoRow(
                Icons.mail_outline_rounded,
                'E-posta',
                _companyProfile?.email ?? '',
              ),
              Divider(height: 20, color: context.colors.surfaceVariant),
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
        Icon(icon, color: context.colors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.content_copy_rounded, color: context.colors.textSecondary, size: 16),
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
          style: TextStyle(color: context.colors.brand,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold)),
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
            child: Text('İptal', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.instance.logout();
              } catch (e) {
                // Hata olsa da çıkış ekranına atalım
              }
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
