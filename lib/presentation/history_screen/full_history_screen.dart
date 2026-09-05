import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/category_constants.dart';
import '../../services/app_state.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/statement_download_dialog.dart';
import 'widgets/transaction_detail_sheet.dart';

enum TransactionTypeFilter { all, debits, credits }

enum DateRangeFilter { allTime, last7Days, thisMonth, last30Days, last90Days, custom }

class FullHistoryScreen extends StatefulWidget {
  const FullHistoryScreen({super.key});

  @override
  State<FullHistoryScreen> createState() => _FullHistoryScreenState();
}

class _FullHistoryScreenState extends State<FullHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  DateRangeFilter _dateFilter = DateRangeFilter.allTime;
  DateTimeRange? _customDateRange;

  String? _selectedCategory;
  String? _selectedPaymentMode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    var filtered = all;
    final now = DateTime.now();

    // 1. Date Range Filter
    switch (_dateFilter) {
      case DateRangeFilter.allTime:
        break;
      case DateRangeFilter.last7Days:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((t) => t.date.isAfter(sevenDaysAgo)).toList();
        break;
      case DateRangeFilter.thisMonth:
        filtered = filtered
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
        break;
      case DateRangeFilter.last30Days:
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filtered = filtered.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();
        break;
      case DateRangeFilter.last90Days:
        final ninetyDaysAgo = now.subtract(const Duration(days: 90));
        filtered = filtered.where((t) => t.date.isAfter(ninetyDaysAgo)).toList();
        break;
      case DateRangeFilter.custom:
        if (_customDateRange != null) {
          final start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          final end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
          filtered = filtered
              .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
              .toList();
        }
        break;
    }

    // 2. Type Filter
    if (_typeFilter == TransactionTypeFilter.debits) {
      filtered = filtered.where((t) => !t.isCredit).toList();
    } else if (_typeFilter == TransactionTypeFilter.credits) {
      filtered = filtered.where((t) => t.isCredit).toList();
    }

    // 3. Category Filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((t) => t.category == _selectedCategory).toList();
    }

    // 4. Payment Mode Filter
    if (_selectedPaymentMode != null) {
      filtered =
          filtered.where((t) => t.paymentMode == _selectedPaymentMode).toList();
    }

    // 5. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((t) {
        return t.merchant.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            t.subcategory.toLowerCase().contains(q) ||
            t.paymentMode.toLowerCase().contains(q) ||
            t.bankRefNo.toLowerCase().contains(q) ||
            t.accountNo.toLowerCase().contains(q) ||
            t.rawText.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txns) {
    final Map<String, List<Transaction>> map = {};
    for (final t in txns) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceLight,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = DateRangeFilter.custom;
      });
    }
  }

  void _showFilterSheet() {
    final categories = CategoryConstants.primaryCategories;
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedPaymentMode = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Reset Filters',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
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
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final catColor = CategoryConstants.getColor(cat);
                    final catIcon = CategoryConstants.getIcon(cat);

                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          _selectedCategory = isSelected ? null : cat;
                        });
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor
                              : AppTheme.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              catIcon,
                              size: 14,
                              color: isSelected ? Colors.white : catColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
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
                  children: paymentModes.map((mode) {
                    final isSelected = _selectedPaymentMode == mode;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          _selectedPaymentMode = isSelected ? null : mode;
                        });
                        setState(() {});
                      },
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
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        availableCategories: CategoryConstants.allCategoriesWithUncategorised,
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
        onAdd: (amount, type, merchant, paymentMode, date, status) async {
          await context.read<AppState>().addManualTransaction(
            amount: amount,
            type: type,
            merchant: merchant,
            paymentMode: paymentMode,
            date: date,
            status: status,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allTxns = appState.allTransactions;
    final filtered = _filterTransactions(allTxns);
    final grouped = _groupByDate(filtered);
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    double totalDebits = 0;
    double totalCredits = 0;
    for (final t in filtered) {
      if (t.isCredit) {
        totalCredits += t.amount;
      } else {
        totalDebits += t.amount;
      }
    }

    final hasActiveFilters = _selectedCategory != null ||
        _selectedPaymentMode != null ||
        _typeFilter != TransactionTypeFilter.all ||
        _dateFilter != DateRangeFilter.allTime ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Full History & Search',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          // Filter button
          IconButton(
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
            icon: Icon(
              Icons.tune_rounded,
              color: (_selectedCategory != null || _selectedPaymentMode != null)
                  ? AppTheme.primary
                  : AppTheme.textPrimary,
            ),
          ),
          // PDF Statement Download
          IconButton(
            tooltip: 'Download Statement PDF',
            onPressed: () {
              StatementDownloadDialog.show(
                context,
                customInitialTransactions: filtered,
                initialPeriodTitle: hasActiveFilters
                    ? 'Custom Filtered Statement (${filtered.length} entries)'
                    : null,
              );
            },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: AppTheme.surfaceLight,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search payee, category, ref, account...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceVariantLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Type & Date Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeFilterChip(
                        TransactionTypeFilter.all,
                        'All Types',
                      ),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip(
                        TransactionTypeFilter.debits,
                        'Debits (-)',
                      ),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip(
                        TransactionTypeFilter.credits,
                        'Credits (+)',
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE0E0E8),
                      ),
                      const SizedBox(width: 12),
                      _buildDateFilterChip(DateRangeFilter.allTime, 'All Time'),
                      const SizedBox(width: 6),
                      _buildDateFilterChip(
                        DateRangeFilter.last7Days,
                        'Last 7 Days',
                      ),
                      const SizedBox(width: 6),
                      _buildDateFilterChip(
                        DateRangeFilter.thisMonth,
                        'This Month',
                      ),
                      const SizedBox(width: 6),
                      _buildDateFilterChip(
                        DateRangeFilter.last30Days,
                        'Last 30 Days',
                      ),
                      const SizedBox(width: 6),
                      _buildDateFilterChip(
                        DateRangeFilter.last90Days,
                        'Last 90 Days',
                      ),
                      const SizedBox(width: 6),
                      _buildCustomDateChip(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Category Quick Filter Pills Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryFilterChip(null, 'All Categories'),
                      ...CategoryConstants.primaryCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildCategoryFilterChip(cat, cat),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFFECECF0),
            child: Row(
              children: [
                Text(
                  '${filtered.length} found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Debits: -₹${_fmt(totalDebits)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Credits: +₹${_fmt(totalCredits)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No matching transactions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try modifying search terms or resetting filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, i) {
                      final key = sortedKeys[i];
                      final txns = grouped[key]!;
                      final date = DateTime.parse(key);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Text(
                              _formatDateHeader(date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: txns.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final t = entry.value;
                                final isLast = idx == txns.length - 1;
                                return _buildRow(t, isLast, appState);
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransaction,
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildTypeFilterChip(TransactionTypeFilter type, String label) {
    final isSelected = _typeFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(DateRangeFilter filter, String label) {
    final isSelected = _dateFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _dateFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _dateFilter == DateRangeFilter.custom;
    final label = _customDateRange != null
        ? '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}'
        : 'Custom Date';

    return GestureDetector(
      onTap: _pickCustomDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 11,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    final catColor = category != null ? CategoryConstants.getColor(category) : AppTheme.primary;
    final catIcon = category != null ? CategoryConstants.getIcon(category) : Icons.category_outlined;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = isSelected ? null : category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? catColor : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              catIcon,
              size: 13,
              color: isSelected ? Colors.white : catColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Transaction t, bool isLast, AppState appState) {
    final icon = CategoryConstants.getIcon(t.category);
    final color = CategoryConstants.getColor(t.category);
    final timeStr = DateFormat('hh:mm a').format(t.date);

    final subInfo = [
      t.paymentMode,
      if (t.bankRefNo.isNotEmpty) 'Ref: ${t.bankRefNo}'
      else if (t.accountNo.isNotEmpty) 'A/c: ${t.accountNo}',
      timeStr,
    ].join(' • ');

    return GestureDetector(
      onTap: () => _showTransactionDetail(t, appState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF2F2F6), width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.merchant.isNotEmpty ? t.merchant : 'Transaction',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subInfo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.isCredit ? AppTheme.success : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 3),
                _buildStatusBadge(t.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase().trim();
    Color bg;
    Color text;
    IconData icon;
    String label;

    if (s == 'failed' || s == 'fail') {
      bg = AppTheme.errorLight;
      text = AppTheme.errorColor;
      icon = Icons.cancel_rounded;
      label = 'Failed';
    } else if (s == 'pending') {
      bg = const Color(0xFFFFF4E5); // warm orange/amber
      text = const Color(0xFFE67E22); // orange/yellow
      icon = Icons.access_time_filled_rounded;
      label = 'Pending';
    } else {
      // success / default
      bg = AppTheme.successLight;
      text = AppTheme.success;
      icon = Icons.check_circle_rounded;
      label = 'Success';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9.5,
            color: text,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  String _formatDateHeader(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('EEE, dd MMM yyyy').format(d);
  }
}
