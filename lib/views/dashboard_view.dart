import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hano/providers/finance_provider.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          if (fp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final kasa = fp.getTotalBalance();
          final borclar = fp.allTransactions.where((t) => t.type == 'Borçlanma').fold(0.0, (sum, t) => sum + t.amount);
          final alacaklar = fp.getTotalSatis() - fp.getTotalTahsilat();
          final finansmanGucu = kasa + (alacaklar > 0 ? alacaklar : 0) - borclar;
          final projeMaliyetleri = fp.getTotalHarcama();
          final netPozisyon = kasa - borclar;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

            // Grid of Cards: Kasa, Borclar, Alacaklar, Finansman Gucu
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = (constraints.maxWidth - 16) / 2;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCard(
                          width: cardWidth,
                          title: 'KASA',
                          value: currencyFormat.format(kasa),
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                        ),
                        _buildMetricCard(
                          width: cardWidth,
                          title: 'BORÇLAR',
                          value: currencyFormat.format(borclar),
                          icon: Icons.receipt_long_rounded,
                          accentColor: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFFEF2F2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCard(
                          width: cardWidth,
                          title: 'ALACAKLAR',
                          value: currencyFormat.format(alacaklar > 0 ? alacaklar : 0),
                          icon: Icons.assignment_returned_rounded,
                          accentColor: const Color(0xFF10B981),
                          bgColor: const Color(0xFFF0FDF4),
                        ),
                        _buildMetricCard(
                          width: cardWidth,
                          title: 'FİNANSMAN GÜCÜ',
                          value: currencyFormat.format(finansmanGucu),
                          icon: Icons.shield_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          bgColor: const Color(0xFFFAF5FF),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Proje Maliyetleri (Full width card)
            _buildMetricCard(
              width: MediaQuery.of(context).size.width - 40,
              title: 'PROJE MALİYETLERİ',
              value: currencyFormat.format(projeMaliyetleri),
              icon: Icons.business_center_rounded,
              accentColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFF7ED),
            ),
            const SizedBox(height: 20),

            // Net Position Card (Degrade Lacivert + Sparkline)
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
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET POZİSYON',
                          style: TextStyle(
                            color: Color(0xB2FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(netPozisyon),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 50,
                      child: CustomPaint(
                        painter: SparklinePainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nakit Akisi (Aylik) Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nakit Akışı (Aylık)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem('Gelir', const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildLegendItem('Gider', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cash Flow Bar Chart
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-Axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildYLabel('8M'),
                      const SizedBox(height: 20),
                      _buildYLabel('6M'),
                      const SizedBox(height: 20),
                      _buildYLabel('4M'),
                      const SizedBox(height: 20),
                      _buildYLabel('2M'),
                      const SizedBox(height: 20),
                      _buildYLabel('0'),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Chart columns
                  Expanded(
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMonthBarColumn('Oca', 5.0, 3.8),
                          _buildMonthBarColumn('Şub', 7.0, 3.5),
                          _buildMonthBarColumn('Mar', 5.0, 4.6),
                          _buildMonthBarColumn('Nis', 5.6, 3.5),
                          _buildMonthBarColumn('May', 5.0, 2.6),
                          _buildMonthBarColumn('Haz', 7.0, 3.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
      },
      ),
    );
  }

  // Helper widget to build Metric Cards
  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildYLabel(String text) {
    return SizedBox(
      width: 20,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildMonthBarColumn(String month, double incomeValue, double expenseValue) {
    const double maxScale = 8.0;
    const double chartMaxHeight = 110.0;
    final double incomeHeight = (incomeValue / maxScale) * chartMaxHeight;
    final double expenseHeight = (expenseValue / maxScale) * chartMaxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Income Bar (Green)
            Container(
              width: 8,
              height: incomeHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            // Expense Bar (Red)
            Container(
              width: 8,
              height: expenseHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SparklinePainter extends CustomPainter {
  const SparklinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x2EFFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.15, h * 0.50, w * 0.3, h * 0.75)
      ..quadraticBezierTo(w * 0.45, h * 0.95, w * 0.6, h * 0.45)
      ..quadraticBezierTo(w * 0.75, h * 0.15, w * 0.9, h * 0.55)
      ..lineTo(w, h * 0.48);

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
