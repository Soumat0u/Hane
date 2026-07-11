import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/recurring_transaction.dart';
import 'package:hane/views/widgets/app_form.dart';

const Map<String, String> kRecurringTypeLabels = {
  'Gider': 'Gider',
  'Gelir': 'Gelir',
  'Tahsilat': 'Tahsilat',
};

const Map<String, String> kRecurringIntervalLabels = {
  RecurringTransaction.monthly: 'Aylık',
  RecurringTransaction.weekly: 'Haftalık',
};

/// Tekrarlayan işlem oluşturma/düzenleme formunu açar. Takvim ve bildirimler
/// gibi başka ekranlardan da bir şablonun detayına/düzenlemesine ulaşmak için kullanılır.
void showRecurringTransactionForm(BuildContext context, {RecurringTransaction? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecurringForm(existing: existing),
  );
}

Future<bool> _confirmDeleteRecurringTransaction(
    BuildContext context, FinanceProvider fp, RecurringTransaction r) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Şablonu Sil'),
      content: Text('"${r.description.isNotEmpty ? r.description : r.category}" şablonunu silmek istediğinize emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
      ],
    ),
  );
  if (confirmed == true && r.id != null) {
    await fp.deleteRecurringTransaction(r.id!);
    return true;
  }
  return false;
}

/// Tekrarlayan işlem şablonlarını listeler ve yönetir (oluştur/düzenle/sil).
/// Şablonlar otomatik işlem oluşturmaz — vadesi geldiğinde Bildirimler
/// ekranında kullanıcı onayına sunulur.
class TekrarlananIslemlerView extends StatelessWidget {
  const TekrarlananIslemlerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Tekrarlayan İşlemler',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: context.colors.brand),
            onPressed: () => showRecurringTransactionForm(context),
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          final templates = fp.recurringTransactions;
          return RefreshIndicator(
            onRefresh: fp.refreshSilently,
            child: templates.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Henüz tekrarlayan işlem şablonu yok.', style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => showRecurringTransactionForm(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Şablon Ekle'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: templates.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildCard(context, fp, templates[index]),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, FinanceProvider fp, RecurringTransaction r) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showRecurringTransactionForm(context, existing: r),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.description.isNotEmpty ? r.description : r.category,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${r.intervalLabel} • Sıradaki: ${r.nextDueDate}',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                ],
              ),
            ),
            Text(currencyFormat.format(r.amount),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.colors.textPrimary)),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.textSecondary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmDeleteRecurringTransaction(context, fp, r),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringForm extends StatefulWidget {
  final RecurringTransaction? existing;
  const _RecurringForm({this.existing});

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descriptionCtrl;
  String _type = 'Gider';
  String _interval = RecurringTransaction.monthly;
  int _dayOfMonth = 1;
  DateTime? _nextDueDate;
  int? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toStringAsFixed(0) : '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _type = e.type;
      _interval = e.interval;
      _dayOfMonth = e.dayOfMonth;
      _nextDueDate = DateTime.tryParse(e.nextDueDate);
      _accountId = e.type == 'Gider' ? e.fromAccountId : e.toAccountId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _nextDueDate == null) {
      if (_nextDueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıradaki vade tarihini seçin.')));
      }
      return;
    }
    setState(() => _saving = true);
    final fp = context.read<FinanceProvider>();
    final r = RecurringTransaction(
      id: widget.existing?.id,
      type: _type,
      amount: _num(_amountCtrl),
      category: _categoryCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      fromAccountId: _type == 'Gider' ? _accountId : null,
      toAccountId: _type != 'Gider' ? _accountId : null,
      interval: _interval,
      dayOfMonth: _dayOfMonth,
      nextDueDate: _nextDueDate!.toIso8601String().split('T').first,
    );
    try {
      if (widget.existing != null) {
        await fp.updateRecurringTransaction(r);
      } else {
        await fp.addRecurringTransaction(r);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final accountOptions = <int?, String>{null: 'Seçiniz (opsiyonel)'};
    for (final a in fp.accounts) {
      if (a.id != null) accountOptions[a.id] = a.name;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.existing != null ? 'Şablonu Düzenle' : 'Yeni Tekrarlayan İşlem',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                const SizedBox(height: 20),
                AppDropdown<String>(
                    label: 'Tür', value: _type, options: kRecurringTypeLabels, onChanged: (v) => setState(() => _type = v!)),
                AppTextField(controller: _descriptionCtrl, label: 'Açıklama', hint: 'Örn. Ofis kirası', required: true),
                AppTextField(controller: _categoryCtrl, label: 'Kategori', hint: 'Örn. Genel Gider'),
                AppTextField(controller: _amountCtrl, label: 'Tutar', number: true, required: true),
                AppDropdown<int?>(
                    label: _type == 'Gider' ? 'Ödeme Kaynağı' : 'Hedef Hesap',
                    value: _accountId,
                    options: accountOptions,
                    onChanged: (v) => setState(() => _accountId = v)),
                AppDropdown<String>(
                    label: 'Tekrar Sıklığı',
                    value: _interval,
                    options: kRecurringIntervalLabels,
                    onChanged: (v) => setState(() => _interval = v!)),
                if (_interval == RecurringTransaction.monthly)
                  AppDropdown<int>(
                    label: 'Ayın Günü',
                    value: _dayOfMonth,
                    options: {for (var d = 1; d <= 28; d++) d: '$d'},
                    onChanged: (v) => setState(() => _dayOfMonth = v!),
                  ),
                AppDateField(
                    label: 'Sıradaki Vade Tarihi', value: _nextDueDate, onChanged: (d) => setState(() => _nextDueDate = d)),
                const SizedBox(height: 8),
                AppSaveButton(saving: _saving, onPressed: _save),
                if (widget.existing != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final deleted = await _confirmDeleteRecurringTransaction(context, fp, widget.existing!);
                            if (deleted && mounted) Navigator.pop(context);
                          },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    label: const Text('Şablonu Sil', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
