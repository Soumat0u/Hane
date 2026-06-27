import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/financial_transaction.dart';
import '../models/account.dart';
import '../models/company_profile.dart';
import '../models/finance_entities.dart';
import '../models/recurring_transaction.dart';

class ApiService {
  // Android emülatörü host makineye 10.0.2.2 üzerinden ulaşır; localhost cihazın kendisidir.
  // Web ve masaüstünde localhost doğrudan çalışır.
  static String get baseUrl {
    const host = String.fromEnvironment('API_HOST', defaultValue: '');
    if (host.isNotEmpty) return 'http://$host:8000/api';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }
  static const String _tokenKey = 'auth_token';

  static final ApiService instance = ApiService._init();
  ApiService._init();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Giriş başarısız: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, {String firstName = '', String lastName = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Kayıt başarısız: ${response.body}');
    }
  }

  Future<void> logout() async {
    final headers = await _getHeaders();
    await http.post(Uri.parse('$baseUrl/auth/logout/'), headers: headers);
    await removeToken();
  }

  // Projects
  Future<List<Project>> readAllProjects() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/projects/'), headers: headers);
    if (response.statusCode == 200) {
      List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Project.fromMap(json)).toList();
    } else {
      throw Exception('Projeler getirilemedi');
    }
  }

  Future<Project> createProject(Project project) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/projects/'),
      headers: headers,
      body: jsonEncode(project.toMap()),
    );
    if (response.statusCode == 201) {
      return Project.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Proje oluşturulamadı');
    }
  }

  Future<Project> updateProject(Project project) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/projects/${project.id}/'),
      headers: headers,
      body: jsonEncode(project.toMap()),
    );
    if (response.statusCode == 200) {
      return Project.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Proje güncellenemedi');
    }
  }

  Future<void> deleteProject(int projectId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId/'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Proje silinemedi');
    }
  }

  // Accounts
  Future<List<Account>> readAllAccounts() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/accounts/'), headers: headers);
    if (response.statusCode == 200) {
      List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Account.fromMap(json)).toList();
    } else {
      throw Exception('Hesaplar getirilemedi');
    }
  }

  Future<Account> createAccount(Account account) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/'),
      headers: headers,
      body: jsonEncode(account.toMap()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Account.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Hesap eklenemedi: ${utf8.decode(response.bodyBytes)}');
    }
  }

  Future<Account> updateAccount(Account account) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/accounts/${account.id}/'),
      headers: headers,
      body: jsonEncode(account.toMap()),
    );
    if (response.statusCode == 200) {
      return Account.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Hesap güncellenemedi');
    }
  }

  // Transactions
  Future<List<FinancialTransaction>> readAllTransactions() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/transactions/'), headers: headers);
    if (response.statusCode == 200) {
      List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => FinancialTransaction.fromMap(json)).toList();
    } else {
      throw Exception('İşlemler getirilemedi');
    }
  }

  Future<List<FinancialTransaction>> readTransactionsForProject(int projectId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/transactions/?project_id=$projectId'), headers: headers);
    if (response.statusCode == 200) {
      List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => FinancialTransaction.fromMap(json)).toList();
    } else {
      throw Exception('Proje işlemleri getirilemedi');
    }
  }

  Future<FinancialTransaction> createTransaction(FinancialTransaction transaction) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: headers,
      body: jsonEncode(transaction.toMap()),
    );
    if (response.statusCode == 201) {
      return FinancialTransaction.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('İşlem oluşturulamadı');
    }
  }

  Future<FinancialTransaction> updateTransaction(FinancialTransaction transaction) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/${transaction.id}/'),
      headers: headers,
      body: jsonEncode(transaction.toMap()),
    );
    if (response.statusCode == 200) {
      return FinancialTransaction.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('İşlem güncellenemedi');
    }
  }

  /// Fiş/fatura eki ile birlikte işlem oluşturur (multipart). `attachmentPath`
  /// verilmezse normal JSON akışıyla aynı sonucu üretir.
  Future<FinancialTransaction> createTransactionWithAttachment(
      FinancialTransaction transaction, String? attachmentPath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transactions/'));
    await _fillMultipartTransaction(request, transaction, attachmentPath);
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 201) {
      return FinancialTransaction.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('İşlem oluşturulamadı: ${utf8.decode(response.bodyBytes)}');
  }

  Future<FinancialTransaction> updateTransactionWithAttachment(
      FinancialTransaction transaction, String? attachmentPath) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/transactions/${transaction.id}/'));
    await _fillMultipartTransaction(request, transaction, attachmentPath);
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      return FinancialTransaction.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('İşlem güncellenemedi: ${utf8.decode(response.bodyBytes)}');
  }

  Future<void> _fillMultipartTransaction(
      http.MultipartRequest request, FinancialTransaction transaction, String? attachmentPath) async {
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Token $token';
    transaction.toMap().forEach((key, value) {
      if (key == 'id' || value == null) return;
      request.fields[key] = value.toString();
    });
    if (attachmentPath != null) {
      request.files.add(await http.MultipartFile.fromPath('attachment', attachmentPath));
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$transactionId/'),
      headers: headers,
    );
    if (response.statusCode != 204) {
      throw Exception('İşlem silinemedi');
    }
  }

  // Company Profile
  Future<CompanyProfile?> getCompanyProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/company-profile/'), headers: headers);
    if (response.statusCode == 200) {
      return CompanyProfile.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 401) {
      return null;
    } else {
      throw Exception('Firma profili getirilemedi');
    }
  }

  Future<CompanyProfile> updateCompanyProfile(CompanyProfile profile) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/company-profile/'),
      headers: headers,
      body: jsonEncode(profile.toMap()),
    );
    if (response.statusCode == 200) {
      return CompanyProfile.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Firma profili güncellenemedi');
    }
  }

  // --- Generic list helper ---
  Future<List<T>> _readList<T>(String path, T Function(Map<String, dynamic>) fromMap) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/$path'), headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => fromMap(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('$path getirilemedi');
    }
  }

  Future<List<Category>> readAllCategories() => _readList('categories/', Category.fromMap);

  Future<Category> createCategory({
    required String name,
    required String type,
    int? parentId,
    String group = '',
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/categories/'),
      headers: headers,
      body: jsonEncode({'name': name, 'type': type, 'parent': parentId, 'group': group}),
    );
    if (response.statusCode == 201) {
      return Category.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Kategori eklenemedi: ${utf8.decode(response.bodyBytes)}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id/'), headers: headers);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Kategori silinemedi');
    }
  }

  // --- Generic create / update / delete helpers ---
  Future<T> _create<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return fromMap(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('$path oluşturulamadı: ${utf8.decode(response.bodyBytes)}');
  }

  Future<T> _update<T>(
    String path,
    int id,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$path$id/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return fromMap(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('$path güncellenemedi: ${utf8.decode(response.bodyBytes)}');
  }

  Future<void> _delete(String path, int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/$path$id/'), headers: headers);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('$path silinemedi');
    }
  }

  // Contacts
  Future<List<Contact>> readAllContacts() => _readList('contacts/', Contact.fromMap);
  Future<Contact> createContact(Contact c) => _create('contacts/', c.toMap(), Contact.fromMap);
  Future<Contact> updateContact(Contact c) => _update('contacts/', c.id!, c.toMap(), Contact.fromMap);
  Future<void> deleteContact(int id) => _delete('contacts/', id);

  // Loans
  Future<List<Loan>> readAllLoans() => _readList('loans/', Loan.fromMap);
  Future<Loan> createLoan(Loan l) => _create('loans/', l.toMap(), Loan.fromMap);
  Future<Loan> updateLoan(Loan l) => _update('loans/', l.id!, l.toMap(), Loan.fromMap);
  Future<void> deleteLoan(int id) => _delete('loans/', id);

  // Cheques
  Future<List<Cheque>> readAllCheques() => _readList('cheques/', Cheque.fromMap);
  Future<Cheque> createCheque(Cheque c) => _create('cheques/', c.toMap(), Cheque.fromMap);
  Future<Cheque> updateCheque(Cheque c) => _update('cheques/', c.id!, c.toMap(), Cheque.fromMap);
  Future<void> deleteCheque(int id) => _delete('cheques/', id);

  // Sales
  Future<List<Sale>> readAllSales() => _readList('sales/', Sale.fromMap);
  Future<Sale> createSale(Sale s) => _create('sales/', s.toMap(), Sale.fromMap);
  Future<Sale> updateSale(Sale s) => _update('sales/', s.id!, s.toMap(), Sale.fromMap);
  Future<void> deleteSale(int id) => _delete('sales/', id);

  // Receivables
  Future<List<Receivable>> readAllReceivables() => _readList('receivables/', Receivable.fromMap);
  Future<Receivable> createReceivable(Receivable r) => _create('receivables/', r.toMap(), Receivable.fromMap);
  Future<Receivable> updateReceivable(Receivable r) => _update('receivables/', r.id!, r.toMap(), Receivable.fromMap);
  Future<void> deleteReceivable(int id) => _delete('receivables/', id);

  // Budget Lines
  Future<List<BudgetLine>> readAllBudgetLines() => _readList('budget-lines/', BudgetLine.fromMap);
  Future<List<BudgetLine>> readBudgetLinesForProject(int projectId) =>
      _readList('budget-lines/?project_id=$projectId', BudgetLine.fromMap);
  Future<BudgetLine> createBudgetLine(BudgetLine b) => _create('budget-lines/', b.toMap(), BudgetLine.fromMap);
  Future<BudgetLine> updateBudgetLine(BudgetLine b) => _update('budget-lines/', b.id!, b.toMap(), BudgetLine.fromMap);
  Future<void> deleteBudgetLine(int id) => _delete('budget-lines/', id);

  // Recurring Transactions
  Future<List<RecurringTransaction>> readAllRecurringTransactions() =>
      _readList('recurring-transactions/', RecurringTransaction.fromMap);
  Future<RecurringTransaction> createRecurringTransaction(RecurringTransaction r) =>
      _create('recurring-transactions/', r.toMap(), RecurringTransaction.fromMap);
  Future<RecurringTransaction> updateRecurringTransaction(RecurringTransaction r) =>
      _update('recurring-transactions/', r.id!, r.toMap(), RecurringTransaction.fromMap);
  Future<void> deleteRecurringTransaction(int id) => _delete('recurring-transactions/', id);

  Future<FinancialTransaction> confirmRecurringTransaction(int id, {String? date}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/recurring-transactions/$id/confirm/'),
      headers: headers,
      body: jsonEncode({if (date != null) 'date': date}),
    );
    if (response.statusCode == 201) {
      return FinancialTransaction.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Tekrarlanan işlem onaylanamadı: ${utf8.decode(response.bodyBytes)}');
  }
}
