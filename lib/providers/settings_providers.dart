import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// Provider for SettingsService singleton
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// StateNotifier for managing theme mode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeModeNotifier(this._settingsService) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load the saved theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final mode = await _settingsService.getThemeMode();
      state = mode;
    } catch (e) {
      // If loading fails, keep the default system theme
      // Error is silently handled to prevent app crashes on startup
    }
  }

  /// Set a new theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _settingsService.setThemeMode(mode);
      state = mode;
    } catch (e) {
      // Rethrow to allow UI to handle the error
      rethrow;
    }
  }
}

/// Provider for theme mode state
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeModeNotifier(settingsService);
});
