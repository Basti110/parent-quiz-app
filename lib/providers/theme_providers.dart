import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import 'settings_providers.dart';

/// StateNotifier for managing theme state (light/dark mode)
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Load the saved theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final isDark = await _settingsService.getDarkMode();
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      // If loading fails, keep the default light theme
      // Error is silently handled to prevent app crashes on startup
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    try {
      final newMode = state == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      await _settingsService.setDarkMode(newMode == ThemeMode.dark);
      state = newMode;
    } catch (e) {
      // Rethrow to allow UI to handle the error
      rethrow;
    }
  }

  /// Set a specific theme mode
  Future<void> setTheme(bool isDark) async {
    try {
      await _settingsService.setDarkMode(isDark);
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      // Rethrow to allow UI to handle the error
      rethrow;
    }
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeNotifier(settingsService);
});
