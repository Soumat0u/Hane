import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/kasa_detay_view.dart';
import 'package:hane/models/account.dart';
import 'package:hane/views/widgets/bank_logo.dart';
import 'package:hane/views/yeni_islem_view.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class KasaScreen extends StatelessWidget {
  const KasaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Kasa', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final kasa = fp.getTotalBalance();
            final bankAccounts = fp.accounts.where((a) => a.type == 'Banka').toList();
            final cashAccounts = fp.accounts.where((a) => a.type == 'Nakit').toList();
            final borsaAccounts = fp.accounts.where((a) => a.type == 'Borsa').toList(); // Varsayımsal
            
            final totalBankalar = bankAccounts.fold(0.0, (sum, a) => sum + a.balance);
            final totalNakit = cashAccounts.fold(0.0, (sum, a) => sum + a.balance);
            final totalBorsa = borsaAccounts.fold(0.0, (sum, a) => sum + a.balance);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Total Kasa Card (Degrade)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.colors.brand,
                          const Color(0xFF021B3A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x3F032B5E),
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
                              'TOPLAM KASA',
                              style: TextStyle(
                                color: context.colors.surface.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(kasa),
                              style: TextStyle(
                                color: context.colors.surface,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(Icons.account_balance_wallet_outlined, color: context.colors.surface.withAlpha(160), size: 48),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BANKALAR
                  _buildSectionHeader(context, 'BANKALAR', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, bankAccounts, isBank: true),
                  const SizedBox(height: 24),

                  // NAKİT
                  _buildSectionHeader(context, 'NAKİT', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, cashAccounts, iconData: Icons.payments_outlined, iconColor: Colors.green),
                  const SizedBox(height: 24),

                  // BORSA
                  _buildSectionHeader(context, 'BORSA', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, borsaAccounts, iconData: Icons.trending_up_rounded, iconColor: Colors.purple),
                  const SizedBox(height: 24),

                  // ÖZET
                  Text(
                    'ÖZET',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow(context, 'Toplam Bankalar', totalBankalar),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Nakit', totalNakit),
                        const SizedBox(height: 12),
                        _buildSummaryRow(context, 'Borsa', totalBorsa),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOPLAM KASA',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.colors.brand,
                              ),
                            ),
                            Text(
                              currencyFormat.format(kasa),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.brand,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showNewTransaction(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Yeni İşlem')),
      body: YeniIslemScreen(initialType: 'Gelir', onBack: () => Navigator.pop(context)),
    )));
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
                    'Yeni İşlem',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, List<Account> accounts, {bool isBank = false, IconData? iconData, Color? iconColor}) {
    if (accounts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text("Kayıt bulunamadı.", style: TextStyle(color: context.colors.textSecondary)),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          ...accounts.asMap().entries.map((entry) {
            final idx = entry.key;
            final a = entry.value;
            return Column(
              children: [
                _buildListItem(
                  context: context,
                  account: a,
                  isBank: isBank,
                  iconData: iconData,
                  iconColor: iconColor,
                  isLast: idx == accounts.length - 1,
                ),
                if (idx < accounts.length - 1)
                  Divider(height: 1, indent: isBank ? 116 : 64, color: context.colors.surfaceVariant),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required Account account,
    bool isBank = false,
    IconData? iconData,
    Color? iconColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KasaDetayView(account: account)),
        );
      },
      borderRadius: isLast 
        ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
        : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: isBank ? 90 : 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.scaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4.0),
              child: isBank
                ? BankLogoWidget(bankName: account.bankLogoPainter.isNotEmpty ? account.bankLogoPainter : account.name, width: 85, height: 32)
                : Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                account.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Text(
              currencyFormat.format(account.balance),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
