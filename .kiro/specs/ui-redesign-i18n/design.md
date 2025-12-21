# Design Document

## Overview

This design addresses the systematic localization of all hardcoded strings in the Flutter parenting quiz app. The analysis revealed approximately 150+ hardcoded strings across various components including error messages, dialog content, button labels, screen titles, and status messages. The solution involves creating new localization keys, updating ARB files with German translations, and refactoring all affected components to use the AppLocalizations system.

## Architecture

The localization system follows Flutter's standard i18n architecture:

```
lib/l10n/
├── app_en.arb          # English translations (source)
├── app_de.arb          # German translations
├── app_localizations.dart        # Generated base class
├── app_localizations_en.dart     # Generated English class
└── app_localizations_de.dart     # Generated German class
```

**Key Components:**
- **ARB Files**: Store translation key-value pairs for each supported locale
- **AppLocalizations**: Generated class providing type-safe access to translations
- **LocalizationsDelegate**: Handles locale switching and loading
- **Context Extension**: Provides easy access to translations via `AppLocalizations.of(context)`

## Components and Interfaces

### 1. Hardcoded String Categories

Based on the codebase analysis, hardcoded strings fall into these categories:

#### A. Error Messages
- Network/API errors: "Error loading questions", "Failed to load statistics"
- Validation errors: "Please select an answer", "Please enter Player A name"
- Authentication errors: "User not authenticated"
- Generic errors: "Error starting VS Mode", "Failed to accept duel"

#### B. Dialog Content
- Titles: "Add Friend", "Exit Duel?", "Duel Challenge"
- Content: "Your progress will be saved and you can continue later"
- Actions: "Accept", "Decline", "Cancel", "OK"

#### C. Screen Titles (AppBar)
- "VS Mode", "VS Mode Setup", "Duel Results"
- "Select Category", "Friends", "Duel"

#### D. Button Labels
- "Start Duel", "Go Back", "Play Again", "Home"
- "Retry", "Exit", "Accept Challenge"

#### E. Status Messages
- Success: "Friend request sent!", "Duel challenge sent!"
- Info: "Friend code copied to clipboard", "Duel declined"
- Loading: Various loading states and progress indicators

#### F. Form Labels and Placeholders
- "ABC123" (friend code placeholder)
- Language selection: "English", "Deutsch"
- Player names and game setup labels

### 2. Localization Key Naming Convention

Following the existing pattern in the ARB files:

```
Category_Context_Element
```

Examples:
- `errorLoadingQuestions` → `errorLoadingDuel`
- `dialogTitleAddFriend` → `dialogTitleExitDuel`
- `buttonAcceptChallenge` → `buttonDeclineChallenge`
- `statusFriendRequestSent` → `statusDuelDeclined`

### 3. Component Refactoring Strategy

Each hardcoded string will be replaced following this pattern:

**Before:**
```dart
Text('Error loading duel: ${e.toString()}')
```

**After:**
```dart
Text(l10n.errorLoadingDuel(e.toString()))
```

**Before:**
```dart
AppBar(title: const Text('VS Mode Setup'))
```

**After:**
```dart
AppBar(title: Text(l10n.vsModeSetup))
```

## Data Models

### 1. New Localization Keys Structure

The following new keys will be added to both ARB files:

#### Error Messages
```json
{
  "errorStartingVsMode": "Error starting VS Mode: {error}",
  "errorLoadingDuel": "Error loading duel: {error}",
  "errorSubmittingAnswer": "Error submitting answer: {error}",
  "errorCompletingDuel": "Error completing duel: {error}",
  "errorAcceptingDuel": "Failed to accept duel: {error}",
  "errorDecliningDuel": "Failed to decline duel: {error}",
  "errorUpdatingStats": "Error updating stats: {error}",
  "errorLoadingResults": "Error loading results: {error}",
  "errorLoadingCategories": "Error loading categories: {error}",
  "errorLoadingFriends": "Error loading friends: {error}",
  "errorLoadingUserData": "Error loading user data: {error}",
  "errorAcceptingFriendRequest": "Failed to accept friend request: {error}",
  "errorDecliningFriendRequest": "Failed to decline friend request: {error}",
  "errorCreatingDuel": "Failed to create duel: {error}",
  "errorAddingFriend": "Failed to add friend. Please try again.",
  "userNotAuthenticated": "User not authenticated"
}
```

#### Validation Messages
```json
{
  "pleaseSelectCategory": "Please select a category",
  "pleaseEnterPlayerAName": "Please enter Player A name",
  "pleaseEnterPlayerBName": "Please enter Player B name",
  "pleaseEnterFriendCode": "Please enter a friend code",
  "friendCodeLength": "Friend code must be 6-8 characters",
  "noUserFoundWithCode": "No user found with this friend code",
  "cannotAddYourself": "You cannot add yourself as a friend",
  "alreadyFriends": "You are already friends with this user"
}
```

#### Dialog Content
```json
{
  "dialogTitleExitDuel": "Exit Duel?",
  "dialogContentExitDuel": "Your progress will be saved and you can continue later.",
  "dialogTitleAddFriend": "Add Friend",
  "dialogTitleDuelChallenge": "Duel Challenge",
  "challengeNoLongerAvailable": "This challenge is no longer available"
}
```

#### Button Labels
```json
{
  "buttonStartDuel": "Start Duel",
  "buttonGoBack": "Go Back",
  "buttonPlayAgain": "Play Again",
  "buttonHome": "Home",
  "buttonAcceptChallenge": "Accept Challenge",
  "buttonDeclineChallenge": "Decline",
  "buttonExit": "Exit",
  "buttonOk": "OK",
  "buttonAccept": "Accept",
  "buttonDecline": "Decline"
}
```

#### Screen Titles
```json
{
  "screenTitleVsMode": "VS Mode",
  "screenTitleDuel": "Duel",
  "screenTitleDuelResults": "Duel Results",
  "screenTitleSelectCategory": "Select Category"
}
```

#### Status Messages
```json
{
  "statusFriendRequestSent": "Friend request sent to {name}!",
  "statusDuelChallengeSent": "Duel challenge sent to {name}!",
  "statusDuelDeclined": "Duel declined",
  "statusFriendCodeCopied": "Friend code copied to clipboard",
  "statusNowFriends": "You are now friends with {name}!",
  "statusFriendRequestDeclined": "Friend request declined",
  "statusFriendAdded": "{name} added as friend!"
}
```

#### Game Content
```json
{
  "vsText": "VS",
  "questionsLabel": "Questions",
  "timeLabel": "Time",
  "winnerLabel": "Winner",
  "answerAtOwnPace": "Answer at your own pace",
  "highestScoreWins": "Highest score wins",
  "passDeviceTo": "Pass device to {playerName}",
  "startPlayerTurn": "START {playerName}'S TURN",
  "duelWith": "Duel with {playerName}",
  "questionProgress": "Question {current} / {total}",
  "submitAnswer": "SUBMIT ANSWER",
  "youLabel": "You"
}
```

#### Form Elements
```json
{
  "friendCodePlaceholder": "ABC123",
  "languageEnglish": "English",
  "languageGerman": "Deutsch",
  "noCategoriesAvailable": "No categories available",
  "pleaseLoginToViewFriends": "Please log in to view friends"
}
```

### 2. German Translations

Each English key will have a corresponding German translation:

```json
{
  "errorStartingVsMode": "Fehler beim Starten des VS Modus: {error}",
  "errorLoadingDuel": "Fehler beim Laden des Duells: {error}",
  "pleaseSelectCategory": "Bitte wählen Sie eine Kategorie",
  "dialogTitleExitDuel": "Duell beenden?",
  "buttonStartDuel": "Duell starten",
  "statusFriendRequestSent": "Freundschaftsanfrage an {name} gesendet!",
  "vsText": "VS",
  "questionsLabel": "Fragen",
  "timeLabel": "Zeit",
  "passDeviceTo": "Gerät an {playerName} übergeben"
}
```

## 
## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

After analyzing the acceptance criteria, the following properties can be tested to ensure proper localization:

**Property 1: Language switching completeness**
*For any* supported language selection, all visible text elements should display content in the selected language and not contain any hardcoded English strings
**Validates: Requirements 1.1, 1.2**

**Property 2: Error message localization**
*For any* error condition that displays a message to the user, the error text should be localized and not contain hardcoded English strings
**Validates: Requirements 1.3, 3.1, 3.2, 3.3, 3.4, 3.5**

**Property 3: Dialog localization completeness**
*For any* dialog that can be opened in the app, all text elements (title, content, buttons) should use localized strings
**Validates: Requirements 1.4, 5.3**

**Property 4: Interactive element localization**
*For any* interactive UI element (buttons, form fields, dropdowns), the displayed text should use localized strings
**Validates: Requirements 1.5, 5.1, 5.2, 5.4**

**Property 5: Navigation element localization**
*For any* navigation element (screen titles, tab labels, menu items), the displayed text should use localized strings
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

**Property 6: Status message localization**
*For any* status message or notification shown to the user, the text should be localized and not contain hardcoded strings
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

**Property 7: Tooltip and help text localization**
*For any* tooltip or help text displayed to the user, the content should use localized strings
**Validates: Requirements 5.5**

## Error Handling

### 1. Missing Translation Keys
- **Detection**: Use Flutter's debug mode to identify missing translation keys
- **Fallback**: Display the key name with a warning prefix (e.g., "MISSING: keyName")
- **Logging**: Log missing keys for developer attention
- **Recovery**: Gracefully degrade to English if German translation is missing

### 2. Locale Loading Failures
- **Detection**: Catch exceptions during locale switching
- **Fallback**: Revert to previous working locale
- **User Feedback**: Show localized error message about language switching failure
- **Recovery**: Allow user to retry language selection

### 3. Parameterized String Errors
- **Detection**: Validate parameter substitution in strings with placeholders
- **Fallback**: Display string without parameters if substitution fails
- **Logging**: Log parameter mismatch errors
- **Recovery**: Ensure app continues functioning with degraded text display

### 4. ARB File Validation
- **Build-time**: Validate ARB file syntax and key consistency
- **Runtime**: Ensure all required keys exist in both language files
- **Development**: Use linting rules to catch missing translations
- **CI/CD**: Automated checks for translation completeness

## Testing Strategy

### Unit Testing Approach
- **Widget Tests**: Test individual components with different locales
- **Translation Tests**: Verify specific translations are loaded correctly
- **Locale Switching Tests**: Test language switching functionality
- **Error Scenario Tests**: Test behavior when translations are missing

### Property-Based Testing Approach
The testing will use the `flutter_test` framework with custom property-based testing utilities to verify localization properties across different scenarios.

**Property-Based Testing Library**: Custom implementation using Flutter's test framework with randomized locale switching and UI traversal.

**Test Configuration**: Each property-based test will run a minimum of 100 iterations with different combinations of:
- Language selections (English/German)
- Screen navigation paths
- Error conditions
- User interactions

**Property Test Implementation Requirements**:
- Each property-based test must be tagged with a comment referencing the design document property
- Use format: `**Feature: ui-redesign-i18n, Property {number}: {property_text}**`
- Tests will programmatically navigate through the app and verify text localization
- Automated detection of hardcoded strings using pattern matching

### Integration Testing
- **End-to-End Locale Tests**: Full app navigation in both languages
- **Cross-Screen Consistency**: Verify consistent terminology across screens
- **Real Device Testing**: Test on actual devices with different system locales
- **Performance Testing**: Ensure locale switching doesn't impact performance

### Manual Testing Checklist
- Visual inspection of all screens in both languages
- Verification of text truncation and layout in German (typically longer)
- Testing of edge cases like very long German compound words
- Accessibility testing with screen readers in both languages

## Implementation Plan Overview

### Phase 1: Analysis and Preparation
1. Complete audit of hardcoded strings (already done)
2. Create comprehensive list of new localization keys
3. Generate German translations for all new keys
4. Update ARB files with new translations

### Phase 2: Core Component Updates
1. Update error handling components
2. Refactor dialog components
3. Update navigation and screen titles
4. Fix button and form element labels

### Phase 3: Status and Notification Updates
1. Update SnackBar messages
2. Fix loading and empty state messages
3. Update success and failure notifications
4. Fix tooltip and help text

### Phase 4: Testing and Validation
1. Implement property-based tests
2. Run comprehensive testing suite
3. Manual testing and validation
4. Performance and accessibility testing

### Phase 5: Quality Assurance
1. German language review by native speaker
2. UI/UX review for text layout issues
3. Final integration testing
4. Documentation updates

This systematic approach ensures complete localization coverage while maintaining code quality and user experience standards.