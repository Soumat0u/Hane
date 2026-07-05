class FinancialTransaction {
  final int? id;
  final int? projectId; // Can be null for general company expenses
  final String type; // 'Gelir', 'Gider', 'Tahsilat', 'Satış', 'Transfer', 'Borçlanma', 'Kredi Kullanımı'
  final double amount;
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
  final String? attachmentUrl; // sunucudan gelen fiş/fatura görseli (salt okunur)
  final double? quantity;
  final String? unit;

  FinancialTransaction({
    this.id,
    this.projectId,
    required this.type,
    required this.amount,
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
    this.attachmentUrl,
    this.quantity,
    this.unit,
  });

  FinancialTransaction copyWith({
    int? id,
    int? projectId,
    String? type,
    double? amount,
    String? date,
    String? category,
    String? description,
    int? fromAccountId,
    int? toAccountId,
    int? contactId,
    String? sourceName,
    String? destName,
    String? contactName,
    String? dueDate,
    String? attachmentUrl,
    double? quantity,
    String? unit,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      contactId: contactId ?? this.contactId,
      sourceName: sourceName ?? this.sourceName,
      destName: destName ?? this.destName,
      contactName: contactName ?? this.contactName,
      dueDate: dueDate ?? this.dueDate,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'type': type,
      'amount': amount,
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
      'quantity': quantity,
      'unit': unit ?? '',
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      projectId: map['project_id'],
      type: map['type'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      date: map['date'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      fromAccountId: map['from_account'],
      toAccountId: map['to_account'],
      contactId: map['contact'],
      sourceName: map['source_name'] ?? '',
      destName: map['dest_name'] ?? '',
      contactName: map['contact_name'] ?? '',
      dueDate: map['due_date'] ?? '',
      attachmentUrl: map['attachment'],
      quantity: map['quantity']?.toDouble(),
      unit: map['unit'],
    );
  }
}
