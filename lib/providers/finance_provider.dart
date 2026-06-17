import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/financial_transaction.dart';
import '../models/account.dart';
import '../models/company_profile.dart';
import '../models/finance_panel.dart';
import '../models/finance_entities.dart';
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
  CompanyProfile? _companyProfile;

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
  CompanyProfile? get companyProfile => _companyProfile;

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

  /// Kullanıcının eklediği yeni alt kategoriyi kaydeder ve listeyi yeniler.
  Future<Category> addSubCategory({
    required String name,
    required int parentId,
    required String type,
  }) async {
    final created = await ApiService.instance.createCategory(
      name: name,
      type: type,
      parentId: parentId,
    );
    _categories = await ApiService.instance.readAllCategories();
    notifyListeners();
    return created;
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  FinanceProvider() {
    refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await ApiService.instance.readAllProjects();
      _accounts = await ApiService.instance.readAllAccounts();
      _allTransactions = await ApiService.instance.readAllTransactions();
      // Yeni şema verileri — biri başarısız olsa bile diğerleri yüklensin
      _loans = await _safe(ApiService.instance.readAllLoans, _loans);
      _cheques = await _safe(ApiService.instance.readAllCheques, _cheques);
      _sales = await _safe(ApiService.instance.readAllSales, _sales);
      _receivables = await _safe(ApiService.instance.readAllReceivables, _receivables);
      _contacts = await _safe(ApiService.instance.readAllContacts, _contacts);
      _categories = await _safe(ApiService.instance.readAllCategories, _categories);
      _budgetLines = await _safe(ApiService.instance.readAllBudgetLines, _budgetLines);
      try {
        _companyProfile = await ApiService.instance.getCompanyProfile();
      } catch (e) {
        debugPrint("Company profile load failed: $e");
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
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
    await ApiService.instance.updateAccount(account);
    await refreshData();
  }

  Future<void> createAccount(Account account) async {
    await ApiService.instance.createAccount(account);
    await refreshData();
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    await ApiService.instance.createTransaction(transaction);
    await refreshData();
  }

  Future<void> createProject(Project project) async {
    await ApiService.instance.createProject(project);
    await refreshData();
  }

  Future<void> updateProject(Project project) async {
    await ApiService.instance.updateProject(project);
    await refreshData();
  }

  Future<void> deleteProject(int projectId) async {
    await ApiService.instance.deleteProject(projectId);
    await refreshData();
  }

  // --- CRUD sarmalayıcıları (yeni modüller) ---
  Future<void> addLoan(Loan loan) async {
    await ApiService.instance.createLoan(loan);
    await refreshData();
  }

  Future<void> addCheque(Cheque cheque) async {
    await ApiService.instance.createCheque(cheque);
    await refreshData();
  }

  Future<Contact> addContact(Contact contact) async {
    final c = await ApiService.instance.createContact(contact);
    await refreshData();
    return c;
  }

  Future<void> addSale(Sale sale) async {
    await ApiService.instance.createSale(sale);
    await refreshData();
  }

  Future<void> addReceivable(Receivable r) async {
    await ApiService.instance.createReceivable(r);
    await refreshData();
  }

  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    _companyProfile = await ApiService.instance.updateCompanyProfile(profile);
    notifyListeners();
  }

  // --- Bütçe ---
  Future<void> addBudgetLine(BudgetLine line) async {
    await ApiService.instance.createBudgetLine(line);
    await refreshData();
  }

  Future<void> updateBudgetLine(BudgetLine line) async {
    await ApiService.instance.updateBudgetLine(line);
    await refreshData();
  }

  Future<void> deleteBudgetLine(int id) async {
    await ApiService.instance.deleteBudgetLine(id);
    await refreshData();
  }

  List<BudgetLine> getProjectBudgetLines(int projectId) =>
      _budgetLines.where((b) => b.projectId == projectId).toList();

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
    await ApiService.instance.updateReceivable(updated);

    await ApiService.instance.createTransaction(
      FinancialTransaction(
        type: 'Tahsilat',
        amount: amount,
        date: date.isNotEmpty ? date : DateTime.now().toIso8601String().split('T').first,
        category: 'Tahsilat',
        description: receivable.description,
        projectId: receivable.projectId,
        toAccountId: toAccountId,
      ),
    );
    await refreshData();
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
