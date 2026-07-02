import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/views/hareket_detay_view.dart';
import 'package:hane/services/export_service.dart';

/// Bir işlem tipinin renk ve ikonunu döndürür (liste ve detay ekranı paylaşır).
({Color color, IconData icon}) transactionVisuals(BuildContext context, String type) {
  switch (type) {
    case 'Gider':
      return (color: context.colors.danger, icon: Icons.arrow_upward_rounded);
    case 'Gelir':
    case 'Tahsilat':
    case 'Satış':
      return (color: context.colors.success, icon: Icons.arrow_downward_rounded);
    case 'Transfer':
      return (color: context.colors.accent, icon: Icons.swap_horiz_rounded);
    default: // Borçlanma, Kredi Kullanımı
      return (color: context.colors.warning, icon: Icons.account_balance_rounded);
  }
}

const _incomeTypes = {'Gelir', 'Tahsilat', 'Satış'};

class HareketlerView extends StatefulWidget {
  const HareketlerView({super.key});

  @override
  State<HareketlerView> createState() => _HareketlerViewState();
}

class _HareketlerViewState extends State<HareketlerView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'Tümü';
  String _selectedProje = 'Tümü';
  String _selectedCari = 'Tümü';
  DateTimeRange? _selectedDateRange;
  String _search = '';

  final Set<int> _selectedIds = {};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  final DateFormat _dateFmt = DateFormat('d MMM yyyy', 'tr_TR');

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected(FinanceProvider fp) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemleri Sil'),
        content: Text('$count işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = List<int>.from(_selectedIds);
    setState(() => _selectedIds.clear());
    // Her biri kendi arayüzden-anında-sil + arkaplanda-senkron mantığıyla, birbirinden bağımsız işler.
    for (final id in ids) {
      fp.deleteTransaction(id);
    }
  }

  // --- Filtreleme ---
  List<FinancialTransaction> _applyFilters(
    List<FinancialTransaction> all,
    Map<int, String> projectNames,
  ) {
    return all.where((t) {
      if (_selectedFilter != 'Tümü' && t.type != _selectedFilter) return false;
      if (_selectedProje != 'Tümü') {
        final name = t.projectId != null ? projectNames[t.projectId] : null;
        if (name != _selectedProje) return false;
      }
      if (_selectedCari != 'Tümü' && t.contactName != _selectedCari) return false;
      if (_selectedDateRange != null) {
        final d = DateTime.tryParse(t.date);
        if (d == null) return false;
        final day = DateUtils.dateOnly(d);
        if (day.isBefore(DateUtils.dateOnly(_selectedDateRange!.start)) ||
            day.isAfter(DateUtils.dateOnly(_selectedDateRange!.end))) {
          return false;
        }
      }
      if (_search.isNotEmpty) {
        final hay =
            '${t.description} ${t.category} ${t.contactName} ${t.sourceName} ${t.destName}'
                .toLowerCase();
        if (!hay.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.date);
        final db = DateTime.tryParse(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da); // en yeni üstte
      });
  }

  bool get _hasActiveFilter =>
      _selectedFilter != 'Tümü' ||
      _selectedProje != 'Tümü' ||
      _selectedCari != 'Tümü' ||
      _selectedDateRange != null;

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'Tümü';
      _selectedProje = 'Tümü';
      _selectedCari = 'Tümü';
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      body: Consumer<FinanceProvider>(
        builder: (context, fp, child) {
          final projectNames = {for (final p in fp.projects) if (p.id != null) p.id!: p.name};
          final categoryOptions = ['Tümü', ...{for (final t in fp.allTransactions) t.type}];
          final projeOptions = ['Tümü', ...projectNames.values];
          final cariOptions = [
            'Tümü',
            ...{for (final t in fp.allTransactions) if (t.contactName.isNotEmpty) t.contactName}
          ];

          final filtered = _applyFilters(fp.allTransactions, projectNames);
          final toplamGelir = filtered
              .where((t) => _incomeTypes.contains(t.type))
              .fold(0.0, (s, t) => s + t.amount);
          final toplamGider = filtered
              .where((t) => t.type == 'Gider')
              .fold(0.0, (s, t) => s + t.amount);

          return Column(
            children: [
              if (_selectionMode) _buildSelectionBar(context, fp),
              const SizedBox(height: 12),
              // Arama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search_rounded, color: context.colors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: InputDecoration(
                                  hintText: 'İşlem ara...',
                                  hintStyle: TextStyle(color: context.colors.textSecondary),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildExportButton(context, filtered),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filtre kartları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterCard(
                      context,
                      Icons.calendar_today_rounded,
                      'Tarih',
                      _dateRangeLabel,
                      onTap: () => _pickDateRange(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCard(
                      context,
                      Icons.folder_open_rounded,
                      'Proje',
                      _selectedProje,
                      onTap: () => _showOptionPicker(context,
                          title: 'Proje Seç',
                          options: projeOptions,
                          current: _selectedProje,
                          onSelect: (v) => setState(() => _selectedProje = v)),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCard(
                      context,
                      Icons.sell_outlined,
                      'Kategori',
                      _selectedFilter,
                      onTap: () => _showOptionPicker(context,
                          title: 'İşlem Türü Seç',
                          options: categoryOptions,
                          current: _selectedFilter,
                          onSelect: (v) => setState(() => _selectedFilter = v)),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCard(
                      context,
                      Icons.person_outline_rounded,
                      'Cari',
                      _selectedCari,
                      onTap: () => _showOptionPicker(context,
                          title: 'Cari Seç',
                          options: cariOptions,
                          current: _selectedCari,
                          onSelect: (v) => setState(() => _selectedCari = v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Özet satırı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _hasActiveFilter
                          ? GestureDetector(
                              onTap: _clearFilters,
                              child: Row(
                                children: [
                                  Icon(Icons.close_rounded, size: 16, color: context.colors.brand),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Filtreyi Temizle',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.brand)),
                                  ),
                                ],
                              ),
                            )
                          : Text('${filtered.length} işlem',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary)),
                    ),
                    _buildSummaryItem(context, 'Gelir', toplamGelir, context.colors.success),
                    _buildSummaryItem(context, 'Gider', toplamGider, context.colors.danger),
                    _buildSummaryItem(
                        context, 'Net', toplamGelir - toplamGider, context.colors.success),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Liste
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: context.colors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              fp.allTransactions.isEmpty
                                  ? 'Henüz işlem yok'
                                  : 'Seçilen filtrelere uygun işlem yok',
                              style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ResponsiveCenter(
                        maxWidth: 820,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, i) =>
                              Divider(color: context.colors.border, height: 1),
                          itemBuilder: (context, i) =>
                              _buildTransactionItem(context, filtered[i], projectNames),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, FinanceProvider fp) {
    return Container(
      color: context.colors.brand,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: _cancelSelection,
            ),
            Expanded(
              child: Text(
                '${_selectedIds.length} seçili',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _deleteSelected(fp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, List<FinancialTransaction> filtered) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.ios_share_rounded, color: context.colors.brand),
        onSelected: (format) => _exportFiltered(context, filtered, format),
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'pdf', child: Text('PDF olarak dışa aktar')),
          PopupMenuItem(value: 'excel', child: Text('Excel olarak dışa aktar')),
        ],
      ),
    );
  }

  Future<void> _exportFiltered(BuildContext context, List<FinancialTransaction> filtered, String format) async {
    try {
      if (format == 'pdf') {
        await ExportService.exportTransactionsPdf(filtered, title: 'Hareketler');
      } else {
        await ExportService.exportTransactionsExcel(filtered, title: 'Hareketler');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarılamadı: $e')));
      }
    }
  }

  Widget _buildSummaryItem(BuildContext context, String label, double value, Color color) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          Text(currencyFormat.format(value),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, IconData icon, String title, String value,
      {VoidCallback? onTap}) {
    final bool isActive = onTap != null && value != 'Tümü';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? context.colors.brand : context.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? context.colors.brand : context.colors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                Text(value, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  String get _dateRangeLabel {
    if (_selectedDateRange == null) return 'Tümü';
    final df = DateFormat('dd.MM.yyyy');
    return '${df.format(_selectedDateRange!.start)} - ${df.format(_selectedDateRange!.end)}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  void _showOptionPicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.colors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final bool selected = option == current;
                    return ListTile(
                      title: Text(option,
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      trailing:
                          selected ? Icon(Icons.check_rounded, color: context.colors.brand) : null,
                      onTap: () {
                        onSelect(option);
                        Navigator.pop(sheetContext);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, FinancialTransaction t, Map<int, String> projectNames) {
    final visuals = transactionVisuals(context, t.type);
    final title = t.description.isNotEmpty ? t.description : t.category;
    final projectName = t.projectId != null ? projectNames[t.projectId] : null;
    final account = t.sourceName.isNotEmpty ? t.sourceName : t.destName;
    final date = DateTime.tryParse(t.date);
    final bool isSelected = t.id != null && _selectedIds.contains(t.id);

    return InkWell(
      onTap: () {
        if (_selectionMode) {
          if (t.id != null) _toggleSelection(t.id!);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HareketDetayView(transaction: t)),
        );
      },
      onLongPress: t.id == null ? null : () => _toggleSelection(t.id!),
      child: Container(
        color: isSelected ? context.colors.brand.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? context.colors.brand : context.colors.textSecondary,
                  size: 24,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: visuals.color, shape: BoxShape.circle),
                child: Icon(visuals.icon, color: Colors.white, size: 24),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.type.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: visuals.color,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                  if (t.contactName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(t.contactName,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary)),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (projectName != null) ...[
                        Icon(Icons.calendar_view_day_rounded, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(projectName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                        ),
                      ],
                      if (account.isNotEmpty) ...[
                        if (projectName != null) ...[
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: context.colors.textSecondary)),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.account_balance_rounded, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(account,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(t.amount),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: visuals.color)),
                const SizedBox(height: 4),
                Text(date != null ? _dateFmt.format(date) : t.date,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: context.colors.textSecondary, height: 1.2)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.colors.border),
          ],
        ),
      ),
    );
  }
}
