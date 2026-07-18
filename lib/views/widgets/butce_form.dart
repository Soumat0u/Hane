import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/app_form.dart';

/// Proje bütçe kalemi ekleme/düzenleme modalı.
Future<void> showButceForm(BuildContext context, Project project, {BudgetLine? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ButceForm(project: project, existing: existing),
  );
}

class _ButceForm extends StatefulWidget {
  final Project project;
  final BudgetLine? existing;
  const _ButceForm({required this.project, this.existing});

  @override
  State<_ButceForm> createState() => _ButceFormState();
}

class _ButceFormState extends State<_ButceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.existing?.category ?? '');
    _amountCtrl = TextEditingController(
        text: widget.existing != null ? widget.existing!.budgetedAmount.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fp = context.read<FinanceProvider>();
    final line = BudgetLine(
      id: widget.existing?.id,
      projectId: widget.project.id,
      category: _categoryCtrl.text.trim(),
      budgetedAmount: _num(_amountCtrl),
    );
    try {
      if (widget.existing != null) {
        await fp.updateBudgetLine(line);
      } else {
        await fp.addBudgetLine(line);
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final fp = context.watch<FinanceProvider>();
    // Gider ana kategorileri öneri olarak.
    final suggestions = fp.expenseCategories.map((c) => c.name).toSet().toList()..sort();

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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.existing != null ? 'Bütçe Kalemini Düzenle' : 'Bütçe Kalemi Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              const SizedBox(height: 20),
              // Kategori — serbest metin + öneri çipleri
              AppTextField(
                  controller: _categoryCtrl, label: 'Kategori', hint: 'Örn. Beton, Demir, İşçilik', required: true),
              if (suggestions.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions.take(12).map((s) {
                    return ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: context.colors.surface,
                      side: BorderSide(color: context.colors.border),
                      onPressed: () => setState(() => _categoryCtrl.text = s),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              AppTextField(controller: _amountCtrl, label: 'Planlanan Bütçe', currency: true, required: true),
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
