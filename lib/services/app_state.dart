import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/categorization_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final DatabaseService _db = DatabaseService();
  final CategorizationService _categorizer = CategorizationService();

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init() async {
    await _db.init();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _db.refresh();
    notifyListeners();
  }

  DatabaseService get db => _db;
  CategorizationService get categorizer => _categorizer;

  // ─── Transactions ─────────────────────────────────────────────────────────────

  List<Transaction> get allTransactions => _db.allTransactions;

  List<Transaction> getTransactionsForMonth(int month, int year) =>
      _db.getTransactionsForMonth(month, year);

  List<Transaction> getTransactionsForDay(DateTime day) =>
      _db.getTransactionsForDay(day);

  double get totalBalance => _db.getTotalBalanceFromTransactions();

  double getTotalIncome(int month, int year) =>
      _db.getTotalIncomeForMonth(month, year);

  double getTotalExpense(int month, int year) =>
      _db.getTotalExpenseForMonth(month, year);

  Map<String, double> getCategorySpend(int month, int year) =>
      _db.getCategorySpendForMonth(month, year);

  List<double> getMonthlySpendForYear(int year) {
    return List.generate(12, (i) => _db.getTotalSpendForYear(i + 1, year));
  }

  Future<void> addTransaction(Transaction txn) async {
    await _db.addTransaction(txn);
    notifyListeners();
  }

  Future<void> addManualTransaction({
    required double amount,
    required String type,
    required String merchant,
    required String paymentMode,
    required DateTime date,
    String? category,
    String? subcategory,
    String status = 'success',
  }) async {
    final cat =
        category ??
        _db.getCategoryOverride(merchant) ??
        _categorizer.categorize(merchant);
    final sub = subcategory ?? _categorizer.getSubcategory(merchant);

    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      amount: amount,
      type: type,
      paymentMode: paymentMode,
      merchant: merchant,
      category: cat,
      subcategory: sub,
      source: 'Manual',
      rawText: '',
      accountNo: '',
      bankRefNo: '',
      status: status,
    );
    await _db.addTransaction(txn);
    notifyListeners();
  }

  Future<void> updateTransactionCategory(
    String id,
    String category,
    String subcategory,
  ) async {
    await _db.updateTransactionCategory(id, category, subcategory);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    notifyListeners();
  }

  Future<void> reprocessSmsTransactions() async {
    final parser = CategorizationService();
    for (var txn in _db.allTransactions) {
      if (txn.source == 'SMS' && txn.rawText.isNotEmpty) {
        final parsed = parser.parseSms(txn.rawText, 'Unknown');
        if (parsed != null) {
          final newMerchant = parsed['merchant'] as String? ?? txn.merchant;
          final newAcct = parsed['accountNo'] as String? ?? '';
          final newRef = parsed['bankRefNo'] as String? ?? '';
          
          final shouldUpdateCat = txn.category == 'Uncategorised' || txn.category == 'Uncategorized';
          final newCat = shouldUpdateCat ? parser.categorize(newMerchant) : txn.category;
          final newSub = shouldUpdateCat ? parser.getSubcategory(newMerchant) : txn.subcategory;

          await _db.updateTransactionCategory(txn.id, newCat, newSub);
          
          // Dirty update for other fields directly in DB instance for this one-off migration
          final idx = _db.allTransactions.indexWhere((t) => t.id == txn.id);
          if (idx != -1) {
            final old = _db.allTransactions[idx];
            _db.allTransactions[idx] = Transaction(
              id: old.id,
              date: old.date,
              amount: old.amount,
              type: old.type,
              paymentMode: old.paymentMode,
              merchant: newMerchant,
              category: newCat,
              subcategory: newSub,
              source: old.source,
              rawText: old.rawText,
              accountNo: newAcct.isNotEmpty ? newAcct : old.accountNo,
              bankRefNo: newRef.isNotEmpty ? newRef : old.bankRefNo,
              status: old.status,
              isSubscription: old.isSubscription,
            );
          }
        }
      }
    }
    // Force save all
    await _db.deleteTransaction('trigger_save'); // hack to save without exposing private method, though we could just notify
    notifyListeners();
  }

  // ─── Budgets ─────────────────────────────────────────────────────────────────

  double getBudget(String category, int month, int year) =>
      _db.getBudgetForCategory(category, month, year);

  Future<void> setBudget(
    String category,
    double limit,
    int month,
    int year,
  ) async {
    await _db.setBudget(category, limit, month, year);
    notifyListeners();
  }

  // ─── User Settings ────────────────────────────────────────────────────────────

  UserSettings get userSettings => _db.userSettings;

  Future<void> saveUserSettings(UserSettings settings) async {
    await _db.saveUserSettings(settings);
    notifyListeners();
  }

  Future<void> setOnboardingDone() async {
    await _db.setOnboardingDone();
  }

  Future<bool> isOnboardingDone() => _db.isOnboardingDone();

  // ─── Subscriptions ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get detectedSubscriptions =>
      _db.detectSubscriptions();

  // ─── Insights ─────────────────────────────────────────────────────────────────

  List<String> getInsights(int month, int year) =>
      _db.generateInsights(month, year);

  // ─── Export ───────────────────────────────────────────────────────────────────

  String exportCsv() => _db.exportToCsv();

  Future<void> deleteAllData() async {
    await _db.deleteAllData();
    notifyListeners();
  }
}
