import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import './widgets/onboarding_permission_widget.dart';
import './widgets/onboarding_setup_widget.dart';
import './widgets/onboarding_value_props_widget.dart';
import './widgets/onboarding_welcome_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _checkingOnboarding = true;

  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final appState = context.read<AppState>();
    final done = await appState.isOnboardingDone();
    if (done && mounted) {
      context.go(AppRoutes.homeScreen);
    } else if (mounted) {
      setState(() => _checkingOnboarding = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finishOnboarding() {
    context.go(AppRoutes.homeScreen);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet
            ? Center(child: SizedBox(width: 480, child: _buildContent()))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              OnboardingWelcomeWidget(
                blobController: _blobController,
                onGetStarted: _nextPage,
              ),
              OnboardingValuePropsWidget(onNext: _nextPage),
              OnboardingPermissionWidget(onNext: _nextPage),
              OnboardingSetupWidget(onFinish: _finishOnboarding),
            ],
          ),
        ),
        _buildPageIndicator(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = _currentPage == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.primary.withAlpha(64),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
