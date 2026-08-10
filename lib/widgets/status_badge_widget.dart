import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BadgeStatus { active, inactive, warning, success, error, info }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final double fontSize;

  const StatusBadgeWidget({
    required this.label,
    this.status = BadgeStatus.active,
    this.fontSize = 11,
    super.key,
  });

  Color _bgColor() {
    switch (status) {
      case BadgeStatus.active:
        return AppTheme.primaryContainer;
      case BadgeStatus.inactive:
        return const Color(0xFFF0F0F5);
      case BadgeStatus.warning:
        return AppTheme.warningLight;
      case BadgeStatus.success:
        return AppTheme.successLight;
      case BadgeStatus.error:
        return AppTheme.errorLight;
      case BadgeStatus.info:
        return const Color(0xFFE8F4FF);
    }
  }

  Color _textColor() {
    switch (status) {
      case BadgeStatus.active:
        return AppTheme.primary;
      case BadgeStatus.inactive:
        return AppTheme.textSecondary;
      case BadgeStatus.warning:
        return AppTheme.warning;
      case BadgeStatus.success:
        return AppTheme.success;
      case BadgeStatus.error:
        return AppTheme.errorColor;
      case BadgeStatus.info:
        return const Color(0xFF0984E3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _textColor(),
        ),
      ),
    );
  }
}
