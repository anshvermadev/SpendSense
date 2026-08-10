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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Row(
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
                      accountLabel: 'All Sources',
                      maskedNum: '••••  ••••',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Expense',
                      amount: totalExpense * _animation.value,
                      gradient: const LinearGradient(
                        colors: [AppTheme.secondary, Color(0xFFFF9A7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      accountLabel: 'All Categories',
                      maskedNum: '••••  ••••',
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
