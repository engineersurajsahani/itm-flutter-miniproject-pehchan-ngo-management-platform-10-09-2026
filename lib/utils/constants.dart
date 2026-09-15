import 'package:flutter/material.dart';

// App-wide constants
class AppConstants {
  // Expense categories
  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
    'Other',
  ];

  // Income categories
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  // Transaction types
  static const String income = 'Income';
  static const String expense = 'Expense';

  // Colors - Neo-Bank Dark Mode Palette (Faithfully matching reference images)
  static const Color primaryColor = Colors.white; // Pure white for primary interactive elements
  static const Color secondaryColor = Color(0xFF2C2C32); // Graphite / dark slate
  static const Color plumColor = Color(0xFF1F1F24); // Dark charcoal pill surface
  static const Color backgroundColor = Color(0xFF070709); // Pitch midnight black
  static const Color cardColor = Color(0xFF141417); // Dark card container
  static const Color surfaceElevated = Color(0xFF1C1C21); // Elevated dark surface
  static const Color cardBorderColor = Color(0xFF222226); // Card outline border
  static const Color cardBorderLight = Color(0xFF2C2C32); // Highlight border
  static const Color incomeColor = Color(0xFF00E676); // High-contrast emerald green
  static const Color expenseColor = Color(0xFFFF453A); // Clean red (no pink tint)
  static const Color warningColor = Color(0xFFFFAB00); // Vivid amber
  static const Color accentGreen = Color(0xFF00E676); // Emerald status accent

  // Neo-bank specific design tokens (from reference images)
  static const Color neoBackground = Color(0xFF070709);
  static const Color neoCard = Color(0xFF141417);
  static const Color neoCardBorder = Color(0xFF222226);
  static const Color neoPill = Color(0xFF1F1F24);
  static const Color neoPillBorder = Color(0xFF2C2C32);
  static const Color statusCompletedBg = Color(0xFF102A1C);
  static const Color statusCompletedText = Color(0xFF00E676);
  static const String currencySymbol = '₹';

  // Text Colors (High Contrast Monochrome & Cool Slate)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for headings & amounts
  static const Color textSecondary = Color(0xFFA1A1AA); // Clean cool neutral grey (no lavender)
  static const Color textMuted = Color(0xFF71717A); // Muted slate grey

  // Gradients (Monochrome & Dark Slate)
  static const LinearGradient sliceGradient = LinearGradient(
    colors: [Color(0xFF2C2C32), Color(0xFF1A1A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sliceHeaderGradient = LinearGradient(
    colors: [Color(0xFF1C1C21), Color(0xFF141417), Color(0xFF070709)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sliceCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1E), Color(0xFF141417)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient vaultGradient = LinearGradient(
    colors: [Color(0xFF222226), Color(0xFF16161A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category icons
  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.laptop;
      case 'business':
        return Icons.business;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.attach_money;
    }
  }

  // Category colors for charts & badges (vibrant, clean, no pinks)
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF5252);
      case 'transport':
        return const Color(0xFF38BDF8);
      case 'shopping':
        return const Color(0xFF818CF8);
      case 'bills':
        return const Color(0xFF2DD4BF);
      case 'entertainment':
        return const Color(0xFFFB923C);
      case 'health':
        return const Color(0xFF4ADE80);
      case 'education':
        return const Color(0xFFA78BFA);
      case 'travel':
        return const Color(0xFFFBBF24);
      case 'salary':
        return const Color(0xFF00E676);
      case 'freelance':
        return const Color(0xFF34D399);
      case 'business':
        return const Color(0xFF60A5FA);
      case 'investment':
        return const Color(0xFF10B981);
      case 'gift':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
