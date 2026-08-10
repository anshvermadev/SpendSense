import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class WeekNavigatorWidget extends StatelessWidget {
  final DateTime selectedWeekStart; // Assumed to be Sunday
  final ValueChanged<DateTime> onWeekChanged;
  final ValueChanged<DateTime>? onDaySelected;

  const WeekNavigatorWidget({
    required this.selectedWeekStart,
    required this.onWeekChanged,
    this.onDaySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = selectedWeekStart.add(const Duration(days: 6));
    
    // Format week text, e.g. "19-25 July"
    final startFormat = selectedWeekStart.month == weekEnd.month
        ? DateFormat('d')
        : DateFormat('d MMM');
    final endFormat = DateFormat('d MMMM');
    final weekText = '${startFormat.format(selectedWeekStart)} - ${endFormat.format(weekEnd)}';

    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final prev = selectedWeekStart.subtract(const Duration(days: 7));
                    onWeekChanged(prev);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  weekText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final next = selectedWeekStart.add(const Duration(days: 7));
                    onWeekChanged(next);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekday strip indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final day = selectedWeekStart.add(Duration(days: i));
                const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                return _WeekDayLabel(
                  weekDays[i], 
                  day.day.toString(),
                  onTap: () => onDaySelected?.call(day),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  final String text;
  final String dateStr;
  final VoidCallback? onTap;
  
  const _WeekDayLabel(this.text, this.dateStr, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
      child: Column(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
