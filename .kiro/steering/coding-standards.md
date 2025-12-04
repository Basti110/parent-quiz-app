---
inclusion: always
---

# Coding Standards

## Dart/Flutter Best Practices

### Naming Conventions

- **Classes**: PascalCase (`UserService`, `QuizScreen`)
- **Files**: snake_case (`user_service.dart`, `quiz_screen.dart`)
- **Variables/Functions**: camelCase (`getUserData`, `currentLevel`)
- **Constants**: lowerCamelCase with const (`const maxQuestions = 10`)
- **Private members**: Prefix with underscore (`_firestore`, `_calculateXP`)

### Code Organization

**Import Order:**

1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Relative imports

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
```

### Async/Await

Always use async/await instead of .then():

```dart
// Good
Future<User> getUser(String id) async {
  final doc = await _firestore.collection('users').doc(id).get();
  return User.fromMap(doc.data()!);
}

// Avoid
Future<User> getUser(String id) {
  return _firestore.collection('users').doc(id).get()
    .then((doc) => User.fromMap(doc.data()!));
}
```

### Null Safety

- Use `?` for nullable types
- Use `!` only when absolutely certain value is non-null
- Prefer null-aware operators (`??`, `?.`)
- Use `late` for non-nullable fields initialized later

```dart
String? optionalValue;
String definiteValue = optionalValue ?? 'default';
int? length = optionalValue?.length;
```

### Widget Best Practices

- Extract complex widgets into separate classes
- Use `const` constructors when possible
- Keep build methods small and readable
- Use `ConsumerWidget` or `Consumer` for Riverpod

```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: user.when(
        data: (data) => _buildContent(data),
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }

  Widget _buildContent(UserModel user) {
    // Build UI
  }
}
```

## Error Handling

Always handle errors gracefully:

```dart
try {
  await someOperation();
} on FirebaseException catch (e) {
  // Handle Firebase errors specifically
  _showError('Firebase error: ${e.message}');
} catch (e) {
  // Handle general errors
  _showError('An error occurred');
  print('Error: $e'); // Log for debugging
}
```

## Comments and Documentation

- Use `///` for public API documentation
- Use `//` for implementation comments
- Document complex logic
- Don't comment obvious code

```dart
/// Calculates the user's current level based on total XP.
///
/// Each level requires 100 XP. Level 1 starts at 0 XP.
int calculateLevel(int totalXp) {
  return (totalXp ~/ 100) + 1;
}
```

## Performance

- Use `const` constructors for immutable widgets
- Avoid rebuilding entire widget trees
- Use `ListView.builder` for long lists
- Cache expensive computations
- Minimize Firestore reads

## Testing

- Write tests for all service methods
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert
- Mock external dependencies

```dart
test('calculateLevel returns correct level for given XP', () {
  // Arrange
  final service = UserService();

  // Act
  final level = service.calculateLevel(250);

  // Assert
  expect(level, equals(3));
});
```
