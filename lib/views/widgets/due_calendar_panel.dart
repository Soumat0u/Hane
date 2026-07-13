import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/tekrarlanan_islemler_view.dart' show showRecurringTransactionForm;

/// Yaklaşan/vadesi dolan borç ÖDEMELERİ ve alacak/tahsilat kalemlerini birlikte
/// gösteren takvim paneli. Eskiden Borçlar ekranındaydı; Genel Bakış'a taşındı.
class DueCalendarPanel extends StatefulWidget {
  const DueCalendarPanel({super.key});

  @override
  State<DueCalendarPanel> createState() => _DueCalendarPanelState();
}

class _DueCalendarPanelState extends State<DueCalendarPanel> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        final items = fp.getAllDuePayments();

        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final selectedOnly = _selectedDay != null
            ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
            : null;
        final isPastSelected = selectedOnly != null && selectedOnly.isBefore(todayOnly);

        List<DuePayment> displayedItems;
        if (isPastSelected) {
          displayedItems = items.where((p) => p.date != null && isSameDay(p.date, selectedOnly)).toList();
        } else {
          final forDay = selectedOnly != null
              ? items.where((p) => p.date != null && isSameDay(p.date, selectedOnly)).toList()
              : <DuePayment>[];
          if (forDay.isNotEmpty) {
            displayedItems = forDay;
          } else {
            final nextWeek = todayOnly.add(const Duration(days: 7));
            displayedItems = items.where((p) => p.date != null && !p.date!.isBefore(todayOnly) && !p.date!.isAfter(nextWeek)).toList();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'VADESİ DOLAN VE YAKLAŞAN ÖDEME/ALACAKLAR',
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
                      return items.where((p) => p.date != null && isSameDay(p.date, day)).toList();
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
                        color: context.colors.brand,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: context.colors.brand.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: context.colors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: displayedItems.isEmpty
                          ? <Widget>[
                              Text(
                                isPastSelected ? 'Bu tarihte geçmiş bir kayıt bulunmuyor.' : 'Yaklaşan ödeme/alacak bulunmuyor.',
                                style: TextStyle(color: context.colors.textSecondary),
                              ),
                            ]
                          : displayedItems
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildItem(context, fp, p),
                                  ))
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, FinanceProvider fp, DuePayment p) {
    final color = p.isPayable ? context.colors.danger : context.colors.success;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            p.rawDate,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              if (p.isUpcomingRecurring) ...[
                Icon(Icons.repeat_rounded, size: 14, color: context.colors.brand),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  p.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${p.isPayable ? '-' : '+'}${currencyFormat.format(p.amount)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
    if (!p.isUpcomingRecurring) return row;
    return InkWell(
      onTap: () {
        final template = fp.recurringTransactions.where((r) => r.id == p.recurringTemplateId).firstOrNull;
        if (template != null) showRecurringTransactionForm(context, existing: template);
      },
      child: row,
    );
  }
}
