import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class DashboardSubscriptionsWidget extends StatefulWidget {
  const DashboardSubscriptionsWidget({super.key});

  @override
  State<DashboardSubscriptionsWidget> createState() =>
      _DashboardSubscriptionsWidgetState();
}

class _DashboardSubscriptionsWidgetState
    extends State<DashboardSubscriptionsWidget> {
  final Set<String> _cancelled = {};

  static const Map<String, IconData> _merchantIcons = {
    'netflix': Icons.play_circle_outline_rounded,
    'spotify': Icons.music_note_outlined,
    'amazon': Icons.local_shipping_outlined,
    'hotstar': Icons.live_tv_outlined,
    'disney': Icons.live_tv_outlined,
    'youtube': Icons.play_arrow_outlined,
    'apple': Icons.apple,
    'google': Icons.g_mobiledata_rounded,
    'microsoft': Icons.window_outlined,
    'adobe': Icons.design_services_outlined,
    'dropbox': Icons.cloud_outlined,
    'linkedin': Icons.work_outline_rounded,
    'coursera': Icons.school_outlined,
    'udemy': Icons.school_outlined,
  };

  static const Map<String, Color> _merchantColors = {
    'netflix': Color(0xFFE50914),
    'spotify': Color(0xFF1DB954),
    'amazon': Color(0xFFFF9900),
    'hotstar': Color(0xFF1A75CF),
    'disney': Color(0xFF1A75CF),
    'youtube': Color(0xFFFF0000),
    'apple': Color(0xFF555555),
    'google': Color(0xFF4285F4),
    'microsoft': Color(0xFF00A4EF),
    'adobe': Color(0xFFFF0000),
    'dropbox': Color(0xFF0061FF),
    'linkedin': Color(0xFF0A66C2),
    'coursera': Color(0xFF0056D2),
    'udemy': Color(0xFFA435F0),
  };

  IconData _getIcon(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in _merchantIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.repeat_outlined;
  }

  Color _getColor(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in _merchantColors.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final subscriptions = appState.detectedSubscriptions;
        final activeTotal = subscriptions
            .where((s) => !_cancelled.contains(s['merchant'] as String))
            .fold(0.0, (sum, s) => sum + (s['averageAmount'] as double));

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
                      'Subscriptions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (activeTotal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '₹${_fmt(activeTotal)}/mo',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Auto-detected recurring charges',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                if (subscriptions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.repeat_outlined,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No subscriptions detected yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add recurring transactions to detect subscriptions',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...subscriptions.map((sub) {
                    final merchant = sub['merchant'] as String;
                    final amount = sub['averageAmount'] as double;
                    final months = sub['activeMonths'] as int;
                    final isCancelled = _cancelled.contains(merchant);
                    final icon = _getIcon(merchant);
                    final color = _getColor(merchant);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withAlpha(31),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, size: 20, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchant,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isCancelled
                                        ? AppTheme.textMuted
                                        : AppTheme.textPrimary,
                                    decoration: isCancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Active for $months month${months != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${_fmt(amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isCancelled
                                      ? AppTheme.textMuted
                                      : AppTheme.textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (!isCancelled)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _cancelled.add(merchant)),
                                  child: const Text(
                                    'Mark cancelled',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariantLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Cancelled',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
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