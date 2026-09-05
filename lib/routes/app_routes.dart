import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/history_screen/full_history_screen.dart';
import '../presentation/history_screen/history_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String onboardingScreen = '/onboarding-screen';
  static const String homeScreen = '/home-screen';
  static const String historyScreen = '/history-screen';
  static const String fullHistoryScreen = '/full-history-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String profileScreen = '/profile-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.fullHistoryScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FullHistoryScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.historyScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HistoryScreen(),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
                transitionDuration: const Duration(milliseconds: 280),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
