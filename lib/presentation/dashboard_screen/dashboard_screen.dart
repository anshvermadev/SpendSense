import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import './widgets/dashboard_category_breakdown_widget.dart';
import './widgets/dashboard_category_trend_widget.dart';
import './widgets/dashboard_header_widget.dart';
import './widgets/dashboard_insights_widget.dart';
import './widgets/dashboard_pie_chart_widget.dart';
import './widgets/dashboard_stat_cards_widget.dart';
import './widgets/dashboard_subscriptions_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  void _onMonthChanged(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
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
      slivers: [
        SliverToBoxAdapter(
          child: DashboardHeaderWidget(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
            onMonthChanged: _onMonthChanged,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: DashboardStatCardsWidget(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: DashboardPieChartWidget(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: DashboardCategoryTrendWidget(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: DashboardCategoryBreakdownWidget(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: DashboardInsightsWidget(
            month: _selectedMonth,
            year: _selectedYear,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        const SliverToBoxAdapter(child: DashboardSubscriptionsWidget()),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DashboardHeaderWidget(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
            onMonthChanged: _onMonthChanged,
          ),
          const SizedBox(height: 20),
          DashboardStatCardsWidget(month: _selectedMonth, year: _selectedYear),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DashboardPieChartWidget(
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: DashboardCategoryTrendWidget(
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DashboardCategoryBreakdownWidget(
                  month: _selectedMonth,
                  year: _selectedYear,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    DashboardInsightsWidget(
                      month: _selectedMonth,
                      year: _selectedYear,
                    ),
                    const SizedBox(height: 20),
                    const DashboardSubscriptionsWidget(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
