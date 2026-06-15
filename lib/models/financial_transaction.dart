class FinancialTransaction {
  final int? id;
  final int? projectId; // Can be null for general company expenses
  final String type; // 'Gelir', 'Gider', 'Tahsilat', 'Satış', 'Transfer', 'Borçlanma', 'Kredi Kullanımı'
  final double amount;
  final String date;
  final String category;
  final String description;
  final String sourceName; // e.g. Bank name, Cash
  final String destName; // For transfers
  final String contactName; // Buyer, Seller, Creditor
  final String dueDate;

  FinancialTransaction({
    this.id,
    this.projectId,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    this.description = '',
    this.sourceName = '',
    this.destName = '',
    this.contactName = '',
    this.dueDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'type': type,
      'amount': amount,
      'date': date,
      'category': category,
      'description': description,
      'sourceName': sourceName,
      'destName': destName,
      'contactName': contactName,
      'dueDate': dueDate,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      projectId: map['projectId'],
      type: map['type'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: map['date'],
      category: map['category'],
      description: map['description'] ?? '',
      sourceName: map['sourceName'] ?? '',
      destName: map['destName'] ?? '',
      contactName: map['contactName'] ?? '',
      dueDate: map['dueDate'] ?? '',
    );
  }
}
