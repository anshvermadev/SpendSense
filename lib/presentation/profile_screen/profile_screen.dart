import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final settings = appState.userSettings;
            final txnCount = appState.allTransactions.length;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar(settings)),
                SliverToBoxAdapter(
                  child: _buildProfileHeader(settings, txnCount),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: _buildDataSourcesSection(appState, settings),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _buildNotificationsSection(appState, settings),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildPrivacySection(appState)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(settings, appState),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(UserSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                settings.name.isNotEmpty ? settings.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showEditProfile(context.read<AppState>()),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserSettings settings, int txnCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.darkCard, AppTheme.darkCardSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  settings.name.isNotEmpty
                      ? settings.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.name.isNotEmpty ? settings.name : 'Your Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$txnCount transactions recorded',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  if (settings.monthlyIncome > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Monthly income: ${settings.currency}${_fmt(settings.monthlyIncome)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourcesSection(AppState appState, UserSettings settings) {
    return _buildSection(
      title: 'Data Sources',
      children: [
        _buildToggleRow(
          icon: Icons.sms_outlined,
          iconColor: AppTheme.primary,
          title: 'SMS Reading',
          subtitle: 'Auto-detect bank transactions',
          value: settings.smsReadingEnabled,
          onChanged: (v) async {
            final updated = UserSettings(
              name: settings.name,
              monthlyIncome: settings.monthlyIncome,
              currency: settings.currency,
              notificationsEnabled: settings.notificationsEnabled,
              smsReadingEnabled: v,
              trackedCategories: settings.trackedCategories,
            );
            await appState.saveUserSettings(updated);
          },
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.upload_file_outlined,
          iconColor: AppTheme.secondary,
          title: 'Bank Statement Import',
          subtitle: 'Import CSV/PDF statements',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Import',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
          ),
          onTap: () => _showImportInfo(),
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.edit_note_outlined,
          iconColor: const Color(0xFF00B894),
          title: 'Manual Entries',
          subtitle:
              '${appState.allTransactions.where((t) => t.source == 'Manual').length} manual entries',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.success,
              ),
            ),
          ),
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(AppState appState, UserSettings settings) {
    return _buildSection(
      title: 'Notifications',
      children: [
        _buildToggleRow(
          icon: Icons.notifications_outlined,
          iconColor: AppTheme.warning,
          title: 'Budget Alerts',
          subtitle: 'Alert when 80% budget used',
          value: settings.notificationsEnabled,
          onChanged: (v) async {
            final updated = UserSettings(
              name: settings.name,
              monthlyIncome: settings.monthlyIncome,
              currency: settings.currency,
              notificationsEnabled: v,
              smsReadingEnabled: settings.smsReadingEnabled,
              trackedCategories: settings.trackedCategories,
            );
            await appState.saveUserSettings(updated);
          },
        ),
        _buildDivider(),
        _buildToggleRow(
          icon: Icons.repeat_outlined,
          iconColor: AppTheme.primary,
          title: 'Subscription Alerts',
          subtitle: 'Notify when subscription detected',
          value: settings.notificationsEnabled,
          onChanged: (v) async {
            final updated = UserSettings(
              name: settings.name,
              monthlyIncome: settings.monthlyIncome,
              currency: settings.currency,
              notificationsEnabled: v,
              smsReadingEnabled: settings.smsReadingEnabled,
              trackedCategories: settings.trackedCategories,
            );
            await appState.saveUserSettings(updated);
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection(AppState appState) {
    return _buildSection(
      title: 'Privacy & Data',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'All transaction data stays on your device only. Nothing is uploaded to any server.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.download_outlined,
          iconColor: AppTheme.primary,
          title: 'Export My Data',
          subtitle: 'Download all transactions as CSV',
          onTap: () => _exportData(appState),
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.delete_outline_rounded,
          iconColor: AppTheme.errorColor,
          title: 'Delete All Data',
          subtitle: 'Permanently remove all transactions',
          titleColor: AppTheme.errorColor,
          onTap: () => _confirmDeleteAll(appState),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(UserSettings settings, AppState appState) {
    return _buildSection(
      title: 'App Settings',
      children: [
        _buildActionRow(
          icon: Icons.currency_rupee_rounded,
          iconColor: AppTheme.primary,
          title: 'Currency',
          subtitle: settings.currency,
          onTap: null,
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.info_outline_rounded,
          iconColor: AppTheme.textSecondary,
          title: 'How Categorisation Works',
          subtitle: 'Rule-based keyword matching',
          onTap: () => _showCategorizationInfo(),
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.category_outlined,
          iconColor: AppTheme.secondary,
          title: 'Tracked Categories',
          subtitle: settings.trackedCategories.join(', '),
          onTap: () => _showCategoryManager(appState, settings),
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.refresh_rounded,
          iconColor: AppTheme.warning,
          title: 'Re-scan Past Transactions',
          subtitle: 'Apply new SMS rules to old data',
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scanning old transactions...')),
            );
            await appState.reprocessSmsTransactions();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-scan complete!')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 18,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 1,
    indent: 64,
    color: Color(0xFFF0F0F5),
  );

  void _showEditProfile(AppState appState) {
    final settings = appState.userSettings;
    final nameCtrl = TextEditingController(text: settings.name);
    final incomeCtrl = TextEditingController(
      text: settings.monthlyIncome > 0
          ? settings.monthlyIncome.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  filled: true,
                  fillColor: AppTheme.surfaceVariantLight,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: incomeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income (Optional)',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppTheme.surfaceVariantLight,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = UserSettings(
                      name: nameCtrl.text.trim(),
                      monthlyIncome:
                          double.tryParse(incomeCtrl.text.trim()) ?? 0,
                      currency: settings.currency,
                      notificationsEnabled: settings.notificationsEnabled,
                      smsReadingEnabled: settings.smsReadingEnabled,
                      trackedCategories: settings.trackedCategories,
                    );
                    await appState.saveUserSettings(updated);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportData(AppState appState) {
    final csv = appState.exportCsv();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Export Data',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your transaction data has been prepared for export.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                csv.length > 200 ? '${csv.substring(0, 200)}...' : csv,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(AppState appState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete All Data',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.errorColor,
          ),
        ),
        content: const Text(
          'This will permanently delete all transactions, budgets, and settings. This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await appState.deleteAllData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bank Statement Import',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Download your bank statement as CSV from your bank\'s net banking portal, then import it here. SpendSense will parse and categorise all transactions automatically.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCategorizationInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'How Categorisation Works',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'SpendSense uses a keyword dictionary to match merchant names to categories. For example, "Swiggy" → Food, "Ola" → Transport.\n\nIf a transaction is miscategorised, you can correct it in History. SpendSense will remember your correction for future transactions from the same merchant.\n\nNo AI or internet connection is required — everything runs on your device.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCategoryManager(AppState appState, UserSettings settings) {
    final allCategories = [
      'Food',
      'Groceries',
      'Transport',
      'Shopping',
      'EMI',
      'Subscriptions',
      'Utilities',
      'Medical',
      'Housing',
      'Entertainment',
    ];
    final selected = Set<String>.from(settings.trackedCategories);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tracked Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allCategories.map((cat) {
                  final isSelected = selected.contains(cat);
                  return GestureDetector(
                    onTap: () => setSheetState(() {
                      if (isSelected) {
                        selected.remove(cat);
                      } else {
                        selected.add(cat);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = UserSettings(
                      name: settings.name,
                      monthlyIncome: settings.monthlyIncome,
                      currency: settings.currency,
                      notificationsEnabled: settings.notificationsEnabled,
                      smsReadingEnabled: settings.smsReadingEnabled,
                      trackedCategories: selected.toList(),
                    );
                    await appState.saveUserSettings(updated);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
