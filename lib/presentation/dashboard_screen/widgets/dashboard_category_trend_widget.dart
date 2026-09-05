import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/category_constants.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class DashboardCategoryTrendWidget extends StatefulWidget {
  final int month;
  final int year;

  const DashboardCategoryTrendWidget({
    required this.month,
    required this.year,
    super.key,
  });

  @override
  State<DashboardCategoryTrendWidget> createState() =>
      _DashboardCategoryTrendWidgetState();
}

class _DashboardCategoryTrendWidgetState
    extends State<DashboardCategoryTrendWidget> {
  String _selectedCategory = 'All';

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

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
        final transactions = appState.getTransactionsForMonth(
          widget.month,
          widget.year,
        );

        final daysCount = _daysInMonth(widget.month, widget.year);
        final dailySpends = List<double>.filled(daysCount, 0.0);

        // Filter non-credit expense transactions
        for (final t in transactions) {
          if (!t.isCredit) {
            final matchesCategory = _selectedCategory == 'All' ||
                t.category.toLowerCase() == _selectedCategory.toLowerCase();
            if (matchesCategory) {
              final dayIndex = t.date.day - 1;
              if (dayIndex >= 0 && dayIndex < daysCount) {
                dailySpends[dayIndex] += t.amount;
              }
            }
          }
        }

        final totalCategorySpend = dailySpends.fold(0.0, (s, a) => s + a);
        double maxDaily = 0.0;
        int peakDayIndex = 0;
        for (int i = 0; i < daysCount; i++) {
          if (dailySpends[i] > maxDaily) {
            maxDaily = dailySpends[i];
            peakDayIndex = i;
          }
        }

        final activeColor = _selectedCategory == 'All'
            ? AppTheme.primary
            : CategoryConstants.getColor(_selectedCategory);

        final monthName = _monthNames[widget.month - 1];

        // All non-income categories to filter by
        final filterCategories = [
          'All',
          ...CategoryConstants.allCategories.where((c) => c != 'Income'),
        ];

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activeColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _selectedCategory == 'All'
                                ? Icons.show_chart_rounded
                                : CategoryConstants.getIcon(_selectedCategory),
                            size: 18,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category Spending Trends',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Daily timeline for $monthName ${widget.year}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (totalCategorySpend > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: activeColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${_fmt(totalCategorySpend)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: activeColor,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category selector chip carousel
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filterCategories.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = filterCategories[index];
                      final isSelected = cat == _selectedCategory;
                      final catColor = cat == 'All'
                          ? AppTheme.primary
                          : CategoryConstants.getColor(cat);
                      final icon = cat == 'All'
                          ? Icons.apps_rounded
                          : CategoryConstants.getIcon(cat);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor
                                : AppTheme.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: catColor.withAlpha(80),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Line Chart or Empty State
                if (totalCategorySpend <= 0)
                  _buildNoSpendPlaceholder(activeColor)
                else ...[
                  SizedBox(
                    height: 175,
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: daysCount.toDouble(),
                        minY: 0,
                        maxY: max(maxDaily * 1.25, 100.0),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: max(maxDaily / 3, 50.0),
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFFF1F1F6),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              interval: daysCount > 20 ? 5 : 4,
                              getTitlesWidget: (val, meta) {
                                final d = val.toInt();
                                if (d < 1 || d > daysCount) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '$monthName $d',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final d = spot.x.toInt();
                                return LineTooltipItem(
                                  '$monthName $d\n₹${_fmtFull(spot.y)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(daysCount, (i) {
                              return FlSpot(
                                (i + 1).toDouble(),
                                dailySpends[i],
                              );
                            }),
                            isCurved: true,
                            curveSmoothness: 0.32,
                            color: activeColor,
                            barWidth: 3.0,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) {
                                return spot.y > 0 && spot.y == maxDaily;
                              },
                              getDotPainter: (spot, percent, bar, index) {
                                return FlDotCirclePainter(
                                  radius: 4.5,
                                  color: Colors.white,
                                  strokeColor: activeColor,
                                  strokeWidth: 3,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  activeColor.withAlpha(50),
                                  activeColor.withAlpha(2),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // KPI summary row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEDEDF4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiItem(
                          'Total Spend',
                          '₹${_fmt(totalCategorySpend)}',
                          activeColor,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFE2E2EC),
                        ),
                        _buildKpiItem(
                          'Peak Day',
                          '$monthName ${peakDayIndex + 1} (₹${_fmt(maxDaily)})',
                          AppTheme.textPrimary,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFE2E2EC),
                        ),
                        _buildKpiItem(
                          'Daily Avg',
                          '₹${_fmt(totalCategorySpend / daysCount)}/d',
                          AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoSpendPlaceholder(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDF4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.query_builder_rounded,
            size: 28,
            color: color.withAlpha(120),
          ),
          const SizedBox(height: 8),
          Text(
            'No $_selectedCategory Expenses',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Zero recorded transactions in this category for this month.',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
