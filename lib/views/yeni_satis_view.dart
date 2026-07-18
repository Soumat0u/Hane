import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Yeni satış sözleşmesi ekleme (daire/dükkan/arsa). Bir projeye bağlıdır.
/// Kaydedildiğinde, kalan tutar için otomatik bir alacak (Satış Taksiti) da oluşturulur.
class YeniSatisView extends StatefulWidget {
  final int projectId;
  final String projectName;
  const YeniSatisView({super.key, required this.projectId, required this.projectName});

  @override
  State<YeniSatisView> createState() => _YeniSatisViewState();
}

class _YeniSatisViewState extends State<YeniSatisView> {
  final _formKey = GlobalKey<FormState>();
  final _unitNoCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _unitType = 'apartment';
  DateTime? _saleDate;
  int? _buyerId;
  bool _createReceivable = true;
  bool _saving = false;

  static const _unitTypes = {'apartment': 'Daire', 'shop': 'Dükkan', 'land': 'Arsa', 'other': 'Diğer'};

  @override
  void dispose() {
    _unitNoCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final price = double.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final fp = context.read<FinanceProvider>();
    final sale = Sale(
      projectId: widget.projectId,
      buyerId: _buyerId,
      unitType: _unitType,
      unitNo: _unitNoCtrl.text.trim(),
      salePrice: price,
      saleDate: _saleDate?.toIso8601String().split('T').first ?? '',
    );
    try {
      await fp.addSale(sale);
      if (_createReceivable && price > 0) {
        await fp.addReceivable(Receivable(
          kind: 'installment',
          status: 'pending',
          projectId: widget.projectId,
          contactId: _buyerId,
          totalAmount: price,
          collectedAmount: 0,
          dueDate: _saleDate?.toIso8601String().split('T').first ?? '',
          description: '${_unitTypes[_unitType]} ${_unitNoCtrl.text.trim()} satış bedeli',
        ));
      }
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
    final contacts = context.watch<FinanceProvider>().contacts;
    final buyerOptions = <int?, String>{null: 'Seçiniz (opsiyonel)'};
    for (final c in contacts) {
      if (c.id != null) buyerOptions[c.id] = c.name;
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
                  Expanded(child: Text('Proje: ${widget.projectName}',
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
            SwitchListTile(
              value: _createReceivable,
              onChanged: (v) => setState(() => _createReceivable = v),
              activeThumbColor: context.colors.brand,
              contentPadding: EdgeInsets.zero,
              title: Text('Satış bedeli için alacak oluştur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
              subtitle: Text('Tahsilat takibi için önerilir', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            ),
            const SizedBox(height: 16),
            AppSaveButton(saving: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
