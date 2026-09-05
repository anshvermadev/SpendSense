import 'package:flutter/material.dart';

/// Centralized category definitions, icons, and color tokens for SpendSense.
/// Synchronized with the SpendSense 15-Class ML Categorization Model.
class CategoryConstants {
  // 15 canonical ML model categories
  static const String food = 'Food';
  static const String groceries = 'Groceries';
  static const String transport = 'Transport';
  static const String shopping = 'Shopping';
  static const String emi = 'EMI';
  static const String subscriptions = 'Subscriptions';
  static const String subscription = 'Subscription';
  static const String utilities = 'Utilities';
  static const String medical = 'Medical';
  static const String housing = 'Housing';
  static const String entertainment = 'Entertainment';
  static const String income = 'Income';
  static const String education = 'Education';
  static const String fuel = 'Fuel';
  static const String personal = 'Personal';
  static const String travel = 'Travel';
  static const String uncategorised = 'Uncategorised';

  /// List of primary expense categories for user selection & tracking
  static const List<String> primaryCategories = [
    'Food',
    'Groceries',
    'Transport',
    'Shopping',
    'Fuel',
    'Entertainment',
    'Subscriptions',
    'Utilities',
    'Medical',
    'Housing',
    'Education',
    'Travel',
    'Personal',
    'EMI',
    'Income',
  ];

  /// All known categories including aliases
  static const List<String> allCategoriesWithUncategorised = [
    ...primaryCategories,
    'Uncategorised',
  ];

  /// Maps categories to distinctive, modern Flutter icons
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.fastfood_outlined,
    'Groceries': Icons.shopping_basket_outlined,
    'Transport': Icons.directions_car_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'EMI': Icons.account_balance_outlined,
    'Subscriptions': Icons.subscriptions_outlined,
    'Subscription': Icons.subscriptions_outlined,
    'Utilities': Icons.electric_bolt_outlined,
    'Medical': Icons.local_hospital_outlined,
    'Housing': Icons.home_outlined,
    'Entertainment': Icons.movie_outlined,
    'Income': Icons.account_balance_wallet_outlined,
    'Education': Icons.school_outlined,
    'Fuel': Icons.local_gas_station_outlined,
    'Personal': Icons.person_outline_rounded,
    'Travel': Icons.flight_takeoff_outlined,
    'Uncategorised': Icons.help_outline_rounded,
    'Uncategorized': Icons.help_outline_rounded,
  };

  /// High-contrast, tailored harmonious color palette
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF6B45),          // Warm Coral Orange
    'Groceries': Color(0xFF00B894),     // Mint Emerald
    'Transport': Color(0xFF0984E3),     // Vibrant Blue
    'Shopping': Color(0xFF6C5CE7),      // Soft Purple
    'EMI': Color(0xFF2D3436),            // Charcoal Slate
    'Subscriptions': Color(0xFF8E44AD),  // Royal Violet
    'Subscription': Color(0xFF8E44AD),   // Royal Violet
    'Utilities': Color(0xFFF39C12),      // Electric Amber
    'Medical': Color(0xFF00CEC9),        // Teal Cyan
    'Housing': Color(0xFF74B9FF),        // Sky Blue
    'Entertainment': Color(0xFFE17055),  // Cinema Terracotta
    'Income': Color(0xFF10B981),         // Green Income
    'Education': Color(0xFF3B82F6),      // Academic Blue
    'Fuel': Color(0xFFEA2027),           // Energy Crimson
    'Personal': Color(0xFFA29BFE),       // Personal Lavender
    'Travel': Color(0xFF0652DD),         // Voyage Navy
    'Uncategorised': Color(0xFFAAAAAC),  // Muted Gray
    'Uncategorized': Color(0xFFAAAAAC),  // Muted Gray
  };

  /// Returns icon with safe fallback
  static IconData getIcon(String? category) {
    if (category == null || category.isEmpty) {
      return Icons.help_outline_rounded;
    }
    return categoryIcons[category] ??
        categoryIcons[canonical(category)] ??
        Icons.category_outlined;
  }

  /// Returns color with safe fallback
  static Color getColor(String? category) {
    if (category == null || category.isEmpty) {
      return const Color(0xFFAAAAAC);
    }
    return categoryColors[category] ??
        categoryColors[canonical(category)] ??
        const Color(0xFFAAAAAC);
  }

  /// Normalizes singular/plural variations (e.g. Subscriptions vs Subscription)
  static String canonical(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'subscription' || lower == 'subscriptions') {
      return 'Subscriptions';
    }
    if (lower == 'uncategorized' || lower == 'uncategorised') {
      return 'Uncategorised';
    }
    for (final cat in primaryCategories) {
      if (cat.toLowerCase() == lower) return cat;
    }
    return raw;
  }
}
