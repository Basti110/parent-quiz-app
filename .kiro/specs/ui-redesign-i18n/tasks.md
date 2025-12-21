# Implementation Plan

- [x] 1. Update ARB files with new localization keys
  - Add all identified hardcoded strings as new localization keys to app_en.arb
  - Provide accurate German translations for all new keys in app_de.arb
  - Ensure consistent naming convention following existing patterns
  - Validate ARB file syntax and structure
  - _Requirements: 1.1, 1.2, 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ]* 1.1 Write property test for ARB file completeness
  - **Property 1: Translation key completeness**
  - **Validates: Requirements 7.1**

- [x] 2. Fix error message localization in services and screens
  - [x] 2.1 Update VS Mode error messages
    - Replace hardcoded error strings in vs_mode_quiz_screen.dart
    - Replace hardcoded error strings in vs_mode_setup_screen.dart
    - Replace hardcoded error strings in vs_mode_result_screen.dart
    - _Requirements: 1.3, 3.1, 3.4_

  - [x] 2.2 Update Duel system error messages
    - Replace hardcoded error strings in duel_question_screen.dart
    - Replace hardcoded error strings in duel_challenge_screen.dart
    - Replace hardcoded error strings in duel_result_screen.dart
    - _Requirements: 1.3, 3.1, 3.4_

  - [x] 2.3 Update Friends system error messages
    - Replace hardcoded error strings in friends_screen.dart
    - Replace hardcoded error strings in vs_mode_friends_screen.dart
    - _Requirements: 1.3, 3.1, 3.2_

  - [x] 2.4 Update general error messages
    - Replace hardcoded error strings in statistics_screen.dart
    - Replace hardcoded error strings in settings_screen.dart
    - _Requirements: 1.3, 3.1_

- [ ]* 2.5 Write property test for error message localization
  - **Property 2: Error message localization**
  - **Validates: Requirements 1.3, 3.1, 3.2, 3.3, 3.4, 3.5**

- [x] 3. Fix screen titles and navigation elements
  - [x] 3.1 Update AppBar titles
    - Replace hardcoded titles in VS Mode screens
    - Replace hardcoded titles in Duel screens
    - Replace hardcoded titles in Friends screens
    - Replace hardcoded titles in Quiz screens
    - _Requirements: 4.1_

  - [x] 3.2 Update navigation labels
    - Verify all existing navigation labels use localization
    - Fix any hardcoded navigation text
    - _Requirements: 4.2, 4.3_

- [ ]* 3.3 Write property test for navigation element localization
  - **Property 5: Navigation element localization**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [x] 4. Fix dialog content and interactive elements
  - [x] 4.1 Update dialog titles and content
    - Replace hardcoded dialog titles (Add Friend, Exit Duel, etc.)
    - Replace hardcoded dialog content text
    - _Requirements: 1.4, 5.3_

  - [x] 4.2 Update button labels
    - Replace hardcoded button text (Accept, Decline, Cancel, etc.)
    - Replace hardcoded action button text (Start Duel, Go Back, etc.)
    - _Requirements: 1.5, 5.1_

  - [x] 4.3 Update form field labels and placeholders
    - Replace hardcoded form labels and placeholders
    - Update language selection radio button labels
    - _Requirements: 5.2_

- [ ]* 4.4 Write property test for dialog and interactive element localization
  - **Property 3: Dialog localization completeness**
  - **Validates: Requirements 1.4, 5.3**

- [ ]* 4.5 Write property test for interactive element localization
  - **Property 4: Interactive element localization**
  - **Validates: Requirements 1.5, 5.1, 5.2, 5.4**

- [x] 5. Fix status messages and notifications
  - [x] 5.1 Update SnackBar messages
    - Replace hardcoded success messages (Friend request sent, etc.)
    - Replace hardcoded info messages (Friend code copied, etc.)
    - Replace hardcoded failure messages
    - _Requirements: 6.1, 6.3_

  - [x] 5.2 Update loading and empty state messages
    - Replace hardcoded loading text
    - Replace hardcoded empty state messages
    - _Requirements: 6.2, 6.3_

  - [x] 5.3 Update validation messages
    - Replace hardcoded validation error text
    - Update form validation messages
    - _Requirements: 3.2_

- [ ]* 5.4 Write property test for status message localization
  - **Property 6: Status message localization**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [x] 6. Fix game-specific content and labels
  - [x] 6.1 Update VS Mode game content
    - Replace hardcoded game labels (VS, Questions, Time, Winner)
    - Replace hardcoded player interaction text
    - Replace hardcoded game flow messages
    - _Requirements: 1.2, 1.5_

  - [x] 6.2 Update Duel game content
    - Replace hardcoded duel-specific text
    - Replace hardcoded progress indicators
    - _Requirements: 1.2, 1.5_

- [ ]* 6.3 Write property test for game content localization
  - **Property 7: Game content localization**
  - **Validates: Requirements 1.2, 1.5**

- [x] 7. Update language selection implementation
  - [x] 7.1 Fix language selection labels
    - Replace hardcoded "English" and "Deutsch" labels with localized versions
    - Ensure proper display of language names in their native form
    - _Requirements: 5.2_

  - [x] 7.2 Test language switching functionality
    - Verify all updated strings change when switching languages
    - Test edge cases and error scenarios during language switching
    - _Requirements: 1.1_

- [ ]* 7.3 Write property test for language switching completeness
  - **Property 1: Language switching completeness**
  - **Validates: Requirements 1.1, 1.2**

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Comprehensive testing and validation
  - [x] 9.1 Run all property-based tests
    - Execute all localization property tests
    - Verify test coverage across all updated components
    - _Requirements: All_

  - [x] 9.2 Manual testing validation
    - Test complete app navigation in both languages
    - Verify text layout and truncation issues
    - Test error scenarios in both languages
    - _Requirements: All_

- [ ]* 9.3 Write integration tests for localization
  - Create end-to-end tests for complete localization coverage
  - Test cross-screen consistency and terminology
  - _Requirements: All_

- [x] 10. Final quality assurance
  - [x] 10.1 German translation review
    - Review all German translations for accuracy and consistency
    - Verify proper German UI conventions are followed
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 10.2 UI layout validation
    - Test German text layout (typically longer than English)
    - Verify no text truncation or overflow issues
    - Test on different screen sizes and orientations
    - _Requirements: 1.1, 1.2_

  - [x] 10.3 Performance validation
    - Verify language switching performance
    - Test app startup time with localization
    - _Requirements: 1.1_

- [x] 11. Final Checkpoint - Make sure all tests are passing
  - Ensure all tests pass, ask the user if questions arise.