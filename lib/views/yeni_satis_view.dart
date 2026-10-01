import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Yeni satış sözleşmesi ekleme (daire/dükkan/arsa). Bir projeye bağlıdır.
/// Kaydedildiğinde, kalan tutar için otomatik bir alacak (Satış Taksiti) oluşturulur;
/// peşinat bir hesaba yatırıldıysa o hesaba Tahsilat olarak işlenir.
/// Proje detayından açıldığında proje sabittir; genel "+ Satış" girişinde seçilir.
class YeniSatisView extends StatefulWidget {
  final int? projectId;
  final String? projectName;
  const YeniSatisView({super.key, this.projectId, this.projectName});

  @override
  State<YeniSatisView> createState() => _YeniSatisViewState();
}

class _YeniSatisViewState extends State<YeniSatisView> {
  final _formKey = GlobalKey<FormState>();
  final _unitNoCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController();
  final _installmentCountCtrl = TextEditingController();
  String _unitType = 'apartment';
  DateTime? _saleDate;
  DateTime? _firstDueDate;
  int? _buyerId;
  int? _projectId;
  int? _downPaymentAccountId;
  bool _createReceivable = true;
  bool _saving = false;

  static const _unitTypes = {'apartment': 'Daire', 'shop': 'Dükkan', 'land': 'Arsa', 'other': 'Diğer'};

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId;
  }

  @override
  void dispose() {
    _unitNoCtrl.dispose();
    _priceCtrl.dispose();
    _downPaymentCtrl.dispose();
    _installmentCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen satışın yapıldığı projeyi seçin.')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final downPayment = double.tryParse(_downPaymentCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (downPayment > price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peşinat, satış fiyatından büyük olamaz.')));
      return;
    }
    setState(() => _saving = true);
    final installmentCount = int.tryParse(_installmentCountCtrl.text) ?? 0;
    final saleDateStr = _saleDate?.toIso8601String().split('T').first ?? '';
    final fp = context.read<FinanceProvider>();
    final sale = Sale(
      projectId: _projectId,
      buyerId: _buyerId,
      unitType: _unitType,
      unitNo: _unitNoCtrl.text.trim(),
      salePrice: price,
      saleDate: saleDateStr,
      downPayment: downPayment,
      installmentCount: installmentCount,
      firstDueDate: (_firstDueDate ?? _saleDate)?.toIso8601String().split('T').first ?? saleDateStr,
      createReceivable: _createReceivable,
      downPaymentAccountId: downPayment > 0 ? _downPaymentAccountId : null,
    );
    try {
      await fp.addSale(sale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Satış kaydedildi')));
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
    final fp = context.watch<FinanceProvider>();
    final buyerOptions = <int?, String>{null: 'Seçiniz (opsiyonel)'};
    for (final c in fp.contacts) {
      if (c.id != null) buyerOptions[c.id] = c.name;
    }
    final projectOptions = <int?, String>{null: 'Proje seçin'};
    for (final p in fp.projects) {
      if (p.id != null) projectOptions[p.id] = p.name;
    }
    final accountOptions = <int?, String>{null: 'Hesaba yatırılmadı'};
    for (final a in fp.accounts) {
      if (a.id != null) accountOptions[a.id] = a.name;
    }

    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        title: Text('Yeni Satış',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          children: [
            if (widget.projectId == null)
              AppDropdown<int?>(label: 'Proje', value: _projectId, options: projectOptions, onChanged: (v) => setState(() => _projectId = v))
            else
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.business_center_outlined, color: context.colors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Proje: ${widget.projectName ?? ''}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
                ],
              ),
            ),
            AppDropdown<String>(label: 'Birim Türü', value: _unitType, options: _unitTypes, onChanged: (v) => setState(() => _unitType = v!)),
            AppTextField(controller: _unitNoCtrl, label: 'Birim No', hint: 'Örn. A-12'),
            AppTextField(controller: _priceCtrl, label: 'Satış Fiyatı', currency: true, required: true),
            if (buyerOptions.length > 1)
              AppDropdown<int?>(label: 'Alıcı (Cari)', value: _buyerId, options: buyerOptions, onChanged: (v) => setState(() => _buyerId = v)),
            AppDateField(label: 'Satış Tarihi', value: _saleDate, onChanged: (d) => setState(() => _saleDate = d)),
            AppTextField(controller: _downPaymentCtrl, label: 'Peşinat (opsiyonel)', currency: true, hint: '0'),
            if (accountOptions.length > 1)
              AppDropdown<int?>(
                label: 'Peşinatın yatırıldığı hesap',
                value: _downPaymentAccountId,
                options: accountOptions,
                onChanged: (v) => setState(() => _downPaymentAccountId = v),
              ),
            SwitchListTile(
              value: _createReceivable,
              onChanged: (v) => setState(() => _createReceivable = v),
              activeThumbColor: context.colors.brand,
              contentPadding: EdgeInsets.zero,
              title: Text('Satış bedeli için alacak oluştur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
              subtitle: Text('Tahsilat takibi için önerilir', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            ),
            if (_createReceivable) ...[
              const SizedBox(height: 4),
              AppTextField(
                controller: _installmentCountCtrl,
                label: 'Taksit Sayısı (opsiyonel)',
                number: true,
                hint: 'Boş bırakılırsa tek kalemde alacak oluşur',
              ),
              AppDateField(
                label: 'İlk Taksit Vadesi (opsiyonel)',
                value: _firstDueDate,
                onChanged: (d) => setState(() => _firstDueDate = d),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sonraki taksitler ilk vadeden başlayarak birer ay arayla otomatik planlanır.',
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppSaveButton(saving: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
