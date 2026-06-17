import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_panel.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/yeni_islem_view.dart';
import 'package:table_calendar/table_calendar.dart';

final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class BorclarView extends StatefulWidget {
  const BorclarView({super.key});

  @override
  State<BorclarView> createState() => _BorclarViewState();
}

class _BorclarViewState extends State<BorclarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Borçlar', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final borclarSection = fp.borclarSection;
            final borclarTotal = fp.getTotalBorc();
            
            // Extract groups safely
            final bankaBorclari = borclarSection.groups.firstWhere((g) => g.title == 'Banka Borçları', orElse: () => PanelGroup('Banka Borçları', [])).items;
            final ticariBorclar = borclarSection.groups.firstWhere((g) => g.title == 'Ticari Borçlar', orElse: () => PanelGroup('Ticari Borçlar', [])).items;
            final cekler = borclarSection.groups.firstWhere((g) => g.title == 'Çekler', orElse: () => PanelGroup('Çekler', [])).items;
            
            final payments = fp.getUpcomingPayments();
            
            // Eğer kullanıcı takvimden bir gün seçtiyse sadece o günkü ödemeleri göster,
            // değilse (tümünü görmek istiyorsa) vadesi yaklaşan ve geçmiş ilk 10 ödemeyi göster.
            // Başlangıçta _selectedDay bugüne eşittir. Eğer bugün ödeme yoksa, genel listeyi göstermek daha mantıklı olabilir.
            var displayedPayments = payments.where((p) => p.date != null && isSameDay(p.date, _selectedDay)).toList();
            if (displayedPayments.isEmpty) {
              displayedPayments = payments.take(10).toList(); // Seçili günde ödeme yoksa yaklaşan 10 ödemeyi göster
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Total Borç Card (Red)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<AppColors>()!.danger,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).extension<AppColors>()!.danger.withOpacity(0.3),
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
                              'TOPLAM BORÇ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(borclarTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(Icons.assignment_rounded, color: Colors.white.withAlpha(160), size: 48),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BANKA BORÇLARI
                  _buildSectionHeader(context, 'BANKA BORÇLARI', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, bankaBorclari.map((item) => 
                    _ListItemData(name: item.name, value: item.amount, icon: Icons.account_balance_wallet_rounded, isBank: true)
                  ).toList()),
                  const SizedBox(height: 24),

                  // TİCARİ BORÇLAR
                  _buildSectionHeader(context, 'TİCARİ BORÇLAR', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, ticariBorclar.map((item) => 
                    _ListItemData(name: item.name, value: item.amount, icon: Icons.engineering_rounded, isBank: false)
                  ).toList()),
                  const SizedBox(height: 24),

                  // ÇEKLER
                  _buildSectionHeader(context, 'ÇEKLER', onNewTap: () {
                    _showNewTransaction(context);
                  }),
                  _buildGroupList(context, cekler.map((item) => 
                    _ListItemData(name: item.name, value: item.amount, icon: Icons.receipt_long_rounded, isBank: false)
                  ).toList()),
                  const SizedBox(height: 24),

                  // VADESİ DOLAN VE YAKLAŞAN ÖDEMELER
                  Text(
                    'VADESİ DOLAN VE YAKLAŞAN ÖDEMELER',
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: (day) {
                            return payments.where((p) => p.date != null && isSameDay(p.date, day)).toList();
                          },
                          calendarFormat: CalendarFormat.month,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            leftChevronIcon: Icon(Icons.chevron_left, color: context.colors.textPrimary),
                            rightChevronIcon: Icon(Icons.chevron_right, color: context.colors.textPrimary),
                          ),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).extension<AppColors>()!.danger,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Theme.of(context).extension<AppColors>()!.danger.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: Theme.of(context).extension<AppColors>()!.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: displayedPayments.isEmpty 
                              ? <Widget>[const Text('Yaklaşan ödeme bulunmuyor.')]
                              : displayedPayments.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildPaymentItem(context, p.rawDate, p.title, p.amount),
                                )).cast<Widget>().toList(),
                          ),
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
      body: YeniIslemScreen(initialType: 'Borçlanma', onBack: () => Navigator.pop(context)),
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

  Widget _buildGroupList(BuildContext context, List<_ListItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Kayıt bulunamadı.')),
            )
          : Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildListItem(
                  context: context,
                  item: item,
                  isLast: idx == items.length - 1,
                  isFirst: idx == 0,
                ),
                if (idx < items.length - 1)
                  Divider(height: 1, indent: 64, color: context.colors.surfaceVariant),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required _ListItemData item,
    bool isLast = false,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
        topRight: isFirst ? const Radius.circular(16) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.scaffold,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4.0),
              child: Icon(item.icon, color: context.colors.brand, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Text(
              currencyFormat.format(item.value),
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

  Widget _buildPaymentItem(BuildContext context, String date, String title, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).extension<AppColors>()!.danger,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        Text(
          currencyFormat.format(amount),
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

class _ListItemData {
  final String name;
  final double value;
  final IconData icon;
  final bool isBank;

  _ListItemData({required this.name, required this.value, required this.icon, required this.isBank});
}
