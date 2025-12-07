import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application theme definitions for light and dark modes
class AppTheme {
  /// Light theme configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    // AppBar theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Card theme
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    // Icon theme
    iconTheme: const IconThemeData(color: AppColors.iconPrimary, size: 24),
    // Primary icon theme
    primaryIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
    ),
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
    ),
    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    ),
    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // List tile theme
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.iconPrimary,
      tileColor: Colors.transparent,
    ),
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      disabledColor: AppColors.textSecondary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textSecondary.withValues(alpha: 0.3);
      }),
    ),
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.borderLight,
    ),
  );

  /// Dark theme configuration
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.accentDark,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    // AppBar theme with proper contrast
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Card theme with proper elevation for dark mode
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.5),
    ),
    // Text theme with WCAG AA compliant contrast ratios
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
    // Icon theme for proper contrast
    iconTheme: const IconThemeData(color: Colors.white, size: 24),
    // Primary icon theme
    primaryIconTheme: const IconThemeData(
      color: AppColors.primaryLight,
      size: 24,
    ),
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
    ),
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
    ),
    // Divider theme for proper visibility
    dividerTheme: DividerThemeData(
      color: AppColors.textSecondary.withValues(alpha: 0.2),
      thickness: 1,
      space: 1,
    ),
    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),
    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.primaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // List tile theme
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      tileColor: Colors.transparent,
    ),
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedColor: AppColors.primaryDark,
      disabledColor: AppColors.textSecondary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryDark;
        }
        return AppColors.textSecondary.withValues(alpha: 0.3);
      }),
    ),
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
      linearTrackColor: AppColors.progressTrackDark,
    ),
  );
}
