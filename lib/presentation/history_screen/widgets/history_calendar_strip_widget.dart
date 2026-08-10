import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HistoryCalendarStripWidget extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  const HistoryCalendarStripWidget({
    required this.selectedMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    super.key,
  });

  int get _daysInMonth =>
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

  int get _emptyDays {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    // weekday is 1 for Mon, 7 for Sun. We want Sunday to be 0
    return firstDay.weekday == 7 ? 0 : firstDay.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final prev = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1,
                      1,
                    );
                    onMonthChanged(prev);
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
                  '${months[selectedMonth.month - 1]} ${selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final next = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      1,
                    );
                    onMonthChanged(next);
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
          // Weekday Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekDayHeader('S'),
                _WeekDayHeader('M'),
                _WeekDayHeader('T'),
                _WeekDayHeader('W'),
                _WeekDayHeader('T'),
                _WeekDayHeader('F'),
                _WeekDayHeader('S'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Day grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _daysInMonth + _emptyDays,
              itemBuilder: (context, i) {
                if (i < _emptyDays) {
                  return const SizedBox.shrink();
                }
                final dayNumber = i - _emptyDays + 1;
                final day = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  dayNumber,
                );
                final isToday =
                    day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                final isSelected =
                    selectedDay != null &&
                    selectedDay!.year == day.year &&
                    selectedDay!.month == day.month &&
                    selectedDay!.day == day.day;

                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : isToday
                              ? AppTheme.secondary.withAlpha(50)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.secondary
                                  : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayHeader extends StatelessWidget {
  final String text;
  const _WeekDayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
