import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.fastfood_outlined,
    'Groceries': Icons.shopping_basket_outlined,
    'Transport': Icons.directions_car_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'EMI': Icons.account_balance_outlined,
    'Subscriptions': Icons.subscriptions_outlined,
    'Utilities': Icons.electric_bolt_outlined,
    'Medical': Icons.local_hospital_outlined,
    'Housing': Icons.home_outlined,
    'Entertainment': Icons.movie_outlined,
    'Uncategorised': Icons.help_outline_rounded,
  };

  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFFFF6B45),
    'Groceries': Color(0xFF00B894),
    'Transport': Color(0xFF0984E3),
    'Shopping': Color(0xFF6C5CE7),
    'EMI': Color(0xFF2D3436),
    'Subscriptions': Color(0xFF6C3483),
    'Utilities': Color(0xFFFDCB6E),
    'Medical': Color(0xFF00B894),
    'Housing': Color(0xFF74B9FF),
    'Entertainment': Color(0xFFE17055),
    'Uncategorised': Color(0xFFAAAAAC),
  };

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final categorySpend = appState.getCategorySpend(
          widget.month,
          widget.year,
        );
        final trackedCategories = appState.userSettings.trackedCategories;

        // Build list: tracked categories + any categories with actual spend
        final allCats = <String>{...trackedCategories};
        allCats.addAll(categorySpend.keys.where((k) => k != 'Income'));
        final categories = allCats.toList()..sort();

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${categories.length} categories',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (categories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No expense data for this month',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...categories.asMap().entries.map((entry) {
                    final cat = entry.key;
                    final name = categories[cat];
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
                    final icon =
                        _categoryIcons[name] ?? Icons.category_outlined;
                    final color = _categoryColors[name] ?? AppTheme.textMuted;

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
