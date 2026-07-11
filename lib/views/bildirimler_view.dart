import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/recurring_transaction.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/views/tekrarlanan_islemler_view.dart' show showRecurringTransactionForm;

class BildirimlerView extends StatelessWidget {
  const BildirimlerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        final notifications = fp.getAllDuePayments();
        final dueTemplates = fp.getDueRecurringTemplates();
        final totalCount = dueTemplates.length + notifications.length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: context.colors.scaffold,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 5),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  color: context.colors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Bildirimler',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (fp.hasUnreadNotifications)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              fp.markAllNotificationsRead();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tümü okundu olarak işaretlendi.')),
                              );
                            },
                            child: Text('Tümünü Oku', style: TextStyle(color: context.colors.brand, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: context.colors.border),
                Expanded(
                  child: totalCount == 0
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: totalCount,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index < dueTemplates.length) {
                              return _buildRecurringCard(context, fp, dueTemplates[index]);
                            }
                            final notif = notifications[index - dueTemplates.length];
                            final isOverdue = notif.isOverdue;
                            final isPayable = notif.isPayable;
                            final isRead = fp.isNotificationRead(notif);
                            
                            // Determine colors and icons based on payment type and overdue status
                            Color iconColor = isPayable ? context.colors.danger : context.colors.success;
                            Color bgColor = isPayable ? context.colors.dangerBg : context.colors.successBg;
                            IconData icon = isPayable ? Icons.payment_outlined : Icons.account_balance_wallet_outlined;

                            if (isOverdue) {
                              iconColor = context.colors.warning;
                              bgColor = context.colors.warningBg;
                              icon = Icons.warning_amber_rounded;
                            }

                            if (notif.isUpcomingRecurring) {
                              iconColor = context.colors.accent;
                              bgColor = context.colors.accentBg;
                              icon = Icons.repeat_rounded;
                            }

                            return Opacity(
                              opacity: isRead ? 0.55 : 1.0,
                              child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.colors.border,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: iconColor, size: 22),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (!isRead) ...[
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: context.colors.brand,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        notif.isUpcomingRecurring
                                            ? 'Yaklaşan Tekrarlayan İşlem'
                                            : (isPayable ? 'Yaklaşan Ödeme' : 'Yaklaşan Tahsilat'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      notif.rawDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOverdue ? context.colors.danger : context.colors.textSecondary,
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    '${notif.title} için ${currencyFormat.format(notif.amount)} tutarında işlem bekleniyor.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.colors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  fp.markNotificationRead(notif);
                                  if (notif.recurringTemplateId != null) {
                                    final template = fp.recurringTransactions
                                        .where((r) => r.id == notif.recurringTemplateId)
                                        .firstOrNull;
                                    if (template != null) {
                                      showRecurringTransactionForm(context, existing: template);
                                    }
                                  }
                                },
                              ),
                            ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurringCard(BuildContext context, FinanceProvider fp, RecurringTransaction r) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showRecurringTransactionForm(context, existing: r),
      child: Container(
      decoration: BoxDecoration(
        color: context.colors.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded, color: context.colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.description.isNotEmpty ? r.description : r.category,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colors.textPrimary),
                ),
              ),
              Text(currencyFormat.format(r.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Tekrarlanan ${r.intervalLabel.toLowerCase()} işlem — vadesi ${r.nextDueDate}',
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await fp.confirmRecurringTransaction(r);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('İşlem oluşturuldu.')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Onaylanamadı: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.brand,
                foregroundColor: context.colors.surface,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Onayla ve Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hiç bildiriminiz yok.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yaklaşan ödeme veya tahsilat vadeniz\nbulunmuyor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
