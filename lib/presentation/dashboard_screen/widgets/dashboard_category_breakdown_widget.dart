import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/category_constants.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class DashboardCategoryBreakdownWidget extends StatefulWidget {
  final int month;
  final int year;

  const DashboardCategoryBreakdownWidget({
    required this.month,
    required this.year,
    super.key,
  });

  @override
  State<DashboardCategoryBreakdownWidget> createState() =>
      _DashboardCategoryBreakdownWidgetState();
}

class _DashboardCategoryBreakdownWidgetState
    extends State<DashboardCategoryBreakdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(DashboardCategoryBreakdownWidget old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _barColor(double pct, bool isOver) {
    if (isOver) return AppTheme.errorColor;
    if (pct >= 0.8) return AppTheme.secondary;
    return AppTheme.primary;
  }

  void _showSetBudgetDialog(
    BuildContext context,
    String categoryName,
    double currentBudget,
  ) {
    final ctrl = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Budget — $categoryName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹  ',
            hintText: 'Monthly limit',
            filled: true,
            fillColor: AppTheme.surfaceVariantLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final limit = double.tryParse(ctrl.text.trim());
              if (limit != null && limit > 0) {
                await context.read<AppState>().setBudget(
                  categoryName,
                  limit,
                  widget.month,
                  widget.year,
                );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _showAllCategories = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final categorySpend = appState.getCategorySpend(
          widget.month,
          widget.year,
        );

        // All non-income categories from canonical list
        final allCanonical = CategoryConstants.allCategories
            .where((k) => k != 'Income')
            .toList();

        final activeCats = allCanonical
            .where((c) => (categorySpend[c] ?? 0.0) > 0)
            .toList()
          ..sort((a, b) =>
              (categorySpend[b] ?? 0.0).compareTo(categorySpend[a] ?? 0.0));

        final displayedCategories = _showAllCategories
            ? (allCanonical.toList()
              ..sort((a, b) {
                final spendA = categorySpend[a] ?? 0.0;
                final spendB = categorySpend[b] ?? 0.0;
                if (spendA > 0 || spendB > 0) {
                  return spendB.compareTo(spendA);
                }
                return a.compareTo(b);
              }))
            : activeCats;

        final totalBudgeted = displayedCategories.fold<double>(
          0.0,
          (sum, c) => sum + appState.getBudget(c, widget.month, widget.year),
        );
        final totalSpent = displayedCategories.fold<double>(
          0.0,
          (sum, c) => sum + (categorySpend[c] ?? 0.0),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category Budgets',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${displayedCategories.length} categories listed',
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter toggle
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showAllCategories = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _showAllCategories
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _showAllCategories
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'All (15)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: _showAllCategories
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _showAllCategories
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showAllCategories = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: !_showAllCategories
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_showAllCategories
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Active (${activeCats.length})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: !_showAllCategories
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !_showAllCategories
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (totalBudgeted > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEDEDF4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Budgeted: ₹${_fmt(totalBudgeted)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Spent: ₹${_fmt(totalSpent)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: totalSpent > totalBudgeted
                                ? AppTheme.errorColor
                                : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                if (displayedCategories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No active expenses for this month',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...displayedCategories.asMap().entries.map((entry) {
                    final cat = entry.key;
                    final name = displayedCategories[cat];
                    final spent = categorySpend[name] ?? 0.0;
                    final budget = appState.getBudget(
                      name,
                      widget.month,
                      widget.year,
                    );
                    final pct = budget > 0
                        ? (spent / budget).clamp(0.0, 1.0)
                        : 0.0;
                    final isOver = budget > 0 && spent > budget;
                    final barColor = _barColor(pct, isOver);
                    final icon = CategoryConstants.getIcon(name);
                    final color = CategoryConstants.getColor(name);

                    return _buildCategoryRow(
                      context: context,
                      index: cat,
                      name: name,
                      icon: icon,
                      iconColor: color,
                      spent: spent,
                      budget: budget,
                      pct: pct,
                      barColor: barColor,
                      isOver: isOver,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow({
    required BuildContext context,
    required int index,
    required String name,
    required IconData icon,
    required Color iconColor,
    required double spent,
    required double budget,
    required double pct,
    required Color barColor,
    required bool isOver,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(31),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showSetBudgetDialog(context, name, budget),
                          child: budget == 0
                              ? const Text(
                                  '+ Set Budget',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : Text(
                                  '${(pct * 100 * v).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: barColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_fmt(spent)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          budget > 0 ? '/ ₹${_fmt(budget)}' : 'No budget set',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: budget > 0 ? pct * v : 0,
                        backgroundColor: barColor.withAlpha(31),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
