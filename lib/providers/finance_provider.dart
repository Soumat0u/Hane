import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/financial_transaction.dart';
import '../models/account.dart';
import '../services/database_helper.dart';

class FinanceProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<Account> _accounts = [];
  List<FinancialTransaction> _allTransactions = [];

  List<Project> get projects => _projects;
  List<Account> get accounts => _accounts;
  List<FinancialTransaction> get allTransactions => _allTransactions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  FinanceProvider() {
    refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await DatabaseHelper.instance.readAllProjects();
      _accounts = await DatabaseHelper.instance.readAllAccounts();
      _allTransactions = await DatabaseHelper.instance.readAllTransactions();
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction);
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
}
