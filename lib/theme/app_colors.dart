import 'package:flutter/material.dart';

/// Color constants for the application
/// Based on Teal color scheme from the design reference
class AppColors {
  // Primary colors - Teal theme (main app color)
  static const Color primary = Color(0xFF14b8a6); // Teal-500
  static const Color primaryDark = Color(0xFF0d9488); // Teal-600
  static const Color primaryLight = Color(0xFF5eead4); // Teal-300

  // Primary variants
  static const Color primaryLightest = Color(0xFFf0fdfa); // Teal-50
  static const Color primaryDarker = Color(0xFF0f766e); // Teal-700

  // Accent colors
  static const Color accent = Color(0xFFf97316); // Orange-500
  static const Color accentLight = Color(0xFFfb923c); // Orange-400
  static const Color accentDark = Color(0xFFea580c); // Orange-600

  // Background colors
  static const Color background = Color(0xFFfafafa); // Grey-50
  static const Color backgroundDark = Color(0xFF0f172a); // Slate-900

  // Surface colors
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1e293b); // Slate-800

  // Text colors
  static const Color textPrimary = Color(0xFF1f2937); // Grey-800
  static const Color textSecondary = Color(0xFF6b7280); // Grey-500
  static const Color textTertiary = Color(0xFF9ca3af); // Grey-400
  static const Color textOnPrimary = Colors.white;
  static const Color textSecondaryDark = Color(
    0xFFb0b0b0,
  ); // Light grey for dark mode secondary text

  // Border colors
  static const Color border = Color(0xFFe5e7eb); // Grey-200
  static const Color borderLight = Color(0xFFf3f4f6); // Grey-100

  // Icon colors
  static const Color iconPrimary = Color(0xFF374151); // Grey-700
  static const Color iconSecondary = Color(0xFF9ca3af); // Grey-400

  // Success/Error colors (Tailwind palette)
  static const Color success = Color(0xFF10b981); // Emerald-500
  static const Color successLightest = Color(0xFFecfdf5); // Emerald-50
  static const Color successLight = Color(0xFFa7f3d0); // Emerald-200
  static const Color successDark = Color(0xFF047857); // Emerald-700
  static const Color successDarkest = Color(0xFF064e3b); // Emerald-900

  static const Color error = Color(0xFFef4444); // Red-500
  static const Color errorLightest = Color(0xFFfef2f2); // Red-50
  static const Color errorLight = Color(0xFFfecaca); // Red-200
  static const Color errorDark = Color(0xFFb91c1c); // Red-700
  static const Color errorDarkest = Color(0xFF7f1d1d); // Red-900

  static const Color warning = Color(0xFFf59e0b); // Amber-500
  static const Color warningLightest = Color(0xFFfffbeb); // Amber-50
  static const Color warningLight = Color(0xFFfde68a); // Amber-200
  static const Color warningMedium = Color(0xFFfbbf24); // Amber-400
  static const Color warningDark = Color(0xFFb45309); // Amber-700
  static const Color warningDarkest = Color(0xFF78350f); // Amber-900

  static const Color info = Color(0xFF3b82f6); // Blue-500

  // Additional palette colors
  static const Color teal50 = Color(0xFFf0fdfa); // Teal-50
  static const Color pink50 = Color(0xFFfdf2f8); // Pink-50
  static const Color yellow50 = Color(0xFFfefce8); // Yellow-50

  // Category colors
  static const Color categorySleep = Color(0xFF6366f1); // Indigo-500
  static const Color categoryNutrition = Color(0xFFf97316); // Orange-500
  static const Color categoryHealth = Color(0xFF10b981); // Green-500
  static const Color categoryPlay = Color(0xFF3b82f6); // Blue-500
  static const Color categoryDefault = Color(0xFF14b8a6); // Teal-500

  // Special colors
  static const Color crown = Color(0xFFfbbf24); // Amber-400
  static const Color fire = Color(0xFFf97316); // Orange-500
  static const Color xp = Color(0xFF14b8a6); // Teal-500
  static const Color cyan500 = Color(0xFF06b6d4); // Cyan-500 for gradients

  // Progress indicator colors
  static const Color progressTrackDark = Color(
    0xFF334155,
  ); // Slate-700 for dark mode progress track

  // VS Mode player colors (MaterialColor for shade access)
  static const MaterialColor playerA = Colors.blue;
  static const MaterialColor playerB = Colors.green;
}
