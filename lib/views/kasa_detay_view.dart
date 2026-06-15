import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hano/models/financial_transaction.dart';
import 'package:hano/providers/finance_provider.dart';
import 'package:hano/models/account.dart';
import 'package:hano/views/kasa_view.dart'; // For Kasa Painters (Garanti, etc)

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

class KasaDetayView extends StatelessWidget {
  final Account account;

  const KasaDetayView({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          account.name,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          // Find related transactions
          final relatedTx = fp.allTransactions.where((t) {
            return t.sourceName == account.name || t.destName == account.name;
          }).toList();

          // Sort by date descending
          relatedTx.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // Header Card with Balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF032B5E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        account.type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
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
                    const Text(
                      'Hesap Hareketleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
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
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                        itemCount: relatedTx.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final t = relatedTx[index];
                          // Determine if this transaction adds or subtracts from this account
                          bool isIncome = false;
                          
                          if (t.type == 'Gelir' || t.type == 'Borçlanma' || t.type == 'Sermaye') {
                            // Money comes in, goes to destName
                            if (t.destName == account.name) isIncome = true;
                          } else if (t.type == 'Gider' || t.type == 'Geri Ödeme' || t.type == 'Kar Dağıtımı') {
                            // Money goes out, comes from sourceName
                            if (t.destName == account.name) isIncome = true; // wait, if destName is account, someone paid into it? No, gider dest is outside.
                            // Actually, for Gider, sourceName is our account.
                            if (t.sourceName == account.name) isIncome = false;
                          } else if (t.type == 'Transfer') {
                            if (t.destName == account.name) isIncome = true;
                            if (t.sourceName == account.name) isIncome = false;
                          }

                          return _buildTransactionCard(t, isIncome);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(FinancialTransaction t, bool isIncome) {
    IconData icon;
    Color color;
    Color bgColor;

    if (t.type == 'Transfer') {
      icon = Icons.sync_alt_rounded;
      color = const Color(0xFF3B82F6);
      bgColor = const Color(0xFFEFF6FF);
    } else if (isIncome) {
      icon = Icons.arrow_downward_rounded;
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFFF0FDF4);
    } else {
      icon = Icons.arrow_upward_rounded;
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
    }

    String counterpartyText = isIncome ? t.sourceName : t.destName;
    if (counterpartyText.isEmpty && t.projectId != null) {
      counterpartyText = 'Proje ${t.projectId}';
    } else if (counterpartyText.isEmpty) {
      counterpartyText = 'Bilinmeyen';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
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
    );
  }
}
