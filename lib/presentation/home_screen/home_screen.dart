import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../history_screen/widgets/statement_download_dialog.dart';
import './widgets/home_analytics_chart_widget.dart';
import './widgets/home_balance_card_widget.dart';
import './widgets/home_financial_pulse_widget.dart';
import './widgets/home_quick_actions_widget.dart';
import './widgets/home_transactions_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: HomeBalanceCardWidget(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
            onMonthChanged: (month, year) {
              setState(() {
                _selectedMonth = month;
                _selectedYear = year;
              });
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: HomeQuickActionsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: HomeAnalyticsChartWidget(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: HomeFinancialPulseWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: HomeTransactionsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    HomeBalanceCardWidget(
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                      onMonthChanged: (month, year) {
                        setState(() {
                          _selectedMonth = month;
                          _selectedYear = year;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const HomeQuickActionsWidget(),
                    const SizedBox(height: 20),
                    HomeAnalyticsChartWidget(
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                    ),
                    const SizedBox(height: 20),
                    const HomeFinancialPulseWidget(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(flex: 4, child: HomeTransactionsWidget()),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          final name = appState.userSettings.name;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
          final firstName = name.isNotEmpty ? name.split(' ').first : 'there';

          return Row(
            children: [
              // User Avatar with gradient
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Greeting & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Welcome to SpendSense',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Shortcut
              GestureDetector(
                onTap: () => context.push(AppRoutes.fullHistoryScreen),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textPrimary,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // PDF Statement Shortcut
              GestureDetector(
                onTap: () => StatementDownloadDialog.show(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppTheme.primary,
                    size: 19,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
