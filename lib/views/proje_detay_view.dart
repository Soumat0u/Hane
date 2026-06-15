import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hano/providers/finance_provider.dart';
import 'package:hano/models/project.dart';
import 'package:hano/views/proje_duzenle_view.dart';
import 'package:hano/views/yeni_islem_view.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class ProjeDetayView extends StatelessWidget {
  final String projectName;

  const ProjeDetayView({super.key, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        final project = fp.projects.firstWhere(
          (p) => p.name == projectName, 
          orElse: () => Project(name: 'Bulunamadı', status: '', statusColorHex: '000000', statusBgColorHex: 'FFFFFF')
        );
        if (project.id == null) {
          return Scaffold(appBar: AppBar(title: Text(projectName)), body: const Center(child: Text("Proje bulunamadı.")));
        }

        final totalGider = fp.getProjectTotalGider(project.id!);
        final totalTahsilat = fp.getProjectTotalTahsilat(project.id!);
        final totalSatis = fp.getProjectTotalSatis(project.id!);
        
        final double kar = totalSatis - project.estimatedTotalCost;
        final int tahsilatPercent = totalSatis > 0 ? ((totalTahsilat / totalSatis) * 100).toInt() : 0;
        final int karPercent = totalSatis > 0 ? ((kar / totalSatis) * 100).toInt() : 0;
        final int harcamaPercent = project.estimatedTotalCost > 0 ? ((totalGider / project.estimatedTotalCost) * 100).toInt() : 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF032B5E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              projectName,
              style: const TextStyle(
                color: Color(0xFF032B5E),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF032B5E)),
                tooltip: 'Düzenle',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjeDuzenleView(project: project),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const YeniIslemScreen(initialType: 'Ödeme'),
                ),
              );
            },
            backgroundColor: const Color(0xFF032B5E),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Yeni İşlem Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(project),
                const SizedBox(height: 16),
                _buildSummaryCards(project, totalTahsilat, totalSatis, kar, tahsilatPercent, karPercent, harcamaPercent),
                _buildSpendingDistribution(project, fp, totalGider),
                const SizedBox(height: 24),
                _buildPaymentsSection(project, fp),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(Project project) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image & Badge
        Expanded(
          flex: 4,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/images/modern_apartment_building.png'),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                project.status,
                style: TextStyle(
                  color: Color(int.parse('0xFF${project.statusColorHex}')),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Project Details
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Konum', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Text('İstanbul / Başakşehir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                    label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              Row(
                children: [
                  const Icon(Icons.square_foot_outlined, color: Color(0xFF64748B), size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('m² (Toplam İnşaat Alanı)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text('${project.areaSqMeters} m²', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined, color: Color(0xFF64748B), size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Konut Sayısı', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text('${project.unitCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, color: Color(0xFF64748B), size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dükkan Sayısı', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            Text('${project.shopCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Project project, double tahsilat, double satis, double kar, int tahsilatPercent, int karPercent, int harcamaPercent) {
    return Row(
      children: [
        _buildStatCard(
          title: 'Toplam Maliyet',
          amount: currencyFormat.format(project.estimatedTotalCost),
          percentage: '%$harcamaPercent',
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFF8FAFC),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          title: 'Tahsilat',
          amount: currencyFormat.format(tahsilat),
          percentage: '%$tahsilatPercent',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          title: 'Satış (Sözleşme)',
          amount: currencyFormat.format(satis),
          icon: Icons.handshake_outlined,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          title: 'Kar',
          amount: currencyFormat.format(kar),
          percentage: '%$karPercent',
          icon: Icons.trending_up,
          iconColor: kar >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          bgColor: kar >= 0 ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    String? percentage,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            if (percentage != null) ...[
              const SizedBox(height: 4),
              Text(percentage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection(Project project, FinanceProvider fp) {
    // To make this dynamic, we need to sum expenses by category.
    // The previous implementation used fixed budgets for categories.
    // Let's create dynamic rows based on actual expenses.
    final categorySpending = fp.getProjectCategorySpending(project.id!);
    
    // Some predefined colors for categories
    final categoryColors = {
      'Beton': const Color(0xFF10B981),
      'Demir': const Color(0xFF10B981),
      'Hafriyat': const Color(0xFFF59E0B),
      'Duvar': const Color(0xFF3B82F6),
      'İşçilik': const Color(0xFF8B5CF6),
      'Genel Gider': const Color(0xFFF43F5E),
    };

    final categoryIcons = {
      'Beton': Icons.fire_truck_outlined,
      'Demir': Icons.grid_4x4_outlined,
      'Hafriyat': Icons.local_shipping_outlined,
      'Duvar': Icons.view_quilt_outlined,
      'İşçilik': Icons.engineering_outlined,
      'Genel Gider': Icons.receipt_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ödemeler (Kategori Bazlı)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ödeme Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Table Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Kategori', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Harcama', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0)),
        // Table Rows
        ...categorySpending.entries.map((e) {
          return _buildPaymentRow(
            icon: categoryIcons[e.key] ?? Icons.category_outlined,
            name: e.key,
            total: currencyFormat.format(e.value),
            remaining: '-',
            progress: 1.0,
            color: categoryColors[e.key] ?? const Color(0xFF10B981)
          );
        }).toList(),
        if (categorySpending.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Henüz ödeme kaydı bulunmuyor.", style: TextStyle(color: Colors.grey)),
          )
      ],
    );
  }

  Widget _buildPaymentRow({
    required IconData icon,
    required String name,
    required String total,
    required String remaining,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF032B5E), size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)))),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(total, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)))),
          Expanded(flex: 2, child: Text(remaining, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)))),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingDistribution(Project project, FinanceProvider fp, double totalGider) {
    final categorySpending = fp.getProjectCategorySpending(project.id!);
    
    final categoryColors = {
      'Beton': const Color(0xFF3B82F6),
      'Demir': const Color(0xFF14B8A6),
      'Duvar': const Color(0xFF8B5CF6),
      'Kalıp & İskele': const Color(0xFF0EA5E9),
      'Hafriyat': const Color(0xFF10B981),
      'Elektrik': const Color(0xFFF59E0B),
      'Sıhhi Tesisat': const Color(0xFFF43F5E),
      'İşçilik': const Color(0xFFCBD5E1),
      'Genel Gider': const Color(0xFF475569),
    };

    final List<SpendingData> data = categorySpending.entries.map((e) {
      double pct = totalGider > 0 ? (e.value / totalGider) * 100 : 0;
      return SpendingData(e.key, currencyFormat.format(e.value), pct, categoryColors[e.key] ?? const Color(0xFF1E293B));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harcama Dağılımı',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),
        if (data.isEmpty)
          const Text("Harcama verisi bulunamadı.", style: TextStyle(color: Colors.grey))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: DonutChartPainter(data),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Toplam Ödenen', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        Text(currencyFormat.format(totalGider), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: data.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                          Text(item.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 40,
                            child: Text('%${item.percentage.toStringAsFixed(1)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class SpendingData {
  final String name;
  final String amount;
  final double percentage;
  final Color color;

  SpendingData(this.name, this.amount, this.percentage, this.color);
}

class DonutChartPainter extends CustomPainter {
  final List<SpendingData> data;

  DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = radius * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;

    for (var item in data) {
      if (item.percentage == 0) continue;
      
      final sweepAngle = (item.percentage / 100) * 2 * pi;
      
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
