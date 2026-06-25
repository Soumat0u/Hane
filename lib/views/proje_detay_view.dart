import 'dart:math';

import 'package:hane/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/views/yeni_proje_view.dart';
import 'package:hane/views/yeni_islem_view.dart';
final dateFormat = DateFormat('dd.MM.yyyy');

class ProjeDetayView extends StatefulWidget {
  final String projectName;

  const ProjeDetayView({super.key, required this.projectName});

  @override
  State<ProjeDetayView> createState() => _ProjeDetayViewState();
}

class _ProjeDetayViewState extends State<ProjeDetayView> {
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        final project = fp.projects.firstWhere(
          (p) => p.name == widget.projectName, 
          orElse: () => Project(name: 'Bulunamadı', status: '', statusColorHex: '000000', statusBgColorHex: 'FFFFFF')
        );
        if (project.id == null) {
          return Scaffold(appBar: AppBar(title: Text(widget.projectName)), body: const Center(child: Text("Proje bulunamadı.")));
        }

        final projectTransactions = fp.getTransactionsForProject(project.id!);
        final harcamalar = projectTransactions.where((t) => t.type == 'Gider').toList();
        
        final totalGider = harcamalar.fold(0.0, (sum, t) => sum + t.amount);
        final kalanButce = project.estimatedTotalCost - totalGider;

        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;
        final buAyHarcama = harcamalar.where((t) {
          final d = DateTime.tryParse(t.date);
          if (d == null) return false;
          return d.month == currentMonth && d.year == currentYear;
        }).fold(0.0, (sum, t) => sum + t.amount);

        // Get unique categories from expenses
        final categories = ['Tümü'];
        final uniqueCategories = harcamalar.map((e) => e.category).toSet().toList();
        uniqueCategories.sort();
        categories.addAll(uniqueCategories);

        if (!_categoriesContains(_selectedCategory, categories)) {
           _selectedCategory = 'Tümü';
        }

        // Filter transactions by selected category
        final filteredHarcamalar = _selectedCategory == 'Tümü' 
            ? harcamalar 
            : harcamalar.where((t) => t.category == _selectedCategory).toList();

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(
            backgroundColor: context.colors.surface,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.projectName,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: context.colors.textPrimary),
                tooltip: 'Düzenle',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YeniProjeView(project: project),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context, project),
                const SizedBox(height: 24),
                _buildHarcamalarHeader(context, project.name),
                const SizedBox(height: 16),
                _buildFilterChips(context, categories),
                const SizedBox(height: 16),
                _buildExpenditureList(context, filteredHarcamalar),
                const SizedBox(height: 24),
                _buildSummaryCards(context, totalGider, buAyHarcama, kalanButce),
                const SizedBox(height: 32),
                _buildSpendingDistribution(context, project, fp, totalGider),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _categoriesContains(String cat, List<String> cats) {
      return cats.contains(cat);
  }

  Widget _buildHeroCard(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/modern_apartment_building.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.projectCode.isNotEmpty ? project.projectCode : 'AKP-001',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: context.colors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location.isNotEmpty ? project.location : '-',
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.home_work_outlined, size: 14, color: context.colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      project.projectType.isNotEmpty ? project.projectType : '-',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pafta, Parsel, Alan
          Row(
            children: [
              _buildProjectStatItem(context, 'Pafta', '125'),
              const SizedBox(width: 16),
              _buildProjectStatItem(context, 'Parsel', '48'),
              const SizedBox(width: 16),
              _buildProjectStatItem(context, 'Alan (m²)', currencyFormat.format(project.areaSqMeters).replaceAll('₺', '').trim()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProjectStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHarcamalarHeader(BuildContext context, String projectName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'HARCAMALAR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YeniIslemScreen(
                  initialType: 'Gider',
                  initialProject: projectName,
                ),
              ),
            );
          },
          icon: Icon(Icons.add, size: 16, color: context.colors.surface),
          label: Text('Yeni Harcama Ekle', style: TextStyle(color: context.colors.surface, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A), // Dark blue almost black from mock
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? context.colors.surface : context.colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
              backgroundColor: context.colors.surface,
              selectedColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : context.colors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenditureList(BuildContext context, List<FinancialTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text("Bu kategoriye ait harcama bulunamadı.", style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('KATEGORİ', style: _headerStyle(context))),
              Expanded(flex: 3, child: Text('AÇIKLAMA / MİKTAR', style: _headerStyle(context))),
              Expanded(flex: 2, child: Text('TEDARİKÇİ', style: _headerStyle(context))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TUTAR', style: _headerStyle(context)))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TARİH', style: _headerStyle(context)))),
              const SizedBox(width: 24), // For arrow icon
            ],
          ),
        ),
        const Divider(height: 1),
        // Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final t = transactions[index];
            DateTime? date = DateTime.tryParse(t.date);
            final dateStr = date != null ? dateFormat.format(date) : t.date;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getIconForCategory(t.category), size: 18, color: context.colors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.description.isNotEmpty ? t.description : '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        // Attempt to extract quantity from description if possible, or just leave it empty. Let's just use description.
                        Text('', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(t.contactName ?? '-', style: TextStyle(fontSize: 12, color: context.colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(currencyFormat.format(t.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(dateStr, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 16, color: context.colors.textSecondary),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: context.colors.textSecondary,
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beton': return Icons.fire_truck_outlined;
      case 'demir': return Icons.grid_4x4_outlined;
      case 'duvar': return Icons.view_quilt_outlined;
      case 'elektrik': return Icons.electrical_services_outlined;
      case 'sıhhi tesisat': return Icons.water_drop_outlined;
      case 'işçilik': return Icons.engineering_outlined;
      case 'kalıp': return Icons.construction_outlined;
      case 'nakliye': return Icons.local_shipping_outlined;
      default: return Icons.build_outlined;
    }
  }

  Widget _buildSummaryCards(BuildContext context, double totalGider, double buAyHarcama, double kalanButce) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryCardColumn(context, 'Toplam Harcama', currencyFormat.format(totalGider), context.colors.textPrimary),
          Container(height: 40, width: 1, color: context.colors.border),
          _buildSummaryCardColumn(context, 'Bu Ay Harcama', currencyFormat.format(buAyHarcama), context.colors.textPrimary),
          Container(height: 40, width: 1, color: context.colors.border),
          _buildSummaryCardColumn(context, 'Kalan Bütçe', currencyFormat.format(kalanButce), context.colors.success),
        ],
      ),
    );
  }

  Widget _buildSummaryCardColumn(BuildContext context, String title, String amount, Color amountColor) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textSecondary)),
        const SizedBox(height: 8),
        Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountColor)),
      ],
    );
  }

  Widget _buildSpendingDistribution(BuildContext context, Project project, FinanceProvider fp, double totalGider) {
    final categorySpending = fp.getProjectCategorySpending(project.id!);
    
    final categoryColors = {
      'Beton': const Color(0xFF0F172A), // Dark blue from mock for chart
      'Demir': const Color(0xFF3B82F6),
      'Duvar': const Color(0xFF10B981),
      'Kalıp & İskele': const Color(0xFF8B5CF6),
      'Hafriyat': context.colors.success,
      'Elektrik': const Color(0xFFF59E0B),
      'Sıhhi Tesisat': const Color(0xFFF43F5E),
      'İşçilik': const Color(0xFFCBD5E1),
      'Genel Gider': context.colors.textSecondary,
    };

    final List<SpendingData> data = categorySpending.entries.map((e) {
      double pct = totalGider > 0 ? (e.value / totalGider) * 100 : 0;
      return SpendingData(e.key, currencyFormat.format(e.value), pct, categoryColors[e.key] ?? context.colors.brand);
    }).toList();

    // Sort data to match mock
    data.sort((a, b) => b.percentage.compareTo(a.percentage));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harcama Dağılımı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
              ),
              Row(
                children: [
                  Text('Tümünü Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.brand)),
                  Icon(Icons.chevron_right, size: 16, color: context.colors.brand),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                          Text('Toplam', style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                          Text(currencyFormat.format(totalGider), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
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
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.name, style: TextStyle(fontSize: 12, color: context.colors.textSecondary))),
                            Text(item.amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 40,
                              child: Text('%${item.percentage.toStringAsFixed(1)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textSecondary)),
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
      ),
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
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
