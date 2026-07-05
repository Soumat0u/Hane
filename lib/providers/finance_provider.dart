import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/financial_transaction.dart';
import '../models/account.dart';
import '../models/company_profile.dart';
import '../models/finance_panel.dart';
import '../models/finance_entities.dart';
import '../models/recurring_transaction.dart';
import '../models/project_document.dart';
import '../models/todo.dart';
import '../services/api_service.dart';

class FinanceProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<Account> _accounts = [];
  List<FinancialTransaction> _allTransactions = [];
  List<Loan> _loans = [];
  List<Cheque> _cheques = [];
  List<Sale> _sales = [];
  List<Receivable> _receivables = [];
  List<Contact> _contacts = [];
  List<Category> _categories = [];
  List<BudgetLine> _budgetLines = [];
  List<RecurringTransaction> _recurringTransactions = [];
  List<ProjectDocument> _projectDocuments = [];
  List<Todo> _todos = [];
  CompanyProfile? _companyProfile;

  // Selection states
  final Set<int> selectedProjectIds = {};
  final Set<int> selectedTransactionIds = {};

  void toggleProjectSelection(int id) {
    if (selectedProjectIds.contains(id)) {
      selectedProjectIds.remove(id);
    } else {
      selectedProjectIds.add(id);
    }
    notifyListeners();
  }

  void clearProjectSelection() {
    selectedProjectIds.clear();
    notifyListeners();
  }

  void toggleTransactionSelection(int id) {
    if (selectedTransactionIds.contains(id)) {
      selectedTransactionIds.remove(id);
    } else {
      selectedTransactionIds.add(id);
    }
    notifyListeners();
  }

  void clearTransactionSelection() {
    selectedTransactionIds.clear();
    notifyListeners();
  }

  List<Project> get projects => _projects;
  List<Account> get accounts => _accounts;
  List<FinancialTransaction> get allTransactions => _allTransactions;
  List<Loan> get loans => _loans;
  List<Cheque> get cheques => _cheques;
  List<Sale> get sales => _sales;
  List<Receivable> get receivables => _receivables;
  List<Contact> get contacts => _contacts;
  List<Category> get categories => _categories;
  List<BudgetLine> get budgetLines => _budgetLines;
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  List<ProjectDocument> get projectDocuments => _projectDocuments;
  List<Todo> get todos => _todos;
  CompanyProfile? get companyProfile => _companyProfile;

  List<ProjectDocument> getProjectDocuments(int projectId) =>
      _projectDocuments.where((d) => d.projectId == projectId).toList();

  /// Uygulama başlığı/markası için firma adı (yoksa jenerik).
  String get companyName {
    final n = _companyProfile?.companyName.trim() ?? '';
    return n.isNotEmpty ? n : 'Hano Finans';
  }

  List<Category> get incomeCategories => _categories.where((c) => c.isIncome).toList();
  List<Category> get expenseCategories => _categories.where((c) => c.isCost).toList();

  /// Belirtilen tipteki ANA kategorileri grup başlığına göre gruplar (UI için).
  Map<String, List<Category>> mainCategoriesByGroup({required bool income}) {
    final list = _categories.where((c) => c.isMain && c.isIncome == income);
    final map = <String, List<Category>>{};
    for (final c in list) {
      map.putIfAbsent(c.group.isEmpty ? 'Diğer' : c.group, () => []).add(c);
    }
    return map;
  }

  /// Bir ana kategorinin alt kategorileri.
  List<Category> subCategoriesOf(int parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  /// Kullanıcının eklediği yeni alt kategoriyi kaydeder.
  /// Optimistic: yeni kategori anında listeye eklenir, kayıt arkaplanda gönderilir.
  Future<Category> addSubCategory({
    required String name,
    required int parentId,
    required String type,
  }) async {
    final temp = Category(
      id: _nextTempId(),
      name: name,
      type: type,
      parentId: parentId,
    );
    final snapshot = List<Category>.from(_categories);
    _categories = [..._categories, temp];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createCategory(
        name: name,
        type: type,
        parentId: parentId,
      ),
      rollback: () => _categories = snapshot,
      errorLabel: 'Kategori eklenemedi',
    ));
    return temp;
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Arkaplan senkron hatalarını UI'ya iletmek için (main.dart dinler ve SnackBar gösterir).
  final ValueNotifier<String?> syncError = ValueNotifier(null);

  // Optimistic eklemelerde kullanılan geçici (negatif) id üreteci; sunucu
  // id'leriyle çakışmaz, arkaplan senkron sonrası gerçek id ile değişir.
  int _tempIdCounter = -1;
  int _nextTempId() => _tempIdCounter--;

  // _silentRefresh çağrılarını çakışmasız hale getirir (coalescing).
  bool _refreshing = false;
  bool _refreshQueued = false;

  // Okunmuş bildirimlerin içerik tabanlı anahtarları (SharedPreferences ile kalıcı).
  final Set<String> _readNotificationKeys = {};
  static const _kReadNotifications = 'pref_read_notifications';

  FinanceProvider() {
    refreshData();
    _loadReadNotifications();
  }

  /// İlk açılış / pull-to-refresh: tam ekran yükleme göstergesiyle veriyi çeker.
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _fetchAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sunucudan tüm veriyi çeker. `_isLoading`'i değiştirmez; optimistic
  /// değişikliklerden sonra arkaplanda çağrılarak yereli sunucuyla eşitler.
  Future<void> _fetchAll() async {
    try {
      final results = await Future.wait([
        _safe(ApiService.instance.readAllProjects, _projects),
        _safe(ApiService.instance.readAllAccounts, _accounts),
        _safe(ApiService.instance.readAllTransactions, _allTransactions),
        _safe(ApiService.instance.readAllLoans, _loans),
        _safe(ApiService.instance.readAllCheques, _cheques),
        _safe(ApiService.instance.readAllSales, _sales),
        _safe(ApiService.instance.readAllReceivables, _receivables),
        _safe(ApiService.instance.readAllContacts, _contacts),
        _safe(ApiService.instance.readAllCategories, _categories),
        _safe(ApiService.instance.readAllBudgetLines, _budgetLines),
        _safe(ApiService.instance.readAllProjectDocuments, _projectDocuments),
        _safe(ApiService.instance.readAllTodos, _todos),
      ]);

      _projects = results[0] as List<Project>;
      _accounts = results[1] as List<Account>;
      _allTransactions = results[2] as List<FinancialTransaction>;
      _loans = results[3] as List<Loan>;
      _cheques = results[4] as List<Cheque>;
      _sales = results[5] as List<Sale>;
      _receivables = results[6] as List<Receivable>;
      _contacts = results[7] as List<Contact>;
      _categories = results[8] as List<Category>;
      _budgetLines = results[9] as List<BudgetLine>;
      _projectDocuments = results[10] as List<ProjectDocument>;
      _todos = results[11] as List<Todo>;
      try {
        _companyProfile = await ApiService.instance.getCompanyProfile();
      } catch (e) {
        debugPrint("Company profile load failed: $e");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  /// Uygulama arka plandan öne gelince vb. dışarıdan tetiklenen sessiz eşitleme.
  Future<void> refreshSilently() => _silentRefresh();

  /// Sunucuyla sessizce (spinner göstermeden) eşitler. Eşzamanlı çağrılar
  /// birleştirilir: bir eşitleme sürerken gelenler tek bir tekrara indirgenir.
  Future<void> _silentRefresh() async {
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _fetchAll();
      } while (_refreshQueued);
    } finally {
      _refreshing = false;
    }
  }

  /// Optimistic mutasyonun sunucu tarafını arkaplanda yürütür: başarılıysa
  /// sessiz eşitleme yapar, başarısızsa yerel değişikliği geri alıp uyarı verir.
  Future<void> _runSync(
    Future<void> Function() remote, {
    required VoidCallback rollback,
    required String errorLabel,
  }) async {
    try {
      await remote();
      await _silentRefresh();
    } catch (e) {
      debugPrint('$errorLabel: $e');
      rollback();
      notifyListeners();
      syncError.value = errorLabel;
    }
  }

  Future<List<T>> _safe<T>(Future<List<T>> Function() loader, List<T> fallback) async {
    try {
      return await loader();
    } catch (e) {
      debugPrint("Optional data load failed: $e");
      return fallback;
    }
  }

  Future<void> updateAccount(Account account) async {
    final snapshot = List<Account>.from(_accounts);
    _accounts = [for (final a in _accounts) a.id == account.id ? account : a];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateAccount(account),
      rollback: () => _accounts = snapshot,
      errorLabel: 'Hesap güncellenemedi',
    ));
  }

  Future<void> createAccount(Account account) async {
    final snapshot = List<Account>.from(_accounts);
    _accounts = [..._accounts, account.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createAccount(account),
      rollback: () => _accounts = snapshot,
      errorLabel: 'Hesap eklenemedi',
    ));
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    final snapshot = List<FinancialTransaction>.from(_allTransactions);
    _allTransactions = [transaction.copyWith(id: _nextTempId()), ..._allTransactions];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createTransaction(transaction),
      rollback: () => _allTransactions = snapshot,
      errorLabel: 'İşlem kaydedilemedi',
    ));
  }

  /// `attachmentPath` verilirse fiş/fatura fotoğrafı ile birlikte işlem oluşturur.
  Future<void> addTransactionWithAttachment(FinancialTransaction transaction, String? attachmentPath) async {
    final snapshot = List<FinancialTransaction>.from(_allTransactions);
    _allTransactions = [transaction.copyWith(id: _nextTempId()), ..._allTransactions];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createTransactionWithAttachment(transaction, attachmentPath),
      rollback: () => _allTransactions = snapshot,
      errorLabel: 'İşlem kaydedilemedi',
    ));
  }

  Future<void> updateTransaction(FinancialTransaction transaction) async {
    final snapshot = List<FinancialTransaction>.from(_allTransactions);
    _allTransactions = [for (final t in _allTransactions) t.id == transaction.id ? transaction : t];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateTransaction(transaction),
      rollback: () => _allTransactions = snapshot,
      errorLabel: 'İşlem güncellenemedi',
    ));
  }

  Future<void> deleteTransaction(int id) async {
    final snapshot = List<FinancialTransaction>.from(_allTransactions);
    _allTransactions = _allTransactions.where((t) => t.id != id).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteTransaction(id),
      rollback: () => _allTransactions = snapshot,
      errorLabel: 'İşlem silinemedi',
    ));
  }

  Future<void> createProject(Project project) async {
    final snapshot = List<Project>.from(_projects);
    _projects = [..._projects, project.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createProject(project),
      rollback: () => _projects = snapshot,
      errorLabel: 'Proje oluşturulamadı',
    ));
  }

  Future<void> updateProject(Project project) async {
    final snapshot = List<Project>.from(_projects);
    _projects = [for (final p in _projects) p.id == project.id ? project : p];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateProject(project),
      rollback: () => _projects = snapshot,
      errorLabel: 'Proje güncellenemedi',
    ));
  }

  Future<void> deleteProject(int projectId) async {
    final snapshot = List<Project>.from(_projects);
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteProject(projectId),
      rollback: () => _projects = snapshot,
      errorLabel: 'Proje silinemedi',
    ));
  }

  // --- CRUD sarmalayıcıları (yeni modüller) ---
  Future<void> addLoan(Loan loan) async {
    final snapshot = List<Loan>.from(_loans);
    _loans = [..._loans, loan.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createLoan(loan),
      rollback: () => _loans = snapshot,
      errorLabel: 'Kredi eklenemedi',
    ));
  }

  Future<void> addCheque(Cheque cheque) async {
    final snapshot = List<Cheque>.from(_cheques);
    _cheques = [..._cheques, cheque.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createCheque(cheque),
      rollback: () => _cheques = snapshot,
      errorLabel: 'Çek eklenemedi',
    ));
  }

  /// Cari, hemen ardından bir işleme bağlanabildiği için burada gerçek sunucu
  /// id'si beklenir (tek POST); ardından yerel liste sessizce eşitlenir.
  Future<Contact> addContact(Contact contact) async {
    final c = await ApiService.instance.createContact(contact);
    _contacts = [..._contacts, c];
    notifyListeners();
    unawaited(_silentRefresh());
    return c;
  }

  Future<void> addSale(Sale sale) async {
    final snapshot = List<Sale>.from(_sales);
    _sales = [..._sales, sale.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createSale(sale),
      rollback: () => _sales = snapshot,
      errorLabel: 'Satış eklenemedi',
    ));
  }

  Future<void> addReceivable(Receivable r) async {
    final snapshot = List<Receivable>.from(_receivables);
    _receivables = [..._receivables, r.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createReceivable(r),
      rollback: () => _receivables = snapshot,
      errorLabel: 'Alacak eklenemedi',
    ));
  }

  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    final snapshot = _companyProfile;
    _companyProfile = profile;
    notifyListeners();
    unawaited(_runSync(
      () async => _companyProfile = await ApiService.instance.updateCompanyProfile(profile),
      rollback: () => _companyProfile = snapshot,
      errorLabel: 'Firma profili güncellenemedi',
    ));
  }

  // --- Bütçe ---
  Future<void> addBudgetLine(BudgetLine line) async {
    final snapshot = List<BudgetLine>.from(_budgetLines);
    _budgetLines = [..._budgetLines, line.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createBudgetLine(line),
      rollback: () => _budgetLines = snapshot,
      errorLabel: 'Bütçe kalemi eklenemedi',
    ));
  }

  Future<void> updateBudgetLine(BudgetLine line) async {
    final snapshot = List<BudgetLine>.from(_budgetLines);
    _budgetLines = [for (final b in _budgetLines) b.id == line.id ? line : b];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateBudgetLine(line),
      rollback: () => _budgetLines = snapshot,
      errorLabel: 'Bütçe kalemi güncellenemedi',
    ));
  }

  Future<void> deleteBudgetLine(int id) async {
    final snapshot = List<BudgetLine>.from(_budgetLines);
    _budgetLines = _budgetLines.where((b) => b.id != id).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteBudgetLine(id),
      rollback: () => _budgetLines = snapshot,
      errorLabel: 'Bütçe kalemi silinemedi',
    ));
  }

  List<BudgetLine> getProjectBudgetLines(int projectId) =>
      _budgetLines.where((b) => b.projectId == projectId).toList();

  // --- Tekrarlayan İşlemler ---
  Future<void> addRecurringTransaction(RecurringTransaction r) async {
    final snapshot = List<RecurringTransaction>.from(_recurringTransactions);
    _recurringTransactions = [..._recurringTransactions, r.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createRecurringTransaction(r),
      rollback: () => _recurringTransactions = snapshot,
      errorLabel: 'Tekrarlayan işlem eklenemedi',
    ));
  }

  Future<void> updateRecurringTransaction(RecurringTransaction r) async {
    final snapshot = List<RecurringTransaction>.from(_recurringTransactions);
    _recurringTransactions = [for (final x in _recurringTransactions) x.id == r.id ? r : x];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateRecurringTransaction(r),
      rollback: () => _recurringTransactions = snapshot,
      errorLabel: 'Tekrarlayan işlem güncellenemedi',
    ));
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final snapshot = List<RecurringTransaction>.from(_recurringTransactions);
    _recurringTransactions = _recurringTransactions.where((x) => x.id != id).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteRecurringTransaction(id),
      rollback: () => _recurringTransactions = snapshot,
      errorLabel: 'Tekrarlayan işlem silinemedi',
    ));
  }

  /// Vadesi bugüne gelmiş veya geçmiş, aktif tekrarlayan işlem şablonları.
  List<RecurringTransaction> getDueRecurringTemplates() {
    final today = DateTime.now();
    return _recurringTransactions.where((r) {
      if (!r.isActive) return false;
      final due = DateTime.tryParse(r.nextDueDate);
      return due != null && !due.isAfter(today);
    }).toList();
  }

  /// Şablonu onaylar: gerçek bir FinancialTransaction oluşturur ve next_due_date'i ilerletir.
  /// Oluşacak işlem sunucuda üretildiği için önceden tahmin edilmez; endpoint
  /// beklenir, sonra yerel veri sessizce (spinner'sız) eşitlenir.
  Future<void> confirmRecurringTransaction(RecurringTransaction template, {String? date}) async {
    try {
      await ApiService.instance.confirmRecurringTransaction(template.id!, date: date);
      await _silentRefresh();
    } catch (e) {
      debugPrint('Tekrarlayan işlem onaylanamadı: $e');
      syncError.value = 'Tekrarlayan işlem onaylanamadı';
    }
  }

  // --- Proje Belgeleri ---
  /// Belge yükleme gerçek dosya baytlarını gerektirdiğinden (optimistic önizleme
  /// mümkün değil) sunucu yanıtı beklenir, ardından listeye eklenir.
  Future<ProjectDocument> addProjectDocument(int projectId, String name, String filePath) async {
    final doc = await ApiService.instance.uploadProjectDocument(projectId, name, filePath);
    _projectDocuments = [doc, ..._projectDocuments];
    notifyListeners();
    return doc;
  }

  Future<void> deleteProjectDocument(int id) async {
    final snapshot = List<ProjectDocument>.from(_projectDocuments);
    _projectDocuments = _projectDocuments.where((d) => d.id != id).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteProjectDocument(id),
      rollback: () => _projectDocuments = snapshot,
      errorLabel: 'Belge silinemedi',
    ));
  }

  Future<void> renameProjectDocument(int id, String name) async {
    final snapshot = List<ProjectDocument>.from(_projectDocuments);
    _projectDocuments = [
      for (final d in _projectDocuments) d.id == id ? d.copyWith(name: name) : d,
    ];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.renameProjectDocument(id, name),
      rollback: () => _projectDocuments = snapshot,
      errorLabel: 'Belge adı güncellenemedi',
    ));
  }

  // --- Yapılacaklar (Todo) ---
  List<Todo> get personalTodos => _todos.where((t) => t.scope == Todo.personal).toList();
  List<Todo> get projectTodos => _todos.where((t) => t.scope == Todo.project).toList();

  Future<void> addTodo(Todo t) async {
    final snapshot = List<Todo>.from(_todos);
    _todos = [..._todos, t.withId(_nextTempId())];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.createTodo(t),
      rollback: () => _todos = snapshot,
      errorLabel: 'Yapılacak eklenemedi',
    ));
  }

  Future<void> toggleTodo(Todo t) async {
    final snapshot = List<Todo>.from(_todos);
    final updated = t.copyWith(isDone: !t.isDone);
    _todos = [for (final x in _todos) x.id == t.id ? updated : x];
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.updateTodo(updated),
      rollback: () => _todos = snapshot,
      errorLabel: 'Yapılacak güncellenemedi',
    ));
  }

  Future<void> deleteTodo(int id) async {
    final snapshot = List<Todo>.from(_todos);
    _todos = _todos.where((t) => t.id != id).toList();
    notifyListeners();
    unawaited(_runSync(
      () => ApiService.instance.deleteTodo(id),
      rollback: () => _todos = snapshot,
      errorLabel: 'Yapılacak silinemedi',
    ));
  }

  double getProjectBudgetTotal(int projectId) =>
      getProjectBudgetLines(projectId).fold(0.0, (s, b) => s + b.budgetedAmount);

  /// Bütçesi aşılmış (gerçek harcama > planlanan) projeler.
  List<Project> get overBudgetProjects => _projects.where((p) {
        if (p.id == null) return false;
        final budget = getProjectBudgetTotal(p.id!);
        return budget > 0 && getProjectTotalGider(p.id!) > budget;
      }).toList();

  // --- Tahsilat akışı ---
  /// Bir alacaktan tahsilat yapar: Receivable.collectedAmount güncellenir ve
  /// seçilen hesaba 'Tahsilat' tipi bir işlem düşülür (bakiye artar).
  Future<void> collectReceivable({
    required Receivable receivable,
    required double amount,
    int? toAccountId,
    String date = '',
  }) async {
    final newCollected = receivable.collectedAmount + amount;
    final fullyCollected = newCollected >= receivable.totalAmount;
    final updated = receivable.copyWith(
      collectedAmount: newCollected,
      status: fullyCollected ? 'collected' : 'partial',
    );
    final tx = FinancialTransaction(
      type: 'Tahsilat',
      amount: amount,
      date: date.isNotEmpty ? date : DateTime.now().toIso8601String().split('T').first,
      category: 'Tahsilat',
      description: receivable.description,
      projectId: receivable.projectId,
      toAccountId: toAccountId,
    );

    // Optimistic: alacağı güncelle + tahsilat işlemini ekle.
    final recvSnapshot = List<Receivable>.from(_receivables);
    final txSnapshot = List<FinancialTransaction>.from(_allTransactions);
    _receivables = [for (final r in _receivables) r.id == receivable.id ? updated : r];
    _allTransactions = [tx.copyWith(id: _nextTempId()), ..._allTransactions];
    notifyListeners();

    unawaited(_runSync(
      () async {
        await ApiService.instance.updateReceivable(updated);
        await ApiService.instance.createTransaction(tx);
      },
      rollback: () {
        _receivables = recvSnapshot;
        _allTransactions = txSnapshot;
      },
      errorLabel: 'Tahsilat kaydedilemedi',
    ));
  }

  /// Bir borcu öder: kind'e göre ilgili kayıt güncellenir ve seçilen hesaptan
  /// gerçek bir para çıkışı işlenir (`collectReceivable` ile simetrik).
  /// Birden fazla sunucu çağrısını içerdiğinden (kayıt güncelleme + işlem
  /// oluşturma) optimistic önizleme yapılmıyor; tamamlanınca sessizce eşitlenir.
  Future<void> payDebt({
    required String kind, // 'contact' | 'loan' | 'cheque'
    required Object ref,
    required double amount,
    int? fromAccountId,
    String date = '',
  }) async {
    final txDate = date.isNotEmpty ? date : DateTime.now().toIso8601String().split('T').first;
    try {
      if (kind == 'contact') {
        final contact = ref as Contact;
        await ApiService.instance.createTransaction(FinancialTransaction(
          type: 'Gelir',
          amount: amount,
          date: txDate,
          category: 'Borç Ödemesi',
          description: '${contact.name} borç ödemesi',
          contactId: contact.id,
          fromAccountId: fromAccountId,
        ));
      } else if (kind == 'loan') {
        final loan = ref as Loan;
        final updated = Loan(
          id: loan.id,
          name: loan.name,
          kind: loan.kind,
          creditorId: loan.creditorId,
          bankName: loan.bankName,
          principal: loan.principal,
          totalPayable: loan.totalPayable,
          paidAmount: loan.paidAmount + amount,
          interestRate: loan.interestRate,
          termMonths: loan.termMonths,
          startDate: loan.startDate,
          isActive: loan.isActive,
        );
        await ApiService.instance.updateLoan(updated);
        await ApiService.instance.createTransaction(FinancialTransaction(
          type: 'Gider',
          amount: amount,
          date: txDate,
          category: 'Kredi Ödemesi',
          description: '${loan.name} kredi ödemesi',
          fromAccountId: fromAccountId,
        ));
      } else if (kind == 'cheque') {
        final cheque = ref as Cheque;
        final updated = Cheque(
          id: cheque.id,
          direction: cheque.direction,
          status: 'given',
          amount: cheque.amount,
          dueDate: cheque.dueDate,
          bankName: cheque.bankName,
          serialNo: cheque.serialNo,
          contactId: cheque.contactId,
          projectId: cheque.projectId,
        );
        await ApiService.instance.updateCheque(updated);
        await ApiService.instance.createTransaction(FinancialTransaction(
          type: 'Gider',
          amount: amount,
          date: txDate,
          category: 'Çek Ödemesi',
          description: cheque.bankName.isNotEmpty ? '${cheque.bankName} çeki ödemesi' : 'Çek ödemesi',
          fromAccountId: fromAccountId,
        ));
      }
      await _silentRefresh();
    } catch (e) {
      debugPrint('Borç ödenemedi: $e');
      syncError.value = 'Borç ödenemedi';
      rethrow;
    }
  }

  // --- Calculations for UI ---

  double getTotalBalance() {
    return _accounts.fold(0, (sum, item) => sum + item.balance);
  }

  // Dashboard total stats
  double getTotalTahsilat() {
    return _allTransactions
        .where((t) => t.type == 'Tahsilat' || t.type == 'Gelir')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getTotalSatis() {
    return _allTransactions
        .where((t) => t.type == 'Satış')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getTotalHarcama() {
    return _allTransactions
        .where((t) => t.type == 'Gider')
        .fold(0, (sum, item) => sum + item.amount);
  }

  // Project Specific Stats
  List<FinancialTransaction> getTransactionsForProject(int projectId) {
    return _allTransactions.where((t) => t.projectId == projectId).toList();
  }

  double getProjectTotalGider(int projectId) {
    return getTransactionsForProject(projectId)
        .where((t) => t.type == 'Gider')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getProjectTotalTahsilat(int projectId) {
    return getTransactionsForProject(projectId)
        .where((t) => t.type == 'Tahsilat' || t.type == 'Gelir')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double getProjectTotalSatis(int projectId) {
    return getTransactionsForProject(projectId)
        .where((t) => t.type == 'Satış')
        .fold(0, (sum, item) => sum + item.amount);
  }

  // Cari Hesap Stats
  List<FinancialTransaction> getTransactionsForContact(int contactId) {
    return _allTransactions.where((t) => t.contactId == contactId).toList();
  }

  /// Carileri türe göre gruplar (Tedarikçi/Müşteri/Taşeron/Devlet/Banka/Diğer).
  Map<String, List<Contact>> get contactsByKind {
    final map = <String, List<Contact>>{};
    for (final c in _contacts) {
      map.putIfAbsent(c.kind, () => []).add(c);
    }
    return map;
  }

  Map<String, double> getProjectCategorySpending(int projectId) {
    final giderler = getTransactionsForProject(projectId).where((t) => t.type == 'Gider');
    Map<String, double> categorySums = {};
    for (var g in giderler) {
      if (categorySums.containsKey(g.category)) {
        categorySums[g.category] = categorySums[g.category]! + g.amount;
      } else {
        categorySums[g.category] = g.amount;
      }
    }
    return categorySums;
  }

  // --- Toplam Borç / Alacak / Finansman Gücü (gerçek veriden hesap) ---

  /// Varlık hesapları (Banka + Nakit); kredi/BCH/kart borcu hariç.
  double getVarlikKasa() {
    return _accounts
        .where((a) => a.type == 'Banka' || a.type == 'Nakit')
        .fold(0.0, (sum, a) => sum + a.balance);
  }

  /// Toplam borç = krediler (kalan) + kullanılan BCH/kart + verilen çekler.
  double getTotalBorc() {
    final krediler = _loans.fold(0.0, (sum, l) => sum + l.remaining);
    final bchKartKullanilan = _accounts
        .where((a) => (a.type == 'BCH' || a.type == 'Kredi Kartı') && a.balance < 0)
        .fold(0.0, (sum, a) => sum + a.balance.abs());
    final verilenCekler = _cheques
        .where((c) => c.isIssued && c.status != 'cashed')
        .fold(0.0, (sum, c) => sum + c.amount);
    final ticariBorclar = _contacts
        .where((c) => (c.kind == 'supplier' || c.kind == 'subcontractor') && c.balance > 0)
        .fold(0.0, (sum, c) => sum + c.balance);
    return krediler + bchKartKullanilan + verilenCekler + ticariBorclar;
  }

  /// Toplam alacak = açık alacaklar (kalan) + alınan çekler.
  double getTotalAlacak() {
    final alacaklar = _receivables.fold(0.0, (sum, r) => sum + r.remaining);
    final alinanCekler = _cheques
        .where((c) => c.isReceived && c.status != 'cashed')
        .fold(0.0, (sum, c) => sum + c.amount);
    return alacaklar + alinanCekler;
  }

  // --- Vade takibi (ödemeler & tahsilatlar) ---

  /// Yaklaşan/geçmiş ÖDEME vadeleri: verilen çekler + vadeli ödeme işlemleri.
  List<DuePayment> getUpcomingPayments() {
    final list = <DuePayment>[];
    for (final c in _cheques.where((c) => c.isIssued && c.status != 'cashed')) {
      list.add(DuePayment(
        title: c.bankName.isNotEmpty ? '${c.bankName} çeki' : 'Verilen çek',
        amount: c.amount,
        date: DateTime.tryParse(c.dueDate),
        rawDate: c.dueDate,
        isPayable: true,
      ));
    }
    for (final t in _allTransactions.where((t) => t.dueDate.isNotEmpty && t.type == 'Gider')) {
      list.add(DuePayment(
        title: t.description.isNotEmpty ? t.description : (t.category.isNotEmpty ? t.category : 'Ödeme'),
        amount: t.amount,
        date: DateTime.tryParse(t.dueDate),
        rawDate: t.dueDate,
        isPayable: true,
      ));
    }
    _sortByDate(list);
    return list;
  }

  /// Yaklaşan/geçmiş TAHSİLAT vadeleri: alınan çekler + açık alacaklar.
  List<DuePayment> getUpcomingCollections() {
    final list = <DuePayment>[];
    for (final c in _cheques.where((c) => c.isReceived && c.status != 'cashed')) {
      list.add(DuePayment(
        title: c.bankName.isNotEmpty ? '${c.bankName} çeki' : 'Alınan çek',
        amount: c.amount,
        date: DateTime.tryParse(c.dueDate),
        rawDate: c.dueDate,
        isPayable: false,
      ));
    }
    for (final r in _receivables.where((r) => r.remaining > 0)) {
      list.add(DuePayment(
        title: r.description.isNotEmpty ? r.description : _receivableKindLabel(r.kind),
        amount: r.remaining,
        date: DateTime.tryParse(r.dueDate),
        rawDate: r.dueDate,
        isPayable: false,
      ));
    }
    _sortByDate(list);
    return list;
  }

  /// Tüm yaklaşan vadeler (ödeme + tahsilat) — bildirimler için.
  List<DuePayment> getAllDuePayments() {
    final all = [...getUpcomingPayments(), ...getUpcomingCollections()];
    _sortByDate(all);
    return all;
  }

  // --- Bildirim okundu durumu ---

  /// Bir bildirim için içeriğe dayalı, yeniden hesaplamada da kararlı benzersiz anahtar.
  String notificationKey(DuePayment p) =>
      '${p.isPayable}|${p.title}|${p.rawDate}|${p.amount}';

  bool isNotificationRead(DuePayment p) =>
      _readNotificationKeys.contains(notificationKey(p));

  /// Henüz okunmamış bildirim sayısı (kırmızı nokta göstergesi için).
  int get unreadNotificationCount =>
      getAllDuePayments().where((p) => !isNotificationRead(p)).length;

  bool get hasUnreadNotifications => unreadNotificationCount > 0 || getDueRecurringTemplates().isNotEmpty;

  Future<void> markNotificationRead(DuePayment p) async {
    if (_readNotificationKeys.add(notificationKey(p))) {
      notifyListeners();
      await _persistReadNotifications();
    }
  }

  Future<void> markAllNotificationsRead() async {
    var changed = false;
    for (final p in getAllDuePayments()) {
      if (_readNotificationKeys.add(notificationKey(p))) changed = true;
    }
    if (changed) {
      notifyListeners();
      await _persistReadNotifications();
    }
  }

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _readNotificationKeys
      ..clear()
      ..addAll(prefs.getStringList(_kReadNotifications) ?? const []);
    notifyListeners();
  }

  Future<void> _persistReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReadNotifications, _readNotificationKeys.toList());
  }

  void _sortByDate(List<DuePayment> list) {
    list.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
  }

  String _receivableKindLabel(String kind) {
    switch (kind) {
      case 'installment':
        return 'Satış taksiti';
      case 'customer':
        return 'Müşteri alacağı';
      case 'government':
        return 'Devlet alacağı';
      case 'retention':
        return 'Hakediş';
      default:
        return 'Alacak';
    }
  }

  /// Finansman gücü = kullanılabilir BCH + kullanılabilir kart limitleri + esnek hesaplar.
  double getFinansmanGucu() {
    return _accounts
        .where((a) => a.type == 'BCH' || a.type == 'Kredi Kartı' || a.type == 'Esnek')
        .fold(0.0, (sum, a) => sum + a.creditLimit);
  }

  /// 5 bölümlü finans panelini GERÇEK veritabanı verisinden kurar.
  List<PanelSection> buildPanelSections() {
    return [
      _buildKasa(),
      _buildBorclar(),
      _buildFinansman(),
      _buildProjeMaliyetleri(),
      _buildAlacaklar(),
    ];
  }

  // Tekil bölüm erişimleri (ilgili detay ekranları için).
  PanelSection get kasaSection => _buildKasa();
  PanelSection get borclarSection => _buildBorclar();
  PanelSection get finansmanSection => _buildFinansman();
  PanelSection get projeMaliyetleriSection => _buildProjeMaliyetleri();
  PanelSection get alacaklarSection => _buildAlacaklar();

  // 1. KASA — Bankalar / Nakit / Borsa
  PanelSection _buildKasa() {
    List<PanelItem> byType(String t) =>
        [for (final a in _accounts.where((a) => a.type == t)) PanelItem(a.name, a.balance)];
    return PanelSection(
      title: 'Kasa',
      totalLabel: 'TOPLAM KASA',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: const Color(0xFF3B82F6),
      bgColor: const Color(0xFFEFF6FF),
      groups: [
        PanelGroup('Bankalar', byType('Banka')),
        PanelGroup('Nakit', byType('Nakit')),
        PanelGroup('Borsa', byType('Borsa')),
      ],
    );
  }

  // 2. BORÇLAR — Banka Borçları (krediler + kullanılan BCH/kart) / Çekler / Ticari
  PanelSection _buildBorclar() {
    final bankaBorclari = <PanelItem>[
      for (final l in _loans) PanelItem(l.name, l.remaining),
      for (final a in _accounts.where((a) => (a.type == 'BCH' || a.type == 'Kredi Kartı') && a.balance < 0))
        PanelItem('${a.name} (kullanılan)', a.balance.abs()),
    ];
    final verilenCekler = [
      for (final c in _cheques.where((c) => c.isIssued && c.status != 'cashed'))
        PanelItem(c.bankName.isNotEmpty ? '${c.bankName} çeki' : 'Çek', c.amount),
    ];
    final ticariBorclar = [
      for (final c in _contacts.where((c) =>
          (c.kind == 'supplier' || c.kind == 'subcontractor') && c.balance > 0))
        PanelItem(c.name, c.balance),
    ];
    return PanelSection(
      title: 'Borçlar',
      totalLabel: 'TOPLAM BORÇ',
      icon: Icons.receipt_long_rounded,
      accentColor: const Color(0xFFEF4444),
      bgColor: const Color(0xFFFEF2F2),
      groups: [
        PanelGroup('Banka Borçları', bankaBorclari),
        PanelGroup('Ticari Borçlar', ticariBorclar),
        PanelGroup('Çekler', verilenCekler),
      ],
    );
  }

  // 3. FİNANSMAN GÜCÜ — BCH Limitleri / Kart Limitleri / Esnek Hesap Limitleri
  PanelSection _buildFinansman() {
    List<PanelItem> avail(String t) => [
          for (final a in _accounts.where((a) => a.type == t && a.availableLimit > 0))
            PanelItem(a.name, a.availableLimit)
        ];
    return PanelSection(
      title: 'Finansman Gücü',
      totalLabel: 'TOPLAM FİNANSMAN GÜCÜ',
      icon: Icons.shield_rounded,
      accentColor: const Color(0xFF8B5CF6),
      bgColor: const Color(0xFFFAF5FF),
      groups: [
        PanelGroup('BCH Limitleri', avail('BCH')),
        PanelGroup('Kredi Kartı Limitleri', avail('Kredi Kartı')),
        PanelGroup('Esnek Hesap Limitleri', avail('Esnek')),
      ],
    );
  }

  // 4. PROJE MALİYETLERİ — her proje, kategori bazında harcama
  PanelSection _buildProjeMaliyetleri() {
    final projeGroups = <PanelGroup>[];
    for (final p in _projects) {
      if (p.id == null) continue;
      final spending = getProjectCategorySpending(p.id!);
      final items = [for (final e in spending.entries) PanelItem(e.key, e.value)];
      projeGroups.add(PanelGroup(p.name, items.isEmpty ? [PanelItem(p.name, 0)] : items));
    }
    return PanelSection(
      title: 'Proje Maliyetleri',
      totalLabel: 'TOPLAM PROJE MALİYETİ',
      icon: Icons.business_center_rounded,
      accentColor: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFFF7ED),
      groups: projeGroups,
    );
  }

  // 5. ALACAKLAR — Satış taksitleri / Müşteri / Devlet / Alınan çekler
  PanelSection _buildAlacaklar() {
    List<PanelItem> recv(String kind) => [
          for (final r in _receivables.where((r) => r.kind == kind && r.remaining > 0))
            PanelItem(r.description.isNotEmpty ? r.description : r.kind, r.remaining)
        ];
    final alinanCekler = [
      for (final c in _cheques.where((c) => c.isReceived && c.status != 'cashed'))
        PanelItem(c.bankName.isNotEmpty ? '${c.bankName} çeki' : 'Çek', c.amount),
    ];
    return PanelSection(
      title: 'Alacaklar',
      totalLabel: 'TOPLAM ALACAK',
      icon: Icons.assignment_returned_rounded,
      accentColor: const Color(0xFF10B981),
      bgColor: const Color(0xFFF0FDF4),
      groups: [
        PanelGroup('Satış / Vadeli Tahsilatlar', recv('installment')),
        PanelGroup('Müşteri Alacakları', recv('customer')),
        PanelGroup('Devlet Alacakları', recv('government')),
        PanelGroup('Alınan Çekler', alinanCekler),
      ],
    );
  }
}
