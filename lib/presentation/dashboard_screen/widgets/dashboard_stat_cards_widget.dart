import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class DashboardStatCardsWidget extends StatefulWidget {
  final int month;
  final int year;

  const DashboardStatCardsWidget({
    required this.month,
    required this.year,
    super.key,
  });

  @override
  State<DashboardStatCardsWidget> createState() =>
      _DashboardStatCardsWidgetState();
}

class _DashboardStatCardsWidgetState extends State<DashboardStatCardsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DashboardStatCardsWidget old) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final totalIncome = appState.getTotalIncome(widget.month, widget.year);
        final totalExpense = appState.getTotalExpense(
          widget.month,
          widget.year,
        );

        final netSavings = totalIncome - totalExpense;
        final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
        final dailyAvg = daysInMonth > 0 ? totalExpense / daysInMonth : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Income',
                          amount: totalIncome * _animation.value,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF9B8FF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          accountLabel: 'All Inflows',
                          maskedNum: '••••  ••••',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Total Expense',
                          amount: totalExpense * _animation.value,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B45), Color(0xFFFF9A7A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          accountLabel: 'All Spends',
                          maskedNum: '••••  ••••',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Secondary KPI Strip: Net Savings & Daily Average
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDEDF4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: (netSavings >= 0
                                          ? const Color(0xFF00B894)
                                          : AppTheme.errorColor)
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  netSavings >= 0
                                      ? Icons.savings_outlined
                                      : Icons.trending_down_rounded,
                                  size: 16,
                                  color: netSavings >= 0
                                      ? const Color(0xFF00B894)
                                      : AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Net Balance',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${netSavings >= 0 ? '+' : ''}₹${_fmt(netSavings * _animation.value)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: netSavings >= 0
                                            ? const Color(0xFF00B894)
                                            : AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: const Color(0xFFEEEEF4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Daily Average',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '₹${_fmt(dailyAvg * _animation.value)}/d',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final LinearGradient gradient;
  final String accountLabel;
  final String maskedNum;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.gradient,
    required this.accountLabel,
    required this.maskedNum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha(89),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.more_vert_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_fmt(amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                  Text(
                    maskedNum,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) => amount
      .toStringAsFixed(2)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
