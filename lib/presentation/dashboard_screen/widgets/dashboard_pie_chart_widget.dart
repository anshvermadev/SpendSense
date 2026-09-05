import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/category_constants.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class DashboardPieChartWidget extends StatefulWidget {
  final int month;
  final int year;

  const DashboardPieChartWidget({
    required this.month,
    required this.year,
    super.key,
  });

  @override
  State<DashboardPieChartWidget> createState() =>
      _DashboardPieChartWidgetState();
}

class _DashboardPieChartWidgetState extends State<DashboardPieChartWidget> {
  int _touchedIndex = -1;

  String _fmt(double val) {
    if (val.isNaN || val.isInfinite) return '0';
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }

  String _fmtFull(double val) {
    if (val.isNaN || val.isInfinite) return '0';
    if (val == val.toInt()) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final categorySpend = appState.getCategorySpend(widget.month, widget.year);
        // Exclude income, only take expenses with positive spend
        final expenseCategories = categorySpend.entries
            .where((e) => e.key != 'Income' && e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final totalExpense = expenseCategories.fold<double>(
          0.0,
          (sum, e) => sum + e.value,
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
                  color: Colors.black.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.pie_chart_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Distribution',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Proportional monthly spend',
                                  style: TextStyle(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${expenseCategories.length} Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (totalExpense <= 0 || expenseCategories.isEmpty)
                  _buildEmptyState()
                else ...[
                  // Interactive Donut Chart
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieResp) {
                                  if (pieResp != null &&
                                      pieResp.touchedSection != null &&
                                      event is! PointerUpEvent &&
                                      event is! PointerCancelEvent) {
                                    setState(() {
                                      _touchedIndex = pieResp
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  } else if (event is PointerUpEvent ||
                                      event is PointerCancelEvent) {
                                    setState(() => _touchedIndex = -1);
                                  }
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: 62,
                              sections: List.generate(
                                expenseCategories.length,
                                (i) {
                                  final isTouched = i == _touchedIndex;
                                  final radius = isTouched ? 28.0 : 20.0;
                                  final entry = expenseCategories[i];
                                  final color = CategoryConstants.getColor(entry.key);

                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: '',
                                    radius: radius,
                                  );
                                },
                              ),
                            ),
                          ),
                          // Center badge
                          _buildCenterBadge(expenseCategories, totalExpense),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category Breakdown Legend Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: expenseCategories.asMap().entries.map((entry) {
                      final i = entry.key;
                      final cat = entry.value;
                      final isSelected = i == _touchedIndex;
                      final color = CategoryConstants.getColor(cat.key);
                      final pct = totalExpense > 0
                          ? ((cat.value / totalExpense) * 100).toStringAsFixed(1)
                          : '0';

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _touchedIndex = _touchedIndex == i ? -1 : i;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withAlpha(35)
                                : const Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : const Color(0xFFEDEDF4),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterBadge(
    List<MapEntry<String, double>> categories,
    double totalExpense,
  ) {
    if (_touchedIndex >= 0 && _touchedIndex < categories.length) {
      final touched = categories[_touchedIndex];
      final color = CategoryConstants.getColor(touched.key);
      final pct = totalExpense > 0
          ? ((touched.value / totalExpense) * 100).toStringAsFixed(1)
          : '0';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CategoryConstants.getIcon(touched.key),
            size: 18,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            touched.key,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₹${_fmt(touched.value)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            '$pct% of spend',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 18,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 2),
        const Text(
          'Total Spend',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '₹${_fmtFull(totalExpense)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        const Text(
          'Tap slices to inspect',
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                size: 32,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Expense Data Yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add transactions or sync SMS to view category distribution',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
