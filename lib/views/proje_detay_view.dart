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
import 'package:hane/views/hareket_detay_view.dart';
import 'package:hane/services/export_service.dart';
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
            child: Image.asset(
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        ],
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
                          Text(
                            project.projectType.isNotEmpty ? project.projectType : '-',
                            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProjectStatItem(context, 'Pafta', project.pafta.isNotEmpty ? project.pafta : '-'),
                    const SizedBox(width: 18),
                    _buildProjectStatItem(context, 'Parsel', project.parsel.isNotEmpty ? project.parsel : '-'),
                    const SizedBox(width: 18),
                    _buildProjectStatItem(context, 'Alan (m²)', currencyFormat.format(project.areaSqMeters).replaceAll('₺', '').trim()),
                  ],
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('KATEGORİ', style: _headerStyle(context))),
              Expanded(flex: 4, child: Text('AÇIKLAMA / MİKTAR', style: _headerStyle(context))),
              Expanded(flex: 3, child: Text('TEDARİKÇİ', style: _headerStyle(context))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TUTAR', style: _headerStyle(context)))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TARİH', style: _headerStyle(context)))),
              const SizedBox(width: 24), // For arrow icon
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final t = transactions[index];
            DateTime? date = DateTime.tryParse(t.date);
            final dateStr = date != null ? dateFormat.format(date) : t.date;

            // Extract description and quantity
            String desc = t.description;
            String qty = '';
            if (desc.contains(' • ')) {
              final parts = desc.split(' • ');
              if (parts.length >= 3) {
                qty = parts[1];
                desc = parts.sublist(2).join(' • ');
              } else if (parts.length == 2) {
                desc = parts[1];
              }
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HareketDetayView(transaction: t),
                  ),
                );
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  // KATEGORI
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.category,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // AÇIKLAMA / MİKTAR
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desc.isNotEmpty ? desc : '-',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (qty.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            qty.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: context.colors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // TEDARİKÇİ
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.contactName.isNotEmpty ? t.contactName : '-',
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // TUTAR / TARİH
                  Expanded(
                    flex: 4, // combined flex of TUTAR and TARİH
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(t.amount),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 10, color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 16, color: context.colors.textSecondary),
                ],
              ),
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
    
    final categoryColors = {
      'Beton': const Color(0xFF0F172A),
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
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < documents.length; i++) ...[
                  _buildDocumentRow(context, fp, documents[i]),
                  if (i < documents.length - 1) Divider(height: 1, indent: 16, color: context.colors.surfaceVariant),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentRow(BuildContext context, FinanceProvider fp, ProjectDocument doc) {
    return InkWell(
      onTap: doc.fileUrl == null ? null : () => launchUrl(Uri.parse(doc.fileUrl!), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 20, color: context.colors.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                doc.name.isNotEmpty ? doc.name : 'Belge',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.textSecondary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmDeleteDocument(context, fp, doc),
            ),
          ],
        ),
      ),
    );
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
