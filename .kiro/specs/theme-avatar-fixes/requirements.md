# Requirements Document

## Introduction

This specification defines critical fixes and improvements to the theme system, avatar selection flow, and color consistency across the parent quiz application. The focus is on ensuring dark mode works properly everywhere, requiring avatar selection during registration, and establishing unified color management through AppColors.

## Glossary

- **System**: The Flutter-based parent quiz mobile application
- **User**: A parent using the application to learn about child-rearing topics
- **Avatar**: User profile picture selected from predefined options in assets/app_images/avatars/
- **Dark Mode**: A color scheme using dark backgrounds to reduce eye strain
- **AppColors**: Centralized color constants defined in lib/theme/app_colors.dart
- **Registration Flow**: The process of creating a new user account
- **Dashboard**: The main home screen showing categories and user stats
- **Navbar**: Bottom navigation bar for switching between main app sections

## Requirements

### Requirement 1

**User Story:** As a new user, I want to select an avatar during registration, so that my profile is personalized from the start.

#### Acceptance Criteria

1. WHEN a user completes the registration form THEN the system SHALL navigate to an avatar selection screen before completing registration
2. WHEN the avatar selection screen displays THEN the system SHALL show all available avatars from assets/app_images/avatars/ in a grid layout
3. WHEN a user taps an avatar THEN the system SHALL highlight the selected avatar with visual feedback
4. WHEN a user confirms avatar selection THEN the system SHALL complete the registration process and save the avatar filename (e.g., "avatar_1.png") to the user's Firestore profile in the avatarPath field
5. WHEN a user attempts to skip avatar selection THEN the system SHALL require selection of at least one avatar before proceeding
6. WHEN displaying a user's avatar THEN the system SHALL load the image from assets/app_images/avatars/ using the avatarPath value stored in Firestore

### Requirement 2

**User Story:** As a user, I want dark mode to work consistently across all screens, so that I have a comfortable viewing experience at night.

#### Acceptance Criteria

1. WHEN dark mode is enabled THEN the dashboard SHALL display with dark background colors from AppColors.backgroundDark
2. WHEN dark mode is enabled THEN the bottom navigation bar SHALL display with dark surface colors from AppColors.surfaceDark
3. WHEN dark mode is enabled THEN all text SHALL be readable with appropriate contrast against dark backgrounds
4. WHEN dark mode is enabled THEN all cards and surfaces SHALL use AppColors.surfaceDark instead of white
5. WHEN dark mode is toggled THEN the system SHALL immediately update all visible screens without requiring a restart

### Requirement 3

**User Story:** As a developer, I want all screens to use AppColors for color values, so that theme changes are consistent and maintainable.

#### Acceptance Criteria

1. WHEN rendering any screen THEN the system SHALL use color constants from AppColors instead of hardcoded Color values
2. WHEN rendering backgrounds THEN the system SHALL use Theme.of(context).scaffoldBackgroundColor or AppColors.background/backgroundDark
3. WHEN rendering text THEN the system SHALL use Theme.of(context).textTheme or AppColors text color constants
4. WHEN rendering buttons THEN the system SHALL use theme-defined button styles or AppColors for custom styling
5. WHEN rendering cards THEN the system SHALL use Theme.of(context).cardTheme or AppColors.surface/surfaceDark

### Requirement 4

**User Story:** As a user, I want the dashboard to look good in both light and dark modes, so that I can use the app comfortably in any lighting condition.

#### Acceptance Criteria

1. WHEN viewing the dashboard in dark mode THEN the hero section SHALL display with appropriate dark overlays and readable text
2. WHEN viewing the dashboard in dark mode THEN the daily goal card SHALL use AppColors.surfaceDark with proper contrast
3. WHEN viewing the dashboard in dark mode THEN category cards SHALL use AppColors.surfaceDark backgrounds
4. WHEN viewing the dashboard in dark mode THEN the "Start Learning" button SHALL use AppColors.primaryDark
5. WHEN viewing the dashboard in dark mode THEN all icons and text SHALL maintain proper contrast ratios for accessibility

### Requirement 5

**User Story:** As a user, I want the bottom navigation bar to respond to dark mode, so that the interface feels cohesive.

#### Acceptance Criteria

1. WHEN dark mode is enabled THEN the bottom navigation bar SHALL use AppColors.surfaceDark as background color
2. WHEN dark mode is enabled THEN selected navigation items SHALL use AppColors.primaryLight for visibility
3. WHEN dark mode is enabled THEN unselected navigation items SHALL use AppColors.textSecondary
4. WHEN dark mode is enabled THEN navigation bar elevation and shadows SHALL be visible against the dark background
5. WHEN switching between light and dark mode THEN the navigation bar SHALL update immediately without visual glitches

### Requirement 6

**User Story:** As a developer, I want to audit all screens for hardcoded colors, so that I can ensure complete theme consistency.

#### Acceptance Criteria

1. WHEN reviewing screen implementations THEN the system SHALL identify all instances of hardcoded Color() constructors
2. WHEN reviewing screen implementations THEN the system SHALL identify all instances of Colors.\* constants used outside of AppColors
3. WHEN hardcoded colors are found THEN the system SHALL replace them with appropriate AppColors constants or theme references
4. WHEN custom colors are necessary THEN the system SHALL add them to AppColors with descriptive names
5. WHEN all screens are audited THEN the system SHALL use only AppColors or theme-provided colors for all UI elements
