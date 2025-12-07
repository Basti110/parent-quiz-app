import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Update the display name for a user
  Future<void> updateDisplayName(String userId, String newName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': newName,
      });
    } on FirebaseException catch (e) {
      throw 'Failed to update display name: ${e.message}';
    }
  }

  /// Set the theme mode preference
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = mode
          .toString()
          .split('.')
          .last; // 'light', 'dark', or 'system'
      await prefs.setString('theme_mode', modeString);
    } catch (e) {
      throw 'Failed to save theme preference: $e';
    }
  }

  /// Get the saved theme mode preference
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString('theme_mode') ?? 'system';
      return _parseThemeMode(modeString);
    } catch (e) {
      // Default to system theme if there's an error
      return ThemeMode.system;
    }
  }

  /// Parse theme mode string to ThemeMode enum
  ThemeMode _parseThemeMode(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Get the dark mode preference (true for dark, false for light)
  Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('darkMode') ?? false;
    } catch (e) {
      // Default to light mode if there's an error
      return false;
    }
  }

  /// Set the dark mode preference
  Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', value);
    } catch (e) {
      throw 'Failed to save dark mode preference: $e';
    }
  }

  /// Get the saved language preference
  Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('language');
    } catch (e) {
      // Return null if there's an error, will trigger device locale detection
      return null;
    }
  }

  /// Set the language preference
  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    } catch (e) {
      throw 'Failed to save language preference: $e';
    }
  }

  /// Get the saved avatar path preference
  Future<String?> getAvatarPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('avatarPath');
    } catch (e) {
      // Return null if there's an error, will use default avatar
      return null;
    }
  }

  /// Set the avatar path preference
  Future<void> setAvatarPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatarPath', path);
    } catch (e) {
      throw 'Failed to save avatar preference: $e';
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw 'Failed to logout: ${e.message}';
    }
  }
}
