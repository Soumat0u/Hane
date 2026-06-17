import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/kasa_view.dart';
import 'package:hane/views/borclar_view.dart';
import 'package:hane/views/finansman_gucu_view.dart';

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

          final kasa = fp.getVarlikKasa();
          final borclar = fp.getTotalBorc();
          final alacaklar = fp.getTotalAlacak();
          final finansmanGucu = fp.getFinansmanGucu();
          final netPozisyon = kasa + alacaklar - borclar;

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
                        _buildMetricCard(context,
                          width: cardWidth,
                          title: 'KASA',
                          value: currencyFormat.format(kasa),
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: context.colors.accent,
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const KasaScreen()));
                          },
                        ),
                        _buildMetricCard(context,
                          width: cardWidth,
                          title: 'BORÇLAR',
                          value: currencyFormat.format(borclar),
                          icon: Icons.receipt_long_rounded,
                          accentColor: Theme.of(context).extension<AppColors>()!.danger,
                          bgColor: const Color(0xFFFEF2F2),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BorclarView()));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCard(context,
                          width: cardWidth,
                          title: 'ALACAKLAR',
                          value: currencyFormat.format(alacaklar > 0 ? alacaklar : 0),
                          icon: Icons.assignment_returned_rounded,
                          accentColor: Theme.of(context).extension<AppColors>()!.success,
                          bgColor: const Color(0xFFF0FDF4),
                        ),
                        _buildMetricCard(context,
                          width: cardWidth,
                          title: 'FİNANSMAN GÜCÜ',
                          value: currencyFormat.format(finansmanGucu),
                          icon: Icons.shield_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          bgColor: const Color(0xFFFAF5FF),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FinansmanGucuView()));
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),



            // Net Position Card (Degrade Lacivert + Sparkline)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colors.brand,
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
                          style: TextStyle(
                            color: context.colors.surface,
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
                Text(
                  'Nakit Akışı (Aylık)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).extension<AppColors>()!.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem('Gelir', Theme.of(context).extension<AppColors>()!.success),
                    const SizedBox(width: 12),
                    _buildLegendItem('Gider', Theme.of(context).extension<AppColors>()!.danger),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cash Flow Bar Chart
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
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
                          _buildMonthBarColumn(context, 'Oca', 5.0, 3.8),
                          _buildMonthBarColumn(context, 'Şub', 7.0, 3.5),
                          _buildMonthBarColumn(context, 'Mar', 5.0, 4.6),
                          _buildMonthBarColumn(context, 'Nis', 5.6, 3.5),
                          _buildMonthBarColumn(context, 'May', 5.0, 2.6),
                          _buildMonthBarColumn(context, 'Haz', 7.0, 3.9),
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
  Widget _buildMetricCard(BuildContext context, {
        required String title,
    required String value,
    required double width,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.textSecondary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).extension<AppColors>()!.textPrimary,
            ),
          ),
        ],
      ),
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

  Widget _buildMonthBarColumn(BuildContext context, String month, double incomeValue, double expenseValue) {
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
                color: Theme.of(context).extension<AppColors>()!.success,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            // Expense Bar (Red)
            Container(
              width: 8,
              height: expenseHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AppColors>()!.danger,
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
