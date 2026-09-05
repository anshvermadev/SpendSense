import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/category_constants.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../history_screen/widgets/add_transaction_sheet.dart';

class HomeAnalyticsChartWidget extends StatefulWidget {
  final int? selectedMonth;
  final int? selectedYear;

  const HomeAnalyticsChartWidget({
    super.key,
    this.selectedMonth,
    this.selectedYear,
  });

  @override
  State<HomeAnalyticsChartWidget> createState() =>
      _HomeAnalyticsChartWidgetState();
}

class _HomeAnalyticsChartWidgetState extends State<HomeAnalyticsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartAnimController;
  late Animation<double> _chartAnim;

  int _currentTab = 0; // 0 = Weekly Flow, 1 = Category Donut
  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;
  bool _hideNumbers = true; // By default hidden for privacy

  int get _activeMonth => widget.selectedMonth ?? DateTime.now().month;
  int get _activeYear => widget.selectedYear ?? DateTime.now().year;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
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
  }

  @override
  void didUpdateWidget(HomeAnalyticsChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
      _touchedBarIndex = -1;
      _touchedPieIndex = -1;
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
        final totalExpense = appState.getTotalExpense(
          _activeMonth,
          _activeYear,
        );
        final categorySpend = appState.getCategorySpend(
          _activeMonth,
          _activeYear,
        );
        final monthTransactions = appState.getTransactionsForMonth(
          _activeMonth,
          _activeYear,
        );

        final monthName = _monthNames[_activeMonth - 1];

        // Weekly breakdown calculations
        final daysInMonth = DateTime(_activeYear, _activeMonth + 1, 0).day;
        final hasWeek5 = daysInMonth > 28;

        final double w1 = monthTransactions
            .where((t) => !t.isCredit && t.date.day >= 1 && t.date.day <= 7)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double w2 = monthTransactions
            .where((t) => !t.isCredit && t.date.day >= 8 && t.date.day <= 14)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double w3 = monthTransactions
            .where((t) => !t.isCredit && t.date.day >= 15 && t.date.day <= 21)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double w4 = monthTransactions
            .where((t) =>
                !t.isCredit &&
                t.date.day >= 22 &&
                t.date.day <= (hasWeek5 ? 28 : daysInMonth))
            .fold(0.0, (sum, t) => sum + t.amount);
        final double w5 = hasWeek5
            ? monthTransactions
                .where((t) => !t.isCredit && t.date.day >= 29)
                .fold(0.0, (sum, t) => sum + t.amount)
            : 0.0;

        final weeklySpends = [w1, w2, w3, w4, if (hasWeek5) w5];
        final maxVal = weeklySpends.isEmpty
            ? 0.0
            : weeklySpends.reduce((a, b) => a > b ? a : b);
        final double maxWeekly = (maxVal * 1.3).clamp(1000.0, double.infinity);

        // Peak week calculation
        int peakWeekIndex = 0;
        double peakWeekAmount = 0.0;
        for (int i = 0; i < weeklySpends.length; i++) {
          if (weeklySpends[i] > peakWeekAmount) {
            peakWeekAmount = weeklySpends[i];
            peakWeekIndex = i;
          }
        }

        // Daily average calculation
        final now = DateTime.now();
        final isCurrentMonth =
            _activeMonth == now.month && _activeYear == now.year;
        final daysElapsed = isCurrentMonth ? now.day : daysInMonth;
        final dailyAverage =
            daysElapsed > 0 ? (totalExpense / daysElapsed) : 0.0;

        // Sorted categories
        final sortedCategories = categorySpend.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sortedCategories.take(4).toList();

        final expenseTxnCount =
            monthTransactions.where((t) => !t.isCredit).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFEAEAEE),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Icon Badge + Title + Privacy Eye + Month Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, Color(0xFF6C5CE7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Spending Pulse',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _hideNumbers = !_hideNumbers,
                                  ),
                                  child: Icon(
                                    _hideNumbers
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _hideNumbers
                                  ? 'Monthly: ₹••••'
                                  : 'Total Spent: ₹${_fmt(totalExpense)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Month indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${monthName.substring(0, 3)} $_activeYear',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Quick Intelligence Metric Badges Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF0984E3),
                        label: 'DAILY AVG',
                        value: _hideNumbers ? '₹••••' : '₹${_fmt(dailyAverage)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF6B45),
                        label: 'PEAK PERIOD',
                        value: totalExpense > 0
                            ? 'Week ${peakWeekIndex + 1}'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFF00B894),
                        label: 'EXPENSES',
                        value: '$expenseTxnCount txns',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Segmented Tab Switcher (Weekly Flow vs Categories)
                Container(
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          index: 0,
                          label: 'Weekly Flow',
                          icon: Icons.bar_chart_rounded,
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          index: 1,
                          label: 'Categories',
                          icon: Icons.pie_chart_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Content Area based on Selected Tab or Empty State
                if (totalExpense == 0)
                  _buildEmptyState(context, monthName)
                else if (_currentTab == 0)
                  _buildWeeklyFlowChart(
                    weeklySpends,
                    maxWeekly,
                    peakWeekIndex,
                    hasWeek5,
                  )
                else
                  _buildCategoryDonutView(topCategories, totalExpense),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Metric Card ─────────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEDEDF2),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Tab Button ──────────────────────────────────────────────────────────

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentTab == index;

    return GestureDetector(
      onTap: () {
        if (_currentTab != index) {
          setState(() {
            _currentTab = index;
            _touchedBarIndex = -1;
            _touchedPieIndex = -1;
          });
          _chartAnimController.forward(from: 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── View 1: Weekly Capsule Bar Chart ────────────────────────────────────

  Widget _buildWeeklyFlowChart(
    List<double> weeklySpends,
    double maxWeekly,
    int peakWeekIndex,
    bool hasWeek5,
  ) {
    const weekLabels = ['1-7', '8-14', '15-21', '22-28', '29+'];

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: AnimatedBuilder(
            animation: _chartAnim,
            builder: (context, _) => BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxWeekly,
                minY: 0,
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, BarTouchResponse? resp) {
                    if (resp != null &&
                        resp.spot != null &&
                        event is! PointerUpEvent &&
                        event is! PointerCancelEvent) {
                      setState(
                        () => _touchedBarIndex =
                            resp.spot!.touchedBarGroupIndex,
                      );
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) {
                      final wLabel = 'Week ${group.x + 1} (${weekLabels[group.x]})';
                      final amount = rod.toY;
                      return BarTooltipItem(
                        '$wLabel\n${_hideNumbers ? '₹••••' : '₹${_fmt(amount)}'}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
                        if (i < 0 || i >= weeklySpends.length) {
                          return const SizedBox.shrink();
                        }
                        final isSelected = _touchedBarIndex == i;
                        final isPeak = peakWeekIndex == i;

                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Wk ${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.15,
                                  fontWeight: isSelected || isPeak
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : (isPeak
                                          ? const Color(0xFFFF6B45)
                                          : AppTheme.textPrimary),
                                ),
                              ),
                              Text(
                                weekLabels[i],
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.15,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      reservedSize: 42,
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
                  horizontalInterval: maxWeekly / 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF1F1F6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weeklySpends.length, (i) {
                  final amt = weeklySpends[i] * _chartAnim.value;
                  final isTouched = _touchedBarIndex == i;
                  final isPeak = peakWeekIndex == i && amt > 0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: amt,
                        width: 22,
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: isTouched
                              ? [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)]
                              : (isPeak
                                  ? [const Color(0xFFFF6B45), const Color(0xFFFFA07A)]
                                  : [AppTheme.primary, AppTheme.primaryLight]),
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxWeekly,
                          color: const Color(0xFFF0F1F7),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Peak week insight badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9FC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEDEDF4), width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: Color(0xFFE67E22),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Week ${peakWeekIndex + 1} (${weekLabels[peakWeekIndex]}) had your highest spending.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── View 2: Category Donut & List ────────────────────────────────────────

  Widget _buildCategoryDonutView(
    List<MapEntry<String, double>> topCategories,
    double totalExpense,
  ) {
    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            // Donut Pie Chart with center icon / label
            SizedBox(
              width: 120,
              height: 120,
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
                              _touchedPieIndex = pieResp
                                  .touchedSection!.touchedSectionIndex;
                            });
                          }
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: List.generate(topCategories.length, (i) {
                        final isTouched = i == _touchedPieIndex;
                        final radius = isTouched ? 22.0 : 16.0;
                        final entry = topCategories[i];
                        final color = CategoryConstants.getColor(entry.key);

                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: '',
                          radius: radius,
                        );
                      }),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.donut_small_rounded,
                        size: 18,
                        color: _touchedPieIndex >= 0 &&
                                _touchedPieIndex < topCategories.length
                            ? CategoryConstants.getColor(
                                topCategories[_touchedPieIndex].key)
                            : AppTheme.primary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _touchedPieIndex >= 0 &&
                                _touchedPieIndex < topCategories.length
                            ? topCategories[_touchedPieIndex].key
                            : 'Top',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Top categories list on the right
            Expanded(
              child: Column(
                children: topCategories.map((entry) {
                  final cat = entry.key;
                  final amt = entry.value;
                  final ratio =
                      totalExpense > 0 ? (amt / totalExpense).clamp(0.0, 1.0) : 0.0;
                  final percent = (ratio * 100).toStringAsFixed(0);
                  final icon = CategoryConstants.getIcon(cat);
                  final color = CategoryConstants.getColor(cat);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(icon, size: 12, color: color),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _hideNumbers
                                  ? '$percent%'
                                  : '$percent% (₹${_fmt(amt)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 3.5,
                            backgroundColor: const Color(0xFFF1F1F6),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, String monthName) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withAlpha(80),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 24,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'All quiet for $monthName $_activeYear',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No expenses recorded yet. Log a spend or sync SMS to view charts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAddTransaction(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Log Spend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
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

  String _fmt(double amount) =>
      NumberFormat('#,##,##0', 'en_IN').format(amount);
}
