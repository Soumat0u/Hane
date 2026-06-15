import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import '../models/financial_transaction.dart';
import '../models/account.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_panel.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS projects');
        await db.execute('DROP TABLE IF EXISTS transactions');
        await db.execute('DROP TABLE IF EXISTS accounts');
        await db.execute('DROP TABLE IF EXISTS company_profile');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE projects (
  id $idType,
  name $textType,
  status $textType,
  statusColorHex $textType,
  statusBgColorHex $textType,
  location $textType,
  areaSqMeters $intType,
  unitCount $intType,
  shopCount $intType,
  estimatedTotalCost $realType,
  estimatedTotalRevenue $realType,
  imagePath TEXT
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  projectId INTEGER,
  type $textType,
  amount $realType,
  date $textType,
  category $textType,
  description $textType,
  sourceName $textType,
  destName $textType,
  contactName $textType,
  dueDate $textType
)
''');

    await db.execute('''
CREATE TABLE accounts (
  id $idType,
  name $textType,
  type $textType,
  balance $realType,
  bankLogoPainter $textType,
  account_details TEXT
)
''');

    await db.execute('''
    CREATE TABLE company_profile (
      id $idType,
      company_name $textType,
      tax_office $textType,
      tax_number $textType,
      commercial_registry $textType,
      mersis_no $textType,
      address_title $textType,
      address_line1 $textType,
      address_line2 $textType,
      city $textType,
      country $textType,
      phone1 $textType,
      phone2 $textType,
      email $textType
    )
    ''');

    // Insert initial mock data
    await _insertMockData(db);
  }

  Future _insertMockData(Database db) async {
    // 1. Insert Company Profile
    await db.insert('company_profile', {
      'company_name': 'ZEYNEP İNŞAAT A.Ş.',
      'tax_office': 'Mecidiyeköy',
      'tax_number': '123 456 7890',
      'commercial_registry': '123456-5',
      'mersis_no': '0123 4567 8900 0012',
      'address_title': 'Merkez Ofis',
      'address_line1': 'Büyükdere Cad. No: 123',
      'address_line2': 'K:4 D:12 Şişli',
      'city': 'İstanbul',
      'country': 'Türkiye',
      'phone1': '+90 212 123 45 67',
      'phone2': '+90 532 123 45 67',
      'email': 'info@zeynepinsaat.com.tr'
    });

    // 2. Insert Accounts
    await db.insert('accounts', {'name': 'Halkbank', 'type': 'Banka', 'balance': 5000000.0, 'bankLogoPainter': 'HalkbankLogoPainter', 'account_details': 'TR12 0001 5001 5800 7293 0000 01'});
    await db.insert('accounts', {'name': 'Ziraat', 'type': 'Banka', 'balance': 2500000.0, 'bankLogoPainter': 'ZiraatLogoPainter', 'account_details': 'TR67 0001 0007 2345 6789 0000 02'});
    await db.insert('accounts', {'name': 'Garanti', 'type': 'Banka', 'balance': 1200000.0, 'bankLogoPainter': 'GarantiLogoPainter', 'account_details': 'TR55 0008 2000 1230 0035 2987 03'});
    await db.insert('accounts', {'name': 'Visa Kredi Kartı', 'type': 'Kredi Kartı', 'balance': 150000.0, 'bankLogoPainter': '', 'account_details': '**** **** **** 1234'});
    await db.insert('accounts', {'name': 'Mastercard', 'type': 'Kredi Kartı', 'balance': 80000.0, 'bankLogoPainter': '', 'account_details': '**** **** **** 5678'});
    await db.insert('accounts', {'name': 'Troy Kart', 'type': 'Kredi Kartı', 'balance': 50000.0, 'bankLogoPainter': '', 'account_details': '**** **** **** 9012'});
    await db.insert('accounts', {'name': 'Nakit Kasa', 'type': 'Nakit', 'balance': 450000.0, 'bankLogoPainter': '', 'account_details': ''});

    // 3. Insert Projects
    final projects = [
      {'name': 'Akpınar Projesi', 'status': 'Devam Ediyor', 'statusColorHex': '10B981', 'statusBgColorHex': 'ECFDF5', 'estimatedTotalCost': 24500000.0, 'estimatedTotalRevenue': 32000000.0},
      {'name': 'Sarayatik Projesi', 'status': 'Devam Ediyor', 'statusColorHex': '10B981', 'statusBgColorHex': 'ECFDF5', 'estimatedTotalCost': 18200000.0, 'estimatedTotalRevenue': 25000000.0},
      {'name': 'Edibecan Projesi', 'status': 'Planlama Aşaması', 'statusColorHex': 'F59E0B', 'statusBgColorHex': 'FFF7ED', 'estimatedTotalCost': 12750000.0, 'estimatedTotalRevenue': 18000000.0},
      {'name': 'Yenişehir Projesi', 'status': 'İhale Aşaması', 'statusColorHex': '3B82F6', 'statusBgColorHex': 'EFF6FF', 'estimatedTotalCost': 9800000.0, 'estimatedTotalRevenue': 15000000.0},
      {'name': 'Güneşli Projesi', 'status': 'Planlama Aşaması', 'statusColorHex': 'F59E0B', 'statusBgColorHex': 'FFF7ED', 'estimatedTotalCost': 7450000.0, 'estimatedTotalRevenue': 10000000.0},
      {'name': 'Beykent Projesi', 'status': 'Devam Ediyor', 'statusColorHex': '10B981', 'statusBgColorHex': 'ECFDF5', 'estimatedTotalCost': 5600000.0, 'estimatedTotalRevenue': 8000000.0},
    ];

    for (var p in projects) {
      await db.insert('projects', {
        'name': p['name'],
        'status': p['status'],
        'statusColorHex': p['statusColorHex'],
        'statusBgColorHex': p['statusBgColorHex'],
        'location': 'İstanbul',
        'areaSqMeters': 12000,
        'unitCount': 48,
        'shopCount': 6,
        'estimatedTotalCost': p['estimatedTotalCost'],
        'estimatedTotalRevenue': p['estimatedTotalRevenue'],
        'imagePath': null
      });
    }

    // 4. Insert Transactions for Akpınar Projesi (ID = 1)
    final transactions = [
      {'projectId': 1, 'type': 'Gider', 'amount': 1200000.0, 'date': '10 Haziran 2024', 'category': 'Hafriyat', 'sourceName': 'Halkbank'},
      {'projectId': 1, 'type': 'Gider', 'amount': 3800000.0, 'date': '12 Haziran 2024', 'category': 'Beton', 'sourceName': 'Halkbank'},
      {'projectId': 1, 'type': 'Gider', 'amount': 2400000.0, 'date': '15 Haziran 2024', 'category': 'Demir', 'sourceName': 'Ziraat'},
      {'projectId': 1, 'type': 'Gider', 'amount': 1600000.0, 'date': '20 Haziran 2024', 'category': 'Duvar', 'sourceName': 'Garanti'},
      {'projectId': 1, 'type': 'Tahsilat', 'amount': 18750000.0, 'date': '25 Haziran 2024', 'category': 'Satış', 'sourceName': 'Halkbank'},
      {'projectId': 1, 'type': 'Satış', 'amount': 24000000.0, 'date': '01 Temmuz 2024', 'category': 'Sözleşme', 'sourceName': ''},
    ];

    for (var t in transactions) {
      await db.insert('transactions', {
        'projectId': t['projectId'],
        'type': t['type'],
        'amount': t['amount'],
        'date': t['date'],
        'category': t['category'],
        'description': 'Mock data',
        'sourceName': t['sourceName'],
        'destName': '',
        'contactName': '',
        'dueDate': ''
      });
    }
  }

  // --- CRUD Operations ---

  // Project
  Future<int> createProject(Project project) async {
    final db = await instance.database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> readAllProjects() async {
    final db = await instance.database;
    final result = await db.query('projects');
    return result.map((json) => Project.fromMap(json)).toList();
  }

  Future<int> updateProject(Project project) async {
    final db = await instance.database;
    return db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  // Account
  Future<List<Account>> readAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts');
    return result.map((json) => Account.fromMap(json)).toList();
  }
  
  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // Transaction
  Future<int> createTransaction(FinancialTransaction transaction) async {
    final db = await instance.database;
    int id = await db.insert('transactions', transaction.toMap());
    
    // Update account balances if it's a real money movement
    if (transaction.type == 'Gider' && transaction.sourceName.isNotEmpty) {
      await _updateAccountBalance(transaction.sourceName, -transaction.amount);
    } else if (transaction.type == 'Gelir' || transaction.type == 'Tahsilat') {
      if (transaction.sourceName.isNotEmpty) {
        await _updateAccountBalance(transaction.sourceName, transaction.amount);
      }
    } else if (transaction.type == 'Transfer') {
      if (transaction.sourceName.isNotEmpty) {
        await _updateAccountBalance(transaction.sourceName, -transaction.amount);
      }
      if (transaction.destName.isNotEmpty) {
        await _updateAccountBalance(transaction.destName, transaction.amount);
      }
    }

    return id;
  }

  Future<void> _updateAccountBalance(String accountName, double amountChange) async {
    final db = await instance.database;
    final res = await db.query('accounts', where: 'name = ?', whereArgs: [accountName]);
    if (res.isNotEmpty) {
      final account = Account.fromMap(res.first);
      final newBalance = account.balance + amountChange;
      await db.update('accounts', {'balance': newBalance}, where: 'id = ?', whereArgs: [account.id]);
    }
  }

  Future<List<FinancialTransaction>> readAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'id DESC');
    return result.map((json) => FinancialTransaction.fromMap(json)).toList();
  }

  Future<List<FinancialTransaction>> readTransactionsForProject(int projectId) async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'projectId = ?', whereArgs: [projectId], orderBy: 'id DESC');
    return result.map((json) => FinancialTransaction.fromMap(json)).toList();
  }

  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await instance.database;
    final maps = await db.query('company_profile', limit: 1);
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await instance.database;
    final existing = await getCompanyProfile();
    if (existing != null) {
      return await db.update(
        'company_profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      return await db.insert('company_profile', profile.toMap());
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
