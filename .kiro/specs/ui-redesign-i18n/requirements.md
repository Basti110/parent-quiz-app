# Requirements Document

## Introduction

This specification defines a comprehensive UI redesign and internationalization (i18n) implementation for the parent quiz application. The redesign includes updating the navigation bar, VS mode screen, dashboard, question flow, settings screen, and adding multi-language support (German and English).

## Design References

This specification is based on the following HTML design mockups:

- **app_navbar_vs_mode.html**: Reference for bottom navigation bar, VS Mode/Friends screen, and settings screen design
- **app_dashboard_questions.html**: Reference for dashboard layout, question flow, and explanation screen with tips display

## Glossary

- **System**: The Flutter-based parent quiz mobile application
- **User**: A parent using the application to learn about child-rearing topics
- **VS Mode**: Pass-and-play competitive quiz mode between two users
- **Dashboard**: The main home screen showing categories and user stats
- **i18n**: Internationalization - the process of designing software to support multiple languages
- **Avatar**: User profile picture selected from predefined options
- **Category**: A topic area for quiz questions (e.g., Sleep, Nutrition, Health, Play)
- **Dark Mode**: A color scheme using dark backgrounds to reduce eye strain

## Requirements

### Requirement 1

**User Story:** As a user, I want to navigate between different sections of the app using a bottom navigation bar, so that I can easily access different features.

#### Acceptance Criteria

1. WHEN the user views any main screen THEN the system SHALL display a bottom navigation bar with icons for Dashboard, VS Mode, Leaderboard, and Settings
2. WHEN the user taps a navigation item THEN the system SHALL navigate to the corresponding screen and highlight the active tab
3. WHEN the user is on a specific screen THEN the system SHALL visually indicate which navigation item is currently active
4. WHEN the navigation bar is displayed THEN the system SHALL use consistent iconography and styling across all tabs

### Requirement 2

**User Story:** As a user, I want to see my quiz statistics and available categories on the dashboard, so that I can quickly start learning about topics that interest me.

#### Acceptance Criteria

1. WHEN the user views the dashboard THEN the system SHALL display a header showing a crown icon and the total number of correctly answered questions
2. WHEN the user views the dashboard THEN the system SHALL display all available quiz categories with their respective icons
3. WHEN a category icon exists in the assets THEN the system SHALL display the category-specific icon from assets/app_images/categories/
4. WHEN a category icon does not exist THEN the system SHALL display the default category icon from assets/app_images/categories/default.png
5. WHEN the user taps a category THEN the system SHALL navigate to the quiz length selection screen for that category
6. WHEN the user taps "Start Random Quiz" THEN the system SHALL begin a quiz with random questions from all categories
7. WHEN the dashboard is displayed THEN the system SHALL show the dashboard background image from assets/app_images/dashboard.png

### Requirement 3

**User Story:** As a user, I want to view and manage my friends list in the VS Mode screen, so that I can compete with other parents.

#### Acceptance Criteria

1. WHEN the user views the VS Mode screen THEN the system SHALL display a leaderboard-style interface showing friends with their wins and losses
2. WHEN the user views the VS Mode screen THEN the system SHALL display each friend's avatar, display name, number of wins, and number of losses
3. WHEN the user taps the add friend button THEN the system SHALL display a dialog to enter a friend code
4. WHEN the user enters a valid friend code THEN the system SHALL add the friend to the user's friends list
5. WHEN the user taps on a friend THEN the system SHALL navigate to the VS Mode setup screen with that friend pre-selected
6. WHEN no friends exist THEN the system SHALL display a message prompting the user to add friends

### Requirement 4

**User Story:** As a user, I want to customize my app experience through settings, so that I can use the app in my preferred language and visual style.

#### Acceptance Criteria

1. WHEN the user views the settings screen THEN the system SHALL display options for dark mode toggle, language selection, avatar change, and logout
2. WHEN the user toggles dark mode THEN the system SHALL immediately apply the dark theme to all screens
3. WHEN the user selects a language (German or English) THEN the system SHALL update all UI text to the selected language
4. WHEN the user taps change avatar THEN the system SHALL display a grid of available avatars from assets/app_images/avatars/
5. WHEN the user selects a new avatar THEN the system SHALL update the user's profile with the selected avatar
6. WHEN the user taps logout THEN the system SHALL sign out the user and navigate to the login screen

### Requirement 5

**User Story:** As a user, I want the app to support multiple languages, so that I can use it in my native language.

#### Acceptance Criteria

1. WHEN the system initializes THEN the system SHALL detect the device's default language and use it if supported
2. WHEN the user changes the language setting THEN the system SHALL persist the language preference across app restarts
3. WHEN displaying any UI text THEN the system SHALL use the appropriate translation for the selected language
4. WHEN a translation is missing for the selected language THEN the system SHALL fall back to English
5. WHEN the system supports a language THEN the system SHALL provide translations for all UI strings, button labels, and messages

### Requirement 6

**User Story:** As a user, I want to select my avatar from predefined options, so that I can personalize my profile.

#### Acceptance Criteria

1. WHEN the user views the avatar selection screen THEN the system SHALL display all available avatars from assets/app_images/avatars/ directory
2. WHEN the user taps an avatar THEN the system SHALL highlight the selected avatar
3. WHEN the user confirms avatar selection THEN the system SHALL update the user's profile in Firestore with the avatar filename
4. WHEN displaying a user's avatar THEN the system SHALL load the image from the assets directory using the stored filename
5. WHEN an avatar file is missing THEN the system SHALL display a default placeholder avatar

### Requirement 7

**User Story:** As a user, I want the question flow to have a clean, modern design, so that I can focus on learning without distractions.

#### Acceptance Criteria

1. WHEN the user views a question THEN the system SHALL display the question text prominently with clear answer options
2. WHEN the user selects an answer THEN the system SHALL provide immediate visual feedback indicating correct or incorrect
3. WHEN the user answers a question THEN the system SHALL display the explanation screen with the correct answer, detailed explanation, and practical tips
4. WHEN the explanation screen displays tips THEN the system SHALL show them in a visually distinct card with an icon
5. WHEN the user completes a quiz THEN the system SHALL display a results screen showing score, XP earned, and performance summary
6. WHEN displaying quiz screens THEN the system SHALL use consistent typography, spacing, and color scheme

### Requirement 8

**User Story:** As a developer, I want to use Flutter's internationalization framework, so that adding new languages is straightforward and maintainable.

#### Acceptance Criteria

1. WHEN implementing i18n THEN the system SHALL use the flutter_localizations package
2. WHEN adding translations THEN the system SHALL store translation strings in ARB (Application Resource Bundle) files
3. WHEN accessing translated strings THEN the system SHALL use the AppLocalizations class generated from ARB files
4. WHEN the app builds THEN the system SHALL generate localization delegates automatically
5. WHEN a new language is added THEN the system SHALL only require adding a new ARB file without code changes
