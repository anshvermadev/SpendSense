import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class HomeFinancialPulseWidget extends StatelessWidget {
  const HomeFinancialPulseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final now = DateTime.now();
        final expense = appState.getTotalExpense(now.month, now.year);
        final income = appState.getTotalIncome(now.month, now.year);
        final monthlyIncomeTarget = appState.userSettings.monthlyIncome > 0
            ? appState.userSettings.monthlyIncome
            : (income > 0 ? income : 50000.0);

        final spendRatio = (expense / monthlyIncomeTarget).clamp(0.0, 1.0);
        final spendPercent = (spendRatio * 100).toInt();

        final insights = appState.getInsights(now.month, now.year);
        final topInsight = insights.isNotEmpty
            ? insights.first
            : 'Track daily transactions to receive automated financial insights.';

        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final daysLeft = daysInMonth - now.day;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE8E8F0),
                width: 0.8,
              ),
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
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Monthly Budget Pulse',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.dashboardScreen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$daysLeft days left',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Spend Ratio Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent ₹${_fmt(expense)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$spendPercent% of monthly limit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: spendPercent > 85
                            ? AppTheme.errorColor
                            : (spendPercent > 60
                                ? AppTheme.secondary
                                : AppTheme.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: spendRatio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF0F0F5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spendPercent > 85
                          ? AppTheme.errorColor
                          : (spendPercent > 60
                              ? AppTheme.secondary
                              : AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Smart Tip / Insight Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topInsight,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(double amount) => NumberFormat('#,##,##0', 'en_IN').format(amount);
}
