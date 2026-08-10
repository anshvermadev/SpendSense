import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class HomeAnalyticsChartWidget extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const HomeAnalyticsChartWidget({
    required this.selectedYear,
    required this.onYearChanged,
    super.key,
  });

  @override
  State<HomeAnalyticsChartWidget> createState() =>
      _HomeAnalyticsChartWidgetState();
}

class _HomeAnalyticsChartWidgetState extends State<HomeAnalyticsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartAnimController;
  late Animation<double> _chartAnim;
  int _touchedIndex = -1;

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: Curves.easeOutCubic,
    );
    _chartAnimController.forward();
    _touchedIndex = DateTime.now().month - 1;
  }

  @override
  void didUpdateWidget(HomeAnalyticsChartWidget old) {
    super.didUpdateWidget(old);
    if (old.selectedYear != widget.selectedYear) {
      _chartAnimController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final monthlySpend = appState.getMonthlySpendForYear(
          widget.selectedYear,
        );
        final maxY = monthlySpend.isEmpty
            ? 10000.0
            : (monthlySpend.reduce((a, b) => a > b ? a : b) * 1.3).clamp(
                1000.0,
                double.infinity,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    _buildYearSelector(),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: AnimatedBuilder(
                    animation: _chartAnim,
                    builder: (context, _) => BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          touchCallback:
                              (FlTouchEvent event, BarTouchResponse? resp) {
                                if (resp != null &&
                                    resp.spot != null &&
                                    event is! PointerUpEvent &&
                                    event is! PointerCancelEvent) {
                                  setState(
                                    () => _touchedIndex =
                                        resp.spot!.touchedBarGroupIndex,
                                  );
                                }
                              },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, gi, rod, ri) {
                              final label = _monthLabels[group.x];
                              final amount = rod.toY;
                              if (amount == 0) return null;
                              return BarTooltipItem(
                                '$label\n₹${(amount / 1000).toStringAsFixed(1)}k',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= _monthLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _monthLabels[i],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: _touchedIndex == i
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: _touchedIndex == i
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 26,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 3,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFF0F0F5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(12, (i) {
                          final amt = monthlySpend[i] * _chartAnim.value;
                          final isActive = _touchedIndex == i;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: amt,
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.primary.withAlpha(64),
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                if (monthlySpend.every((v) => v == 0)) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No spending data for ${widget.selectedYear}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
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

  Widget _buildYearSelector() {
    return GestureDetector(
      onTap: () => _showYearPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Year - ${widget.selectedYear}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Year',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...([2024, 2025, 2026]).map(
              (y) => ListTile(
                title: Text(
                  '$y',
                  style: TextStyle(
                    color: widget.selectedYear == y
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                    fontWeight: widget.selectedYear == y
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: widget.selectedYear == y
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  widget.onYearChanged(y);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
