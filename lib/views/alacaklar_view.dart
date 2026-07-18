import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/utils/thousands_formatter.dart';
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
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, _) {
            final receivables = fp.receivables.where((r) => r.remaining > 0).toList();
            final total = fp.getTotalAlacak();

            return RefreshIndicator(
              onRefresh: fp.refreshSilently,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: centeredPagePadding(context, maxContentWidth: 760, top: 8.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopCard(context, total),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'AÇIK ALACAKLAR', onNewTap: () => _showAddReceivable(context)),
                    _buildGroupList(context, fp, receivables),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required VoidCallback onNewTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          InkWell(
            onTap: onNewTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: context.colors.brand),
                  const SizedBox(width: 4),
                  Text(
                    'Yeni Alacak',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.brand),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, FinanceProvider fp, List<Receivable> receivables) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: receivables.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Açık alacak yok.')),
            )
          : Column(
              children: [
                ...receivables.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return Column(
                    children: [
                      _buildListItem(context: context, fp: fp, r: r, isFirst: idx == 0, isLast: idx == receivables.length - 1),
                      if (idx < receivables.length - 1) Divider(height: 1, indent: 64, color: context.colors.surfaceVariant),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required FinanceProvider fp,
    required Receivable r,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final df = DateFormat('d MMM yyyy', 'tr_TR');
    final due = DateTime.tryParse(r.dueDate);
    final overdue = due != null && due.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.scaffold,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.assignment_returned_rounded, color: context.colors.success, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.description.isNotEmpty ? r.description : (_kindLabels[r.kind] ?? 'Alacak'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                ),
                if (r.dueDate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    due != null ? df.format(due) : r.dueDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: overdue ? context.colors.danger : context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(r.remaining),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showCollectDialog(context, fp, r),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Tahsil Et',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, double total) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.success,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.success.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOPLAM ALACAK',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.assignment_returned_rounded, color: Colors.white.withAlpha(160), size: 48),
          ),
        ],
      ),
    );
  }

  // --- Tahsilat diyaloğu ---
  void _showCollectDialog(BuildContext context, FinanceProvider fp, Receivable r) {
    final amountCtrl = TextEditingController(text: formatAmountForDisplay(r.remaining));
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
                inputFormatters: [ThousandsSeparatorInputFormatter()],
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
              AppTextField(controller: _totalCtrl, label: 'Toplam Tutar', currency: true, required: true),
              if (projectOptions.length > 1)
                AppDropdown<int?>(
                    label: 'Proje', value: _projectId, options: projectOptions, onChanged: (v) => setState(() => _projectId = v)),
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
