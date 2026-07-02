class Account {
  final int? id;
  final String name;
  final String type; // 'Banka', 'Nakit', 'Borsa', 'Kredi Kartı', 'BCH', 'Esnek'
  final double openingBalance;
  final double balance;
  final double creditLimit; // kredi kartı / BCH / esnek hesap için
  final double availableLimit; // kullanılabilir limit (backend'de hesaplanır)
  final String bankLogoPainter;
  final String accountDetails; // IBAN veya kart no
  final bool isActive;

  Account({
    this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    required this.balance,
    this.creditLimit = 0.0,
    this.availableLimit = 0.0,
    this.bankLogoPainter = '',
    this.accountDetails = '',
    this.isActive = true,
  });

  /// Optimistic eklemede geçici id atamak için (arkaplan senkron gerçek id ile değiştirir).
  Account withId(int? newId) => Account(
        id: newId,
        name: name,
        type: type,
        openingBalance: openingBalance,
        balance: balance,
        creditLimit: creditLimit,
        availableLimit: availableLimit,
        bankLogoPainter: bankLogoPainter,
        accountDetails: accountDetails,
        isActive: isActive,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'opening_balance': openingBalance,
      'balance': balance,
      'credit_limit': creditLimit,
      'bank_logo_painter': bankLogoPainter,
      'account_details': accountDetails,
      'is_active': isActive,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      openingBalance: (map['opening_balance'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      creditLimit: (map['credit_limit'] ?? 0).toDouble(),
      availableLimit: (map['available_limit'] ?? 0).toDouble(),
      bankLogoPainter: map['bank_logo_painter'] ?? '',
      accountDetails: map['account_details'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }
}
