import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/views/hareketler_view.dart' show transactionVisuals;

const _incomeTypes = {'Gelir', 'Tahsilat', 'Satış'};

class HareketDetayView extends StatefulWidget {
  final FinancialTransaction transaction;

  const HareketDetayView({super.key, required this.transaction});

  @override
  State<HareketDetayView> createState() => _HareketDetayViewState();
}

class _HareketDetayViewState extends State<HareketDetayView> {
  final DateFormat _dateFmt = DateFormat('d MMM yyyy', 'tr_TR');
  final DateFormat _shortFmt = DateFormat('dd.MM.yyyy');

  String _fmtDate(String raw, {bool short = false}) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return (short ? _shortFmt : _dateFmt).format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        // Güncel kaydı listeden çek (düzenleme sonrası taze veri); yoksa (silinmiş) gelen referans.
        final t = fp.allTransactions.firstWhere(
          (x) => x.id == widget.transaction.id,
          orElse: () => widget.transaction,
        );
        final visuals = transactionVisuals(context, t.type);
        final projectName = t.projectId != null
            ? (fp.projects.where((p) => p.id == t.projectId).isNotEmpty
                ? fp.projects.firstWhere((p) => p.id == t.projectId).name
                : null)
            : null;
        final account = t.sourceName.isNotEmpty ? t.sourceName : t.destName;
        final related = _relatedTransactions(fp, t);

        return Scaffold(
          backgroundColor: context.colors.scaffold,
          appBar: AppBar(
            backgroundColor: context.colors.scaffold,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: context.colors.textPrimary, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Hareket Detayı',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: context.colors.textPrimary, size: 28),
                color: context.colors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'duzenle') {
                    _showEditDialog(fp, t);
                  } else if (value == 'sil') {
                    _confirmDelete(fp, t);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'duzenle',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: context.colors.accent),
                      const SizedBox(width: 12),
                      Text('Düzenle',
                          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'sil',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.danger),
                      const SizedBox(width: 12),
                      Text('Sil',
                          style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: centeredPagePadding(context, maxContentWidth: 700, horizontal: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Centered Premium Header
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      // Circular Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: visuals.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(visuals.icon, color: visuals.color, size: 32),
                      ),
                      const SizedBox(height: 16),
                      // Amount
                      Text(
                        '${_incomeTypes.contains(t.type) ? '+' : '-'} ${currencyFormat.format(t.amount)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: visuals.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Category / Description
                      Text(
                        t.description.isNotEmpty ? t.description : t.category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: visuals.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: visuals.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (t.contactName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          t.contactName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _fmtDate(t.date),
                            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Detaylar
                _card(context, [
                  _detailRow(context, Icons.sell_outlined, 'Kategori', t.category.isNotEmpty ? t.category : '-'),
                  _divider(context),
                  _detailRow(context, Icons.person_outline_rounded, 'Alıcı / Kişi',
                      t.contactName.isNotEmpty ? t.contactName : '-'),
                  _divider(context),
                  _detailRow(context, Icons.domain_rounded, 'Proje', projectName ?? '-'),
                  _divider(context),
                  _detailRow(context, Icons.account_balance_wallet_outlined, 'Ödeme Kaynağı',
                      account.isNotEmpty ? account : '-'),
                  _divider(context),
                  _detailRow(context, Icons.payments_outlined, 'Tutar', currencyFormat.format(t.amount),
                      valueColor: visuals.color),
                  if (t.dueDate.isNotEmpty) ...[
                    _divider(context),
                    _detailRow(context, Icons.event_outlined, 'Vade', _fmtDate(t.dueDate)),
                  ],
                ]),

                if (t.attachmentUrl != null && t.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'FİŞ / FATURA'),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      t.attachmentUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 120,
                        color: context.colors.surfaceVariant,
                        alignment: Alignment.center,
                        child: Text('Görsel yüklenemedi', style: TextStyle(color: context.colors.textSecondary)),
                      ),
                    ),
                  ),
                ],

                if (related.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'İLGİLİ İŞLEM GEÇMİŞİ'),
                  const SizedBox(height: 12),
                  _card(
                    context,
                    [
                      for (int i = 0; i < related.length; i++) ...[
                        _historyRow(context, related[i]),
                        if (i < related.length - 1) _divider(context),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildBalanceSummary(context, fp, t, projectName),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- İlgili işlemler: aynı cari, yoksa aynı proje ---
  List<FinancialTransaction> _relatedTransactions(FinanceProvider fp, FinancialTransaction t) {
    bool match(FinancialTransaction x) {
      if (x.id == t.id) return false;
      if (t.contactId != null) return x.contactId == t.contactId;
      if (t.contactName.isNotEmpty) return x.contactName == t.contactName;
      if (t.projectId != null) return x.projectId == t.projectId;
      return false;
    }

    final list = fp.allTransactions.where(match).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.date);
        final db = DateTime.tryParse(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    return list.take(8).toList();
  }

  Widget _buildBalanceSummary(
      BuildContext context, FinanceProvider fp, FinancialTransaction t, String? projectName) {
    // İlgili cari (yoksa proje) için tüm işlemler üzerinden gerçek toplamlar.
    bool sameGroup(FinancialTransaction x) {
      if (t.contactId != null) return x.contactId == t.contactId;
      if (t.contactName.isNotEmpty) return x.contactName == t.contactName;
      if (t.projectId != null) return x.projectId == t.projectId;
      return false;
    }

    final group = fp.allTransactions.where(sameGroup);
    final gelir = group.where((x) => _incomeTypes.contains(x.type)).fold(0.0, (s, x) => s + x.amount);
    final gider = group.where((x) => x.type == 'Gider').fold(0.0, (s, x) => s + x.amount);
    final net = gelir - gider;

    final label = t.contactName.isNotEmpty
        ? t.contactName
        : (projectName != null ? projectName : 'Toplam');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(context, '$label — TOPLAM BAKİYE'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              _balanceCol(context, 'Gelir / Tahsilat', gelir, context.colors.success),
              _vsep(context),
              _balanceCol(context, 'Gider / Ödeme', gider, context.colors.danger),
              _vsep(context),
              _balanceCol(context, 'Net', net, net >= 0 ? context.colors.success : context.colors.danger),
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceCol(BuildContext context, String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.brand)),
          const SizedBox(height: 8),
          Text(currencyFormat.format(value),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _vsep(BuildContext context) =>
      Container(width: 1, height: 40, color: context.colors.border);

  // --- Düzenle / Sil ---
  Future<void> _confirmDelete(FinanceProvider fp, FinancialTransaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('İşlemi Sil', style: TextStyle(color: context.colors.textPrimary)),
        content: Text('Bu işlemi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: TextStyle(color: context.colors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç', style: TextStyle(color: context.colors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sil',
                  style: TextStyle(color: context.colors.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true || t.id == null) return;
    try {
      await fp.deleteTransaction(t.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
      }
    }
  }

  Future<void> _showEditDialog(FinanceProvider fp, FinancialTransaction t) async {
    final descCtrl = TextEditingController(text: t.description);
    final amountCtrl = TextEditingController(text: t.amount.toStringAsFixed(0));
    final categoryCtrl = TextEditingController(text: t.category);
    DateTime selectedDate = DateTime.tryParse(t.date) ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text('İşlemi Düzenle', style: TextStyle(color: context.colors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(descCtrl, 'Açıklama'),
                const SizedBox(height: 12),
                _editField(amountCtrl, 'Tutar', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _editField(categoryCtrl, 'Kategori'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tarih',
                      labelStyle: TextStyle(color: context.colors.textSecondary),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colors.border)),
                    ),
                    child: Text(_shortFmt.format(selectedDate),
                        style: TextStyle(color: context.colors.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Vazgeç', style: TextStyle(color: context.colors.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.brand, foregroundColor: Colors.white),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? t.amount;
    final updated = t.copyWith(
      description: descCtrl.text,
      amount: amount,
      category: categoryCtrl.text,
      date: selectedDate.toIso8601String(),
    );
    try {
      await fp.updateTransaction(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem güncellendi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Güncellenemedi: $e')));
      }
    }
  }

  Widget _editField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.colors.textSecondary),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colors.border)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colors.brand)),
      ),
    );
  }

  // --- Küçük UI yardımcıları ---
  Widget _card(BuildContext context, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(children: children),
      );

  Widget _divider(BuildContext context) =>
      Divider(color: context.colors.border.withValues(alpha: 0.5), height: 1);

  Widget _sectionTitle(BuildContext context, String text) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.colors.textPrimary,
          letterSpacing: 0.5));

  Widget _detailRow(BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: context.colors.textSecondary))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? context.colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, FinancialTransaction t) {
    final visuals = transactionVisuals(context, t.type);
    final title = t.description.isNotEmpty ? t.description : t.category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(_fmtDate(t.date, short: true),
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(title.isNotEmpty ? title : t.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text(currencyFormat.format(t.amount),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: visuals.color)),
          ),
        ],
      ),
    );
  }
}
