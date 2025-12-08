# Implementation Plan

- [x] 1. Add UserService method for avatar updates

  - Create updateAvatarPath method in UserService
  - Add error handling for Firestore update failures
  - _Requirements: 1.4_

- [ ]\* 1.1 Write property test for avatar persistence

  - **Property 1: Avatar selection persistence**
  - **Validates: Requirements 1.4**

- [x] 2. Modify AvatarSelectionScreen for dual-mode operation

  - Add isRegistrationFlow and userId parameters to constructor
  - Implement conditional button text ("Continue" vs "Save")
  - Implement conditional navigation (to home vs back)
  - Add validation to prevent proceeding without selection
  - Update save logic to use UserService.updateAvatarPath
  - Prevent back navigation during registration flow using WillPopScope
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ]\* 2.1 Write property test for avatar asset loading

  - **Property 2: Avatar asset loading**
  - **Validates: Requirements 1.6**

- [x] 3. Update RegisterScreen to integrate avatar selection

  - Modify \_handleRegister to navigate to AvatarSelectionScreen after successful registration
  - Pass userId and isRegistrationFlow=true to AvatarSelectionScreen
  - Remove direct navigation to home screen
  - _Requirements: 1.1_

- [x] 4. Update AuthService registration flow

  - Ensure registerWithEmail does NOT set avatarPath initially
  - Keep avatarUrl field as null in initial user document
  - _Requirements: 1.4_

- [x] 5. Checkpoint - Test registration flow with avatar selection

  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Audit and fix HomeScreen dark mode colors

  - Replace hardcoded Colors.white with Theme.of(context).cardColor for daily goal card
  - Replace hardcoded Colors.teal with AppColors.primary/primaryDark for "Start Learning" button
  - Update hero section gradient to use theme-aware colors
  - Update top bar icons and text to use theme colors
  - Ensure all text uses Theme.of(context).textTheme colors
  - _Requirements: 2.1, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.4, 4.5_

- [x] 7. Audit and fix MainNavigationScreen dark mode colors

  - Remove hardcoded Colors.white backgroundColor
  - Ensure bottomNavigationBar uses Theme.of(context).bottomNavigationBarTheme
  - Remove hardcoded AppColors.primary and AppColors.textSecondary if theme provides them
  - Verify selected/unselected colors adapt to theme
  - _Requirements: 2.2, 2.3, 2.5, 3.1, 3.4, 5.1, 5.2, 5.3, 5.5_

- [x] 8. Audit and fix CategoryCard widget dark mode colors

  - Replace any hardcoded colors with Theme.of(context).cardColor
  - Ensure text uses Theme.of(context).textTheme colors
  - Verify card elevation is visible in dark mode
  - _Requirements: 2.3, 2.4, 2.5, 3.1, 3.5, 4.3_

- [ ]\* 8.1 Write property test for color source consistency

  - **Property 3: Color source consistency**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 6.5**

- [x] 9. Audit and fix quiz screens for color consistency

  - Update lib/screens/quiz/quiz_screen.dart
  - Update lib/screens/quiz/quiz_result_screen.dart
  - Update lib/screens/quiz/quiz_explanation_screen.dart
  - Update lib/screens/quiz/quiz_length_screen.dart
  - Update lib/screens/quiz/category_selection_screen.dart
  - Replace hardcoded colors with AppColors or theme colors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 10. Audit and fix friends and leaderboard screens

  - Update lib/screens/friends/friends_screen.dart
  - Update lib/screens/leaderboard/leaderboard_screen.dart
  - Update lib/widgets/friend_list_item.dart
  - Replace hardcoded colors with AppColors or theme colors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 11. Audit and fix VS mode screens

  - Update lib/screens/vs_mode/vs_mode_setup_screen.dart
  - Update lib/screens/vs_mode/vs_mode_quiz_screen.dart
  - Update lib/screens/vs_mode/vs_mode_result_screen.dart
  - Update lib/screens/vs_mode/vs_mode_handoff_screen.dart
  - Update lib/screens/vs_mode/vs_mode_friends_screen.dart
  - Replace hardcoded colors with AppColors or theme colors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 12. Audit and fix auth screens

  - Update lib/screens/auth/login_screen.dart
  - Update lib/screens/auth/register_screen.dart
  - Update lib/screens/auth/onboarding_screen.dart
  - Replace hardcoded colors with AppColors or theme colors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 13. Audit and fix settings screen

  - Update lib/screens/settings/settings_screen.dart
  - Replace hardcoded colors with AppColors or theme colors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ]\* 13.1 Write property test for dark mode text contrast

  - **Property 4: Dark mode text contrast**
  - **Validates: Requirements 2.3, 4.5**

- [x] 14. Update AppTheme dark theme configuration

  - Review and enhance dark theme colors in lib/theme/app_theme.dart
  - Ensure all theme properties have appropriate dark mode values
  - Verify contrast ratios meet WCAG AA standards
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.5_

- [ ]\* 14.1 Write property test for theme switching reactivity

  - **Property 5: Theme switching reactivity**
  - **Validates: Requirements 2.5, 5.5**

- [x] 15. Add missing AppColors constants if needed

  - Review all screens for custom colors that should be in AppColors
  - Add any missing color constants with descriptive names
  - Ensure both light and dark variants are defined
  - _Requirements: 3.1, 6.4_

- [x] 16. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
  - Test registration flow with avatar selection
  - Test dark mode on all screens
  - Test theme switching responsiveness
  - Verify no hardcoded colors remain
