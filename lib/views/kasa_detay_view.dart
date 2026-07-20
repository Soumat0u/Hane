import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/kasa_view.dart'; // For Kasa Painters (Garanti, etc)
import 'package:hane/views/hareket_detay_view.dart';
final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

class KasaDetayView extends StatelessWidget {
  final Account account;

  const KasaDetayView({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          account.name,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          // FK'lı işlemler (fromAccountId/toAccountId == account.id) VE eski
          // isim-bazlı işlemler (sourceName/destName == account.name) birlikte
          // dahil edilir — aksi halde yalnızca FK ile bağlı işlemler (ör. kredi/
          // çek ödemesi) bu ekranda hiç görünmez (bkz. Account.recalculate_balance
          // backend'deki aynı hibrit mantık).
          final relatedTx = fp.allTransactions.where((t) {
            final fkMatch = t.fromAccountId == account.id || t.toAccountId == account.id;
            final nameMatch = t.sourceName == account.name || t.destName == account.name;
            return fkMatch || nameMatch;
          }).toList();

          // Sort by date descending
          relatedTx.sort((a, b) => b.date.compareTo(a.date));

          return ResponsiveCenter(
            maxWidth: 820,
            child: Column(
            children: [
              // Header Card with Balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(bottom: BorderSide(color: context.colors.border)),
                ),
                child: Column(
                  children: [
                    if (account.type == 'Kredi Kartı') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'KULLANILABİLİR LİMİT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(account.availableLimit),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.brand,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: context.colors.border),
                          Column(
                            children: [
                              Text(
                                'GÜNCEL BORÇ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(account.balance.abs()),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'GÜNCEL BAKİYE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(account.balance),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: context.colors.brand,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.accentBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        account.type,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Transaction List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Hesap Hareketleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${relatedTx.length} İşlem',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction List
              Expanded(
                child: relatedTx.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz hesap hareketi bulunmuyor.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 4),
                        itemCount: relatedTx.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final t = relatedTx[index];
                          final isFkDest = t.toAccountId != null && t.toAccountId == account.id;
                          final isFkSource = t.fromAccountId != null && t.fromAccountId == account.id;
                          bool isIncome = false;
                          if (t.type == 'Transfer') {
                            if (isFkDest || t.destName == account.name) isIncome = true;
                            if (isFkSource || t.sourceName == account.name) isIncome = false;
                          } else if (isFkDest) {
                            isIncome = true;
                          } else if (isFkSource) {
                            isIncome = false;
                          } else if (t.type == 'Gelir' || t.type == 'Tahsilat' || t.type == 'Satış' || t.type == 'Borçlanma' || t.type == 'Sermaye' || t.type == 'Kredi Kullanımı') {
                            isIncome = true;
                          } else {
                            isIncome = false;
                          }

                          return _buildTransactionCard(context, t, isIncome);
                        },
                      ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, FinancialTransaction t, bool isIncome) {
    IconData icon;
    Color color;
    Color bgColor;

    if (t.type == 'Transfer') {
      icon = Icons.sync_alt_rounded;
      color = context.colors.accent;
      bgColor = context.colors.accentBg;
    } else if (isIncome) {
      icon = Icons.arrow_downward_rounded;
      color = context.colors.success;
      bgColor = context.colors.successBg;
    } else {
      icon = Icons.arrow_upward_rounded;
      color = context.colors.danger;
      bgColor = context.colors.dangerBg;
    }

    String counterpartyText = isIncome ? t.sourceName : t.destName;
    if (counterpartyText.isEmpty) counterpartyText = t.contactName;
    if (counterpartyText.isEmpty) counterpartyText = t.description;
    if (counterpartyText.isEmpty) counterpartyText = t.category;
    if (counterpartyText.isEmpty && t.projectId != null) {
      counterpartyText = 'Proje ${t.projectId}';
    } else if (counterpartyText.isEmpty) {
      counterpartyText = 'Bilinmeyen';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HareketDetayView(transaction: t),
          ),
        );
      },
      child: Container(
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
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description.isNotEmpty ? t.description : t.type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.date} • $counterpartyText',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(t.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
