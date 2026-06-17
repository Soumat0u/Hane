import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Alacaklar ekranı — satış taksitleri, müşteri/devlet alacakları, hakedişler.
/// Her alacak için tahsilat yapılabilir (kalan düşer, ilgili hesaba para girer).
class AlacaklarView extends StatelessWidget {
  const AlacaklarView({super.key});

  static const _kindLabels = {
    'installment': 'Satış Taksiti',
    'customer': 'Müşteri Alacağı',
    'government': 'Devlet Alacağı',
    'retention': 'Hakediş',
    'other': 'Diğer',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        title: Text('Alacaklar',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReceivable(context),
        backgroundColor: context.colors.success,
        icon: Icon(Icons.add, color: context.colors.surface),
        label: Text('Yeni Alacak', style: TextStyle(color: context.colors.surface)),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, _) {
          final receivables = fp.receivables.where((r) => r.remaining > 0).toList();
          final total = fp.getTotalAlacak();

          return RefreshIndicator(
            onRefresh: fp.refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(20),
              children: [
                _buildTopCard(context, total),
                const SizedBox(height: 24),
                if (receivables.isEmpty)
                  _buildEmptyState(context)
                else
                  ...receivables.map((r) => _buildReceivableCard(context, fp, r)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, double total) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.success, Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOPLAM ALACAK',
                  style: TextStyle(color: context.colors.surface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(currencyFormat.format(total),
                  style: TextStyle(color: context.colors.surface, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.colors.surface.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.assignment_returned_rounded, color: context.colors.surface, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(BuildContext context, FinanceProvider fp, Receivable r) {
    final df = DateFormat('d MMM yyyy', 'tr_TR');
    final due = DateTime.tryParse(r.dueDate);
    final overdue = due != null && due.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final ratio = r.totalAmount > 0 ? (r.collectedAmount / r.totalAmount).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.description.isNotEmpty ? r.description : (_kindLabels[r.kind] ?? 'Alacak'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_kindLabels[r.kind] ?? r.kind,
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFormat.format(r.remaining),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
                  Text('kalan', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: context.colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.success),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (r.dueDate.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: overdue ? context.colors.danger : context.colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      due != null ? df.format(due) : r.dueDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: overdue ? context.colors.danger : context.colors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              TextButton.icon(
                onPressed: () => _showCollectDialog(context, fp, r),
                icon: Icon(Icons.payments_outlined, size: 16, color: context.colors.success),
                label: Text('Tahsil Et', style: TextStyle(color: context.colors.success, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: context.colors.surfaceVariant, shape: BoxShape.circle),
            child: Icon(Icons.assignment_returned_outlined, size: 48, color: context.colors.success),
          ),
          const SizedBox(height: 16),
          Text('Açık alacak yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Yeni alacak eklemek için sağ alttaki butonu kullanın.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // --- Tahsilat diyaloğu ---
  void _showCollectDialog(BuildContext context, FinanceProvider fp, Receivable r) {
    final amountCtrl = TextEditingController(text: r.remaining.toStringAsFixed(0));
    final accounts = fp.accounts.where((a) => a.type == 'Banka' || a.type == 'Nakit').toList();
    int? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tahsilat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kalan: ${currencyFormat.format(r.remaining)}',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: appInputDecoration(context, 'Tahsil edilen tutar'),
              ),
              const SizedBox(height: 12),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: selectedAccountId,
                  decoration: appInputDecoration(context),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} hesabına')))
                      .toList(),
                  onChanged: (v) => setLocal(() => selectedAccountId = v),
                )
              else
                Text('Önce bir Banka/Nakit hesabı ekleyin.',
                    style: TextStyle(color: context.colors.danger, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                      if (amount <= 0) return;
                      setLocal(() => saving = true);
                      try {
                        await fp.collectReceivable(
                          receivable: r,
                          amount: amount,
                          toAccountId: selectedAccountId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.success, foregroundColor: context.colors.surface),
              child: saving
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                  : const Text('Tahsil Et'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Yeni alacak ekleme modalı ---
  void _showAddReceivable(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReceivableForm(),
    );
  }
}

class _AddReceivableForm extends StatefulWidget {
  const _AddReceivableForm();

  @override
  State<_AddReceivableForm> createState() => _AddReceivableFormState();
}

class _AddReceivableFormState extends State<_AddReceivableForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  String _kind = 'customer';
  String _currency = 'TRY';
  DateTime? _dueDate;
  int? _projectId;
  bool _saving = false;

  static const _kinds = {
    'installment': 'Satış Taksiti',
    'customer': 'Müşteri Alacağı',
    'government': 'Devlet Alacağı',
    'retention': 'Hakediş',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _descCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final total = double.tryParse(_totalCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final r = Receivable(
      kind: _kind,
      status: 'pending',
      projectId: _projectId,
      totalAmount: total,
      collectedAmount: 0,
      currency: _currency,
      dueDate: _dueDate?.toIso8601String().split('T').first ?? '',
      description: _descCtrl.text.trim(),
    );
    try {
      await context.read<FinanceProvider>().addReceivable(r);
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final projects = context.watch<FinanceProvider>().projects;
    final projectOptions = <int?, String>{null: 'Genel (proje yok)'};
    for (final p in projects) {
      if (p.id != null) projectOptions[p.id] = p.name;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Yeni Alacak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              const SizedBox(height: 20),
              AppDropdown<String>(label: 'Tür', value: _kind, options: _kinds, onChanged: (v) => setState(() => _kind = v!)),
              AppTextField(controller: _descCtrl, label: 'Açıklama', hint: 'Örn. A Blok 3. taksit', required: true),
              AppTextField(controller: _totalCtrl, label: 'Toplam Tutar', number: true, required: true),
              if (projectOptions.length > 1)
                AppDropdown<int?>(
                    label: 'Proje', value: _projectId, options: projectOptions, onChanged: (v) => setState(() => _projectId = v)),
              AppDropdown<String>(
                  label: 'Para Birimi', value: _currency, options: kCurrencyOptions, onChanged: (v) => setState(() => _currency = v!)),
              AppDateField(label: 'Vade Tarihi', value: _dueDate, onChanged: (d) => setState(() => _dueDate = d)),
              const SizedBox(height: 8),
              AppSaveButton(saving: _saving, onPressed: _save),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
