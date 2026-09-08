import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../presentation/home_screen/widgets/uncertain_transaction_modal.dart';
import '../services/app_state.dart';
import './app_navigation.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUncertainTransactions();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkUncertainTransactions();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkUncertainTransactions() {
    if (!mounted) return;
    context.read<AppState>().promptUncertainTransactionModal();
  }

  @override
  Widget build(BuildContext context) {
    // Watch AppState so whenever a new transaction arrives via SMS or is added while app is open,
    // this rebuilds and triggers the modal check immediately.
    context.watch<AppState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUncertainTransactions();
    });

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: AppNavigation(navigationShell: widget.navigationShell),
    );
  }
}

