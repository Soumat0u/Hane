import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';

/// Yeni kredi / KGF ekleme formu.
class YeniKrediView extends StatefulWidget {
  const YeniKrediView({super.key});

  @override
  State<YeniKrediView> createState() => _YeniKrediViewState();
}

class _YeniKrediViewState extends State<YeniKrediView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();

  String _kind = 'loan';
  DateTime? _startDate;
  bool _saving = false;

  static const _kinds = {'loan': 'Kredi', 'kgf': 'KGF', 'other': 'Diğer'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _principalCtrl.dispose();
    _totalCtrl.dispose();
    _paidCtrl.dispose();
    _rateCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final loan = Loan(
      name: _nameCtrl.text.trim(),
      kind: _kind,
      bankName: _bankCtrl.text.trim(),
      principal: _num(_principalCtrl),
      totalPayable: _num(_totalCtrl),
      paidAmount: _num(_paidCtrl),
      interestRate: _num(_rateCtrl),
      termMonths: int.tryParse(_termCtrl.text) ?? 0,
      startDate: _startDate?.toIso8601String().split('T').first ?? '',
    );
    try {
      await context.read<FinanceProvider>().addLoan(loan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kredi eklendi')));
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
        title: Text('Yeni Kredi',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: centeredPagePadding(context, maxContentWidth: 560, horizontal: 20, top: 20, bottom: 20),
          children: [
            _field(_nameCtrl, 'Kredi Adı', hint: 'Örn. Ziraat Konut Kredisi', required: true),
            _dropdown('Tür', _kind, _kinds, (v) => setState(() => _kind = v!)),
            _field(_bankCtrl, 'Banka', hint: 'Örn. Ziraat Bankası'),
            _field(_principalCtrl, 'Ana Para', keyboard: true, required: true),
            _field(_totalCtrl, 'Toplam Geri Ödeme (faiz dahil)', keyboard: true),
            _field(_paidCtrl, 'Şu ana kadar ödenen', keyboard: true),
            Row(
              children: [
                Expanded(child: _field(_rateCtrl, 'Faiz %', keyboard: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_termCtrl, 'Vade (ay)', keyboard: true)),
              ],
            ),
            _dateTile(),
            const SizedBox(height: 24),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, bool keyboard = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            keyboardType: keyboard ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null : null,
            decoration: _dec(hint),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.brand)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _dropdown(String label, String value, Map<String, String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: _dec(null),
            items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Başlangıç Tarihi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2015),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: context.colors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _startDate == null
                        ? 'Seçiniz'
                        : '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}',
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.brand,
          foregroundColor: context.colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
            : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
