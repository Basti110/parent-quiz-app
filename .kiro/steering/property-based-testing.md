---
inclusion: manual
---

# Property-Based Testing Guidelines

## Overview

Property-based testing verifies that correctness properties hold across all valid inputs, not just specific examples. Each correctness property in the design document should have a corresponding property-based test.

## Test Requirements

### Tagging Convention

Every property-based test MUST include a comment tag:

```dart
// Feature: parent-quiz-app, Property X: [property description]
test('property description', () {
  // Test implementation
});
```

### Iteration Count

Each property test should run a minimum of **100 iterations** to ensure thorough coverage.

### Test Structure

```dart
import 'package:test/test.dart';

void main() {
  group('PropertyName', () {
    // Feature: parent-quiz-app, Property 15: Streak continuation
    test('completing session on consecutive day increments streak', () {
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final user = generateRandomUser();
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        user.lastActiveAt = yesterday;

        // Execute operation
        final result = updateStreak(user);

        // Verify property holds
        expect(result.streakCurrent, equals(user.streakCurrent + 1));
      }
    });
  });
}
```

## Common Property Patterns

### 1. Round-Trip Properties

For serialization/deserialization:

```dart
// Property: Serialization round trip
test('toMap then fromMap preserves data', () {
  for (int i = 0; i < 100; i++) {
    final original = generateRandomUser();
    final map = original.toMap();
    final restored = UserModel.fromMap(map, original.id);
    expect(restored, equals(original));
  }
});
```

### 2. Invariant Properties

Properties that must always hold:

```dart
// Property: Longest streak invariant
test('streakLongest is always >= streakCurrent', () {
  for (int i = 0; i < 100; i++) {
    final user = generateRandomUser();
    expect(user.streakLongest, greaterThanOrEqualTo(user.streakCurrent));
  }
});
```

### 3. Calculation Properties

Verify calculations are correct:

```dart
// Property: Level calculation
test('level equals floor(totalXp / 100) + 1', () {
  for (int i = 0; i < 100; i++) {
    final xp = Random().nextInt(10000);
    final level = calculateLevel(xp);
    expect(level, equals((xp ~/ 100) + 1));
  }
});
```

### 4. State Transition Properties

Verify state changes are correct:

```dart
// Property: Question state update
test('answering question increments seenCount', () {
  for (int i = 0; i < 100; i++) {
    final state = generateRandomQuestionState();
    final originalSeen = state.seenCount;

    final updated = updateQuestionState(state, isCorrect: Random().nextBool());

    expect(updated.seenCount, equals(originalSeen + 1));
  }
});
```

## Test Data Generators

Create helper functions to generate random valid test data:

```dart
UserModel generateRandomUser() {
  final random = Random();
  return UserModel(
    id: 'user_${random.nextInt(1000)}',
    displayName: 'User ${random.nextInt(1000)}',
    email: 'user${random.nextInt(1000)}@test.com',
    friendCode: generateRandomFriendCode(),
    totalXp: random.nextInt(10000),
    streakCurrent: random.nextInt(100),
    streakLongest: random.nextInt(100) + random.nextInt(100),
    // ... other fields
  );
}

String generateRandomFriendCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  final length = 6 + random.nextInt(3); // 6-8 characters
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
```

## Edge Cases

While property tests cover general cases, also test edge cases:

- Empty collections
- Boundary values (0, max int)
- Null values where applicable
- Special characters in strings

## Running Property Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/user_service_test.dart

# Run with coverage
flutter test --coverage
```

## Debugging Failed Properties

When a property test fails:

1. Note the random seed (if using seeded random)
2. Reproduce with the same seed
3. Identify the specific input that caused failure
4. Fix the implementation or refine the property
5. Re-run all tests to ensure fix doesn't break other properties
