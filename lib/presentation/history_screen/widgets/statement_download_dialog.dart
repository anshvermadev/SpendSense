import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/app_state.dart';
import '../../../services/database_service.dart';
import '../../../services/pdf_statement_service.dart';
import '../../../theme/app_theme.dart';

enum StatementPeriod {
  last10,
  currentMonth,
  last30Days,
  last90Days,
  allTime,
  custom,
}

class StatementDownloadDialog extends StatefulWidget {
  final List<Transaction>? customInitialTransactions;
  final String? initialPeriodTitle;

  const StatementDownloadDialog({
    super.key,
    this.customInitialTransactions,
    this.initialPeriodTitle,
  });

  static Future<void> show(
    BuildContext context, {
    List<Transaction>? customInitialTransactions,
    String? initialPeriodTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatementDownloadDialog(
        customInitialTransactions: customInitialTransactions,
        initialPeriodTitle: initialPeriodTitle,
      ),
    );
  }

  @override
  State<StatementDownloadDialog> createState() =>
      _StatementDownloadDialogState();
}

class _StatementDownloadDialogState extends State<StatementDownloadDialog> {
  StatementPeriod _selectedPeriod = StatementPeriod.last10;
  DateTimeRange? _customRange;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.customInitialTransactions != null) {
      _selectedPeriod = StatementPeriod.allTime;
    }
  }

  List<Transaction> _resolveTransactions(AppState appState) {
    if (widget.customInitialTransactions != null) {
      return widget.customInitialTransactions!;
    }

    final all = appState.allTransactions;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case StatementPeriod.last10:
        return all.take(10).toList();
      case StatementPeriod.currentMonth:
        return all
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      case StatementPeriod.last30Days:
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return all.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();
      case StatementPeriod.last90Days:
        final ninetyDaysAgo = now.subtract(const Duration(days: 90));
        return all.where((t) => t.date.isAfter(ninetyDaysAgo)).toList();
      case StatementPeriod.allTime:
        return all;
      case StatementPeriod.custom:
        if (_customRange == null) return all;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
        );
        return all
            .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
            .toList();
    }
  }

  String _getPeriodTitle() {
    if (widget.initialPeriodTitle != null) {
      return widget.initialPeriodTitle!;
    }
    switch (_selectedPeriod) {
      case StatementPeriod.last10:
        return 'Mini Statement (Last 10 Transactions)';
      case StatementPeriod.currentMonth:
        return 'Current Month (${DateFormat('MMMM yyyy').format(DateTime.now())})';
      case StatementPeriod.last30Days:
        return 'Last 30 Days';
      case StatementPeriod.last90Days:
        return 'Last 90 Days';
      case StatementPeriod.allTime:
        return 'Full Account History';
      case StatementPeriod.custom:
        if (_customRange != null) {
          final f = DateFormat('dd MMM yyyy');
          return '${f.format(_customRange!.start)} to ${f.format(_customRange!.end)}';
        }
        return 'Custom Date Range';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceLight,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = StatementPeriod.custom;
      });
    }
  }

  Future<void> _generatePdf(AppState appState) async {
    final transactions = _resolveTransactions(appState);
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions found for the selected period.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final accountHolder = appState.userSettings.name.isNotEmpty
          ? appState.userSettings.name
          : 'SpendSense Account';

      DateTime? start;
      DateTime? end;
      if (_selectedPeriod == StatementPeriod.custom && _customRange != null) {
        start = _customRange!.start;
        end = _customRange!.end;
      }

      await PdfStatementService.generateAndDownloadStatement(
        context: context,
        transactions: transactions,
        accountHolder: accountHolder,
        periodTitle: _getPeriodTitle(),
        startDate: start,
        endDate: end,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final txns = _resolveTransactions(appState);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
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
                        'Download PDF Statement',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Official bank-grade account statement',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppTheme.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (widget.customInitialTransactions == null) ...[
              const Text(
                'STATEMENT PERIOD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Options
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip(
                    StatementPeriod.last10,
                    'Last 10 (Mini)',
                    Icons.history_rounded,
                  ),
                  _buildPeriodChip(
                    StatementPeriod.currentMonth,
                    'Current Month',
                    Icons.calendar_month_rounded,
                  ),
                  _buildPeriodChip(
                    StatementPeriod.last30Days,
                    'Last 30 Days',
                    Icons.date_range_rounded,
                  ),
                  _buildPeriodChip(
                    StatementPeriod.last90Days,
                    'Last 90 Days',
                    Icons.timelapse_rounded,
                  ),
                  _buildPeriodChip(
                    StatementPeriod.allTime,
                    'All Time',
                    Icons.all_inclusive_rounded,
                  ),
                  _buildCustomChip(),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE0E0E8),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${txns.length} transaction${txns.length == 1 ? '' : 's'} included in statement',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generatePdf(appState),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  _isGenerating
                      ? 'Generating Statement...'
                      : 'Download / Print Statement',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    StatementPeriod period,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    final isSelected = _selectedPeriod == StatementPeriod.custom;
    final dateLabel = _customRange != null
        ? '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}'
        : 'Custom Date...';

    return GestureDetector(
      onTap: _pickCustomRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_calendar_rounded,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
