import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import './widgets/history_calendar_strip_widget.dart';
import './widgets/history_transaction_list_widget.dart';
import './widgets/add_transaction_sheet.dart';
import './widgets/transaction_detail_sheet.dart';
import './widgets/day_navigator_widget.dart';
import './widgets/week_navigator_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime _selectedWeekStart = _getStartOfWeek(DateTime.now());
  
  DateTime? _filterDay; // Used in Month view to filter by a specific day

  String _searchQuery = '';
  String? _filterCategory;
  String? _filterPaymentMode;
  final TextEditingController _searchController = TextEditingController();

  static DateTime _getStartOfWeek(DateTime date) {
    int diff = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {}); // Re-render when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> txns) {
    var filtered = txns;
    
    // Tab-based filtering
    if (_tabController.index == 0) { // Day
      filtered = filtered.where((t) => 
        t.date.year == _selectedDay.year &&
        t.date.month == _selectedDay.month &&
        t.date.day == _selectedDay.day
      ).toList();
    } else if (_tabController.index == 1) { // Week
      final weekDays = List.generate(7, (i) => _selectedWeekStart.add(Duration(days: i)));
      filtered = filtered.where((t) {
        return weekDays.any((d) => 
          d.year == t.date.year && 
          d.month == t.date.month && 
          d.day == t.date.day
        );
      }).toList();
    } else { // Month
      filtered = filtered.where((t) => 
        t.date.year == _selectedMonth.year &&
        t.date.month == _selectedMonth.month
      ).toList();
      if (_filterDay != null) {
        filtered = filtered.where((t) => 
          t.date.year == _filterDay!.year &&
          t.date.month == _filterDay!.month &&
          t.date.day == _filterDay!.day
        ).toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.merchant.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_filterCategory != null) {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }
    if (_filterPaymentMode != null) {
      filtered = filtered
          .where((t) => t.paymentMode == _filterPaymentMode)
          .toList();
    }
    return filtered;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txns) {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in txns) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  void _showFilterSheet() {
    final appState = context.read<AppState>();
    final categories =
        appState.allTransactions.map((t) => t.category).toSet().toList()
          ..sort();
    final paymentModes = [
      'UPI',
      'Card',
      'Cash',
      'Auto-debit',
      'ATM',
      'Bank Transfer',
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        categories: categories,
        paymentModes: paymentModes,
        selectedCategory: _filterCategory,
        selectedPaymentMode: _filterPaymentMode,
        onApply: (cat, mode) {
          setState(() {
            _filterCategory = cat;
            _filterPaymentMode = mode;
          });
        },
        onClear: () {
          setState(() {
            _filterCategory = null;
            _filterPaymentMode = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 8),
            _buildTabBar(),
            Expanded(
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  final allTxns = appState.allTransactions;
                  final filtered = _applyFilters(allTxns);
                  final grouped = _groupByDate(filtered);
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildNavigatorWidget(),
                            _buildSearchBar(),
                          ],
                        ),
                      ),
                      HistoryTransactionListWidget(
                        grouped: grouped,
                        onTransactionTap: (txn) =>
                            _showTransactionDetail(txn, appState),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => _showAddTransaction(),
          backgroundColor: AppTheme.secondary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedDay = DateTime.now();
            _selectedWeekStart = _getStartOfWeek(DateTime.now());
            _selectedMonth = DateTime.now();
            _filterDay = null;
          });
        },
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.textPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Day'),
          Tab(text: 'Week'),
          Tab(text: 'Month'),
        ],
      ),
    );
  }

  Widget _buildNavigatorWidget() {
    if (_tabController.index == 0) {
      return DayNavigatorWidget(
        selectedDay: _selectedDay,
        onDayChanged: (d) => setState(() => _selectedDay = d),
      );
    } else if (_tabController.index == 1) {
      return WeekNavigatorWidget(
        selectedWeekStart: _selectedWeekStart,
        onWeekChanged: (d) => setState(() => _selectedWeekStart = d),
        onDaySelected: (d) => setState(() {
          _selectedDay = d;
          _tabController.animateTo(0);
        }),
      );
    } else {
      return HistoryCalendarStripWidget(
        selectedMonth: _selectedMonth,
        selectedDay: _filterDay,
        onMonthChanged: (d) => setState(() {
          _selectedMonth = d;
          _filterDay = null;
        }),
        onDaySelected: (d) => setState(() {
          if (_tabController.index == 2) { // Allow switching to Day tab from Month grid
            _selectedDay = d;
            _tabController.animateTo(0);
          }
        }),
      );
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Consumer<AppState>(
            builder: (context, appState, _) {
              final name = appState.userSettings.name;
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          const Text(
            'History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_filterCategory != null || _filterPaymentMode != null)
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: (_filterCategory != null || _filterPaymentMode != null)
                    ? AppTheme.primary
                    : AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(Transaction txn, AppState appState) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(
        transaction: txn,
        availableCategories: appState.userSettings.trackedCategories,
        onCategoryChanged: (cat, sub) async {
          await appState.updateTransactionCategory(txn.id, cat, sub);
        },
        onDelete: () async {
          await appState.deleteTransaction(txn.id);
        },
      ),
    );
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        onAdd: (amount, type, merchant, paymentMode, date) async {
          await context.read<AppState>().addManualTransaction(
            amount: amount,
            type: type,
            merchant: merchant,
            paymentMode: paymentMode,
            date: date,
          );
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentModes;
  final String? selectedCategory;
  final String? selectedPaymentMode;
  final Function(String?, String?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.categories,
    required this.paymentModes,
    required this.selectedCategory,
    required this.selectedPaymentMode,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _cat;
  String? _mode;

  @override
  void initState() {
    super.initState();
    _cat = widget.selectedCategory;
    _mode = widget.selectedPaymentMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final isSelected = _cat == cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = isSelected ? null : cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.paymentModes.map((mode) {
              final isSelected = _mode == mode;
              return GestureDetector(
                onTap: () => setState(() => _mode = isSelected ? null : mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    mode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_cat, _mode);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
