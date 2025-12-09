# Design Document: Simplified Gamification System

## Overview

This design document outlines the architecture for transitioning from an XP-based gamification system to a simplified streak-based system. The new system focuses on daily goals, streak maintenance, question mastery, and asynchronous friend duels. This redesign removes complexity while maintaining user engagement through clear, achievable goals and social competition.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │ Settings │  │ Friends  │  │  Duel    │   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screens │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Provider Layer (Riverpod)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ User Provider│  │Settings Prov.│  │ Duel Provider│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │UserService   │  │SettingsServ. │  │ DuelService  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Firestore                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  users   │  │  duels   │  │questions │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Changes

1. **Remove XP System**: Eliminate totalXp, currentLevel, weeklyXpCurrent, weeklyXpWeekStart fields
2. **Add Streak Points**: New field for tracking cumulative streak achievements
3. **Add Daily Goal**: User-configurable target for questions per day
4. **Add Daily Progress**: Track questions answered today
5. **Add Duel System**: New collection for asynchronous competitive gameplay
6. **Simplify Leaderboard**: Rank by streak points instead of weekly XP

## Components and Interfaces

### Data Models

#### Updated UserModel

```dart
class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String friendCode;

  // Streak tracking
  final int streakCurrent;
  final int streakLongest;
  final int streakPoints;

  // Daily goal system
  final int dailyGoal;              // Default: 10
  final int questionsAnsweredToday;
  final DateTime lastDailyReset;

  // Question statistics
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int totalMasteredQuestions;

  // Duel statistics (simplified)
  final int duelsCompleted;
  final int duelsWon;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarPath,
    required this.createdAt,
    required this.lastActiveAt,
    required this.friendCode,
    required this.streakCurrent,
    required this.streakLongest,
    required this.streakPoints,
    required this.dailyGoal,
    required this.questionsAnsweredToday,
    required this.lastDailyReset,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.totalMasteredQuestions,
    required this.duelsCompleted,
    required this.duelsWon,
  });

  Map<String, dynamic> toMap() { /* ... */ }
  factory UserModel.fromMap(Map<String, dynamic> map, String id) { /* ... */ }
}
```

#### New DuelModel

```dart
class DuelModel {
  final String id;
  final String challengerId;
  final String opponentId;
  final DuelStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  // Questions (same 5 for both participants)
  final List<String> questionIds;

  // Challenger's data
  final Map<String, bool> challengerAnswers;  // questionId -> isCorrect
  final int challengerScore;                   // Calculated incrementally
  final DateTime? challengerCompletedAt;

  // Opponent's data
  final Map<String, bool> opponentAnswers;     // questionId -> isCorrect
  final int opponentScore;                     // Calculated incrementally
  final DateTime? opponentCompletedAt;

  DuelModel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.questionIds,
    required this.challengerAnswers,
    required this.challengerScore,
    this.challengerCompletedAt,
    required this.opponentAnswers,
    required this.opponentScore,
    this.opponentCompletedAt,
  });

  Map<String, dynamic> toMap() { /* ... */ }
  factory DuelModel.fromMap(Map<String, dynamic> map, String id) { /* ... */ }

  String? getWinnerId() {
    // Only determine winner when both have completed
    if (challengerCompletedAt == null || opponentCompletedAt == null) return null;

    if (challengerScore > opponentScore) return challengerId;
    if (opponentScore > challengerScore) return opponentId;
    return null; // Tie
  }
}

enum DuelStatus {
  pending,      // Waiting for opponent to accept
  accepted,     // Accepted, waiting for both to complete
  completed,    // Both participants finished
  declined,     // Opponent declined
  expired,      // Expired after 7 days
}
```

#### New FriendModel

```dart
class FriendModel {
  final String friendUserId;
  final String status;
  final DateTime createdAt;
  final String createdBy;

  // Head-to-head duel statistics
  final int myWins;
  final int theirWins;
  final int ties;
  final int totalDuels;

  FriendModel({
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.myWins = 0,
    this.theirWins = 0,
    this.ties = 0,
    this.totalDuels = 0,
  });

  Map<String, dynamic> toMap() { /* ... */ }
  factory FriendModel.fromMap(Map<String, dynamic> map) { /* ... */ }

  /// Returns formatted head-to-head record (e.g., "5-3-1")
  String getRecordString() {
    return '$myWins-$theirWins-$ties';
  }

  /// Returns true if user is leading in head-to-head
  bool isLeading() {
    return myWins > theirWins;
  }

  /// Returns true if tied in head-to-head
  bool isTied() {
    return myWins == theirWins;
  }
}
```

### Service Layer

#### Updated UserService

```dart
class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore});

  // Core user operations
  Future<UserModel> getUserData(String userId);
  Stream<UserModel> getUserStream(String userId);

  // Daily goal management
  Future<void> updateDailyGoal(String userId, int newGoal);
  Future<void> incrementQuestionsAnsweredToday(String userId);
  Future<void> resetDailyProgressIfNeeded(String userId);

  // Streak management
  Future<void> checkAndUpdateStreak(String userId);
  Future<int> calculateStreakPoints(int currentStreak);
  Future<void> awardStreakPoints(String userId, int points);

  // Question statistics
  Future<void> incrementTotalQuestions(String userId, bool correct);
  Future<void> updateMasteredCount(String userId);

  // Helper methods
  bool _isSameDay(DateTime date1, DateTime date2);
  bool _isYesterday(DateTime lastActive, DateTime today);
}
```

#### New DuelService

```dart
class DuelService {
  final FirebaseFirestore _firestore;

  DuelService({FirebaseFirestore? firestore});

  // Duel creation and management
  Future<String> createDuel(String challengerId, String opponentId);
  Future<void> acceptDuel(String duelId, String userId);
  Future<void> declineDuel(String duelId, String userId);

  // Duel gameplay
  Future<void> submitAnswer({
    required String duelId,
    required String userId,
    required int questionIndex,
    required String questionId,
    required bool isCorrect,
  });
  Future<void> completeDuel(String duelId, String userId);

  // Duel queries
  Stream<List<DuelModel>> getPendingDuels(String userId);
  Stream<List<DuelModel>> getActiveDuels(String userId);
  Stream<List<DuelModel>> getCompletedDuels(String userId);
  Future<DuelModel> getDuel(String duelId);

  // Helper methods
  Future<List<String>> _generateDuelQuestions();
  Future<void> _updateDuelStatistics(String winnerId, String loserId, bool isTie);
  Future<void> _updateHeadToHeadStats(String userId, String friendId, bool userWon, bool isTie);
}
```

#### Updated SettingsService

```dart
class SettingsService {
  final FirebaseFirestore _firestore;

  SettingsService({FirebaseFirestore? firestore});

  // Daily goal settings (updates user document)
  Future<void> updateDailyGoal(String userId, int goal);
  Future<int> getDailyGoal(String userId);
  bool validateDailyGoal(int goal); // Must be 1-50

  // Other settings (updates user document)
  Future<void> updateAvatarPath(String userId, String avatarPath);

  // Note: All settings are stored in the user document at users/{userId}
  // There is no separate settings collection
}
```

## Data Models

### Firebase Collections

#### users/{userId}

```dart
{
  'displayName': String,
  'email': String,
  'avatarPath': String?,
  'createdAt': Timestamp,
  'lastActiveAt': Timestamp,
  'friendCode': String,

  // Streak system
  'streakCurrent': int,
  'streakLongest': int,
  'streakPoints': int,

  // Daily goal system
  'dailyGoal': int,                    // Default: 10
  'questionsAnsweredToday': int,
  'lastDailyReset': Timestamp,

  // Question statistics
  'totalQuestionsAnswered': int,
  'totalCorrectAnswers': int,
  'totalMasteredQuestions': int,

  // Duel statistics
  'duelsCompleted': int,
  'duelsWon': int,
}
```

#### duels/{duelId}

```dart
{
  'challengerId': String,
  'opponentId': String,
  'status': String,                    // 'pending', 'accepted', 'completed', 'declined', 'expired'
  'createdAt': Timestamp,
  'acceptedAt': Timestamp?,
  'completedAt': Timestamp?,

  // Questions (same for both)
  'questionIds': List<String>,         // 5 question IDs

  // Challenger data
  'challengerAnswers': Map<String, bool>,  // questionId -> isCorrect (calculated after each answer)
  'challengerScore': int,                  // Incremented after each correct answer
  'challengerCompletedAt': Timestamp?,

  // Opponent data
  'opponentAnswers': Map<String, bool>,    // questionId -> isCorrect (calculated after each answer)
  'opponentScore': int,                    // Incremented after each correct answer
  'opponentCompletedAt': Timestamp?,
}
```

#### users/{userId}/friends/{friendUserId}

```dart
{
  'friendUserId': String,
  'status': String,                    // 'accepted' for MVP
  'createdAt': Timestamp,
  'createdBy': String,                 // userId who initiated

  // Head-to-head duel statistics
  'myWins': int,                       // How many times I beat this friend
  'theirWins': int,                    // How many times they beat me
  'ties': int,                         // How many ties between us
  'totalDuels': int,                   // Total duels completed between us
}
```

### Firestore Indexes

Required indexes for optimal performance:

1. **users collection**:

   - `streakPoints` DESC (for leaderboard)
   - `friendCode` (for friend lookup)

2. **duels collection**:
   - `challengerId`, `status` (for user's challenges)
   - `opponentId`, `status` (for user's received duels)
   - `status`, `createdAt` (for cleanup of expired duels)

### Future Cloud Functions Migration

The duel system is designed to support future migration to Cloud Functions with minimal refactoring:

#### Current MVP (Client-Side)

```dart
// Client submits answer with correctness already determined
await duelService.submitAnswer(
  duelId: duelId,
  userId: userId,
  questionIndex: index,
  questionId: questionId,
  isCorrect: isCorrect,  // Client determines correctness
);

// Client updates Firestore directly
await _firestore.collection('duels').doc(duelId).update({
  'challengerAnswers.$questionId': isCorrect,
  'challengerScore': FieldValue.increment(isCorrect ? 1 : 0),
});
```

#### Future (Cloud Function)

```dart
// Client submits only the selected answer
await duelService.submitAnswer(
  duelId: duelId,
  userId: userId,
  questionIndex: index,
  questionId: questionId,
  selectedAnswerIndices: [0, 2],  // Just the selection
);

// Cloud Function handles everything
// functions/src/index.ts
export const submitDuelAnswer = functions.https.onCall(async (data, context) => {
  const { duelId, userId, questionId, selectedAnswerIndices } = data;

  // Load question to check correctness
  const question = await admin.firestore()
    .collection('questions')
    .doc(questionId)
    .get();

  // Determine correctness server-side
  const isCorrect = checkAnswer(question.data(), selectedAnswerIndices);

  // Update duel with validated data
  const isChallenger = /* determine from duel data */;
  const field = isChallenger ? 'challengerAnswers' : 'opponentAnswers';
  const scoreField = isChallenger ? 'challengerScore' : 'opponentScore';

  await admin.firestore().collection('duels').doc(duelId).update({
    [`${field}.${questionId}`]: isCorrect,
    [scoreField]: admin.firestore.FieldValue.increment(isCorrect ? 1 : 0),
  });

  return { success: true, isCorrect };
});
```

#### Migration Benefits

1. **Security**: Server validates correctness, preventing cheating
2. **Consistency**: Single source of truth for answer validation
3. **Auditability**: Server logs all answer submissions
4. **Extensibility**: Easy to add features like time limits, hints, etc.

#### Data Model Compatibility

The current data model supports both approaches:

```dart
// Works for both client-side and Cloud Function
{
  'challengerAnswers': {
    'question_id_1': true,   // Can be written by client OR Cloud Function
    'question_id_2': false,
  },
  'challengerScore': 1,      // Can be incremented by client OR Cloud Function
}
```

#### Firestore Security Rules

**MVP (Client-Side)**:

```javascript
// Allow users to write their own answers
match /duels/{duelId} {
  allow read: if request.auth != null &&
    (resource.data.challengerId == request.auth.uid ||
     resource.data.opponentId == request.auth.uid);

  allow update: if request.auth != null &&
    (resource.data.challengerId == request.auth.uid ||
     resource.data.opponentId == request.auth.uid);
}
```

**Future (Cloud Function)**:

```javascript
// Only Cloud Functions can write answers
match /duels/{duelId} {
  allow read: if request.auth != null &&
    (resource.data.challengerId == request.auth.uid ||
     resource.data.opponentId == request.auth.uid);

  // No direct write access - must go through Cloud Function
  allow write: if false;
}
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Daily Goal Properties

**Property 1: Daily goal bounds**
_For any_ daily goal value, when a user attempts to set it, the system should only accept values between 1 and 50 (inclusive)
**Validates: Requirements 1.3**

**Property 2: Daily goal persistence**
_For any_ user and valid daily goal value, when the goal is updated, retrieving the user's profile should return the new goal value
**Validates: Requirements 1.4**

**Property 3: Daily progress tracking**
_For any_ user, when they answer N questions in a single day, the questionsAnsweredToday field should equal N
**Validates: Requirements 1.5**

### Streak Properties

**Property 4: Streak initialization**
_For any_ user meeting their daily goal for the first time, the current streak should be set to 1
**Validates: Requirements 2.1**

**Property 5: Streak continuation**
_For any_ user who met their daily goal yesterday and meets it again today, the current streak should increment by 1
**Validates: Requirements 2.2**

**Property 6: Streak reset**
_For any_ user who fails to meet their daily goal for a calendar day, the current streak should reset to 0
**Validates: Requirements 2.3**

**Property 7: Longest streak tracking**
_For any_ user, the longest streak value should always be greater than or equal to the current streak value
**Validates: Requirements 2.4**

### Streak Points Properties

**Property 8: No points for days 1-2**
_For any_ user with a current streak of 1 or 2, no streak points should be awarded
**Validates: Requirements 3.3**

**Property 9: Three points at day 3**
_For any_ user reaching exactly 3 consecutive days, exactly 3 streak points should be awarded
**Validates: Requirements 3.1**

**Property 10: Three points per additional day**
_For any_ user with a streak greater than 3, each additional consecutive day should award exactly 3 streak points
**Validates: Requirements 3.2**

**Property 11: Streak points accumulation**
_For any_ user, total streak points should only increase, never decrease
**Validates: Requirements 3.5**

### Question Statistics Properties

**Property 12: Correct answer counting**
_For any_ user answering a question correctly, the totalCorrectAnswers count should increment by 1
**Validates: Requirements 4.1**

**Property 13: Total questions counting**
_For any_ user answering any question (correct or incorrect), the totalQuestionsAnswered count should increment by 1
**Validates: Requirements 4.3**

**Property 14: Mastery threshold**
_For any_ question, when a user answers it correctly 3 times, the question should be marked as mastered
**Validates: Requirements 4.4**

**Property 15: Mastered count accuracy**
_For any_ user, the totalMasteredQuestions count should equal the number of questions in their questionStates subcollection where mastered is true
**Validates: Requirements 4.5**

### Daily Progress Properties

**Property 16: Daily reset timing**
_For any_ user, when a new calendar day begins, questionsAnsweredToday should reset to 0
**Validates: Requirements 5.5**

**Property 17: Progress completion indicator**
_For any_ user, when questionsAnsweredToday equals or exceeds dailyGoal, the daily goal should be marked as complete
**Validates: Requirements 5.4**

### Duel Properties

**Property 18: Duel question consistency**
_For any_ duel, both the challenger and opponent should receive the exact same 5 questions in the same order
**Validates: Requirements 11.5**

**Property 19: Duel score calculation**
_For any_ duel, each participant's score should be incremented by 1 when they answer a question correctly, and the final score should equal the number of correct answers
**Validates: Requirements 13.2**

**Property 20: Duel winner determination**
_For any_ completed duel, the participant with the higher score should be identified as the winner, or if scores are equal, it should be marked as a tie
**Validates: Requirements 13.4**

**Property 21: Duel state transitions**
_For any_ duel, the status should only transition in this order: pending → accepted → completed (or pending → declined)
**Validates: Requirements 15.2**

**Property 22: Duel answer immutability**
_For any_ duel question, once a participant submits an answer, that answer should not be changeable
**Validates: Requirements 12.5**

### Leaderboard Properties

**Property 23: Leaderboard ordering**
_For any_ set of users, the leaderboard should rank them in descending order by streakPoints
**Validates: Requirements 7.1**

**Property 24: Zero points display**
_For any_ user with 0 streak points, they should still appear on the leaderboard with a rank
**Validates: Requirements 7.5**

### Head-to-Head Statistics Properties

**Property 25: Head-to-head record accuracy**
_For any_ two friends who have completed N duels together, the sum of myWins + theirWins + ties should equal N (totalDuels)
**Validates: Requirements 15a.2**

**Property 26: Head-to-head symmetry**
_For any_ two friends A and B, friend A's myWins should equal friend B's theirWins, and vice versa
**Validates: Requirements 15a.2**

**Property 27: Head-to-head initialization**
_For any_ newly created friendship, all head-to-head statistics (myWins, theirWins, ties, totalDuels) should be initialized to 0
**Validates: Requirements 15a.5**

## Error Handling

### User Service Errors

1. **Invalid Daily Goal**: When goal < 1 or goal > 50

   - Throw `ArgumentError` with message "Daily goal must be between 1 and 50"
   - Display user-friendly error in UI

2. **Streak Calculation Failure**: When unable to determine streak status

   - Log error details
   - Maintain current streak value (don't reset)
   - Show generic error to user

3. **Firebase Connection Issues**: When Firestore operations fail
   - Catch `FirebaseException`
   - Retry once after 2-second delay
   - Show "Connection error. Please try again." message

### Duel Service Errors

1. **Invalid Duel Challenge**: When challenging non-friend or self

   - Throw `ArgumentError` with descriptive message
   - Prevent UI action before service call

2. **Duel Not Found**: When accessing non-existent duel

   - Throw `StateError` with "Duel not found"
   - Navigate user back to friends screen

3. **Invalid Duel State**: When action doesn't match current status

   - Throw `StateError` with "Invalid duel state for this action"
   - Refresh duel data and show current state

4. **Question Generation Failure**: When unable to fetch 5 questions
   - Log error
   - Retry once
   - If still fails, show "Unable to create duel. Please try again later."

### Settings Service Errors

1. **Validation Errors**: When settings values are invalid

   - Return validation result with specific error message
   - Display inline error in settings form

2. **Save Failures**: When unable to persist settings
   - Show "Failed to save settings. Please try again."
   - Keep form in edit mode with current values

## Testing Strategy

### Unit Testing

Unit tests will verify specific examples and edge cases:

1. **Daily Goal Validation**

   - Test boundary values: 0, 1, 50, 51
   - Test negative values
   - Test non-integer values

2. **Streak Calculation**

   - Test same-day activity (no change)
   - Test consecutive days (increment)
   - Test gap of 2+ days (reset)
   - Test timezone edge cases

3. **Streak Points Calculation**

   - Test days 1-2 (0 points)
   - Test day 3 (3 points)
   - Test days 4-10 (3 points each)

4. **Duel State Transitions**

   - Test valid transitions
   - Test invalid transitions
   - Test concurrent completion

5. **Score Calculation**
   - Test all correct (5/5)
   - Test all incorrect (0/5)
   - Test mixed results

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using the `test` package with custom generators:

**Testing Framework**: Dart's built-in `test` package with custom property-based testing utilities

**Configuration**: Each property test should run a minimum of 100 iterations

**Test Tagging**: Each property-based test must include a comment with this format:

```dart
// **Feature: simplified-gamification, Property N: [property text]**
```

**Property Test Implementation**:

1. **Property 1: Daily goal bounds** (Requirements 1.3)

   - Generate random integers (including negative, zero, positive, very large)
   - Verify only values 1-50 are accepted

2. **Property 2: Daily goal persistence** (Requirements 1.4)

   - Generate random valid daily goals
   - Set goal, retrieve user data
   - Verify retrieved goal matches set goal

3. **Property 5: Streak continuation** (Requirements 2.2)

   - Generate random user with random current streak
   - Simulate meeting daily goal on consecutive days
   - Verify streak increments correctly

4. **Property 6: Streak reset** (Requirements 2.3)

   - Generate random user with random current streak
   - Simulate missing a day
   - Verify streak resets to 0

5. **Property 10: Three points per additional day** (Requirements 3.2)

   - Generate random streak values > 3
   - Calculate expected points
   - Verify actual points match expected

6. **Property 15: Mastered count accuracy** (Requirements 4.5)

   - Generate random set of question states
   - Count mastered questions manually
   - Verify system count matches manual count

7. **Property 18: Duel question consistency** (Requirements 11.5)

   - Generate random duel
   - Verify both participants have identical question lists

8. **Property 19: Duel score calculation** (Requirements 13.2)

   - Generate random sequence of correct/incorrect answers
   - Simulate incremental score updates after each answer
   - Verify final score equals count of correct answers

9. **Property 23: Leaderboard ordering** (Requirements 7.1)
   - Generate random list of users with random streak points
   - Sort manually by streak points descending
   - Verify system ordering matches manual sort

### Integration Testing

Integration tests will verify end-to-end workflows:

1. **Complete Daily Goal Flow**

   - User answers questions throughout the day
   - Verify progress updates
   - Verify streak updates when goal met
   - Verify streak points awarded correctly

2. **Duel Complete Flow**

   - User A challenges User B
   - User B accepts
   - Both complete questions
   - Verify results screen shows correct data

3. **Settings Update Flow**
   - User changes daily goal
   - Verify persistence
   - Verify new goal affects progress tracking

### Migration Testing

1. **Data Migration Validation**

   - Create test users with old schema
   - Run migration
   - Verify all required fields present
   - Verify XP fields removed
   - Verify streak data preserved

2. **Backward Compatibility**
   - Verify app handles users mid-migration
   - Verify no data loss during migration

## Migration Strategy

### Phase 1: Schema Update

1. Add new fields to UserModel with default values
2. Deploy code that can read both old and new schemas
3. Run migration script to update all user documents

### Phase 2: Data Migration Script

```dart
Future<void> migrateUsers() async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();

  for (final doc in usersSnapshot.docs) {
    final data = doc.data();

    // Preserve existing data
    final updates = {
      'streakCurrent': data['streakCurrent'] ?? 0,
      'streakLongest': data['streakLongest'] ?? 0,
      'streakPoints': 0, // Initialize to 0
      'dailyGoal': 10, // Default
      'questionsAnsweredToday': 0,
      'lastDailyReset': Timestamp.now(),
      'totalQuestionsAnswered': 0,
      'totalCorrectAnswers': 0,
      'totalMasteredQuestions': 0,
      'duelsCompleted': data['duelsPlayed'] ?? 0,
      'duelsWon': data['duelsWon'] ?? 0,
    };

    // Remove old fields
    await doc.reference.update(updates);
    await doc.reference.update({
      'totalXp': FieldValue.delete(),
      'currentLevel': FieldValue.delete(),
      'weeklyXpCurrent': FieldValue.delete(),
      'weeklyXpWeekStart': FieldValue.delete(),
      'duelPoints': FieldValue.delete(),
      'duelsPlayed': FieldValue.delete(),
      'duelsLost': FieldValue.delete(),
    });
  }
}
```

### Phase 3: UI Updates

1. Update home screen to show daily progress instead of XP
2. Update leaderboard to rank by streak points
3. Update settings to include daily goal adjustment
4. Update friends screen to show avatars and enable duel challenges

### Phase 4: Cleanup

1. Remove XP-related code
2. Remove weekly history collection (no longer needed)
3. Update Firebase indexes
4. Update documentation

## UI/UX Considerations

### Home Screen Changes

**Before**: Shows XP, level, weekly XP
**After**: Shows daily progress (7/10 questions), current streak (5 days), streak points (12)

### Leaderboard Changes

**Before**: Ranks by weekly XP, resets Monday
**After**: Ranks by total streak points, shows current streak

### Settings Screen Changes

**Add**: Daily goal slider (1-50 questions)
**Remove**: No XP-related settings needed

### Friends Screen Changes

**Add**: Friend avatars displayed prominently
**Add**: Tap avatar to challenge to duel
**Add**: Pending duel indicators
**Add**: Active duel status

### New Duel Screens

1. **Duel Challenge Screen**: Confirm challenge to friend
2. **Duel Question Screen**: Answer 5 questions (similar to quiz screen)
3. **Duel Results Screen**: Side-by-side comparison with question breakdown

## VS Mode Improvements

### Overview

The VS Mode (pass-and-play) feature will be enhanced with two key improvements:

1. **Explanation Screen Integration**: After each question, players will see an explanation screen (matching solo mode) that shows the correct answer, educational explanation, and optional source links.

2. **Time-Based Tiebreaker**: Each player's completion time will be tracked from their first question to their last question. When both players have equal scores, the player with the faster completion time wins.

### VS Mode Architecture

#### Current Flow

```
Setup Screen → Quiz Screen (Player A) → Handoff Screen → Quiz Screen (Player B) → Results Screen
```

#### Enhanced Flow

```
Setup Screen →
  Quiz Screen (Player A) → [Question → Answer → Explanation] × N → Handoff Screen →
  Quiz Screen (Player B) → [Question → Answer → Explanation] × N → Results Screen
```

### VS Mode Data Models

#### Updated VSModeSession

```dart
class VSModeSession {
  final String categoryId;
  final int questionsPerPlayer;
  final String playerAName;
  final String playerBName;
  final List<String> playerAQuestionIds;
  final List<String> playerBQuestionIds;
  final Map<String, bool> playerAAnswers;
  final Map<String, bool> playerBAnswers;

  // New fields for timing (only counts question time, not explanation time)
  final int playerAElapsedSeconds;  // Accumulated time spent on questions only
  final int playerBElapsedSeconds;  // Accumulated time spent on questions only

  // New fields for explanation tracking
  final Map<String, bool> playerAExplanationsViewed;
  final Map<String, bool> playerBExplanationsViewed;

  // Computed properties
  int? get playerATimeSeconds => playerAElapsedSeconds;
  int? get playerBTimeSeconds => playerBElapsedSeconds;
}
```

#### Updated VSModeResult

```dart
class VSModeResult {
  final String playerAName;
  final String playerBName;
  final int playerAScore;
  final int playerBScore;
  final int? playerATimeSeconds;
  final int? playerBTimeSeconds;
  final VSModeOutcome outcome;
  final bool wonByTime;

  String formatTime(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

### VS Mode Service Updates

#### New Methods

```dart
/// Record when a player starts viewing a question (timer starts/resumes)
VSModeSession recordQuestionStart({
  required VSModeSession session,
  required String playerId,
  required DateTime startTime,
});

/// Record when a player submits an answer (timer pauses)
VSModeSession recordQuestionEnd({
  required VSModeSession session,
  required String playerId,
  required DateTime endTime,
});

/// Record that a player viewed an explanation
VSModeSession recordExplanationViewed({
  required VSModeSession session,
  required String playerId,
  required String questionId,
});

/// Calculate XP for a player based on their answers and explanation views
int calculatePlayerXP({
  required Map<String, bool> answers,
  required Map<String, bool> explanationsViewed,
  required int questionsPerPlayer,
});
```

#### Updated calculateResult Method

```dart
VSModeResult calculateResult(VSModeSession session) {
  final playerAScore = session.playerAScore;
  final playerBScore = session.playerBScore;

  VSModeOutcome outcome;
  bool wonByTime = false;

  if (playerAScore > playerBScore) {
    outcome = VSModeOutcome.playerAWins;
  } else if (playerBScore > playerAScore) {
    outcome = VSModeOutcome.playerBWins;
  } else {
    // Scores are equal - check completion times
    final playerATime = session.playerATimeSeconds;
    final playerBTime = session.playerBTimeSeconds;

    if (playerATime != null && playerBTime != null) {
      if (playerATime < playerBTime) {
        outcome = VSModeOutcome.playerAWins;
        wonByTime = true;
      } else if (playerBTime < playerATime) {
        outcome = VSModeOutcome.playerBWins;
        wonByTime = true;
      } else {
        outcome = VSModeOutcome.tie;
      }
    } else {
      // Missing time data (backward compatibility)
      outcome = VSModeOutcome.tie;
    }
  }

  return VSModeResult(
    playerAName: session.playerAName,
    playerBName: session.playerBName,
    playerAScore: playerAScore,
    playerBScore: playerBScore,
    playerATimeSeconds: session.playerATimeSeconds,
    playerBTimeSeconds: session.playerBTimeSeconds,
    outcome: outcome,
    wonByTime: wonByTime,
  );
}
```

### VS Mode Screen Updates

#### VSModeQuizScreen Changes

**State Changes**:

- Remove `_showExplanation` flag (explanation will be separate screen)
- Add `_questionStartTime: DateTime?` field (tracks current question start time)
- Add `_explanationsViewed: Set<String>` field

**Flow Changes**:

```dart
@override
void initState() {
  super.initState();
  // Start timer when first question is displayed
  _questionStartTime = DateTime.now();
  _session = vsModeService.recordQuestionStart(
    session: _session!,
    playerId: _currentPlayer,
    startTime: _questionStartTime!,
  );
}

void _submitAnswer() {
  // Stop timer when answer is submitted
  final questionEndTime = DateTime.now();
  _session = vsModeService.recordQuestionEnd(
    session: _session!,
    playerId: _currentPlayer,
    endTime: questionEndTime,
  );

  // Validate and record answer
  final isCorrect = question.isCorrectAnswer(_selectedIndices.toList());
  _session = vsModeService.submitPlayerAnswer(
    session: _session!,
    playerId: _currentPlayer,
    questionId: questionId,
    isCorrect: isCorrect,
  );

  // Navigate to explanation screen (timer is paused)
  Navigator.pushNamed(
    context,
    '/quiz-explanation',
    arguments: {
      'question': question,
      'isCorrect': isCorrect,
      'isLastQuestion': _currentQuestionIndex >= _currentPlayerQuestionIds.length - 1,
      'selectedIndices': _selectedIndices.toList(),
      'isVSMode': true,
    },
  ).then((_) {
    // Mark explanation as viewed
    _explanationsViewed.add(questionId);
    _session = vsModeService.recordExplanationViewed(
      session: _session!,
      playerId: _currentPlayer,
      questionId: questionId,
    );

    // Move to next question or finish
    if (_currentQuestionIndex >= _currentPlayerQuestionIds.length - 1) {
      _finishPlayerTurn();
    } else {
      _nextQuestion();
    }
  });
}

void _nextQuestion() {
  setState(() {
    _currentQuestionIndex++;
    _selectedIndices.clear();
    // Restart timer for next question
    _questionStartTime = DateTime.now();
    _session = vsModeService.recordQuestionStart(
      session: _session!,
      playerId: _currentPlayer,
      startTime: _questionStartTime!,
    );
  });
}

void _finishPlayerTurn() {
  // Timer already stopped when last answer was submitted
  // Navigate to handoff or results
  if (_currentPlayer == 'playerA') {
    Navigator.pushReplacementNamed(
      context,
      '/vs-mode-handoff',
      arguments: {'session': _session!, 'questionsMap': _questionsMap!},
    );
  } else {
    Navigator.pushReplacementNamed(
      context,
      '/vs-mode-result',
      arguments: {'session': _session!},
    );
  }
}
```

#### QuizExplanationScreen Changes

```dart
// Add support for VS Mode flag
final isVSMode = args['isVSMode'] as bool? ?? false;

// Skip user stat updates when in VS Mode (handled by VS Mode service)
if (!isVSMode) {
  await userService.updateQuestionState(userId, question.id, isCorrect);
}

// Adjust button text based on mode
final buttonText = isVSMode
  ? (isLastQuestion ? 'Continue' : 'Next Question')
  : (isLastQuestion ? 'Finish' : 'Next Question');
```

#### VSModeResultScreen Changes

**UI Layout**:

```
┌─────────────────────────────────┐
│         VS Mode Results         │
├─────────────────────────────────┤
│  Player A          Player B     │
│  [Avatar]          [Avatar]     │
│  Score: 4/5        Score: 4/5   │
│  Time: 2:34 ⚡     Time: 3:12   │
│                                 │
│  Player A Wins! (Won by speed!) │
│                                 │
│  [Question Breakdown]           │
│  Q1: ✓ vs ✓                    │
│  Q2: ✓ vs ✗                    │
│  ...                            │
└─────────────────────────────────┘
```

**Display Logic**:

- Show completion times formatted as "MM:SS"
- Highlight faster time with ⚡ icon
- Show "Won by speed!" when `wonByTime` is true
- Show "Perfect Tie!" when scores and times are identical

### VS Mode Correctness Properties

**Property 29: VS Mode Explanation Display**
_For any_ question answered in VS Mode, the explanation screen should be displayed with the question text, correct answer, and explanation text.
**Validates: Requirements 16.1, 16.2**

**Property 30: VS Mode Source Links Display**
_For any_ question with source links or tips, those elements should appear on the explanation screen when displayed in VS Mode.
**Validates: Requirements 16.3**

**Property 31: VS Mode Navigation After Explanation**
_For any_ question in VS Mode, tapping the continue button on the explanation screen should advance to either the next question (if more remain) or the handoff/results screen (if it was the last question).
**Validates: Requirements 16.5, 26.3**

**Property 32: VS Mode Explanation Tracking**
_For any_ explanation viewed in VS Mode, the system should record that the explanation was viewed for that specific question and player.
**Validates: Requirements 17.4**

**Property 33: VS Mode Start Time Recording**
_For any_ player beginning their question sequence in VS Mode, the system should record a start timestamp when they answer their first question.
**Validates: Requirements 18.1**

**Property 34: VS Mode End Time Recording**
_For any_ player completing their question sequence in VS Mode, the system should record an end timestamp when they finish their last question.
**Validates: Requirements 18.2**

**Property 35: VS Mode Completion Time Calculation**
_For any_ player with both start and end timestamps in VS Mode, the completion time in seconds should equal the difference between end and start times.
**Validates: Requirements 18.3**

**Property 36: VS Mode Time Persistence**
_For any_ completed VS Mode session, both players' completion times should be stored and retrievable.
**Validates: Requirements 18.4, 21.4**

**Property 37: VS Mode Question-Only Timing**
_For any_ player's question sequence in VS Mode, the elapsed time should only include time spent viewing and answering questions, excluding time spent on explanation screens.
**Validates: Requirements 18.5**

**Property 38: VS Mode Score-First Winner Determination**
_For any_ VS Mode session where one player has a higher score than the other, that player should be declared the winner regardless of completion times.
**Validates: Requirements 19.4**

**Property 39: VS Mode Time-Based Tiebreaker**
_For any_ VS Mode session where both players have equal scores but different completion times, the player with the shorter completion time should be declared the winner.
**Validates: Requirements 19.1, 19.2**

**Property 40: VS Mode Winner Indication Flag**
_For any_ VS Mode result where the winner was determined by completion time (not score), the wonByTime flag should be set to true.
**Validates: Requirements 19.5**

**Property 41: VS Mode Results Display Completeness**
_For any_ completed VS Mode session, the results screen should display both players' scores and completion times.
**Validates: Requirements 20.1**

**Property 42: VS Mode Time Formatting**
_For any_ completion time in seconds in VS Mode, it should be formatted as "MM:SS" where MM is zero-padded minutes and SS is zero-padded seconds.
**Validates: Requirements 20.2**

**Property 43: VS Mode Tiebreaker Message Display**
_For any_ VS Mode result where wonByTime is true, the results screen should display a message indicating the winner was faster.
**Validates: Requirements 20.3**

**Property 44: VS Mode Non-Negative Time Values**
_For any_ stored completion time in VS Mode, the value should be a non-negative integer (>= 0).
**Validates: Requirements 21.3**

**Property 45: VS Mode Incomplete Session Time Handling**
_For any_ VS Mode session where a player has not completed their questions, their completion time should be null or 0.
**Validates: Requirements 21.5**

**Property 46: VS Mode Time Rounding**
_For any_ completion time calculation in VS Mode, fractional seconds should be rounded to the nearest whole second for display and comparison.
**Validates: Requirements 22.2**

**Property 47: VS Mode Timing Pause During Explanations**
_For any_ player viewing an explanation screen in VS Mode, the elapsed time should not increase while the explanation is displayed.
**Validates: Requirements 22.3**

**Property 48: VS Mode Elapsed Time Accumulation**
_For any_ player answering N questions in VS Mode, the total elapsed time should equal the sum of time spent on each individual question screen.
**Validates: Requirements 22.5, 22.2**

**Property 48b: VS Mode Explanation Time Exclusion**
_For any_ player who spends T seconds total on explanation screens in VS Mode, the completion time should not include any of those T seconds.
**Validates: Requirements 18.5, 22.3**

**Property 49: VS Mode Backward Compatibility**
_For any_ old VS Mode session without time data, the system should handle it gracefully without errors and display results using score-only comparison.
**Validates: Requirements 24.1, 24.2, 24.3**

**Property 50: VS Mode New Session Initialization**
_For any_ newly created VS Mode session, the session data should include time tracking fields (even if initially null).
**Validates: Requirements 24.5**

**Property 51: VS Mode Correct Answer XP**
_For any_ correct answer in VS Mode, the player should earn 10 XP.
**Validates: Requirements 25.1**

**Property 52: VS Mode Incorrect Answer with Explanation XP**
_For any_ incorrect answer where the explanation is viewed in VS Mode, the player should earn 5 XP.
**Validates: Requirements 25.2**

**Property 53: VS Mode Incorrect Answer without Explanation XP**
_For any_ incorrect answer where the explanation is not viewed in VS Mode, the player should earn 2 XP.
**Validates: Requirements 25.3**

**Property 54: VS Mode Session Bonus XP**
_For any_ completed VS Mode session, the same XP bonuses as solo mode should apply (session completion bonus and perfect score bonus).
**Validates: Requirements 25.4**

**Property 55: VS Mode Selective Stat Updates**
_For any_ completed VS Mode session, only the logged-in user's XP and stats should be updated (the guest player's stats should not change).
**Validates: Requirements 25.5**

**Property 56: VS Mode Final Results Display**
_For any_ VS Mode session where both players have completed their questions, the results screen should display with all scores and times.
**Validates: Requirements 26.5**

### VS Mode Error Handling

#### Timing Errors

**Scenario**: Negative elapsed time calculated for a question (clock skew)
**Handling**:

- Validate that question end time is after start time
- If invalid, log error and skip that question's duration (don't add to total)
- Continue with remaining questions

**Scenario**: Missing elapsed time for completed session
**Handling**:

- Check for null or zero elapsed time before comparison
- Display "--:--" for missing times in UI
- Use score-only comparison for winner determination

#### Explanation Screen Errors

**Scenario**: Navigation fails when returning from explanation screen
**Handling**:

- Wrap navigation in try-catch
- Show error message to user
- Provide "Continue" button to retry navigation

**Scenario**: Question data missing when displaying explanation
**Handling**:

- Validate question data before navigation
- Show generic error message if data is missing
- Allow user to skip to next question

### VS Mode Testing

#### Unit Tests

1. **Time Calculation Tests**

   - Test elapsed time accumulation across multiple questions
   - Test time formatting for edge cases (0 seconds, 59 seconds, 60 seconds, etc.)
   - Test that explanation viewing time is not included in elapsed time

2. **Winner Determination Tests**

   - Test score-based winner (no tie)
   - Test time-based tiebreaker (equal scores, different times)
   - Test perfect tie (equal scores and times)
   - Test backward compatibility (missing time data)

3. **XP Calculation Tests**
   - Test XP for correct answers
   - Test XP for incorrect answers with/without explanation viewing
   - Test session bonuses
   - Test that only logged-in user's stats are updated

#### Property-Based Tests

1. **Property 35: VS Mode Completion Time Calculation**

   - Generate random question durations for N questions
   - Verify total elapsed time equals sum of individual question durations

2. **Property 38: VS Mode Score-First Winner Determination**

   - Generate random sessions with different scores
   - Verify higher score always wins regardless of time

3. **Property 39: VS Mode Time-Based Tiebreaker**

   - Generate random sessions with equal scores, different times
   - Verify faster time wins

4. **Property 42: VS Mode Time Formatting**

   - Generate random time values (0-3600 seconds)
   - Verify all format as valid "MM:SS" strings

5. **Property 44: VS Mode Non-Negative Time Values**

   - Generate random session data
   - Verify all stored times are >= 0

6. **Property 48: VS Mode Elapsed Time Accumulation**

   - Generate random question durations
   - Verify total equals sum of parts

7. **Property 48b: VS Mode Explanation Time Exclusion**

   - Generate random question and explanation durations
   - Verify elapsed time only includes question durations

8. **Property 49: VS Mode Backward Compatibility**

   - Generate sessions with and without time data
   - Verify all handle gracefully without errors

9. **Property 51-53: VS Mode XP Calculation**
   - Generate random answer patterns
   - Verify XP matches expected values for each scenario

### VS Mode Implementation Notes

#### Reusing QuizExplanationScreen

The existing `QuizExplanationScreen` will be modified to support VS Mode with an `isVSMode` flag that:

- Skips user stat updates (handled by VS Mode service)
- Adjusts button text appropriately
- Maintains the same visual appearance

#### Time Tracking Implementation

```dart
// In VSModeQuizScreen state
DateTime? _questionStartTime;

// When question screen is displayed (initState or after returning from explanation)
@override
void initState() {
  super.initState();
  _questionStartTime = DateTime.now();
  _session = vsModeService.recordQuestionStart(
    session: _session!,
    playerId: _currentPlayer,
    startTime: _questionStartTime!,
  );
}

// When answer is submitted (before navigating to explanation)
void _submitAnswer() {
  final questionEndTime = DateTime.now();
  _session = vsModeService.recordQuestionEnd(
    session: _session!,
    playerId: _currentPlayer,
    endTime: questionEndTime,
  );
  
  // Timer is now paused during explanation screen
  // ... navigate to explanation ...
}

// When moving to next question (after explanation)
void _nextQuestion() {
  setState(() {
    _currentQuestionIndex++;
    // Restart timer for next question
    _questionStartTime = DateTime.now();
    _session = vsModeService.recordQuestionStart(
      session: _session!,
      playerId: _currentPlayer,
      startTime: _questionStartTime!,
    );
  });
}
```

#### Winner Determination Logic Isolation

The winner determination logic is isolated in `VSModeService.calculateResult()` to facilitate future migration to Cloud Functions. This method is self-contained with no dependencies on Flutter or client-side state.

### VS Mode Performance Considerations

1. **Timestamp Precision**: Using `DateTime.now()` provides millisecond precision, sufficient for this use case
2. **Explanation Screen Reuse**: Avoids code duplication and ensures consistency
3. **State Management**: All timing state is managed in local state, avoiding unnecessary provider updates
4. **Data Model Efficiency**: Using computed properties for time calculations ensures data consistency
