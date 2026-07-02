import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/views/kasa_view.dart';
import 'package:hane/views/borclar_view.dart';
import 'package:hane/views/finansman_gucu_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

          // Nakit akışı grafiği son 6 ayın GERÇEK işlemlerinden hesaplanır.
          final cashFlow = _computeCashFlow(fp);
          final flowMax = _niceMax(cashFlow);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 16.0),
            child: ResponsiveCenter(
              maxWidth: 1100,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

            // Grid of Cards: Kasa, Borclar, Alacaklar, Finansman Gucu
            // Mobilde 2, geniş ekranda 4 sütuna kadar.
            LayoutBuilder(
              builder: (context, constraints) {
                const double gap = 16;
                final int cols = responsiveColumns(constraints.maxWidth, minCardWidth: 160, maxColumns: 4);
                final double cardWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _buildMetricCard(context,
                      width: cardWidth,
                      title: 'KASA',
                      value: currencyFormat.format(kasa),
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: context.colors.accent,
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
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BorclarView()));
                      },
                    ),
                    _buildMetricCard(context,
                      width: cardWidth,
                      title: 'ALACAKLAR',
                      value: currencyFormat.format(alacaklar > 0 ? alacaklar : 0),
                      icon: Icons.assignment_returned_rounded,
                      accentColor: Theme.of(context).extension<AppColors>()!.success,
                    ),
                    _buildMetricCard(context,
                      width: cardWidth,
                      title: 'FİNANSMAN GÜCÜ',
                      value: currencyFormat.format(finansmanGucu),
                      icon: Icons.shield_rounded,
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FinansmanGucuView()));
                      },
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
                  // Y-Axis labels (her aralık sabit 5 milyon)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i <= _flowIntervals; i++) ...[
                        _buildYLabel(_compactAmount(flowMax - i * _flowStep(flowMax))),
                        if (i < _flowIntervals) const SizedBox(height: 20),
                      ],
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
                          for (final f in cashFlow)
                            _buildMonthBarColumn(context, f.label, f.income, f.expense, flowMax),
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
                  color: accentColor.withValues(alpha: 0.12),
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

  Widget _buildMonthBarColumn(
      BuildContext context, String month, double incomeValue, double expenseValue, double maxScale) {
    const double chartMaxHeight = 110.0;
    final double safeScale = maxScale <= 0 ? 1 : maxScale;
    final double incomeHeight = (incomeValue / safeScale) * chartMaxHeight;
    final double expenseHeight = (expenseValue / safeScale) * chartMaxHeight;

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

  static const List<String> _shortMonths = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  /// Son 6 ayın (eskiden yeniye) gelir/gider toplamlarını gerçek işlemlerden hesaplar.
  List<_MonthFlow> _computeCashFlow(FinanceProvider fp, {int count = 6}) {
    final now = DateTime.now();
    final flows = <_MonthFlow>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      double income = 0, expense = 0;
      for (final t in fp.allTransactions) {
        final d = DateTime.tryParse(t.date);
        if (d == null || d.year != m.year || d.month != m.month) continue;
        if (t.type == 'Tahsilat' || t.type == 'Gelir') {
          income += t.amount;
        } else if (t.type == 'Gider') {
          expense += t.amount;
        }
      }
      flows.add(_MonthFlow(_shortMonths[m.month - 1], income, expense));
    }
    return flows;
  }

  /// Y ekseninde her zaman sabit 4 aralık (5 etiket) gösterilir; aralık
  /// büyüklüğü 5 milyonun katı olacak şekilde son 6 ayın en büyük değerine
  /// göre hesaplanır. Böylece grafik hem 5M'lik adımlarla bölünür hem de
  /// etiket sayısı sabit kalıp grafik boyu devasalaşmaz.
  static const double _flowStepUnit = 5000000;
  static const int _flowIntervals = 4;

  /// Grafik için üst ölçek: en yüksek gelir/gider değerine göre.
  double _niceMax(List<_MonthFlow> flows) {
    double maxVal = 0;
    for (final f in flows) {
      if (f.income > maxVal) maxVal = f.income;
      if (f.expense > maxVal) maxVal = f.expense;
    }
    if (maxVal <= 0) return _flowStepUnit * _flowIntervals;
    final step = ((maxVal / _flowIntervals) / _flowStepUnit).ceil() * _flowStepUnit;
    return (step <= 0 ? _flowStepUnit : step) * _flowIntervals;
  }

  double _flowStep(double flowMax) => flowMax / _flowIntervals;

  /// Y ekseni etiketleri için kısa tutar biçimi (1.2M, 850B, 500).
  String _compactAmount(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(v >= 1e7 ? 0 : 1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}B';
    return v.toStringAsFixed(0);
  }
}

/// Bir ayın gelir/gider özeti (nakit akışı grafiği için).
class _MonthFlow {
  final String label;
  final double income;
  final double expense;
  const _MonthFlow(this.label, this.income, this.expense);
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
