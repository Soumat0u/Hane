double _toDouble(dynamic v) => (v ?? 0).toDouble();

/// Tekrarlayan işlem şablonu: vadesi geldiğinde kullanıcı onayıyla gerçek
/// bir FinancialTransaction'a dönüştürülür (otomatik oluşturma yok).
class RecurringTransaction {
  static const weekly = 'weekly';
  static const monthly = 'monthly';

  final int? id;
  final String type; // Gelir, Gider, Tahsilat...
  final double amount;
  final String category;
  final String description;
  final int? projectId;
  final int? contactId;
  final int? fromAccountId;
  final int? toAccountId;
  final String interval; // weekly, monthly
  final int dayOfMonth;
  final String nextDueDate;
  final bool isActive;

  RecurringTransaction({
    this.id,
    required this.type,
    this.amount = 0.0,
    this.category = '',
    this.description = '',
    this.projectId,
    this.contactId,
    this.fromAccountId,
    this.toAccountId,
    this.interval = monthly,
    this.dayOfMonth = 1,
    required this.nextDueDate,
    this.isActive = true,
  });

  factory RecurringTransaction.fromMap(Map<String, dynamic> m) => RecurringTransaction(
        id: m['id'],
        type: m['type'] ?? 'Gider',
        amount: _toDouble(m['amount']),
        category: m['category'] ?? '',
        description: m['description'] ?? '',
        projectId: m['project'],
        contactId: m['contact'],
        fromAccountId: m['from_account'],
        toAccountId: m['to_account'],
        interval: m['interval'] ?? monthly,
        dayOfMonth: m['day_of_month'] ?? 1,
        nextDueDate: m['next_due_date'] ?? '',
        isActive: m['is_active'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'project': projectId,
        'contact': contactId,
        'from_account': fromAccountId,
        'to_account': toAccountId,
        'interval': interval,
        'day_of_month': dayOfMonth,
        'next_due_date': nextDueDate,
        'is_active': isActive,
      };

  String get intervalLabel => interval == weekly ? 'Haftalık' : 'Aylık';
}
