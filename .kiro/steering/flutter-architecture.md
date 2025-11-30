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
