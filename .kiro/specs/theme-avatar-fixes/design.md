# Design Document

## Overview

This design addresses three critical improvements to the parent quiz application:

1. **Mandatory Avatar Selection During Registration**: Integrating avatar selection as a required step in the registration flow, ensuring all users have a personalized profile from the start.

2. **Dark Mode Fixes**: Ensuring dark mode works consistently across all screens, particularly the dashboard and bottom navigation bar, by properly utilizing theme-aware colors and AppColors constants.

3. **Unified Color Management**: Auditing and refactoring all screens to use AppColors constants instead of hardcoded color values, ensuring theme consistency and maintainability.

The design leverages the existing avatar selection screen, theme infrastructure, and Firestore user model while adding new registration flow logic and comprehensive color auditing.

## Architecture

### Registration Flow Enhancement

The registration flow will be modified to include an intermediate avatar selection step:

```
RegisterScreen → AvatarSelectionScreen (new step) → MainNavigationScreen
```

The AvatarSelectionScreen will be reused but adapted to work in two modes:

- **Registration mode**: Required selection, saves to Firestore, navigates to home
- **Settings mode**: Optional change, saves to Firestore, navigates back

### Theme System Architecture

The theme system uses a layered approach:

1. **AppColors**: Static color constants for both light and dark themes
2. **AppTheme**: ThemeData configurations that reference AppColors
3. **ThemeNotifier**: Riverpod state management for theme switching
4. **Theme.of(context)**: Runtime theme access in widgets

### Color Management Strategy

All screens will follow this hierarchy for color selection:

1. **First choice**: Use `Theme.of(context)` properties (scaffoldBackgroundColor, textTheme, etc.)
2. **Second choice**: Use AppColors constants when theme properties don't provide the needed color
3. **Never**: Use hardcoded `Color()` constructors or `Colors.*` constants directly

## Components and Interfaces

### Modified Components

#### 1. AvatarSelectionScreen

**Purpose**: Reusable avatar selection widget that works in both registration and settings contexts

**Interface**:

```dart
class AvatarSelectionScreen extends ConsumerStatefulWidget {
  final bool isRegistrationFlow;
  final String? userId; // Required for registration flow

  const AvatarSelectionScreen({
    super.key,
    this.isRegistrationFlow = false,
    this.userId,
  });
}
```

**Behavior**:

- In registration mode: Shows "Continue" button, saves to Firestore, navigates to home
- In settings mode: Shows "Save" button, saves to Firestore, navigates back
- Validates that an avatar is selected before allowing continuation
- Stores avatar filename (e.g., "avatar_1.png") in Firestore user document

#### 2. RegisterScreen

**Purpose**: User registration form

**Changes**:

- After successful Firebase Auth registration, navigate to AvatarSelectionScreen instead of home
- Pass userId to AvatarSelectionScreen for Firestore update
- Remove immediate navigation to home

#### 3. AuthService

**Purpose**: Authentication and user management

**Changes**:

- Modify `registerWithEmail` to NOT set avatarPath initially (will be set by AvatarSelectionScreen)
- Keep avatarUrl field as null in initial user document creation

#### 4. UserService

**Purpose**: User data management

**New Method**:

```dart
Future<void> updateAvatarPath(String userId, String avatarPath) async {
  await _firestore.collection('users').doc(userId).update({
    'avatarPath': avatarPath,
  });
}
```

### Theme-Aware Components

#### 1. HomeScreen (Dashboard)

**Dark Mode Fixes**:

- Hero section: Use theme-aware text colors and overlays
- Daily goal card: Use `Theme.of(context).cardTheme.color` or `AppColors.surface/surfaceDark`
- Category cards: Ensure CategoryCard widget uses theme colors
- "Start Learning" button: Use `AppColors.primary/primaryDark` based on theme
- Top bar: Use theme text colors for level/streak/XP display

#### 2. MainNavigationScreen

**Dark Mode Fixes**:

- Bottom navigation bar: Use `Theme.of(context).bottomNavigationBarTheme`
- Ensure selected/unselected colors adapt to theme
- Background color should use theme's surface color

#### 3. CategoryCard Widget

**Dark Mode Fixes**:

- Card background: Use `Theme.of(context).cardTheme.color`
- Text colors: Use `Theme.of(context).textTheme` colors
- Border/elevation: Ensure visibility in dark mode

## Data Models

### UserModel

**Existing Fields** (no changes needed):

```dart
class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl; // Stores filename like "avatar_1.png"
  // ... other fields
}
```

**Note**: The `avatarUrl` field is actually used for storing the avatar filename (e.g., "avatar_1.png"), not a full URL. This is consistent with the existing schema.

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: Avatar selection persistence

_For any_ avatar selection during registration, the selected avatar filename should be saved to the user's Firestore document in the avatarPath field, and retrieving the user document should return the same avatar filename.

**Validates: Requirements 1.4**

### Property 2: Avatar asset loading

_For any_ avatarPath value stored in Firestore, loading the avatar should successfully retrieve the corresponding image from assets/app_images/avatars/ without errors.

**Validates: Requirements 1.6**

### Property 3: Color source consistency

_For any_ widget in the application, all color values should originate from either Theme.of(context) properties or AppColors constants, with no direct use of Color() constructors or Colors.\* constants outside of AppColors definitions.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 6.5**

### Property 4: Dark mode text contrast

_For any_ text element displayed in dark mode, the contrast ratio between the text color and its background color should meet WCAG AA accessibility standards (minimum 4.5:1 for normal text, 3:1 for large text).

**Validates: Requirements 2.3, 4.5**

### Property 5: Theme switching reactivity

_For any_ visible screen, when the theme mode is toggled between light and dark, all color-dependent UI elements should update immediately in the same frame without requiring navigation, screen refresh, or app restart.

**Validates: Requirements 2.5, 5.5**

## Error Handling

### Registration Flow Errors

1. **Avatar selection failure**: If Firestore update fails, show error message and allow retry
2. **Navigation errors**: If navigation fails after avatar selection, log error and retry
3. **Asset loading errors**: If avatar image fails to load, show placeholder icon

### Theme Switching Errors

1. **SharedPreferences failure**: If theme preference can't be saved, continue with in-memory state
2. **Theme loading failure**: Default to system theme if saved preference can't be loaded

### Color Management Errors

1. **Missing AppColors constant**: Add new constant to AppColors with appropriate light/dark values
2. **Theme property unavailable**: Fall back to AppColors constant

## Testing Strategy

### Unit Tests

1. **UserService.updateAvatarPath**: Test successful update and error handling
2. **AvatarSelectionScreen mode detection**: Test registration vs settings mode behavior
3. **Theme color extraction**: Test that screens use theme colors correctly

### Property-Based Tests

Property-based tests will use the `test` package with custom generators for comprehensive validation:

1. **Property 1 (Avatar completeness)**: Generate random user registration flows and verify avatarPath is set
2. **Property 2 (Color consistency)**: Parse widget trees and verify no hardcoded colors
3. **Property 3 (Contrast ratios)**: Generate random text/background combinations and verify WCAG compliance
4. **Property 4 (Theme switching)**: Generate random theme toggle sequences and verify immediate updates
5. **Property 5 (Avatar validity)**: Generate random avatar selections and verify file existence

### Integration Tests

1. **Complete registration flow**: Test user registration → avatar selection → home navigation
2. **Theme switching**: Test toggling dark mode and verifying all screens update
3. **Avatar display**: Test that selected avatar appears in profile and navigation

### Manual Testing Checklist

1. Register new user and verify avatar selection is required
2. Toggle dark mode and verify dashboard looks correct
3. Toggle dark mode and verify navigation bar updates
4. Check all screens for visual consistency in both themes
5. Verify avatar appears correctly after selection

## Implementation Notes

### Avatar Selection Integration

The AvatarSelectionScreen will need to:

- Accept a `isRegistrationFlow` parameter to determine behavior
- Accept a `userId` parameter for Firestore updates
- Show different button text ("Continue" vs "Save")
- Navigate differently based on mode
- Prevent back navigation during registration flow

### Color Audit Process

For each screen file:

1. Search for `Color(` constructors
2. Search for `Colors.` constants
3. Replace with appropriate AppColors constant or Theme.of(context) property
4. Test in both light and dark modes
5. Verify contrast ratios meet accessibility standards

### Dark Mode Specific Fixes

**Dashboard (HomeScreen)**:

- Hero section gradient: Adjust opacity for dark mode
- Daily goal card: Use `Theme.of(context).cardColor`
- Category cards: Ensure CategoryCard uses theme colors
- Text colors: Use theme text colors throughout

**Navigation Bar (MainNavigationScreen)**:

- Background: Use `Theme.of(context).bottomNavigationBarTheme.backgroundColor`
- Selected color: Use theme's primary color
- Unselected color: Use theme's text secondary color

**CategoryCard Widget**:

- Background: Use `Theme.of(context).cardColor`
- Text: Use `Theme.of(context).textTheme` colors
- Icons: Use theme-appropriate icon colors

### Files Requiring Color Audit

Based on the codebase structure, these files likely need color auditing:

- lib/screens/home/home_screen.dart
- lib/screens/main_navigation.dart
- lib/widgets/category_card.dart
- lib/screens/quiz/\*.dart
- lib/screens/friends/friends_screen.dart
- lib/screens/leaderboard/leaderboard_screen.dart
- lib/screens/settings/settings_screen.dart
- lib/screens/vs_mode/\*.dart
- lib/screens/auth/\*.dart
