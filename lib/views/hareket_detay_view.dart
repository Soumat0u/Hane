import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/views/hareketler_view.dart' show transactionVisuals;
import 'package:hane/views/yeni_islem_view.dart';
import 'package:hane/views/widgets/fullscreen_image_view.dart';



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
        final DateTime? tDate = DateTime.tryParse(t.date);
        final bool isPastMonth = tDate != null &&
            (tDate.year < DateTime.now().year ||
                (tDate.year == DateTime.now().year && tDate.month < DateTime.now().month));

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
              if (isPastMonth)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Tooltip(
                    message: 'Geçmiş aylara ait hareketler değiştirilemez.',
                    child: Icon(Icons.lock_outline_rounded, color: context.colors.textSecondary, size: 24),
                  ),
                )
              else
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
                // Başlık kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: visuals.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: visuals.color, shape: BoxShape.circle),
                        child: Icon(visuals.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.type.toUpperCase(),
                        style: TextStyle(
                                    fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: visuals.color,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                        t.description.isNotEmpty ? t.description : t.category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary)),
                      ),
                                Text(currencyFormat.format(t.amount),
                          style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: visuals.color)),
                              ],
                      ),
                            if (t.contactName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(t.contactName,
                          style: TextStyle(
                                        fontSize: 13,
                            fontWeight: FontWeight.w600,
                                        color: context.colors.textPrimary)),
                        ),
                            const SizedBox(height: 12),
                            Row(children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 6),
                              Text(_fmtDate(t.date),
                                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                            ]),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                  if (t.documentNo.isNotEmpty) ...[
                    _divider(context),
                    _detailRow(context, Icons.description_outlined, 'Fatura No', t.documentNo),
                  ],
                ]),

                if (t.attachmentUrl != null && t.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle(context, 'FİŞ / FATURA'),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final url = t.attachmentUrl!.startsWith('http://web-production')
                        ? t.attachmentUrl!.replaceFirst('http://', 'https://')
                        : t.attachmentUrl!;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FullscreenImageView(imageUrl: url, heroTag: url)),
                      ),
                      child: Hero(
                        tag: url,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            url,
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
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }



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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => YeniIslemScreen(
          initialTransaction: t,
          onBack: () => Navigator.pop(ctx),
        ),
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


}
