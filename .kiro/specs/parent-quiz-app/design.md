# Design Document

## Overview

ParentQuiz is a Flutter mobile application that provides evidence-based parenting education through gamified quizzes. The app uses Firebase Authentication for user management and Cloud Firestore as the primary database. The architecture follows a clean separation between UI (screens/widgets), business logic (services), and data models, enabling future extensibility with Cloud Functions while maintaining a simple, maintainable codebase for the MVP phase.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Application             │
├─────────────────────────────────────────┤
│  Screens (UI Layer)                     │
│  - Auth Screens                         │
│  - Home Screen                          │
│  - Quiz Screens                         │
│  - Leaderboard Screen                   │
│  - Friends Screen                       │
│  - VS Mode Screens                      │
├─────────────────────────────────────────┤
│  Services (Business Logic)              │
│  - AuthService                          │
│  - QuizService                          │
│  - UserService                          │
│  - LeaderboardService                   │
│  - FriendsService                       │
├─────────────────────────────────────────┤
│  Models (Data Layer)                    │
│  - User                                 │
│  - Category                             │
│  - Question                             │
│  - QuestionState                        │
│  - Friend                               │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│         Firebase Backend                │
├─────────────────────────────────────────┤
│  Firebase Auth                          │
│  Cloud Firestore                        │
│  - user collection                      │
│  - category collection                  │
│  - question collection                  │
│  - user/{id}/questionStates             │
│  - user/{id}/friends                    │
└─────────────────────────────────────────┘
```

### Design Principles

1. **Simplicity First**: Use standard Flutter Material Design components without custom theming
2. **Client-Side Logic**: All business logic runs on the client (no Cloud Functions in MVP)
3. **Direct Firestore Access**: Services interact directly with Firestore collections
4. **Future-Proof Structure**: Data model and service layer designed to accommodate Cloud Functions later
5. **State Management**: Use Riverpod for clean, testable, and type-safe state management

## Components and Interfaces

### 1. Authentication Flow

**Screens:**

- `OnboardingScreen`: Displays app introduction slides
- `LoginScreen`: Email/password login form
- `RegisterScreen`: Name, email, password registration form

**AuthService:**

```dart
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<User?> registerWithEmail(String name, String email, String password);
  Future<User?> signInWithEmail(String email, String password);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  String generateFriendCode(); // 6-8 character alphanumeric
}
```

### 2. Quiz Solo Mode

**Screens:**

- `HomeScreen`: Main navigation hub with Play, VS Mode, and Progress sections
- `CategorySelectionScreen`: Grid/list of quiz categories
- `QuizLengthScreen`: Choose 5 or 10 questions
- `QuizScreen`: Display question, options, and handle answers
- `QuizResultScreen`: Show session results, XP earned, streak status

**QuizService:**

```dart
class QuizService {
  final FirebaseFirestore _firestore;

  Future<List<Category>> getCategories();
  Future<List<Question>> getQuestionsForSession(String categoryId, int count, String userId);
  Future<void> submitAnswer(String userId, String questionId, int selectedIndex, bool isCorrect);
  Future<int> calculateSessionXP(List<bool> answers, bool allCorrect, int questionCount);
  Future<void> updateUserXP(String userId, int xpGained);
}
```

**Question Selection Logic:**

1. Query questions where `categoryId` matches and `isActive` is true
2. Load user's `questionStates` for these questions
3. Priority 1: Questions with `seenCount == 0` (never seen)
4. Priority 2: Questions with oldest `lastSeenAt` timestamp
5. Randomly select from prioritized pool

### 3. XP and Progression System

**UserService:**

```dart
class UserService {
  final FirebaseFirestore _firestore;

  Future<UserModel> getUserData(String userId);
  Future<void> updateStreak(String userId);
  Future<void> updateWeeklyXP(String userId, int xpGained);
  Future<void> updateQuestionState(String userId, String questionId, bool correct);
  int calculateLevel(int totalXp); // 100 XP per level
  Future<Map<String, double>> getCategoryMastery(String userId);
}
```

**XP Calculation Rules:**

- Correct answer: +10 XP
- Incorrect + explanation viewed: +5 XP
- Incorrect without explanation: +2 XP
- 5-question session bonus: +10 XP
- 10-question session bonus: +25 XP
- All correct bonus: +10 XP

**Streak Logic:**

```dart
void updateStreak(String userId) async {
  final user = await getUserData(userId);
  final now = DateTime.now();
  final lastActive = user.lastActiveAt;

  if (isSameDay(now, lastActive)) {
    // Same day, no change
    return;
  } else if (isYesterday(lastActive, now)) {
    // Consecutive day
    user.streakCurrent++;
    if (user.streakCurrent > user.streakLongest) {
      user.streakLongest = user.streakCurrent;
    }
  } else {
    // Streak broken
    user.streakCurrent = 1;
  }

  user.lastActiveAt = now;
  await _firestore.collection('user').doc(userId).update(user.toMap());
}
```

### 4. Weekly Leaderboard

**LeaderboardService:**

```dart
class LeaderboardService {
  final FirebaseFirestore _firestore;

  Future<List<LeaderboardEntry>> getGlobalLeaderboard(int limit);
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId);
  Future<int> getUserRank(String userId);
  void checkAndResetWeeklyXP(String userId); // Called before adding XP
}
```

**Weekly XP Reset Logic:**

```dart
void checkAndResetWeeklyXP(String userId) async {
  final user = await getUserData(userId);
  final now = DateTime.now();
  final weekStart = user.weeklyXpWeekStart;

  // Check if we're in a new week (Monday-based)
  final currentMonday = getMondayOfWeek(now);

  if (weekStart.isBefore(currentMonday)) {
    // New week started, reset
    await _firestore.collection('user').doc(userId).update({
      'weeklyXpCurrent': 0,
      'weeklyXpWeekStart': currentMonday,
    });
  }
}
```

### 5. VS Mode (Pass & Play)

**Screens:**

- `VSModeSetupScreen`: Category, length, and player name selection
- `VSModeQuizScreen`: Quiz screen with player indicator
- `VSModeHandoffScreen`: "Pass device to Player B" prompt
- `VSModeResultScreen`: Show both players' scores and winner

**VSModeService:**

```dart
class VSModeService {
  final QuizService _quizService;

  Future<VSModeSession> startVSMode(String categoryId, int questionsPerPlayer, String playerAName, String playerBName);
  Future<void> submitPlayerAnswer(VSModeSession session, String playerId, String questionId, bool isCorrect);
  VSModeResult calculateResult(VSModeSession session);
  Future<void> updateDuelStats(String userId, VSModeResult result, String userPlayerName);
}
```

**Duel Points Logic:**

- Win: +3 points, increment `duelsWon` and `duelsPlayed`
- Tie: +1 point, increment `duelsPlayed`
- Loss: +0 points, increment `duelsLost` and `duelsPlayed`

### 6. Friends System

**Screens:**

- `FriendsScreen`: Display friend code, friends list, and "Add Friend" button
- `AddFriendDialog`: Input field for friend code

**FriendsService:**

```dart
class FriendsService {
  final FirebaseFirestore _firestore;

  Future<UserModel?> findUserByFriendCode(String friendCode);
  Future<void> addFriend(String userId, String friendUserId);
  Future<List<UserModel>> getFriends(String userId);
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId);
}
```

**Add Friend Flow:**

1. User enters friend code
2. Query `user` collection where `friendCode == inputCode`
3. If found, create document at `user/{userId}/friends/{friendUserId}`
4. Set `status: "accepted"`, `createdAt: now`, `createdBy: userId`
5. Optionally create reciprocal entry (for future bidirectional queries)

### 7. Points History System

**Subcollection:**

- `user/{userId}/history/{date}`: Weekly points history for analytics and charts

**HistoryService:**

```dart
class HistoryService {
  final FirebaseFirestore _firestore;

  Future<void> saveWeeklyPoints(String userId, DateTime weekStart, int points);
  Future<List<WeeklyPoints>> getPointsHistory(String userId, int weeks);
  Future<Map<String, int>> getMonthlyStats(String userId, int months);
}
```

**Use Cases:**

- Display progress charts showing XP over time
- Compare current week performance to previous weeks
- Show monthly/yearly statistics
- Identify learning patterns and streaks

### 8. Settings and Preferences System

**Screens:**

- `SettingsScreen`: Display user preferences and account management options

**SettingsService:**

```dart
class SettingsService {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  Future<void> updateDisplayName(String userId, String newName);
  Future<void> setThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
  Future<void> logout();
}
```

**Theme Management:**

- Store theme preference locally using `shared_preferences` package
- Support three modes: light, dark, and system (follows device setting)
- Apply theme using `ThemeMode` in MaterialApp
- Persist selection across app restarts

**Settings Options:**

1. **Account Settings:**

   - Display current display name with edit button
   - Logout button with confirmation dialog

2. **Appearance Settings:**
   - Theme selector: Light, Dark, System
   - Visual preview of selected theme

**State Management:**

```dart
// Theme Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    state = _parseThemeMode(themeModeString);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString().split('.').last);
  }
}
```

## Data Models

### User Model

```dart
class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String friendCode;
  final int totalXp;
  final int currentLevel;
  final int weeklyXpCurrent;
  final DateTime weeklyXpWeekStart;
  final int streakCurrent;
  final int streakLongest;
  final int duelsPlayed;
  final int duelsWon;
  final int duelsLost;
  final int duelPoints;

  Map<String, dynamic> toMap();
  factory UserModel.fromMap(Map<String, dynamic> map, String id);
}
```

### Category Model

```dart
class Category {
  final String id;
  final String title;
  final String description;
  final int order;
  final String iconName;
  final bool isPremium;

  Map<String, dynamic> toMap();
  factory Category.fromMap(Map<String, dynamic> map, String id);
}
```

### Question Model

```dart
class Question {
  final String id;
  final String categoryId;
  final String text;
  final List<String> options;
  final List<int> correctIndices; // Support multiple correct answers
  final String explanation;
  final String? sourceLabel;
  final String? sourceUrl;
  final int difficulty;
  final bool isActive;

  Map<String, dynamic> toMap();
  factory Question.fromMap(Map<String, dynamic> map, String id);

  // Helper methods
  bool get isSingleChoice => correctIndices.length == 1;
  bool get isMultipleChoice => correctIndices.length > 1;
  bool isCorrectAnswer(List<int> selectedIndices) {
    return selectedIndices.toSet().containsAll(correctIndices) &&
           correctIndices.toSet().containsAll(selectedIndices);
  }
}
```

### QuestionState Model

```dart
class QuestionState {
  final String questionId;
  final int seenCount;
  final int correctCount;
  final DateTime lastSeenAt;
  final bool mastered;

  Map<String, dynamic> toMap();
  factory QuestionState.fromMap(Map<String, dynamic> map);
}
```

### Friend Model

```dart
class Friend {
  final String friendUserId;
  final String status; // "accepted" for MVP
  final DateTime createdAt;
  final String createdBy;

  Map<String, dynamic> toMap();
  factory Friend.fromMap(Map<String, dynamic> map);
}
```

### WeeklyPoints Model

```dart
class WeeklyPoints {
  final String date; // yyyy-MM-dd format (Monday of the week)
  final DateTime weekStart;
  final DateTime weekEnd;
  final int points;
  final int sessionsCompleted;
  final int questionsAnswered;
  final int correctAnswers;

  Map<String, dynamic> toMap();
  factory WeeklyPoints.fromMap(Map<String, dynamic> map, String date);
}
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Authentication & User Creation Properties

Property 1: User document creation completeness
_For any_ valid registration with name, email, and password, the created user document should contain all required fields: displayName, email, createdAt, lastActiveAt, friendCode, totalXp (0), currentLevel (1), weeklyXpCurrent (0), weeklyXpWeekStart, streakCurrent (0), streakLongest (0), duelsPlayed (0), duelsWon (0), duelsLost (0), duelPoints (0)
**Validates: Requirements 1.3, 11.1**

Property 2: Friend code format
_For any_ created user, the friend code should be a unique alphanumeric string with length between 6 and 8 characters
**Validates: Requirements 1.4**

Property 3: Authentication timestamp update
_For any_ successful authentication, the user's lastActiveAt field should be updated to the current timestamp
**Validates: Requirements 2.2**

Property 4: Authentication error handling
_For any_ invalid credentials (wrong email or password), the authentication attempt should fail and return an error without modifying any user data
**Validates: Requirements 2.3**

### Quiz Question Selection Properties

Property 5: Unseen question prioritization
_For any_ quiz session request where unseen questions (seenCount = 0) exist in the category, all selected questions should have seenCount = 0 before any questions with seenCount > 0 are considered
**Validates: Requirements 4.1**

Property 6: Oldest question fallback
_For any_ quiz session request where no unseen questions exist, the selected questions should be ordered by lastSeenAt timestamp in ascending order (oldest first)
**Validates: Requirements 4.2**

Property 7: Question state update on answer
_For any_ answered question, the questionStates document should have seenCount incremented by 1, and if the answer was correct, correctCount should also be incremented by 1
**Validates: Requirements 4.6**

### XP Calculation Properties

Property 8: Correct answer XP
_For any_ correct answer, the user should receive exactly 10 XP
**Validates: Requirements 5.1**

Property 9: Incorrect answer with explanation XP
_For any_ incorrect answer where the explanation is viewed, the user should receive exactly 5 XP
**Validates: Requirements 5.2**

Property 10: Incorrect answer without explanation XP
_For any_ incorrect answer where the explanation is not viewed, the user should receive exactly 2 XP
**Validates: Requirements 5.3**

Property 11: Five-question session bonus
_For any_ completed 5-question session, the user should receive a 10 XP bonus in addition to per-question XP
**Validates: Requirements 5.4**

Property 12: Ten-question session bonus
_For any_ completed 10-question session, the user should receive a 25 XP bonus in addition to per-question XP
**Validates: Requirements 5.5**

Property 13: Perfect session bonus
_For any_ session where all questions are answered correctly, the user should receive an additional 10 XP bonus
**Validates: Requirements 5.6**

Property 14: Session XP persistence
_For any_ completed session, both totalXp and weeklyXpCurrent in the user document should be incremented by the total session XP
**Validates: Requirements 5.7**

### Streak Properties

Property 15: Streak continuation
_For any_ user whose lastActiveAt is exactly yesterday's date, completing a session should increment streakCurrent by 1
**Validates: Requirements 6.2**

Property 16: Streak reset
_For any_ user whose lastActiveAt is more than 1 day ago, completing a session should reset streakCurrent to 1
**Validates: Requirements 6.3**

Property 17: Longest streak invariant
_For any_ user at any time, streakLongest should always be greater than or equal to streakCurrent
**Validates: Requirements 6.4**

### Level and Mastery Properties

Property 18: Level calculation
_For any_ totalXp value, currentLevel should equal floor(totalXp / 100) + 1
**Validates: Requirements 7.1**

Property 19: Question mastery threshold
_For any_ question with correctCount >= 3, the mastered field should be true
**Validates: Requirements 7.3**

Property 20: Category mastery calculation
_For any_ category, the mastery percentage should equal (number of mastered questions / total questions in category) \* 100
**Validates: Requirements 7.4**

### Weekly Leaderboard Properties

Property 21: Weekly XP accumulation
_For any_ session completed within the current week (between weeklyXpWeekStart and weeklyXpWeekStart + 7 days), the session XP should be added to weeklyXpCurrent
**Validates: Requirements 8.2**

Property 22: Weekly XP reset
_For any_ session completed after the current week ends, weeklyXpCurrent should be reset to the session XP and weeklyXpWeekStart should be updated to the Monday of the current week
**Validates: Requirements 8.3**

Property 23: Leaderboard sorting
_For any_ leaderboard query, the returned users should be sorted by weeklyXpCurrent in descending order (highest first)
**Validates: Requirements 8.4**

### VS Mode Properties

Property 24: Duel winner determination
_For any_ completed duel, the player with more correct answers should be declared the winner, or if scores are equal, the result should be a tie
**Validates: Requirements 9.5**

Property 25: Duel win stats update
_For any_ duel where the logged-in user wins, duelsPlayed should increment by 1, duelsWon should increment by 1, and duelPoints should increment by 3
**Validates: Requirements 9.6**

Property 26: Duel tie stats update
_For any_ duel that ends in a tie with the logged-in user, duelsPlayed should increment by 1 and duelPoints should increment by 1
**Validates: Requirements 9.7**

Property 27: Duel loss stats update
_For any_ duel where the logged-in user loses, duelsPlayed should increment by 1 and duelsLost should increment by 1
**Validates: Requirements 9.8**

### Friends System Properties

Property 28: Friend code lookup
_For any_ friend code query, the system should return at most one user whose friendCode field exactly matches the input
**Validates: Requirements 10.3**

Property 29: Friend document creation
_For any_ successful friend addition, a document should be created at user/{userId}/friends/{friendUserId} with fields: friendUserId, status ("accepted"), createdAt (current timestamp), and createdBy (current userId)
**Validates: Requirements 10.4**

Property 30: Friends leaderboard sorting
_For any_ friends leaderboard query, the returned friends should be sorted by weeklyXpCurrent in descending order
**Validates: Requirements 10.6**

### Data Structure Properties

Property 31: Question state structure
_For any_ created or updated questionStates document, it should contain fields: questionId, seenCount (>= 0), correctCount (>= 0), lastSeenAt (valid timestamp), and mastered (boolean)
**Validates: Requirements 11.2**

Property 32: Friend document structure
_For any_ created friend document, it should contain fields: friendUserId, status, createdAt (valid timestamp), and createdBy
**Validates: Requirements 11.3**

Property 33: Category data structure
_For any_ loaded category, it should contain fields: title, description, order, iconName, and isPremium
**Validates: Requirements 11.4**

Property 34: Question data structure
_For any_ loaded question, it should contain fields: categoryId, text, options (list of 3-4 strings), correctIndices (list of integers 0-3), explanation, difficulty, and isActive
**Validates: Requirements 11.5**

Property 35: Multiple correct answers validation
_For any_ question with multiple correct answers, a user's answer should only be marked correct if all and only the correct indices are selected
**Validates: Requirements 11.5**

### Points History Properties

Property 36: Weekly points persistence
_For any_ completed week, a history document should be created at user/{userId}/history/{date} with fields: date (yyyy-MM-dd), weekStart, weekEnd, points, sessionsCompleted, questionsAnswered, correctAnswers
**Validates: Requirements 11.1**

Property 37: History date format
_For any_ history document, the date field should be in yyyy-MM-dd format representing the Monday of that week
**Validates: Requirements 11.1**

### Settings and Preferences Properties

Property 38: Display name update persistence
_For any_ valid display name change, the user document's displayName field should be updated to the new value
**Validates: Requirements 13.3**

Property 39: Theme mode persistence
_For any_ theme mode selection (light, dark, or system), the preference should be stored locally and restored on app restart
**Validates: Requirements 13.4, 13.5**

Property 40: Logout state cleanup
_For any_ logout action, the user should be signed out from Firebase Auth and navigated to the login screen
**Validates: Requirements 13.2**

## Error Handling

### Authentication Errors

- Invalid email format: Display user-friendly error message
- Weak password: Display password requirements
- Email already exists: Prompt user to login instead
- Network errors: Display retry option with offline indicator

### Quiz Session Errors

- No questions available: Display message and return to category selection
- Firestore read/write failures: Cache session data locally and retry on reconnection
- Invalid question data: Skip question and log error for admin review

### Friends System Errors

- Friend code not found: Display "No user found with this code"
- Duplicate friend: Display "Already friends with this user"
- Self-add attempt: Display "Cannot add yourself as a friend"

### General Error Handling Strategy

- All Firestore operations wrapped in try-catch blocks
- User-facing error messages should be clear and actionable
- Technical errors logged for debugging but not shown to users
- Offline mode: Cache critical data and sync when connection restored

## Testing Strategy

### Unit Testing

The app will use Flutter's built-in testing framework with the `flutter_test` package for unit tests. Unit tests will cover:

**Service Layer Tests:**

- AuthService: Test user registration, login, logout, and friend code generation
- QuizService: Test question selection logic, answer submission, and XP calculation
- UserService: Test streak updates, level calculation, and mastery percentage
- LeaderboardService: Test weekly XP reset logic and ranking calculations
- FriendsService: Test friend code lookup and friend addition

**Model Tests:**

- Test `toMap()` and `fromMap()` serialization for all models
- Test edge cases like empty strings, null values, and boundary values

**Specific Example Tests:**

- Test that onboarding shows on first launch
- Test navigation from login to home screen after successful auth
- Test that home screen displays required buttons
- Test VS Mode handoff screen appears between players
- Test friends screen displays friend code and add button

### Property-Based Testing

The app will use the `test` package with custom property test helpers (or `dart_check` if available) for property-based testing. Each property-based test should run a minimum of 100 iterations.

**Property Test Implementation Requirements:**

- Each property-based test MUST be tagged with a comment referencing the design document property
- Tag format: `// Feature: parent-quiz-app, Property X: [property description]`
- Each correctness property MUST be implemented by a SINGLE property-based test
- Tests should generate random valid inputs to verify properties hold across all cases

**Property Test Coverage:**

- Authentication: Generate random valid user data and verify document structure (Properties 1-4)
- Question selection: Generate random question pools with various seenCounts and verify prioritization (Properties 5-7)
- XP calculation: Generate random answer patterns and verify XP awards (Properties 8-14)
- Streak logic: Generate random date sequences and verify streak updates (Properties 15-17)
- Level/mastery: Generate random XP values and question states (Properties 18-20)
- Weekly leaderboard: Generate random session dates and verify XP tracking (Properties 21-23)
- VS Mode: Generate random duel outcomes and verify stat updates (Properties 24-27)
- Friends: Generate random friend codes and verify lookup/creation (Properties 28-30)
- Data structures: Generate random data and verify all required fields (Properties 31-34)

### Integration Testing

Integration tests will verify end-to-end flows using Flutter's `integration_test` package:

- Complete registration → quiz session → result flow
- Login → category selection → quiz → leaderboard flow
- VS Mode complete flow from setup to results
- Friends addition and leaderboard viewing flow

### Test Data Setup

For testing, seed Firestore with:

- 5-10 sample categories
- 50-100 sample questions across categories
- 10-20 test users with varying XP, streaks, and stats

Use Firebase Emulator Suite for local testing to avoid affecting production data.

## Future Extensibility

### Cloud Functions Migration Path

The current client-side architecture is designed to easily migrate to Cloud Functions:

**Phase 3 Enhancements:**

1. **XP Calculation**: Move to Cloud Function triggered on session completion

   - Prevents client-side XP manipulation
   - Current: `QuizService.calculateSessionXP()` → Future: `onSessionComplete` trigger

2. **Leaderboard Updates**: Maintain materialized leaderboard collection

   - Current: Query all users on-demand → Future: Pre-computed rankings
   - Cloud Function updates rankings on XP changes

3. **Friend Requests**: Add approval workflow

   - Current: Direct acceptance → Future: Pending/accepted states
   - Cloud Function handles bidirectional friend relationship

4. **Question State Verification**: Server-side validation
   - Prevents manipulation of mastery status
   - Cloud Function verifies answer correctness before updating states

### Online VS Mode

Future online multiplayer will add:

- `duel` collection with real-time synchronization
- Matchmaking service
- Turn-based gameplay with notifications
- Duel history and replay functionality

### Premium Features

Architecture supports future premium content:

- `isPremium` flag already in Category model
- Payment integration via Firebase Extensions
- User subscription status in UserModel

### Analytics and Monitoring

Future analytics integration points:

- Session completion events
- Question difficulty analysis
- User engagement metrics
- A/B testing for XP rewards

## UI/UX Guidelines

### Screen Structure

All screens follow standard Flutter Material Design:

- `AppBar` for navigation and titles
- `Scaffold` as base structure
- `FloatingActionButton` for primary actions where appropriate
- Standard `BottomNavigationBar` for main navigation

### Common Widgets

- **Buttons**: `ElevatedButton` for primary actions, `TextButton` for secondary
- **Forms**: `TextFormField` with standard validation
- **Lists**: `ListView.builder` for dynamic content
- **Cards**: `Card` widget for category and question display
- **Progress**: `LinearProgressIndicator` for XP/level progress
- **Dialogs**: `AlertDialog` for confirmations and errors

### Navigation Pattern

Use Flutter's `Navigator` with named routes:

```dart
'/': HomeScreen
'/login': LoginScreen
'/register': RegisterScreen
'/onboarding': OnboardingScreen
'/category-selection': CategorySelectionScreen
'/quiz': QuizScreen
'/quiz-result': QuizResultScreen
'/leaderboard': LeaderboardScreen
'/friends': FriendsScreen
'/vs-mode-setup': VSModeSetupScreen
'/vs-mode-quiz': VSModeQuizScreen
'/vs-mode-result': VSModeResultScreen
'/settings': SettingsScreen
```

### State Management

Use **Riverpod** (flutter_riverpod) for state management throughout the app. Riverpod provides compile-time safety, excellent testability, and clean separation of business logic from UI.

**Provider Structure:**

```dart
// Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// User Data
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});
final userDataProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStream(userId);
});
final userServiceProvider = Provider<UserService>((ref) => UserService());

// Quiz State
final quizServiceProvider = Provider<QuizService>((ref) => QuizService());
final activeQuizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final quizService = ref.watch(quizServiceProvider);
  return QuizNotifier(quizService);
});
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final quizService = ref.watch(quizServiceProvider);
  return quizService.getCategories();
});

// Leaderboard
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) => LeaderboardService());
final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard(50);
});
final friendsLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, userId) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getFriendsLeaderboard(userId);
});

// Friends
final friendsServiceProvider = Provider<FriendsService>((ref) => FriendsService());
final friendsListProvider = StreamProvider.family<List<UserModel>, String>((ref, userId) {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriendsStream(userId);
});

// Settings
final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
```

**Key Provider Types:**

- **Provider**: Singleton instances of service classes (AuthService, QuizService, etc.)
- **StateNotifierProvider**: For complex state with multiple actions (active quiz session, VS mode)
- **StreamProvider**: For real-time Firestore data (user data, friends list, auth state)
- **FutureProvider**: For one-time async data loads (categories, leaderboard)
- **family**: For providers that need parameters (user-specific data)

**Benefits for this project:**

- No BuildContext needed for accessing state in business logic
- Easy to test providers in isolation
- Automatic disposal and caching
- Type-safe dependency injection
- Compile-time safety prevents runtime errors

### Loading States

- Show `CircularProgressIndicator` during async operations
- Disable buttons during processing to prevent double-submission
- Display error messages using `SnackBar`

### Responsive Design

- Use `MediaQuery` for screen dimensions
- Support both portrait and landscape orientations
- Ensure touch targets are minimum 48x48 logical pixels
- Test on various screen sizes (phone and tablet)
