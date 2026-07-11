import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/company_profile.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Firma profili düzenleme formu. Profil ekranından "Düzenle" ile veya
/// ilk kurulumda (onboarding) kullanılır.
class FirmaDuzenleView extends StatefulWidget {
  final bool isOnboarding;
  const FirmaDuzenleView({super.key, this.isOnboarding = false});

  @override
  State<FirmaDuzenleView> createState() => _FirmaDuzenleViewState();
}

class _FirmaDuzenleViewState extends State<FirmaDuzenleView> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
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
      'city': TextEditingController(text: p?.city ?? ''),
      'country': TextEditingController(text: p?.country ?? 'Türkiye'),
      'phone1': TextEditingController(text: p?.phone1 ?? ''),
      'email': TextEditingController(text: p?.email ?? ''),
      'website': TextEditingController(text: p?.website ?? ''),
    };
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
      city: _v('city'),
      country: _v('country'),
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          children: [
            if (widget.isOnboarding) ...[
              Text('Hoş geldiniz! 👷',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.brand)),
              const SizedBox(height: 6),
              Text('Başlamadan önce firma bilgilerinizi girin. Bu bilgiler uygulama genelinde kullanılır.',
                  style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
              const SizedBox(height: 24),
            ],
            _section('Firma'),
            AppTextField(controller: _c['name']!, label: 'Firma Adı', hint: 'Örn. Yılmaz İnşaat A.Ş.', required: true),
            AppTextField(controller: _c['taxOffice']!, label: 'Vergi Dairesi'),
            AppTextField(controller: _c['taxNumber']!, label: 'Vergi No', number: true),
            AppTextField(controller: _c['registry']!, label: 'Ticari Sicil No'),
            AppTextField(controller: _c['mersis']!, label: 'Mersis No'),
            const SizedBox(height: 8),
            _section('Adres'),
            AppTextField(controller: _c['addressTitle']!, label: 'Adres Başlığı', hint: 'Merkez Ofis'),
            AppTextField(controller: _c['addressLine1']!, label: 'Adres'),
            Row(
              children: [
                Expanded(child: AppTextField(controller: _c['city']!, label: 'Şehir')),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(controller: _c['country']!, label: 'Ülke')),
              ],
            ),
            const SizedBox(height: 8),
            _section('İletişim'),
            AppTextField(controller: _c['phone1']!, label: 'Telefon'),
            AppTextField(controller: _c['email']!, label: 'E-posta'),
            AppTextField(controller: _c['website']!, label: 'Web Sitesi'),
            const SizedBox(height: 16),
            AppSaveButton(saving: _saving, onPressed: _save, label: widget.isOnboarding ? 'Devam Et' : 'Kaydet'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: EdgeInsets.only(bottom: 12, top: 4),
        child: Text(t.toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
      );
}
