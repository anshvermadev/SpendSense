import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../history_screen/widgets/add_transaction_sheet.dart';
import '../../history_screen/widgets/statement_download_dialog.dart';

class HomeQuickActionsWidget extends StatelessWidget {
  const HomeQuickActionsWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            context: context,
            label: 'Add Spend',
            icon: Icons.add_circle_outline_rounded,
            color: AppTheme.primary,
            onTap: () => _showAddTransaction(context),
          ),
          _buildActionItem(
            context: context,
            label: 'Passbook',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF0984E3),
            onTap: () => context.go(AppRoutes.historyScreen),
          ),
          _buildActionItem(
            context: context,
            label: 'PDF Export',
            icon: Icons.picture_as_pdf_outlined,
            color: AppTheme.secondary,
            onTap: () => StatementDownloadDialog.show(context),
          ),
          _buildActionItem(
            context: context,
            label: 'Analytics',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF00B894),
            onTap: () => context.go(AppRoutes.dashboardScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
