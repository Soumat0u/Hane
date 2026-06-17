class FinancialTransaction {
  final int? id;
  final int? projectId; // Can be null for general company expenses
  final String type; // 'Gelir', 'Gider', 'Tahsilat', 'Satış', 'Transfer', 'Borçlanma', 'Kredi Kullanımı'
  final double amount;
  final String currency;
  final String date;
  final String category;
  final String description;
  // Ledger FK bağlantıları (hibrit bakiye); verilirse string isim alanlarına tercih edilir.
  final int? fromAccountId; // para çıkışı (Gider/Transfer kaynağı)
  final int? toAccountId; // para girişi (Tahsilat/Transfer hedefi)
  final int? contactId; // cari hesap
  final String sourceName; // legacy: banka adı, Nakit
  final String destName; // legacy: transfer hedefi
  final String contactName; // alıcı, satıcı, alacaklı
  final String dueDate;

  FinancialTransaction({
    this.id,
    this.projectId,
    required this.type,
    required this.amount,
    this.currency = 'TRY',
    required this.date,
    required this.category,
    this.description = '',
    this.fromAccountId,
    this.toAccountId,
    this.contactId,
    this.sourceName = '',
    this.destName = '',
    this.contactName = '',
    this.dueDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'date': date,
      'category': category,
      'description': description,
      'from_account': fromAccountId,
      'to_account': toAccountId,
      'contact': contactId,
      'source_name': sourceName,
      'dest_name': destName,
      'contact_name': contactName,
      'due_date': dueDate,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      projectId: map['project_id'],
      type: map['type'],
      amount: map['amount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'TRY',
      date: map['date'],
      category: map['category'],
      description: map['description'] ?? '',
      fromAccountId: map['from_account'],
      toAccountId: map['to_account'],
      contactId: map['contact'],
      sourceName: map['source_name'] ?? '',
      destName: map['dest_name'] ?? '',
      contactName: map['contact_name'] ?? '',
      dueDate: map['due_date'] ?? '',
    );
  }
}
