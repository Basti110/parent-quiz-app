---
inclusion: always
---

# Flutter Architecture Guidelines

## Project Structure

This is a Flutter application following clean architecture principles:

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── models/                   # Data models (UserModel, Category, Question, etc.)
├── services/                 # Business logic layer (AuthService, QuizService, etc.)
├── providers/                # Riverpod providers for state management
└── screens/                  # UI layer organized by feature
    ├── auth/                 # Authentication screens
    ├── home/                 # Home screen
    ├── quiz/                 # Quiz-related screens
    ├── leaderboard/          # Leaderboard screen
    ├── friends/              # Friends management screens
    ├── vs_mode/              # VS Mode screens
    ├── statistics/           # Statistics screen (NEW)
    └── settings/             # Settings screen
```

## State Management

**Use Riverpod for all state management:**

- **Provider**: For singleton service instances (AuthService, QuizService, etc.)
- **StateNotifierProvider**: For complex state with multiple actions
- **StreamProvider**: For real-time Firestore data
- **FutureProvider**: For one-time async data loads
- **family**: For providers that need parameters

**Example:**

```dart
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userDataProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStream(userId);
});
```

### Real-Time Data Patterns

**Always use StreamProvider for data that changes in real-time:**

- Friend lists (to see incoming challenges)
- Duel status (to see when opponent completes)
- User stats (to see live updates)

**Example - Duel Real-Time Updates:**

```dart
// Provider
final duelStreamProvider = StreamProvider.family<Duel, String>((ref, duelId) {
  final duelService = ref.watch(duelServiceProvider);
  return duelService.getDuelStream(duelId);
});

// Service
Stream<Duel> getDuelStream(String duelId) {
  return _firestore
      .collection('duels')
      .doc(duelId)
      .snapshots()
      .map((doc) => Duel.fromMap(doc.data()!));
}

// UI - Use Consumer for automatic rebuilds
Consumer(
  builder: (context, ref, child) {
    final duelAsync = ref.watch(duelStreamProvider(duelId));
    return duelAsync.when(
      data: (duel) => _buildDuelUI(duel),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)
```

**Avoid FutureBuilder for real-time data** - it doesn't update when data changes.

## Service Layer Pattern

All business logic should be in service classes:

```dart
class ServiceName {
  final FirebaseFirestore _firestore;

  ServiceName({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Public methods for business operations
  Future<Result> doSomething() async {
    // Implementation
  }
}
```

### Duel System Architecture

**Single Source of Truth Pattern:**

The duel system uses the `openChallenge` field in friendship documents as the single source of truth for active challenges:

```dart
// Check for active challenge before creating new one
Future<bool> hasActiveDuel(String userId, String friendId) async {
  final friendDoc = await _firestore
      .collection('users')
      .doc(userId)
      .collection('friends')
      .doc(friendId)
      .get();

  final data = friendDoc.data();
  return data?['openChallenge'] != null;
}

// Create challenge - updates both friendship documents
Future<String> createDuel(String challengerId, String opponentId) async {
  // Check for existing challenge first
  if (await hasActiveDuel(challengerId, opponentId)) {
    throw Exception('Active challenge already exists');
  }

  // Create duel document
  final duelRef = _firestore.collection('duels').doc();
  
  // Update both friendship documents with openChallenge
  final batch = _firestore.batch();
  batch.set(duelRef, duelData);
  batch.update(challengerFriendDoc, {'openChallenge': challengeData});
  batch.update(opponentFriendDoc, {'openChallenge': challengeData});
  await batch.commit();
  
  return duelRef.id;
}
```

**Lifecycle Management:**

1. **Challenge Created**: Set `openChallenge` with `status: 'pending'`
2. **Challenge Accepted**: Update `status` to `'accepted'`
3. **Both Complete**: Keep `openChallenge` (for "View Results" button)
4. **Results Viewed**: Clear `openChallenge` (allow new challenges)

**Real-Time Updates:**

- Use `StreamProvider` to watch duel documents
- UI automatically updates when opponent completes
- Show different states based on completion timestamps

### Statistics System Architecture

**Dynamic Calculation Pattern:**

Statistics are calculated on-demand from the `questionStates` subcollection rather than stored as denormalized counts:

```dart
// Statistics Service
class StatisticsService {
  Future<UserStatistics> getUserStatistics(String userId) async {
    // Load all question states for the user
    final statesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('questionStates')
        .get();

    // Calculate statistics from question states
    // - Count where seenCount > 0 for answered questions
    // - Count where mastered == true for mastered questions
    // - Group by category for category-level stats
  }
}

// Statistics Providers
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final userStatisticsProvider = FutureProvider.family<UserStatistics, String>(
  (ref, userId) {
    final statisticsService = ref.watch(statisticsServiceProvider);
    return statisticsService.getUserStatistics(userId);
  },
);
```

**Key Models:**
- `UserStatistics`: Overall user progress with category breakdown
- `CategoryStatistics`: Per-category progress with percentages
- Uses `questionCounter` field from categories for performance

## UI Guidelines

- Use standard Material Design components (no custom theming in MVP)
- All screens should use `Scaffold` as base structure
- Use `AppBar` for navigation and titles
- Use `ElevatedButton` for primary actions, `TextButton` for secondary
- Show `CircularProgressIndicator` during async operations
- Display errors using `SnackBar`

## Firebase Integration

- All Firestore operations should be in service classes
- Use try-catch blocks for all Firebase operations
- Handle offline scenarios gracefully
- Never expose Firebase operations directly in UI code

## Error Handling

```dart
try {
  // Firebase operation
} on FirebaseException catch (e) {
  // Handle Firebase-specific errors
  print('Firebase error: ${e.code} - ${e.message}');
  // Show user-friendly message
} catch (e) {
  // Handle general errors
  print('Error: $e');
}
```

## Testing

- Write unit tests for all service classes
- Write property-based tests for correctness properties
- Use Firebase Emulator Suite for testing
- Mock Firestore in unit tests when needed
