import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../services/app_state.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';

class HomeTransactionsWidget extends StatelessWidget {
  const HomeTransactionsWidget({super.key});

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
    'Income': Icons.account_balance_wallet_outlined,
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
    'Income': Color(0xFF00B894),
    'Uncategorised': Color(0xFFAAAAAC),
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final transactions = appState.allTransactions.take(8).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.historyScreen),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                _buildEmptyState()
              else
                Container(
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
                    children: transactions.asMap().entries.map((entry) {
                      return _buildRow(
                        entry.value,
                        entry.key,
                        transactions.length,
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first transaction',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Transaction t, int index, int total) {
    final isLast = index == total - 1;
    final icon = _categoryIcons[t.category] ?? Icons.help_outline_rounded;
    final color = _categoryColors[t.category] ?? AppTheme.textMuted;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.merchant,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${t.paymentMode} · ${_formatDate(t.date)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.isCredit ? AppTheme.success : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            color: Color(0xFFF0F0F5),
          ),
      ],
    );
  }

  String _fmt(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _formatDate(DateTime d) {
    const months = [
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}