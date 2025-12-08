# Implementation Plan

- [x] 1. Set up internationalization infrastructure

  - Add flutter_localizations dependency to pubspec.yaml
  - Create l10n directory and configuration files
  - Create app_en.arb with English translations for all UI strings
  - Create app_de.arb with German translations for all UI strings
  - Update pubspec.yaml with l10n configuration
  - Run flutter gen-l10n to generate localization files
  - _Requirements: 5.1, 5.3, 5.4, 5.5, 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ]\* 1.1 Write property test for translation fallback

  - **Property 6: Translation fallback**
  - **Validates: Requirements 5.4**

- [x] 2. Create theme management system

  - Create lib/theme/app_theme.dart with light and dark theme definitions
  - Create lib/theme/app_colors.dart with color constants
  - Create lib/providers/theme_providers.dart with ThemeNotifier
  - Extend SettingsService with getDarkMode and setDarkMode methods
  - Add SharedPreferences dependency if not already present
  - _Requirements: 4.2_

- [x] 2.1 Write property test for theme persistence

  - **Property 4: Theme persistence**
  - **Validates: Requirements 4.2**

- [x] 3. Create locale management system

  - Create lib/providers/locale_providers.dart with LocaleNotifier
  - Extend SettingsService with getLanguage and setLanguage methods
  - Implement device locale detection on first launch
  - _Requirements: 5.1, 5.2_

- [ ]\* 3.1 Write property test for language persistence

  - **Property 3: Language persistence**
  - **Validates: Requirements 5.2**

- [ ]\* 3.2 Write property test for locale change propagation

  - **Property 8: Locale change propagation**
  - **Validates: Requirements 4.3**

- [x] 4. Update main.dart with i18n and theme support

  - Import AppLocalizations and localization delegates
  - Add theme and locale providers to MaterialApp
  - Configure supportedLocales for English and German
  - Set up localizationsDelegates
  - _Requirements: 5.1, 5.3, 8.4_

- [x] 5. Create main navigation structure

  - Create lib/screens/main_navigation.dart with bottom navigation bar
  - Implement navigation state management with selectedIndex
  - Add navigation items for Dashboard, VS Mode, Leaderboard, Settings
  - Implement \_onItemTapped to switch between screens
  - Use AppLocalizations for navigation labels
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ]\* 5.1 Write property test for navigation consistency

  - **Property 1: Navigation state consistency**
  - **Validates: Requirements 1.2, 1.3**

- [x] 6. Create category card widget

  - Create lib/widgets/category_card.dart
  - Implement icon path resolution with fallback to default.png
  - Add error handling for missing category icons
  - Implement navigation to QuizLengthScreen on tap
  - Style card with elevation and proper spacing
  - _Requirements: 2.3, 2.4_

- [x] 6.1 Write property test for category icon fallback

  - **Property 2: Category icon fallback**
  - **Validates: Requirements 2.4**

- [x] 7. Redesign home screen (dashboard)

  - Update lib/screens/home/home_screen.dart
  - Create header with crown icon and correct answers count
  - Add dashboard background image display
  - Implement categories grid with CategoryCard widgets
  - Add "Start Random Quiz" button at bottom
  - Use AppLocalizations for all text
  - _Requirements: 2.1, 2.2, 2.5, 2.6, 2.7_

- [x] 8. Create friend list item widget

  - Create lib/widgets/friend_list_item.dart
  - Display friend avatar, display name, wins, and losses
  - Add navigation to VSModeSetupScreen on tap
  - Style with Card and ListTile
  - Use AppLocalizations for wins/losses labels
  - _Requirements: 3.2_

- [x] 8.1 Write property test for friend list ordering

  - **Property 7: Friend list ordering**
  - **Validates: Requirements 3.2**

- [x] 9. Create VS Mode friends screen

  - Create lib/screens/vs_mode/vs_mode_friends_screen.dart
  - Display friends list using FriendListItem widgets
  - Add "Add Friend" button in app bar
  - Implement add friend dialog with friend code input
  - Show empty state message when no friends exist
  - Use AppLocalizations for all text
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 10. Extend Friend model

  - Update lib/models/friend.dart
  - Add avatarPath field
  - Add wins and losses fields
  - Add computed properties for totalGames and winRate
  - Update fromMap and toMap methods
  - _Requirements: 3.2_

- [x] 11. Create avatar selection screen

  - Create lib/screens/settings/avatar_selection_screen.dart
  - Load all avatars from assets/app_images/avatars/
  - Display avatars in a grid layout
  - Implement selection state with visual highlight
  - Add save button to persist selection
  - Extend SettingsService with getAvatarPath and setAvatarPath
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]\* 11.1 Write property test for avatar selection validation

  - **Property 5: Avatar selection validation**
  - **Validates: Requirements 6.3**

- [x] 12. Redesign settings screen

  - Update lib/screens/settings/settings_screen.dart
  - Add dark mode toggle using SwitchListTile
  - Add language selection ListTile with dialog
  - Add change avatar ListTile with navigation
  - Add logout ListTile with confirmation
  - Use AppLocalizations for all text
  - Connect to theme and locale providers
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 13. Update user model for avatar support

  - Update lib/models/user_model.dart
  - Add avatarPath field
  - Update fromMap and toMap methods
  - Update Firestore schema documentation
  - _Requirements: 6.3, 6.4_

- [x] 14. Update all existing screens with AppLocalizations

  - Update lib/screens/auth/login_screen.dart
  - Update lib/screens/auth/register_screen.dart
  - Update lib/screens/auth/onboarding_screen.dart
  - Update lib/screens/quiz/quiz_screen.dart
  - Update lib/screens/quiz/quiz_result_screen.dart
  - Update lib/screens/quiz/quiz_explanation_screen.dart (including "Explanation", "Tips", "Correct!", "Incorrect", "Next Question", "Finish Quiz" labels)
  - Update lib/screens/leaderboard/leaderboard_screen.dart
  - Replace all hardcoded strings with AppLocalizations calls
  - _Requirements: 5.3, 5.5, 7.3, 7.4_

- [x] 15. Add all required assets

  - Verify assets/app_images/avatars/ contains avatar_1.png through avatar_6.png
  - Verify assets/app_images/categories/ contains category icons
  - Verify assets/app_images/categories/default.png exists
  - Verify assets/app_images/dashboard.png exists
  - Update pubspec.yaml assets section if needed
  - _Requirements: 2.3, 2.4, 2.7, 6.1, 6.4_

- [x] 16. Update pubspec.yaml dependencies

  - Add flutter_localizations dependency
  - Add shared_preferences dependency (if not present)
  - Verify flutter_riverpod is present
  - Add intl dependency for date formatting
  - Run flutter pub get
  - _Requirements: 8.1_

- [x] 17. Create app settings model

  - Create lib/models/app_settings.dart
  - Define AppSettings class with darkMode, languageCode, avatarPath
  - Implement fromMap and toMap methods
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 18. Update navigation flow

  - Update AuthWrapper to navigate to MainNavigationScreen instead of HomeScreen
  - Ensure all navigation uses named routes or MaterialPageRoute consistently
  - Update logout flow to navigate to login screen
  - _Requirements: 1.1, 4.6_

- [x] 19. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [ ] 20. Write unit tests for theme management

  - Test ThemeNotifier toggleTheme method
  - Test theme persistence to SharedPreferences
  - Test theme loading on initialization
  - _Requirements: 4.2_

- [ ]\* 21. Write unit tests for locale management

  - Test LocaleNotifier setLocale method
  - Test locale persistence to SharedPreferences
  - Test locale loading on initialization
  - Test device locale detection
  - _Requirements: 5.1, 5.2_

- [ ]\* 22. Write unit tests for settings service extensions

  - Test getDarkMode and setDarkMode
  - Test getLanguage and setLanguage
  - Test getAvatarPath and setAvatarPath
  - _Requirements: 4.2, 5.2, 6.3_

- [ ]\* 23. Write widget tests

  - Test BottomNavigationBar displays correct items
  - Test CategoryCard displays icon and title
  - Test FriendListItem displays friend data
  - Test SettingsScreen displays all options
  - Test AvatarSelectionScreen displays avatar grid
  - _Requirements: 1.1, 2.3, 3.2, 4.1, 6.1_

- [ ] 24. Write integration tests

  - Test complete navigation flow through all tabs
  - Test language change updates all screens
  - Test theme change updates all screens
  - Test avatar selection and display
  - Test friend addition and display
  - _Requirements: 1.2, 4.2, 4.3, 6.3, 3.4_

- [ ] 25. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
