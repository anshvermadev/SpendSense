import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/category_constants.dart';
import '../../../services/app_state.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';

class UncertainTransactionModal extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onCompleted;

  const UncertainTransactionModal({
    required this.transaction,
    this.onCompleted,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    Transaction transaction, {
    VoidCallback? onCompleted,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncertainTransactionModal(
        transaction: transaction,
      ),
    );
    onCompleted?.call();
  }

  @override
  State<UncertainTransactionModal> createState() =>
      _UncertainTransactionModalState();
}

class _UncertainTransactionModalState extends State<UncertainTransactionModal> {
  String? _selectedCategory;
  bool _applyToAll = true;
  bool _isSubmitting = false;

  final List<String> _categories = CategoryConstants.primaryCategories;

  @override
  void initState() {
    super.initState();
    if (_categories.contains(widget.transaction.category)) {
      _selectedCategory = widget.transaction.category;
    }
  }

  String _fmt(double val) {
    if (val.isNaN || val.isInfinite) return '0';
    if (val == val.toInt()) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }

  Future<void> _handleConfirm(AppState appState) async {
    if (_selectedCategory == null) return;
    setState(() => _isSubmitting = true);

    final merchant = widget.transaction.merchant.trim();
    final chosenCategory = _selectedCategory!;

    try {
      if (_applyToAll) {
        await appState.assignMerchantCategory(
          merchant: merchant,
          category: chosenCategory,
          subcategory: widget.transaction.subcategory,
          updateAllForMerchant: true,
        );
      } else {
        await appState.updateTransactionCategory(
          widget.transaction.id,
          chosenCategory,
          widget.transaction.subcategory,
          updateAllForMerchant: false,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _applyToAll
                        ? 'Saved! All transactions for "$merchant" set to $chosenCategory.'
                        : 'Updated transaction to $chosenCategory.',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleSkip(AppState appState) {
    appState.dismissUncertainTransaction(widget.transaction.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final merchantName = t.merchant.isNotEmpty ? t.merchant : 'Unknown Payee';
    final appState = context.read<AppState>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Payee Detected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Assign a category once, and SpendSense will auto-categorize it every time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transaction summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E5EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        merchantName.isNotEmpty ? merchantName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.paymentMode} • ${t.date.day}/${t.date.month}/${t.date.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: t.isCredit ? AppTheme.success : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: CategoryConstants.getColor(_selectedCategory).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedCategory!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CategoryConstants.getColor(_selectedCategory),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Categories grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  final color = CategoryConstants.getColor(cat);
                  final icon = CategoryConstants.getIcon(cat);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withAlpha(30)
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E2EA),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? color : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? color : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Apply to all toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () {
                setState(() => _applyToAll = !_applyToAll);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _applyToAll
                      ? AppTheme.primary.withAlpha(15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _applyToAll
                        ? AppTheme.primary.withAlpha(60)
                        : const Color(0xFFE5E5EB),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _applyToAll,
                      onChanged: (val) {
                        setState(() => _applyToAll = val ?? true);
                      },
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remember for "$merchantName"',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Updates past history & auto-categorizes future payments',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => _handleSkip(appState),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Skip for Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_selectedCategory == null || _isSubmitting)
                        ? null
                        : () => _handleConfirm(appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primary.withAlpha(80),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Save & Categorize',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
