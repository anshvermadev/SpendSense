import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String paymentMode; // UPI, Card, Cash, Auto-debit, ATM
  final String merchant;
  final String category;
  final String subcategory;
  final String source; // SMS, CSV, Manual
  final String rawText;
  final String accountNo;
  final String bankRefNo;
  final String status; // 'success', 'failed', 'pending'
  bool isSubscription;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.paymentMode,
    required this.merchant,
    required this.category,
    required this.subcategory,
    required this.source,
    required this.rawText,
    this.accountNo = '',
    this.bankRefNo = '',
    this.status = 'success',
    this.isSubscription = false,
  });

  bool get isCredit => type == 'credit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'type': type,
    'paymentMode': paymentMode,
    'merchant': merchant,
    'category': category,
    'subcategory': subcategory,
    'source': source,
    'rawText': rawText,
    'accountNo': accountNo,
    'bankRefNo': bankRefNo,
    'status': status,
    'isSubscription': isSubscription,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    paymentMode: json['paymentMode'] as String? ?? 'UPI',
    merchant: json['merchant'] as String,
    category: json['category'] as String,
    subcategory: json['subcategory'] as String? ?? '',
    source: json['source'] as String? ?? 'Manual',
    rawText: json['rawText'] as String? ?? '',
    accountNo: json['accountNo'] as String? ?? '',
    bankRefNo: json['bankRefNo'] as String? ?? '',
    status: _parseStatus(json['status'] as String?, json['rawText'] as String?),
    isSubscription: json['isSubscription'] as bool? ?? false,
  );

  static String _parseStatus(String? status, String? rawText) {
    if (status != null && status.isNotEmpty) {
      final s = status.toLowerCase().trim();
      if (s == 'fail' || s == 'failed' || s == 'failure') return 'failed';
      if (s == 'pending' || s == 'process' || s == 'processing') return 'pending';
      return 'success';
    }
    final raw = (rawText ?? '').toLowerCase();
    if (raw.contains('fail') ||
        raw.contains('declin') ||
        raw.contains('unsuccessful') ||
        raw.contains('bounc')) {
      return 'failed';
    }
    if (raw.contains('pending') ||
        raw.contains('processing') ||
        raw.contains('in progress')) {
      return 'pending';
    }
    return 'success';
  }
}

class Budget {
  final String category;
  final double monthlyLimit;
  final int month;
  final int year;

  Budget({
    required this.category,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'monthlyLimit': monthlyLimit,
    'month': month,
    'year': year,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    category: json['category'] as String,
    monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
    month: json['month'] as int,
    year: json['year'] as int,
  );
}

class MerchantOverride {
  final String merchantKeyword;
  final String category;
  final String subcategory;

  MerchantOverride({
    required this.merchantKeyword,
    required this.category,
    required this.subcategory,
  });

  Map<String, dynamic> toJson() => {
    'merchantKeyword': merchantKeyword,
    'category': category,
    'subcategory': subcategory,
  };

  factory MerchantOverride.fromJson(Map<String, dynamic> json) =>
      MerchantOverride(
        merchantKeyword: json['merchantKeyword'] as String,
        category: json['category'] as String,
        subcategory: json['subcategory'] as String? ?? '',
      );
}

class UserSettings {
  String name;
  double monthlyIncome;
  String currency;
  bool notificationsEnabled;
  bool smsReadingEnabled;
  List<String> trackedCategories;

  UserSettings({
    this.name = '',
    this.monthlyIncome = 0,
    this.currency = '₹',
    this.notificationsEnabled = true,
    this.smsReadingEnabled = true,
    this.trackedCategories = const [
      'Food',
      'Groceries',
      'Transport',
      'Shopping',
      'Fuel',
      'Entertainment',
      'Subscriptions',
      'Utilities',
      'Medical',
      'Housing',
      'Education',
      'Travel',
      'Personal',
      'EMI',
    ],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'monthlyIncome': monthlyIncome,
    'currency': currency,
    'notificationsEnabled': notificationsEnabled,
    'smsReadingEnabled': smsReadingEnabled,
    'trackedCategories': trackedCategories,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    name: json['name'] as String? ?? '',
    monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? '₹',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    smsReadingEnabled: json['smsReadingEnabled'] as bool? ?? true,
    trackedCategories:
        (json['trackedCategories'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [
          'Food',
          'Groceries',
          'Transport',
          'Shopping',
          'Fuel',
          'Entertainment',
          'Subscriptions',
          'Utilities',
          'Medical',
          'Housing',
          'Education',
          'Travel',
          'Personal',
          'EMI',
        ],
  );
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _transactionsKey = 'transactions';
  static const String _budgetsKey = 'budgets';
  static const String _merchantOverridesKey = 'merchant_overrides';
  static const String _userSettingsKey = 'user_settings';
  static const String _onboardingDoneKey = 'onboarding_done';
  static const String _deletedSignaturesKey = 'deleted_signatures';

  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<MerchantOverride> _merchantOverrides = [];
  List<String> _deletedSignatures = [];
  UserSettings _userSettings = UserSettings();
  bool _initialized = false;

  Future<void> refresh() async {
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Force reload from disk to sync background isolate changes
    await init();
  }

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Load deleted signatures
    final deletedJson = prefs.getString(_deletedSignaturesKey);
    if (deletedJson != null) {
      final list = jsonDecode(deletedJson) as List<dynamic>;
      _deletedSignatures = list.map((e) => e as String).toList();
    }

    // Load transactions
    final txnJson = prefs.getString(_transactionsKey);
    if (txnJson != null) {
      final list = jsonDecode(txnJson) as List<dynamic>;
      _transactions = list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .where((t) => !isTransactionDeleted(t.id, t.bankRefNo, t.rawText))
          .toList();
    }

    // Load budgets
    final budgetJson = prefs.getString(_budgetsKey);
    if (budgetJson != null) {
      final list = jsonDecode(budgetJson) as List<dynamic>;
      _budgets = list
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Load merchant overrides
    final overrideJson = prefs.getString(_merchantOverridesKey);
    if (overrideJson != null) {
      final list = jsonDecode(overrideJson) as List<dynamic>;
      _merchantOverrides = list
          .map((e) => MerchantOverride.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Load user settings
    final settingsJson = prefs.getString(_userSettingsKey);
    if (settingsJson != null) {
      _userSettings = UserSettings.fromJson(
        jsonDecode(settingsJson) as Map<String, dynamic>,
      );
    }

    _initialized = true;
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transactionsKey,
      jsonEncode(_transactions.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _budgetsKey,
      jsonEncode(_budgets.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> _saveMerchantOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _merchantOverridesKey,
      jsonEncode(_merchantOverrides.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userSettingsKey, jsonEncode(_userSettings.toJson()));
  }

  Future<void> _saveDeletedSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deletedSignaturesKey, jsonEncode(_deletedSignatures));
  }

  bool isTransactionDeleted(String id, String bankRefNo, String rawText) {
    final idTrim = id.trim();
    final refTrim = bankRefNo.trim();
    if (idTrim.isNotEmpty && _deletedSignatures.contains(idTrim)) return true;
    if (refTrim.isNotEmpty && _deletedSignatures.contains(refTrim)) return true;
    return false;
  }

  // ─── Transactions ───────────────────────────────────────────────────────────

  List<Transaction> get allTransactions {
    final copy = List<Transaction>.from(_transactions);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<Transaction> getTransactionsForMonth(int month, int year) {
    return _transactions
        .where((t) => t.date.month == month && t.date.year == year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsForDay(DateTime day) {
    return _transactions
        .where(
          (t) =>
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalBalanceFromTransactions() {
    double balance = 0;
    for (final t in _transactions) {
      if (t.isCredit) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double getTotalIncomeForMonth(int month, int year) {
    return _transactions
        .where(
          (t) => t.date.month == month && t.date.year == year && t.isCredit,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseForMonth(int month, int year) {
    return _transactions
        .where(
          (t) => t.date.month == month && t.date.year == year && !t.isCredit,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalSpendForYear(int month, int year) {
    return _transactions
        .where(
          (t) => t.date.month == month && t.date.year == year && !t.isCredit,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategorySpendForMonth(int month, int year) {
    final Map<String, double> result = {};
    for (final t in _transactions) {
      if (t.date.month == month && t.date.year == year && !t.isCredit) {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
    }
    return result;
  }

  Future<void> addTransaction(Transaction txn) async {
    if (isTransactionDeleted(txn.id, txn.bankRefNo, txn.rawText)) {
      return;
    }
    // Avoid re-adding identical existing transactions
    final isDup = _transactions.any(
      (t) =>
          (t.id.trim().isNotEmpty && t.id.trim() == txn.id.trim()) ||
          (txn.bankRefNo.trim().isNotEmpty &&
              t.bankRefNo.trim() == txn.bankRefNo.trim()),
    );
    if (isDup) return;

    _transactions.add(txn);
    await _saveTransactions();
  }

  Future<void> updateTransactionCategory(
    String id,
    String category,
    String subcategory, {
    bool updateAllForMerchant = true,
  }) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = _transactions[idx];
    final targetMerchant = old.merchant.trim().toLowerCase();

    if (updateAllForMerchant && targetMerchant.isNotEmpty && targetMerchant != 'unknown') {
      for (int i = 0; i < _transactions.length; i++) {
        final t = _transactions[i];
        if (t.merchant.trim().toLowerCase() == targetMerchant) {
          _transactions[i] = Transaction(
            id: t.id,
            date: t.date,
            amount: t.amount,
            type: t.type,
            paymentMode: t.paymentMode,
            merchant: t.merchant,
            category: category,
            subcategory: subcategory,
            source: t.source,
            rawText: t.rawText,
            accountNo: t.accountNo,
            bankRefNo: t.bankRefNo,
            status: t.status,
            isSubscription: t.isSubscription,
          );
        }
      }
    } else {
      _transactions[idx] = Transaction(
        id: old.id,
        date: old.date,
        amount: old.amount,
        type: old.type,
        paymentMode: old.paymentMode,
        merchant: old.merchant,
        category: category,
        subcategory: subcategory,
        source: old.source,
        rawText: old.rawText,
        accountNo: old.accountNo,
        bankRefNo: old.bankRefNo,
        status: old.status,
        isSubscription: old.isSubscription,
      );
    }

    // Save sticky merchant override for future transactions
    if (targetMerchant.isNotEmpty && targetMerchant != 'unknown') {
      await addMerchantOverride(
        MerchantOverride(
          merchantKeyword: targetMerchant,
          category: category,
          subcategory: subcategory,
        ),
      );
    }
    await _saveTransactions();
  }

  Future<void> updateCategoryForMerchant(
    String merchant,
    String category,
    String subcategory,
  ) async {
    final targetMerchant = merchant.trim().toLowerCase();
    if (targetMerchant.isEmpty || targetMerchant == 'unknown') return;

    for (int i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.merchant.trim().toLowerCase() == targetMerchant) {
        _transactions[i] = Transaction(
          id: t.id,
          date: t.date,
          amount: t.amount,
          type: t.type,
          paymentMode: t.paymentMode,
          merchant: t.merchant,
          category: category,
          subcategory: subcategory,
          source: t.source,
          rawText: t.rawText,
          accountNo: t.accountNo,
          bankRefNo: t.bankRefNo,
          status: t.status,
          isSubscription: t.isSubscription,
        );
      }
    }

    await addMerchantOverride(
      MerchantOverride(
        merchantKeyword: targetMerchant,
        category: category,
        subcategory: subcategory,
      ),
    );
    await _saveTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final idTrim = id.trim();
    final targetIdx = _transactions.indexWhere((t) => t.id.trim() == idTrim);
    if (targetIdx == -1) return;

    final target = _transactions[targetIdx];
    final targetMerchant = target.merchant.trim().toLowerCase();

    // Tombstone the deleted ID and bankRefNo so it can never be restored
    if (idTrim.isNotEmpty && !_deletedSignatures.contains(idTrim)) {
      _deletedSignatures.add(idTrim);
    }
    if (target.bankRefNo.trim().isNotEmpty &&
        !_deletedSignatures.contains(target.bankRefNo.trim())) {
      _deletedSignatures.add(target.bankRefNo.trim());
    }

    _transactions.removeAt(targetIdx);

    // If there are no remaining transactions for this merchant,
    // clear the sticky category override and memory so future payments prompt again!
    if (targetMerchant.isNotEmpty && targetMerchant != 'unknown') {
      final hasRemaining = _transactions.any(
        (t) => t.merchant.trim().toLowerCase() == targetMerchant,
      );
      if (!hasRemaining) {
        await removeMerchantOverride(targetMerchant);
      }
    }

    await _saveDeletedSignatures();
    await _saveTransactions();
  }

  Future<void> updateTransactionFull(Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _transactions[idx] = updated;
    await _saveTransactions();
  }

  void replaceTransactionInList(Transaction updated) {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _transactions[idx] = updated;
    }
  }

  Future<void> saveAllTransactions() async {
    await _saveTransactions();
  }

  // ─── Budgets ─────────────────────────────────────────────────────────────────

  List<Budget> getBudgetsForMonth(int month, int year) {
    return _budgets.where((b) => b.month == month && b.year == year).toList();
  }

  double getBudgetForCategory(String category, int month, int year) {
    final budget = _budgets.firstWhere(
      (b) => b.category == category && b.month == month && b.year == year,
      orElse: () =>
          Budget(category: category, monthlyLimit: 0, month: month, year: year),
    );
    return budget.monthlyLimit;
  }

  Future<void> setBudget(
    String category,
    double limit,
    int month,
    int year,
  ) async {
    final idx = _budgets.indexWhere(
      (b) => b.category == category && b.month == month && b.year == year,
    );
    if (idx >= 0) {
      _budgets[idx] = Budget(
        category: category,
        monthlyLimit: limit,
        month: month,
        year: year,
      );
    } else {
      _budgets.add(
        Budget(
          category: category,
          monthlyLimit: limit,
          month: month,
          year: year,
        ),
      );
    }
    await _saveBudgets();
  }

  // ─── Merchant Overrides ───────────────────────────────────────────────────────

  Future<void> addMerchantOverride(MerchantOverride override) async {
    final key = override.merchantKeyword.trim().toLowerCase();
    final normalizedOverride = MerchantOverride(
      merchantKeyword: key,
      category: override.category,
      subcategory: override.subcategory,
    );
    final idx = _merchantOverrides.indexWhere(
      (m) => m.merchantKeyword.trim().toLowerCase() == key,
    );
    if (idx >= 0) {
      _merchantOverrides[idx] = normalizedOverride;
    } else {
      _merchantOverrides.add(normalizedOverride);
    }
    await _saveMerchantOverrides();
  }

  String? getCategoryOverride(String merchant) {
    final lower = merchant.trim().toLowerCase();
    if (lower.isEmpty || lower == 'unknown') return null;
    // 1. Exact match has highest precedence
    for (final o in _merchantOverrides) {
      if (lower == o.merchantKeyword.trim().toLowerCase()) return o.category;
    }
    // 2. Substring match
    for (final o in _merchantOverrides) {
      final key = o.merchantKeyword.trim().toLowerCase();
      if (key.isNotEmpty && lower.contains(key)) return o.category;
    }
    return null;
  }

  String? getSubcategoryOverride(String merchant) {
    final lower = merchant.trim().toLowerCase();
    if (lower.isEmpty || lower == 'unknown') return null;
    // 1. Exact match has highest precedence
    for (final o in _merchantOverrides) {
      if (lower == o.merchantKeyword.trim().toLowerCase()) return o.subcategory;
    }
    // 2. Substring match
    for (final o in _merchantOverrides) {
      final key = o.merchantKeyword.trim().toLowerCase();
      if (key.isNotEmpty && lower.contains(key)) return o.subcategory;
    }
    return null;
  }

  Future<void> removeMerchantOverride(String merchant) async {
    final lower = merchant.trim().toLowerCase();
    if (lower.isEmpty || lower == 'unknown') return;
    _merchantOverrides.removeWhere(
      (m) => m.merchantKeyword.trim().toLowerCase() == lower,
    );
    await _saveMerchantOverrides();
  }

  // ─── User Settings ────────────────────────────────────────────────────────────

  UserSettings get userSettings => _userSettings;

  Future<void> saveUserSettings(UserSettings settings) async {
    _userSettings = settings;
    await _saveUserSettings();
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  // ─── Subscriptions ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> detectSubscriptions() {
    final Map<String, List<Transaction>> byMerchant = {};
    for (final t in _transactions) {
      if (!t.isCredit) {
        byMerchant.putIfAbsent(t.merchant, () => []).add(t);
      }
    }

    final List<Map<String, dynamic>> subscriptions = [];
    byMerchant.forEach((merchant, txns) {
      if (txns.length < 2) return;
      txns.sort((a, b) => a.date.compareTo(b.date));
      final amounts = txns.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final allSimilar = amounts.every(
        (a) => (a - avgAmount).abs() / avgAmount < 0.15,
      );
      if (!allSimilar) return;

      // Check monthly recurrence
      bool isMonthly = false;
      for (int i = 1; i < txns.length; i++) {
        final diff = txns[i].date.difference(txns[i - 1].date).inDays;
        if (diff >= 25 && diff <= 35) {
          isMonthly = true;
          break;
        }
      }
      if (!isMonthly && txns.length < 3) return;

      subscriptions.add({
        'merchant': merchant,
        'averageAmount': avgAmount,
        'firstSeen': txns.first.date,
        'lastSeen': txns.last.date,
        'activeMonths': txns.length,
        'isActive': true,
      });
    });

    return subscriptions;
  }

  // ─── Insights ─────────────────────────────────────────────────────────────────

  List<String> generateInsights(int month, int year) {
    final insights = <String>[];
    final categorySpend = getCategorySpendForMonth(month, year);
    final totalExpense = getTotalExpenseForMonth(month, year);
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysLeft = (month == now.month && year == now.year)
        ? daysInMonth - now.day
        : 0;

    if (categorySpend.isEmpty) {
      insights.add(
        'No transactions recorded for this month yet. Add transactions to see insights.',
      );
      return insights;
    }

    // Top spending category
    final topCategory = categorySpend.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    insights.add(
      'Your top spending category is ${topCategory.key} at ₹${_fmt(topCategory.value)} this month.',
    );

    // Budget usage
    final budget = getBudgetForCategory(topCategory.key, month, year);
    if (budget > 0) {
      final pct = (topCategory.value / budget * 100).toStringAsFixed(1);
      if (daysLeft > 0) {
        insights.add(
          'You are at $pct% of your ${topCategory.key} budget with $daysLeft days left this month.',
        );
      } else {
        insights.add(
          'You used $pct% of your ${topCategory.key} budget this month.',
        );
      }
    }

    // Compare to previous month
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevExpense = getTotalExpenseForMonth(prevMonth, prevYear);
    if (prevExpense > 0 && totalExpense > 0) {
      final change = ((totalExpense - prevExpense) / prevExpense * 100).abs();
      final direction = totalExpense > prevExpense ? 'more' : 'less';
      insights.add(
        'You spent ${change.toStringAsFixed(1)}% $direction than last month (₹${_fmt(prevExpense)} vs ₹${_fmt(totalExpense)}).',
      );
    }

    return insights;
  }

  String _fmt(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  // ─── Export ───────────────────────────────────────────────────────────────────

  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Date,Amount,Type,Payment Mode,Merchant,Category,Subcategory,Source',
    );
    for (final t in allTransactions) {
      buffer.writeln(
        '${t.date.toIso8601String()},${t.amount},${t.type},${t.paymentMode},"${t.merchant}","${t.category}","${t.subcategory}",${t.source}',
      );
    }
    return buffer.toString();
  }

  Future<void> deleteAllData() async {
    _transactions.clear();
    _budgets.clear();
    _merchantOverrides.clear();
    _deletedSignatures.clear();
    _userSettings = UserSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.remove(_budgetsKey);
    await prefs.remove(_merchantOverridesKey);
    await prefs.remove(_deletedSignaturesKey);
    await prefs.remove(_userSettingsKey);
    await prefs.remove(_onboardingDoneKey);
  }
}
