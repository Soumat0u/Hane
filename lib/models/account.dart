class Account {
  final int? id;
  final String name;
  final String type; // 'Banka', 'Kredi Kartı', 'Nakit', etc.
  final double balance;
  final String bankLogoPainter; // Will be kept for backward compatibility, but we are using local images now
  final String accountDetails; // Stores IBAN or Card Number

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankLogoPainter = '',
    this.accountDetails = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'bankLogoPainter': bankLogoPainter,
      'account_details': accountDetails,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      balance: map['balance'] ?? 0.0,
      bankLogoPainter: map['bankLogoPainter'] ?? '',
      accountDetails: map['account_details'] ?? '',
    );
  }
}
