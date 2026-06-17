// Backend'deki Loan, Cheque, Sale, Receivable, Contact modellerinin Dart karşılıkları.
// Hepsi read-ağırlıklı; panel ve listeleme ekranlarında kullanılır.

double _toDouble(dynamic v) => (v ?? 0).toDouble();

/// Vadesi olan bir ödeme/tahsilat kalemi (takvim ve bildirimler için).
class DuePayment {
  final String title;
  final double amount;
  final DateTime? date; // ayrıştırılamadıysa null
  final String rawDate;
  final bool isPayable; // true = ödeme (borç), false = tahsilat (alacak)

  DuePayment({
    required this.title,
    required this.amount,
    required this.date,
    required this.rawDate,
    required this.isPayable,
  });

  bool get isOverdue =>
      date != null && date!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
}

/// Gelir/gider kategorisi. Ana kategori (parentId == null) veya alt kategori.
class Category {
  final int? id;
  final String name;
  final String type; // cost, income
  final String group; // ana kategori grubu (Malzeme, Proje Masrafı...)
  final int? parentId; // alt kategoriyse ana kategorinin id'si
  final int childCount; // ana kategorinin alt kategori sayısı

  Category({
    this.id,
    required this.name,
    this.type = 'cost',
    this.group = '',
    this.parentId,
    this.childCount = 0,
  });

  bool get isIncome => type == 'income';
  bool get isCost => type == 'cost';
  bool get isMain => parentId == null;

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'],
        name: m['name'] ?? '',
        type: m['type'] ?? 'cost',
        group: m['group'] ?? '',
        parentId: m['parent'],
        childCount: m['child_count'] ?? 0,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'type': type, 'group': group, 'parent': parentId};
}

/// Cari hesap (tedarikçi, müşteri, taşeron, devlet).
class Contact {
  final int? id;
  final String name;
  final String kind; // supplier, customer, subcontractor, government, bank, other
  final String phone;
  final String email;
  final String taxNumber;
  final String note;
  final double balance; // backend türetir: + bizim borcumuz, − bizden alacak

  Contact({
    this.id,
    required this.name,
    this.kind = 'other',
    this.phone = '',
    this.email = '',
    this.taxNumber = '',
    this.note = '',
    this.balance = 0.0,
  });

  factory Contact.fromMap(Map<String, dynamic> m) => Contact(
        id: m['id'],
        name: m['name'] ?? '',
        kind: m['kind'] ?? 'other',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        taxNumber: m['tax_number'] ?? '',
        note: m['note'] ?? '',
        balance: _toDouble(m['balance']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'kind': kind,
        'phone': phone,
        'email': email,
        'tax_number': taxNumber,
        'note': note,
      };
}

/// Vadeli banka borcu (Kredi / KGF).
class Loan {
  final int? id;
  final String name;
  final String kind; // loan, kgf, other
  final int? creditorId;
  final String bankName;
  final double principal;
  final double totalPayable;
  final double paidAmount;
  final double remaining;
  final double interestRate;
  final int termMonths;
  final String currency;
  final String startDate;
  final bool isActive;

  Loan({
    this.id,
    required this.name,
    this.kind = 'loan',
    this.creditorId,
    this.bankName = '',
    this.principal = 0.0,
    this.totalPayable = 0.0,
    this.paidAmount = 0.0,
    this.remaining = 0.0,
    this.interestRate = 0.0,
    this.termMonths = 0,
    this.currency = 'TRY',
    this.startDate = '',
    this.isActive = true,
  });

  factory Loan.fromMap(Map<String, dynamic> m) => Loan(
        id: m['id'],
        name: m['name'] ?? '',
        kind: m['kind'] ?? 'loan',
        creditorId: m['creditor'],
        bankName: m['bank_name'] ?? '',
        principal: _toDouble(m['principal']),
        totalPayable: _toDouble(m['total_payable']),
        paidAmount: _toDouble(m['paid_amount']),
        remaining: _toDouble(m['remaining']),
        interestRate: _toDouble(m['interest_rate']),
        termMonths: m['term_months'] ?? 0,
        currency: m['currency'] ?? 'TRY',
        startDate: m['start_date'] ?? '',
        isActive: m['is_active'] ?? true,
      );

  // remaining backend'de türetilir; yazarken gönderilmez.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'kind': kind,
        'creditor': creditorId,
        'bank_name': bankName,
        'principal': principal,
        'total_payable': totalPayable,
        'paid_amount': paidAmount,
        'interest_rate': interestRate,
        'term_months': termMonths,
        'currency': currency,
        'start_date': startDate,
        'is_active': isActive,
      };
}

/// Çek (alınan / verilen).
class Cheque {
  final int? id;
  final String direction; // received, issued
  final String status; // portfolio, deposited, cashed, given, bounced
  final double amount;
  final String currency;
  final String dueDate;
  final String bankName;
  final String serialNo;
  final int? contactId;
  final int? projectId;

  Cheque({
    this.id,
    this.direction = 'received',
    this.status = 'portfolio',
    this.amount = 0.0,
    this.currency = 'TRY',
    this.dueDate = '',
    this.bankName = '',
    this.serialNo = '',
    this.contactId,
    this.projectId,
  });

  bool get isIssued => direction == 'issued';
  bool get isReceived => direction == 'received';

  factory Cheque.fromMap(Map<String, dynamic> m) => Cheque(
        id: m['id'],
        direction: m['direction'] ?? 'received',
        status: m['status'] ?? 'portfolio',
        amount: _toDouble(m['amount']),
        currency: m['currency'] ?? 'TRY',
        dueDate: m['due_date'] ?? '',
        bankName: m['bank_name'] ?? '',
        serialNo: m['serial_no'] ?? '',
        contactId: m['contact'],
        projectId: m['project'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'direction': direction,
        'status': status,
        'amount': amount,
        'currency': currency,
        'due_date': dueDate,
        'bank_name': bankName,
        'serial_no': serialNo,
        'contact': contactId,
        'project': projectId,
      };
}

/// Satış sözleşmesi (daire / dükkan / arsa).
class Sale {
  final int? id;
  final int? projectId;
  final int? buyerId;
  final String unitType; // apartment, shop, land, other
  final String unitNo;
  final double salePrice;
  final double collected;
  final double remaining;
  final String currency;
  final String saleDate;
  final bool isCompleted;

  Sale({
    this.id,
    this.projectId,
    this.buyerId,
    this.unitType = 'apartment',
    this.unitNo = '',
    this.salePrice = 0.0,
    this.collected = 0.0,
    this.remaining = 0.0,
    this.currency = 'TRY',
    this.saleDate = '',
    this.isCompleted = false,
  });

  factory Sale.fromMap(Map<String, dynamic> m) => Sale(
        id: m['id'],
        projectId: m['project'],
        buyerId: m['buyer'],
        unitType: m['unit_type'] ?? 'apartment',
        unitNo: m['unit_no'] ?? '',
        salePrice: _toDouble(m['sale_price']),
        collected: _toDouble(m['collected']),
        remaining: _toDouble(m['remaining']),
        currency: m['currency'] ?? 'TRY',
        saleDate: m['sale_date'] ?? '',
        isCompleted: m['is_completed'] ?? false,
      );

  // collected / remaining backend'de türetilir; yazarken gönderilmez.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'project': projectId,
        'buyer': buyerId,
        'unit_type': unitType,
        'unit_no': unitNo,
        'sale_price': salePrice,
        'currency': currency,
        'sale_date': saleDate,
        'is_completed': isCompleted,
      };
}

/// Alacak / taksit kaydı.
class Receivable {
  final int? id;
  final String kind; // installment, customer, government, retention, other
  final String status; // pending, partial, collected, overdue
  final int? contactId;
  final int? projectId;
  final int? saleId;
  final double totalAmount;
  final double collectedAmount;
  final double remaining;
  final String currency;
  final String dueDate;
  final String description;

  Receivable({
    this.id,
    this.kind = 'customer',
    this.status = 'pending',
    this.contactId,
    this.projectId,
    this.saleId,
    this.totalAmount = 0.0,
    this.collectedAmount = 0.0,
    this.remaining = 0.0,
    this.currency = 'TRY',
    this.dueDate = '',
    this.description = '',
  });

  factory Receivable.fromMap(Map<String, dynamic> m) => Receivable(
        id: m['id'],
        kind: m['kind'] ?? 'customer',
        status: m['status'] ?? 'pending',
        contactId: m['contact'],
        projectId: m['project'],
        saleId: m['sale'],
        totalAmount: _toDouble(m['total_amount']),
        collectedAmount: _toDouble(m['collected_amount']),
        remaining: _toDouble(m['remaining']),
        currency: m['currency'] ?? 'TRY',
        dueDate: m['due_date'] ?? '',
        description: m['description'] ?? '',
      );

  // remaining backend'de türetilir; yazarken gönderilmez.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'kind': kind,
        'status': status,
        'contact': contactId,
        'project': projectId,
        'sale': saleId,
        'total_amount': totalAmount,
        'collected_amount': collectedAmount,
        'currency': currency,
        'due_date': dueDate,
        'description': description,
      };

  Receivable copyWith({double? collectedAmount, String? status}) => Receivable(
        id: id,
        kind: kind,
        status: status ?? this.status,
        contactId: contactId,
        projectId: projectId,
        saleId: saleId,
        totalAmount: totalAmount,
        collectedAmount: collectedAmount ?? this.collectedAmount,
        currency: currency,
        dueDate: dueDate,
        description: description,
      );
}

/// Proje bütçe kalemi: kategori bazında planlanan tutar (gerçekleşme ile karşılaştırılır).
class BudgetLine {
  final int? id;
  final int? projectId;
  final String category;
  final double budgetedAmount;
  final double actualAmount; // backend türetir (o kategorideki Gider toplamı)
  final String currency;

  BudgetLine({
    this.id,
    this.projectId,
    required this.category,
    this.budgetedAmount = 0.0,
    this.actualAmount = 0.0,
    this.currency = 'TRY',
  });

  /// Kullanım yüzdesi (0..1+); bütçe 0 ise 0.
  double get usageRatio =>
      budgetedAmount > 0 ? actualAmount / budgetedAmount : 0.0;
  double get remaining => budgetedAmount - actualAmount;
  bool get isOverBudget => budgetedAmount > 0 && actualAmount > budgetedAmount;

  factory BudgetLine.fromMap(Map<String, dynamic> m) => BudgetLine(
        id: m['id'],
        projectId: m['project'],
        category: m['category'] ?? '',
        budgetedAmount: _toDouble(m['budgeted_amount']),
        actualAmount: _toDouble(m['actual_amount']),
        currency: m['currency'] ?? 'TRY',
      );

  // actual_amount backend'de türetilir; yazarken gönderilmez.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'project': projectId,
        'category': category,
        'budgeted_amount': budgetedAmount,
        'currency': currency,
      };
}
