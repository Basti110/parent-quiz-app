import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';
import 'settings_providers.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsService _settingsService;

  LocaleNotifier(this._settingsService) : super(const Locale('en')) {
    _loadLocale();
  }

  /// Load the saved locale or detect device locale on first launch
  Future<void> _loadLocale() async {
    final savedLanguageCode = await _settingsService.getLanguage();

    if (savedLanguageCode != null) {
      // Use saved language preference
      state = Locale(savedLanguageCode);
    } else {
      // First launch: detect device locale
      final deviceLocale = _detectDeviceLocale();
      state = deviceLocale;
      // Save the detected locale for future launches
      await _settingsService.setLanguage(deviceLocale.languageCode);
    }
  }

  /// Detect the device's default locale
  Locale _detectDeviceLocale() {
    // Get the device's locale from the platform
    final platformLocale = ui.PlatformDispatcher.instance.locale;

    // Check if the device locale is supported (English or German)
    if (platformLocale.languageCode == 'de') {
      return const Locale('de');
    }

    // Default to English for all other locales
    return const Locale('en');
  }

  /// Set a new locale and persist it
  Future<void> setLocale(String languageCode) async {
    await _settingsService.setLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return LocaleNotifier(settingsService);
});
