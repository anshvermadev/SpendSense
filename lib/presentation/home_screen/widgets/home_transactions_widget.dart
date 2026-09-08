import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/category_constants.dart';
import '../../../routes/app_routes.dart';
import '../../../services/app_state.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../history_screen/widgets/transaction_detail_sheet.dart';
import './uncertain_transaction_modal.dart';

class HomeTransactionsWidget extends StatelessWidget {
  const HomeTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final transactions = appState.allTransactions.take(6).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.fullHistoryScreen),
                    child: const Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildUncertainBanner(context, appState),
              if (transactions.isEmpty)
                _buildEmptyState()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: transactions.asMap().entries.map((entry) {
                      return _buildRow(
                        context,
                        entry.value,
                        entry.key,
                        transactions.length,
                        appState,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + below to record your first transaction',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertainBanner(BuildContext context, AppState appState) {
    final uncertain = appState.getUncertainTransactions();
    if (uncertain.isEmpty) return const SizedBox.shrink();

    final count = uncertain.length;
    final firstTxn = uncertain.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? 'New payee "${firstTxn.merchant}" needs category'
                  : '$count transactions need category',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => UncertainTransactionModal.show(context, firstTxn),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Assign',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Transaction t,
    int index,
    int total,
    AppState appState,
  ) {
    final isLast = index == total - 1;
    final icon = CategoryConstants.getIcon(t.category);
    final color = CategoryConstants.getColor(t.category);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(t.date);

    final catLower = t.category.trim().toLowerCase();
    final isUncertain = (catLower == 'uncategorised' ||
            catLower == 'uncategorized' ||
            catLower == 'unknown' ||
            catLower.contains('friend') ||
            catLower.contains('peer')) &&
        appState.db.getCategoryOverride(t.merchant) == null;

    return InkWell(
      onTap: () {
        if (isUncertain) {
          UncertainTransactionModal.show(context, t);
        } else {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionDetailSheet(
              transaction: t,
              availableCategories: CategoryConstants.allCategoriesWithUncategorised,
              onCategoryChanged: (cat, sub) async {
                await appState.updateTransactionCategory(t.id, cat, sub);
              },
              onDelete: () async {
                await appState.deleteTransaction(t.id);
              },
            ),
          );
        }
      },
      borderRadius: BorderRadius.vertical(
        top: index == 0 ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Category icon avatar
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

                // Payee & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.merchant.isNotEmpty ? t.merchant : 'Transaction',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${t.paymentMode} • $dateStr',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUncertain) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFFD166),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'Tap to categorize',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Amount & Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color:
                            t.isCredit ? AppTheme.success : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStatusBadge(t.status),
                  ],
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 70,
              color: Color(0xFFF2F2F6),
            ),
        ],
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
      bg = const Color(0xFFFFF4E5);
      text = const Color(0xFFE67E22);
      icon = Icons.access_time_filled_rounded;
      label = 'Pending';
    } else {
      bg = AppTheme.successLight;
      text = AppTheme.success;
      icon = Icons.check_circle_rounded;
      label = 'Success';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: text),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}