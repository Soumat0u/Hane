import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hano/providers/finance_provider.dart';
import 'package:hano/views/kasa_detay_view.dart';
import 'package:hano/models/account.dart';
import 'package:hano/views/widgets/bank_logo.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class KasaScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const KasaScreen({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          final kasa = fp.getTotalBalance();
          final bankAccounts = fp.accounts.where((a) => a.type == 'Banka').toList();
          final creditCards = fp.accounts.where((a) => a.type == 'Kredi Kartı').toList();
          final cashAccounts = fp.accounts.where((a) => a.type == 'Nakit').toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

            // Top Total Kasa Card (Degrade)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF032B5E),
                    Color(0xFF021B3A),
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
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(kasa),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: SafeBoxPainter(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // "Bankalar" Section Title
            const Text(
              'Bankalar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Bankalar Grouped List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ...bankAccounts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final a = entry.value;
                    return Column(
                      children: [
                        _buildListItem(
                          context: context,
                          account: a,
                          iconData: Icons.account_balance,
                          iconColor: const Color(0xFF3B82F6),
                          name: a.name,
                          value: currencyFormat.format(a.balance),
                          isLast: idx == bankAccounts.length - 1,
                        ),
                        if (idx < bankAccounts.length - 1)
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }),
                  if (bankAccounts.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("Banka hesabı bulunamadı.")),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // "Kredi Kartları" Section Title
            const Text(
              'Kredi Kartları',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Kredi Kartları Grouped List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ...creditCards.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final a = entry.value;
                    return Column(
                      children: [
                        _buildCardListItem(
                          context: context,
                          account: a,
                          name: a.name,
                          remainingLimit: currencyFormat.format(a.balance), // using balance as remaining limit for now
                          maxLimit: currencyFormat.format(120000), // mock max limit
                          isLast: idx == creditCards.length - 1,
                        ),
                        if (idx < creditCards.length - 1)
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }),
                  if (creditCards.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("Kredi kartı bulunamadı.")),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nakit and Borsa Grouped List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ...cashAccounts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final a = entry.value;
                    return Column(
                      children: [
                        _buildListItem(
                          context: context,
                          account: a,
                          iconData: Icons.money_rounded,
                          iconColor: const Color(0xFF10B981),
                          name: a.name,
                          value: currencyFormat.format(a.balance),
                          isLast: idx == cashAccounts.length - 1,
                        ),
                        if (idx < cashAccounts.length - 1)
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }),
                  if (cashAccounts.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("Nakit hesabı bulunamadı.")),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
      },
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required Account account,
    IconData? iconData,
    Color? iconColor,
    required String name,
    required String value,
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
        : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: (account.type == 'Banka' || account.type == 'Kredi Kartı') ? 90 : 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4.0),
              child: (account.type == 'Banka' || account.type == 'Kredi Kartı')
                ? BankLogoWidget(bankName: account.name, width: 85, height: 32)
                : Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardListItem({
    required BuildContext context,
    required Account account,
    required String name,
    required String remainingLimit,
    required String maxLimit,
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
        : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: (account.type == 'Banka' || account.type == 'Kredi Kartı') ? 90 : 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4.0),
              child: BankLogoWidget(bankName: account.name, width: 85, height: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limit: $maxLimit',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  remainingLimit,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kalan Limit',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SAFEBOX PAINTER ---
class SafeBoxPainter extends CustomPainter {
  const SafeBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, w - 8, h - 8), const Radius.circular(6)), paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.5), 8, paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.5), 2, paint);
    canvas.drawLine(Offset(w - 12, 8), Offset(w - 12, h - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


