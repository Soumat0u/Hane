import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/company_profile.dart';
import 'package:hane/views/widgets/app_form.dart';
import 'package:hane/constants/tr_locations.dart';
import 'package:hane/services/notification_service.dart';

/// Firma profili düzenleme formu. Profil ekranından "Düzenle" ile veya
/// ilk kurulumda (onboarding) kullanılır.
class FirmaDuzenleView extends StatefulWidget {
  final bool isOnboarding;
  /// Yalnızca [isOnboarding] true iken kullanılır: kullanıcı formu doldurmadan
  /// atlamak isterse çağrılır (bilgiler sonradan Profil sayfasından girilebilir).
  final VoidCallback? onSkip;
  const FirmaDuzenleView({super.key, this.isOnboarding = false, this.onSkip});

  @override
  State<FirmaDuzenleView> createState() => _FirmaDuzenleViewState();
}

class _FirmaDuzenleViewState extends State<FirmaDuzenleView> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late List<String> _cityOptions;
  late List<String> _countryOptions;
  late String _city;
  late String _country;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<FinanceProvider>().companyProfile;
    _c = {
      'name': TextEditingController(text: p?.companyName ?? ''),
      'taxOffice': TextEditingController(text: p?.taxOffice ?? ''),
      'taxNumber': TextEditingController(text: p?.taxNumber ?? ''),
      'registry': TextEditingController(text: p?.commercialRegistry ?? ''),
      'mersis': TextEditingController(text: p?.mersisNo ?? ''),
      'addressTitle': TextEditingController(text: p?.addressTitle ?? ''),
      'addressLine1': TextEditingController(text: p?.addressLine1 ?? ''),
      'phone1': TextEditingController(text: p?.phone1 ?? ''),
      'email': TextEditingController(text: p?.email ?? ''),
      'website': TextEditingController(text: p?.website ?? ''),
    };
    final rawCity = p?.city ?? '';
    _cityOptions = [...kTurkishCities];
    _city = rawCity.isEmpty ? kTurkishCities.first : rawCity;
    if (!_cityOptions.contains(_city)) _cityOptions.insert(0, _city);

    _countryOptions = ['Türkiye'];
    _country = 'Türkiye';
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String k) => _c[k]!.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = context.read<FinanceProvider>().companyProfile;
    final profile = CompanyProfile(
      id: existing?.id,
      companyName: _v('name'),
      taxOffice: _v('taxOffice'),
      taxNumber: _v('taxNumber'),
      commercialRegistry: _v('registry'),
      mersisNo: _v('mersis'),
      addressTitle: _v('addressTitle'),
      addressLine1: _v('addressLine1'),
      addressLine2: existing?.addressLine2 ?? '',
      city: _city,
      country: _country,
      phone1: _v('phone1'),
      phone2: existing?.phone2 ?? '',
      email: _v('email'),
      website: _v('website'),
      readNotifications: existing?.readNotifications ?? '',
    );
    try {
      await context.read<FinanceProvider>().updateCompanyProfile(profile);
      if (!mounted) return;
      if (widget.isOnboarding) {
        // Onboarding kapısı (OnboardingGate) profil dolunca otomatik ana ekrana geçer.
        // Gerekli izinler (bildirim vb.) burada, onboarding'in sonunda istenir.
        NotificationService.instance.requestPermission();
        setState(() => _saving = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firma bilgileri güncellendi')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        automaticallyImplyLeading: !widget.isOnboarding,
        title: Text(widget.isOnboarding ? 'Firma Bilgileri' : 'Firmayı Düzenle',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (widget.isOnboarding && widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: Text('Atla', style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          children: [
            if (widget.isOnboarding) ...[
              Text('Hoş geldiniz!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.brand)),
              const SizedBox(height: 6),
              Text('Başlamadan önce firma bilgilerinizi girin. Bu bilgiler uygulama genelinde kullanılır.',
                  style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
              const SizedBox(height: 24),
            ],
            _sectionCard(
              context,
              icon: Icons.apartment_rounded,
              title: 'Firma',
              children: [
                AppTextField(controller: _c['name']!, label: 'Firma Adı', hint: 'Örn. Yılmaz İnşaat A.Ş.', required: true),
                AppTextField(controller: _c['taxOffice']!, label: 'Vergi Dairesi'),
                AppTextField(controller: _c['taxNumber']!, label: 'Vergi No', number: true),
                AppTextField(controller: _c['registry']!, label: 'Ticari Sicil No', number: true),
                AppTextField(controller: _c['mersis']!, label: 'Mersis No', number: true),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              icon: Icons.location_on_rounded,
              title: 'Adres',
              children: [
                AppTextField(controller: _c['addressTitle']!, label: 'Adres Başlığı', hint: 'Merkez Ofis'),
                AppTextField(controller: _c['addressLine1']!, label: 'Adres'),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Şehir',
                        value: _city,
                        options: {for (final c in _cityOptions) c: c},
                        onChanged: (v) => setState(() => _city = v ?? _city),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Ülke',
                        value: _country,
                        options: {for (final c in _countryOptions) c: c},
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              icon: Icons.contact_phone_rounded,
              title: 'İletişim',
              children: [
                AppTextField(controller: _c['phone1']!, label: 'Telefon'),
                AppTextField(controller: _c['email']!, label: 'E-posta'),
                AppTextField(controller: _c['website']!, label: 'Web Sitesi'),
              ],
            ),
            const SizedBox(height: 16),
            AppSaveButton(saving: _saving, onPressed: _save, label: widget.isOnboarding ? 'Devam Et' : 'Kaydet'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.brand),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
