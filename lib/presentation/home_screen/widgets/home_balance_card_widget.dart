import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/app_state.dart';
import '../../../theme/app_theme.dart';

class HomeBalanceCardWidget extends StatefulWidget {
  final int? selectedMonth;
  final int? selectedYear;
  final Function(int month, int year)? onMonthChanged;

  const HomeBalanceCardWidget({
    super.key,
    this.selectedMonth,
    this.selectedYear,
    this.onMonthChanged,
  });

  @override
  State<HomeBalanceCardWidget> createState() => _HomeBalanceCardWidgetState();
}

class _HomeBalanceCardWidgetState extends State<HomeBalanceCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _prevExpense = 0;
  bool _isBalanceHidden = true; // Hidden by default as requested!
  late int _internalMonth;
  late int _internalYear;

  int get _activeMonth => widget.selectedMonth ?? _internalMonth;
  int get _activeYear => widget.selectedYear ?? _internalYear;

  static const List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _internalMonth = widget.selectedMonth ?? DateTime.now().month;
    _internalYear = widget.selectedYear ?? DateTime.now().year;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HomeBalanceCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.selectedMonth != null && widget.selectedMonth != _internalMonth) ||
        (widget.selectedYear != null && widget.selectedYear != _internalYear)) {
      if (widget.selectedMonth != null) _internalMonth = widget.selectedMonth!;
      if (widget.selectedYear != null) _internalYear = widget.selectedYear!;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeMonth(int month, int year) {
    setState(() {
      _internalMonth = month;
      _internalYear = year;
    });
    widget.onMonthChanged?.call(month, year);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final monthExpense = appState.getTotalExpense(
          _activeMonth,
          _activeYear,
        );
        final monthIncome = appState.getTotalIncome(
          _activeMonth,
          _activeYear,
        );
        final totalBalance = appState.totalBalance;

        if (monthExpense != _prevExpense) {
          _prevExpense = monthExpense;
          _controller.forward(from: 0);
        }

        final monthName = _monthNames[_activeMonth - 1];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF161626),
                  Color(0xFF222238),
                  Color(0xFF1B182B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF161626).withAlpha(120),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppTheme.primary.withAlpha(30),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative ambient circles
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withAlpha(35),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withAlpha(20),
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Card Title + Month Dropdown Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'SpendSense Smart Card',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Month Dropdown Button directly on the main card (Screen-safe PopupMenu)
                          PopupMenuButton<int>(
                            initialValue: _activeMonth,
                            tooltip: 'Select Month',
                            position: PopupMenuPosition.under,
                            offset: const Offset(0, 8),
                            color: const Color(0xFF1E1B2E),
                            elevation: 16,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withAlpha(40),
                                width: 0.8,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 165,
                              maxWidth: 190,
                              maxHeight: 360,
                            ),
                            onSelected: (int newMonth) {
                              _changeMonth(newMonth, _activeYear);
                            },
                            itemBuilder: (context) {
                              return List.generate(12, (index) {
                                final m = index + 1;
                                final isSelected = m == _activeMonth;
                                final isCurrent = m == DateTime.now().month &&
                                    _activeYear == DateTime.now().year;

                                return PopupMenuItem<int>(
                                  value: m,
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : Colors.white38,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _monthNames[index],
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.primaryLight
                                                : Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 12.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withAlpha(90),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'NOW',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              });
                            },
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(45),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_monthNames[_activeMonth - 1].substring(0, 3)} $_activeYear',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Main Hero: Selected Month Expense Label & Privacy Toggle
                      Row(
                        children: [
                          Text(
                            'TOTAL EXPENSE (${monthName.toUpperCase()})',
                            style: const TextStyle(
                              color: Color(0xFFA0A0B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(
                              () => _isBalanceHidden = !_isBalanceHidden,
                            ),
                            child: Icon(
                              _isBalanceHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white60,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Animated Expense Amount
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          if (_isBalanceHidden) {
                            return const Text(
                              '₹ • • • • • •',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            );
                          }
                          final displayExpense = monthExpense * _animation.value;
                          return Text(
                            '₹${_fmt(displayExpense)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Selected Month Inflow & Total Net Balance Pills
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Inflow Pill
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00B894).withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Color(0xFF55EFC4),
                                      size: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income (${monthName.substring(0, 3)})',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFA0A0B8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _isBalanceHidden
                                              ? '₹ ••••'
                                              : '+₹${_fmt(monthIncome)}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF55EFC4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              width: 1,
                              height: 28,
                              color: Colors.white.withAlpha(25),
                            ),
                            const SizedBox(width: 12),

                            // Net Balance Pill
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Net Balance',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFA0A0B8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _isBalanceHidden
                                              ? '₹ ••••'
                                              : '₹${_fmt(totalBalance)}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Card Footer: Name & Card Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appState.userSettings.name.isNotEmpty
                                ? appState.userSettings.name.toUpperCase()
                                : 'PRIMARY ACCOUNT',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.contactless_rounded,
                                color: Colors.white38,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE TRACKER',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  String _fmt(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }
}
