import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/services/export_service.dart';
import 'package:hane/views/cari_hesaplar_view.dart' show kContactKindLabels;

/// Cari hesap ekstresi: bir cariye ait tüm hareketleri (yalnızca `contact` FK'si
/// set edilmiş işlemler) tarih sırasına göre listeler.
class CariHesapDetayView extends StatelessWidget {
  final Contact contact;

  const CariHesapDetayView({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          contact.name,
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<FinanceProvider>(
            builder: (context, fp, child) {
              final relatedTx = contact.id == null ? <FinancialTransaction>[] : fp.getTransactionsForContact(contact.id!);
              return PopupMenuButton<String>(
                icon: Icon(Icons.ios_share_rounded, color: context.colors.textPrimary),
                onSelected: (format) => _export(context, relatedTx, format),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'pdf', child: Text('PDF olarak dışa aktar')),
                  PopupMenuItem(value: 'excel', child: Text('Excel olarak dışa aktar')),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          final relatedTx = contact.id == null ? <FinancialTransaction>[] : fp.getTransactionsForContact(contact.id!);
          relatedTx.sort((a, b) => b.date.compareTo(a.date));

          final isDebt = contact.balance > 0;
          final isCredit = contact.balance < 0;
          final balanceColor =
              isDebt ? context.colors.danger : (isCredit ? context.colors.success : context.colors.brand);
          final balanceLabel = isDebt ? 'BORCUMUZ' : (isCredit ? 'ALACAĞIMIZ' : 'GÜNCEL BAKİYE');

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(bottom: BorderSide(color: context.colors.border)),
                ),
                child: Column(
                  children: [
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(contact.balance.abs()),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: balanceColor),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.accentBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        kContactKindLabels[contact.kind] ?? contact.kind,
                        style: TextStyle(fontSize: 12, color: context.colors.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Hesap Hareketleri',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${relatedTx.length} İşlem',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: relatedTx.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Henüz hareket bulunmuyor.', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                        itemCount: relatedTx.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildTransactionCard(context, relatedTx[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context, List<FinancialTransaction> transactions, String format) async {
    try {
      final title = 'Cari Ekstresi - ${contact.name}';
      if (format == 'pdf') {
        await ExportService.exportTransactionsPdf(transactions, title: title);
      } else {
        await ExportService.exportTransactionsExcel(transactions, title: title);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarılamadı: $e')));
      }
    }
  }

  Widget _buildTransactionCard(BuildContext context, FinancialTransaction t) {
    // Gelir: cariden bize para girişi (borcumuz azalır/alacağımız azalır).
    // Gider: bize cariye para çıkışı (borcumuz artar).
    final isIncome = t.type == 'Gelir';
    final icon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final color = isIncome ? context.colors.success : context.colors.danger;
    final bgColor = isIncome ? context.colors.successBg : context.colors.dangerBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isNotEmpty ? t.description : t.type,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(t.date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '-' : '+'}${currencyFormat.format(t.amount)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
