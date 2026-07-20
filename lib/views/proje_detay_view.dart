import 'dart:math';

import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/models/project_document.dart';
import 'package:hane/views/yeni_proje_view.dart';
import 'package:hane/views/yeni_islem_view.dart';
import 'package:hane/views/yeni_satis_view.dart';
import 'package:hane/views/hareket_detay_view.dart';
import 'package:hane/services/export_service.dart';
import 'package:hane/services/api_service.dart';
final dateFormat = DateFormat('dd.MM.yyyy');

class ProjeDetayView extends StatefulWidget {
  final String projectName;

  const ProjeDetayView({super.key, required this.projectName});

  @override
  State<ProjeDetayView> createState() => _ProjeDetayViewState();
}

class _ProjeDetayViewState extends State<ProjeDetayView> {
  String _selectedCategory = 'Tümü';
  bool _showAllExpenses = false;
  static const int _expenseDisplayLimit = 10;

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
        final harcamalar = projectTransactions.where((t) => t.type == 'Gider').toList()
          ..sort((a, b) {
            final da = DateTime.tryParse(a.date);
            final db = DateTime.tryParse(b.date);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da); // en yeni üstte
          });

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
        final displayedHarcamalar = _showAllExpenses
            ? filteredHarcamalar
            : filteredHarcamalar.take(_expenseDisplayLimit).toList();

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
              PopupMenuButton<String>(
                icon: Icon(Icons.ios_share_rounded, color: context.colors.textPrimary),
                onSelected: (format) =>
                    _exportProjectReport(context, project, harcamalar, fp.getProjectBudgetLines(project.id!), format),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'pdf', child: Text('PDF olarak dışa aktar')),
                  PopupMenuItem(value: 'excel', child: Text('Excel olarak dışa aktar')),
                ],
              ),
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
            padding: centeredPagePadding(context, maxContentWidth: 900, horizontal: 16, top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context, project),
                const SizedBox(height: 16),
                _buildProjectDetailsCard(context, project),
                const SizedBox(height: 24),
                _buildHarcamalarHeader(context, project.name),
                const SizedBox(height: 16),
                _buildFilterChips(context, categories),
                const SizedBox(height: 16),
                _buildExpenditureList(context, displayedHarcamalar),
                if (filteredHarcamalar.length > _expenseDisplayLimit)
                  _buildShowMoreButton(context),
                const SizedBox(height: 24),
                _buildSummaryCards(context, totalGider, buAyHarcama, kalanButce),
                const SizedBox(height: 32),
                _buildSpendingDistribution(context, project, fp, totalGider),
                const SizedBox(height: 32),
                _buildSalesSection(context, fp, project),
                const SizedBox(height: 32),
                _buildDocumentsSection(context, fp, project),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportProjectReport(
    BuildContext context,
    Project project,
    List<FinancialTransaction> harcamalar,
    List<BudgetLine> budgetLines,
    String format,
  ) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportProjectCostReportPdf(project.name, harcamalar, budgetLines);
      } else {
        await ExportService.exportProjectCostReportExcel(project.name, harcamalar, budgetLines);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarılamadı: $e')));
      }
    }
  }

  bool _categoriesContains(String cat, List<String> cats) {
      return cats.contains(cat);
  }

  Widget _buildHeroCard(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          // Project Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: project.imagePath != null
                ? Image.network(
                    project.imagePath!.startsWith('/media') ? '${ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${project.imagePath}' : project.imagePath!,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/modern_apartment_building.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 18),
          // Details + Stats
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Details
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.projectCode.isNotEmpty ? project.projectCode : '—',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 15, color: context.colors.textSecondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              project.location.isNotEmpty ? project.location : '-',
                              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.home_work_outlined, size: 15, color: context.colors.textSecondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              project.projectType.isNotEmpty ? project.projectType : '-',
                              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Expanded(
                  flex: 8,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildProjectStatItem(context, 'Pafta', project.pafta.isNotEmpty ? project.pafta : '-'),
                      _buildProjectStatItem(context, 'Parsel', project.parsel.isNotEmpty ? project.parsel : '-'),
                      _buildProjectStatItem(context, 'Alan (m²)', currencyFormat.format(project.areaSqMeters).replaceAll('₺', '').trim()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard(BuildContext context, Project project) {
    final hasDescription = project.description.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJE DETAYLARI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildProjectStatItem(context, 'Bağımsız Bölüm', project.totalIndependentSections > 0 ? '${project.totalIndependentSections}' : '-'),
              _buildProjectStatItem(context, 'Konut Sayısı', project.unitCount > 0 ? '${project.unitCount}' : '-'),
              _buildProjectStatItem(context, 'İşyeri Sayısı', project.shopCount > 0 ? '${project.shopCount}' : '-'),
              _buildProjectStatItem(context, 'Başlangıç Tarihi', project.startDate.isNotEmpty ? project.startDate : '-'),
              _buildProjectStatItem(context, 'Tahmini Bitiş', project.endDate.isNotEmpty ? project.endDate : '-'),
              _buildProjectStatItem(context, 'Öngörülen Gelir', currencyFormat.format(project.estimatedTotalRevenue)),
            ],
          ),
          if (hasDescription) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: 16),
            Text(
              'AÇIKLAMA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.description,
              style: TextStyle(fontSize: 13, color: context.colors.textPrimary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
                  onBack: () => Navigator.pop(context),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Yeni Harcama Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.brand,
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
              showCheckmark: false,
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.colors.textPrimary,
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
              selectedColor: context.colors.brand,
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

  /// Harcama listesinin hemen altına yapışık, yuvarlak "daha fazla/az göster" butonu.
  Widget _buildShowMoreButton(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Center(
        child: Material(
          color: context.colors.surface,
          shape: CircleBorder(side: BorderSide(color: context.colors.border)),
          elevation: 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _showAllExpenses = !_showAllExpenses),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedRotation(
                turns: _showAllExpenses ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.brand, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Web panelindeki `categoryIcon()` ile aynı eşleme.
  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beton':
      case 'nakliye':
        return Icons.local_shipping_outlined;
      case 'demir':
        return Icons.grid_4x4_outlined;
      case 'duvar':
        return Icons.view_column_outlined;
      case 'elektrik':
        return Icons.bolt_outlined;
      case 'sıhhi tesisat':
        return Icons.water_drop_outlined;
      case 'işçilik':
        return Icons.engineering_outlined;
      case 'kalıp':
        return Icons.construction_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  Widget _buildExpenditureList(BuildContext context, List<FinancialTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text("Bu kategoriye ait harcama bulunamadı.", style: TextStyle(color: Colors.grey))),
      );
    }

    // Web panelindeki `.expense-table` ile aynı: tek bir çerçeve içinde,
    // satırlar arası ince ayraçlarla ayrılan birleşik liste (kart-içinde-kart değil).
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: context.colors.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('KATEGORİ', style: _headerStyle(context))),
                Expanded(flex: 3, child: Text('AÇIKLAMA', style: _headerStyle(context))),
                Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('TUTAR', style: _headerStyle(context)))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TARİH', style: _headerStyle(context)))),
                const SizedBox(width: 20), // Ok ikonu için
              ],
            ),
          ),
          for (var index = 0; index < transactions.length; index++) ...[
            if (index > 0) Divider(height: 1, color: context.colors.border),
            Builder(builder: (context) {
              final t = transactions[index];
              DateTime? date = DateTime.tryParse(t.date);
              final dateStr = date != null ? dateFormat.format(date) : t.date;

              // Extract description and quantity
              String desc = t.description;
              if (desc.contains(' • ')) {
                final parts = desc.split(' • ');
                desc = parts.length >= 3 ? parts.sublist(2).join(' • ') : (parts.length == 2 ? parts[1] : desc);
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HareketDetayView(transaction: t),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // KATEGORİ
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_categoryIcon(t.category), size: 16, color: context.colors.textPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.category,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // AÇIKLAMA
                      Expanded(
                        flex: 3,
                        child: Text(
                          desc.isNotEmpty ? desc : '-',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // TUTAR
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormat.format(t.amount),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary),
                        ),
                      ),
                      // TARİH
                      Expanded(
                        flex: 2,
                        child: Text(
                          dateStr,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: context.colors.textSecondary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: context.colors.textSecondary,
    );
  }

  Widget _buildSummaryCards(BuildContext context, double totalGider, double buAyHarcama, double kalanButce) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryCardColumn(context, 'Toplam Harcama', currencyFormat.format(totalGider), context.colors.textPrimary),
          _buildSummaryCardColumn(context, 'Bu Ay Harcama', currencyFormat.format(buAyHarcama), context.colors.textPrimary),
          _buildSummaryCardColumn(context, 'Kalan Bütçe', currencyFormat.format(kalanButce), const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildSummaryCardColumn(BuildContext context, String title, String amount, Color amountColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingDistribution(BuildContext context, Project project, FinanceProvider fp, double totalGider) {
    final categorySpending = fp.getProjectCategorySpending(project.id!);
    
    // Web panelindeki (ProjectDetail.jsx) ile aynı palet: bilinen kategoriler sabit
    // renkte, tanınmayanlar (örn. serbest metin girilmiş kategoriler) birbirinden
    // ayırt edilebilsin diye sırayla bu yedek paletten renk alır.
    final categoryColors = {
      'Beton': const Color(0xFF0F172A),
      'Demir': const Color(0xFF3B82F6),
      'Duvar': const Color(0xFF10B981),
      'Kalıp & İskele': const Color(0xFF8B5CF6),
      'Hafriyat': const Color(0xFF10B981),
      'Elektrik': const Color(0xFFF59E0B),
      'Sıhhi Tesisat': const Color(0xFFF43F5E),
      'İşçilik': const Color(0xFFCBD5E1),
      'Genel Gider': const Color(0xFF64748B),
    };
    const fallbackColors = [
      Color(0xFF032B5E),
      Color(0xFF6366F1),
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFFEC4899),
      Color(0xFF84CC16),
    ];

    var fallbackIndex = 0;
    final List<SpendingData> data = categorySpending.entries.map((e) {
      double pct = totalGider > 0 ? (e.value / totalGider) * 100 : 0;
      final color = categoryColors[e.key] ?? fallbackColors[fallbackIndex++ % fallbackColors.length];
      return SpendingData(e.key, currencyFormat.format(e.value), pct, color);
    }).toList();

    // En yüksek harcamadan en düşüğe sırala.
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
          Text(
            'Harcama Dağılımı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 24),
          if (data.isEmpty)
            const Text("Harcama verisi bulunamadı.", style: TextStyle(color: Colors.grey))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
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
                ),
                const SizedBox(height: 24),
                Column(
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
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSalesSection(BuildContext context, FinanceProvider fp, Project project) {
    final sales = fp.sales.where((s) => s.projectId == project.id).toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SATIŞLAR',
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
                    builder: (context) => YeniSatisView(projectId: project.id!, projectName: project.name),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Yeni Satış Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (sales.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text('Bu projeye ait satış bulunamadı.', style: TextStyle(color: context.colors.textSecondary)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < sales.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.border),
                  _buildSaleRow(context, fp, sales[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaleRow(BuildContext context, FinanceProvider fp, Sale sale) {
    const unitTypeLabels = {'apartment': 'Daire', 'shop': 'Dükkan', 'land': 'Arsa', 'other': 'Diğer'};
    final buyer = sale.buyerId == null
        ? null
        : fp.contacts.where((c) => c.id == sale.buyerId).firstOrNull;
    final title = '${unitTypeLabels[sale.unitType] ?? sale.unitType}${sale.unitNo.isNotEmpty ? ' ${sale.unitNo}' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary)),
                if (buyer != null)
                  Text(buyer.name, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                if (sale.installmentCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.accentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sale.installmentCount} Taksit',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.accent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(sale.salePrice),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary)),
                Text(
                  sale.remaining > 0 ? 'Kalan: ${currencyFormat.format(sale.remaining)}' : 'Tahsil Edildi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sale.remaining > 0 ? context.colors.danger : context.colors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, FinanceProvider fp, Project project) {
    final documents = fp.getProjectDocuments(project.id!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BELGELER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () => _pickAndUploadDocument(context, fp, project),
              icon: Icon(Icons.upload_file_rounded, size: 16, color: context.colors.brand),
              label: Text('Belge Ekle',
                  style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            alignment: Alignment.center,
            child: Text('Henüz belge eklenmedi.', style: TextStyle(color: context.colors.textSecondary)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documents.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, i) => _buildDocumentCard(context, fp, documents[i]),
          ),
      ],
    );
  }

  static bool _isImageUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  Widget _buildDocumentCard(BuildContext context, FinanceProvider fp, ProjectDocument doc) {
    final isImage = _isImageUrl(doc.fileUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: doc.fileUrl == null ? null : () => launchUrl(Uri.parse(doc.fileUrl!), mode: LaunchMode.externalApplication),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: context.colors.scaffold,
                    child: isImage
                        ? Image.network(
                            doc.fileUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                Icon(Icons.description_outlined, size: 40, color: context.colors.brand),
                          )
                        : Icon(Icons.description_outlined, size: 40, color: context.colors.brand),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _confirmDeleteDocument(context, fp, doc),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _renameDocument(context, fp, doc),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.name.isNotEmpty ? doc.name : 'Belge',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.edit_outlined, size: 12, color: context.colors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDocument(BuildContext context, FinanceProvider fp, ProjectDocument doc) async {
    final controller = TextEditingController(text: doc.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belge Adını Değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Belge adı'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == doc.name) return;
    await fp.renameProjectDocument(doc.id!, newName);
  }

  Future<void> _pickAndUploadDocument(BuildContext context, FinanceProvider fp, Project project) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    try {
      await fp.addProjectDocument(project.id!, file.name, file.path!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belge yüklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteDocument(BuildContext context, FinanceProvider fp, ProjectDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('"${doc.name}" belgesini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed == true && doc.id != null) {
      await fp.deleteProjectDocument(doc.id!);
    }
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
    // Web panelindeki (recharts innerRadius=54/outerRadius=72) ile aynı oranda
    // ince bir halka; segmentler arasında web'deki `paddingAngle` gibi
    // küçük bir boşluk bırakılır (düz uçlu segmentler, yuvarlak uç yok).
    final strokeWidth = radius * 0.25;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final visibleCount = data.where((d) => d.percentage > 0).length;
    final gap = visibleCount > 1 ? (2 * pi / 180) : 0.0; // ~2 derece

    double startAngle = -pi / 2;

    for (var item in data) {
      if (item.percentage == 0) continue;

      final sweepAngle = (item.percentage / 100) * 2 * pi - gap;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
