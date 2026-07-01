import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Yeni çek ekleme formu (alınan / verilen).
class YeniCekView extends StatefulWidget {
  const YeniCekView({super.key});

  @override
  State<YeniCekView> createState() => _YeniCekViewState();
}

class _YeniCekViewState extends State<YeniCekView> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();

  String _direction = 'received';
  String _status = 'portfolio';
  DateTime? _dueDate;
  int? _contactId;
  bool _saving = false;

  static const _directions = {'received': 'Alınan Çek', 'issued': 'Verilen Çek'};
  static const _statuses = {
    'portfolio': 'Portföyde',
    'deposited': 'Tahsile Verildi',
    'cashed': 'Tahsil Edildi',
    'given': 'Ciro/Ödendi',
    'bounced': 'Karşılıksız',
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cheque = Cheque(
      direction: _direction,
      status: _status,
      amount: _num(_amountCtrl),
      dueDate: _dueDate?.toIso8601String().split('T').first ?? '',
      bankName: _bankCtrl.text.trim(),
      serialNo: _serialCtrl.text.trim(),
      contactId: _contactId,
    );
    try {
      await context.read<FinanceProvider>().addCheque(cheque);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çek eklendi')));
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
    final contactOptions = <int?, String>{null: 'Seçiniz (opsiyonel)'};
    for (final c in contacts) {
      if (c.id != null) contactOptions[c.id] = c.name;
    }

    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        title: Text('Yeni Çek',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          children: [
            AppDropdown<String>(
                label: 'Çek Türü', value: _direction, options: _directions, onChanged: (v) => setState(() => _direction = v!)),
            AppTextField(controller: _amountCtrl, label: 'Tutar', number: true, required: true),
            AppTextField(controller: _bankCtrl, label: 'Banka', hint: 'Örn. Garanti BBVA'),
            AppTextField(controller: _serialCtrl, label: 'Seri No', hint: 'Opsiyonel'),
            AppDropdown<String>(
                label: 'Durum', value: _status, options: _statuses, onChanged: (v) => setState(() => _status = v!)),
            AppDateField(label: 'Vade Tarihi', value: _dueDate, onChanged: (d) => setState(() => _dueDate = d)),
            if (contactOptions.length > 1)
              AppDropdown<int?>(
                  label: 'Cari (Müşteri/Tedarikçi)',
                  value: _contactId,
                  options: contactOptions,
                  onChanged: (v) => setState(() => _contactId = v)),
            const SizedBox(height: 24),
            AppSaveButton(saving: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
