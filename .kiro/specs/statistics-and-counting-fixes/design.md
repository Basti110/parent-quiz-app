# Design Document: Statistics and Counting Fixes

## Overview

This design document outlines the architecture for fixing three critical issues in the gamification system:

1. **Category Question Counter**: Replace dynamic calculation with a stored `questionCounter` field in category documents
2. **Dynamic Statistics Calculation**: Calculate user statistics from `questionStates` subcollection instead of storing denormalized counts
3. **Statistics Screen**: Add a new dedicated screen to display user learning progress with category-level breakdown

These changes improve performance, ensure data consistency, and provide users with better visibility into their learning progress.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │ Settings │  │ Friends  │  │Statistics│   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Provider Layer (Riverpod)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ User Provider│  │Category Prov.│  │Statistics Pr.│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │UserService   │  │QuizService   │  │StatisticsServ│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Firestore                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │categories│  │  users   │  │questions │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Changes

1. **Category Model**: Add `questionCounter` field to store total active questions
2. **Statistics Service**: New service to calculate statistics from `questionStates` subcollection
3. **Statistics Screen**: New UI screen with category-level breakdown
4. **Navigation**: Add statistics tab to main navigation bar
5. **Data Flow**: Statistics calculated on-demand from source of truth (questionStates)

## Components and Interfaces

### Data Models

#### Updated Category Model

```dart
class Category {
  final String id;
  final String title;
  final String description;
  final int order;
  final String iconName;
  final bool isPremium;
  final int questionCounter;  // NEW: Total active questions in this category

  Category({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.iconName,
    required this.isPremium,
    required this.questionCounter,
  });

  Map<String, dynamic> toMap() { /* ... */ }
  factory Category.fromMap(Map<String, dynamic> map, String id) { /* ... */ }
}
```

#### New CategoryStatistics Model

```dart
class CategoryStatistics {
  final String categoryId;
  final String categoryTitle;
  final String categoryIconName;     // NEW: Icon name for display
  final int totalQuestions;          // From category.questionCounter
  final int questionsAnswered;       // Count of questionStates with seenCount > 0
  final int questionsMastered;       // Count of questionStates with mastered == true
  final int questionsSeen;           // Count of questionStates with seenCount > 0

  CategoryStatistics({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIconName,
    required this.totalQuestions,
    required this.questionsAnswered,
    required this.questionsMastered,
    required this.questionsSeen,
  });

  double get percentageAnswered => 
    totalQuestions > 0 ? questionsAnswered / totalQuestions : 0.0;
  
  double get percentageMastered => 
    totalQuestions > 0 ? questionsMastered / totalQuestions : 0.0;
}
```

#### New UserStatistics Model

```dart
class UserStatistics {
  final int totalQuestionsAnswered;   // Sum of all questionsAnswered across categories
  final int totalQuestionsMastered;   // Sum of all questionsMastered across categories
  final int totalQuestionsSeen;       // Sum of all questionsSeen across categories
  final List<CategoryStatistics> categoryStats;

  UserStatistics({
    required this.totalQuestionsAnswered,
    required this.totalQuestionsMastered,
    required this.totalQuestionsSeen,
    required this.categoryStats,
  });

  double get percentageAnswered => 
    totalQuestionsSeen > 0 ? totalQuestionsAnswered / totalQuestionsSeen : 0.0;
  
  double get percentageMastered => 
    totalQuestionsSeen > 0 ? totalQuestionsMastered / totalQuestionsSeen : 0.0;
}
```

### Service Layer

#### Updated QuizService

```dart
class QuizService {
  final FirebaseFirestore _firestore;

  QuizService({FirebaseFirestore? firestore});

  // Updated method - use questionCounter field
  Future<int> getQuestionCountForCategory(String categoryId) async {
    try {
      final categoryDoc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();

      if (!categoryDoc.exists) {
        return 0;
      }

      final data = categoryDoc.data()!;
      final questionCounter = data['questionCounter'] as int?;

      // Fallback to querying if field is missing
      if (questionCounter == null) {
        return await _countActiveQuestions(categoryId);
      }

      return questionCounter;
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      throw Exception('Failed to load question count');
    }
  }

  // Helper method for fallback
  Future<int> _countActiveQuestions(String categoryId) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
```

#### New StatisticsService

```dart
class StatisticsService {
  final FirebaseFirestore _firestore;

  StatisticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user statistics calculated from questionStates
  /// Property 2.1, 2.2, 2.3: Count questions from questionStates subcollection
  Future<UserStatistics> getUserStatistics(String userId) async {
    try {
      // Load all question states for the user
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      // Load all categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get();

      final categories = <String, Category>{};
      for (final doc in categoriesSnapshot.docs) {
        final category = Category.fromMap(doc.data(), doc.id);
        categories[category.id] = category;
      }

      // Load all questions to map questionId -> categoryId
      final questionsSnapshot = await _firestore
          .collection('questions')
          .get();

      final questionToCategory = <String, String>{};
      for (final doc in questionsSnapshot.docs) {
        final data = doc.data();
        questionToCategory[doc.id] = data['categoryId'] as String;
      }

      // Calculate statistics by category
      final categoryStats = <String, CategoryStatistics>{};
      int totalAnswered = 0;
      int totalMastered = 0;
      int totalSeen = 0;

      for (final state in statesSnapshot.docs) {
        final questionState = QuestionState.fromMap(state.data());
        final categoryId = questionToCategory[questionState.questionId];

        if (categoryId == null) continue;

        // Initialize category stats if needed
        if (!categoryStats.containsKey(categoryId)) {
          final category = categories[categoryId];
          if (category != null) {
            categoryStats[categoryId] = CategoryStatistics(
              categoryId: categoryId,
              categoryTitle: category.title,
              categoryIconName: category.iconName,
              totalQuestions: category.questionCounter,
              questionsAnswered: 0,
              questionsMastered: 0,
              questionsSeen: 0,
            );
          }
        }

        final stats = categoryStats[categoryId];
        if (stats != null) {
          // Count seen questions (seenCount > 0)
          if (questionState.seenCount > 0) {
            categoryStats[categoryId] = CategoryStatistics(
              categoryId: stats.categoryId,
              categoryTitle: stats.categoryTitle,
              totalQuestions: stats.totalQuestions,
              questionsAnswered: stats.questionsAnswered + 1,
              questionsMastered: stats.questionsMastered,
              questionsSeen: stats.questionsSeen + 1,
            );
            totalAnswered++;
            totalSeen++;
          }

          // Count mastered questions (mastered == true)
          if (questionState.mastered) {
            final updatedStats = categoryStats[categoryId]!;
            categoryStats[categoryId] = CategoryStatistics(
              categoryId: updatedStats.categoryId,
              categoryTitle: updatedStats.categoryTitle,
              totalQuestions: updatedStats.totalQuestions,
              questionsAnswered: updatedStats.questionsAnswered,
              questionsMastered: updatedStats.questionsMastered + 1,
              questionsSeen: updatedStats.questionsSeen,
            );
            totalMastered++;
          }
        }
      }

      return UserStatistics(
        totalQuestionsAnswered: totalAnswered,
        totalQuestionsMastered: totalMastered,
        totalQuestionsSeen: totalSeen,
        categoryStats: categoryStats.values.toList(),
      );
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      throw Exception('Failed to load statistics');
    }
  }

  /// Get statistics for a specific category
  Future<CategoryStatistics> getCategoryStatistics(
    String userId,
    String categoryId,
  ) async {
    try {
      final userStats = await getUserStatistics(userId);
      final categoryStats = userStats.categoryStats
          .firstWhere((stat) => stat.categoryId == categoryId);
      return categoryStats;
    } catch (e) {
      print('Error loading category statistics: $e');
      throw Exception('Failed to load category statistics');
    }
  }
}
```

#### Updated UserService

```dart
class UserService {
  // Remove methods that calculate statistics from stored counts
  // Instead, use StatisticsService to calculate from questionStates

  // Keep existing methods for streak, daily goal, etc.
  // But remove: totalQuestionsAnswered, totalCorrectAnswers, totalMasteredQuestions updates
}
```

### Providers

#### New Statistics Provider

```dart
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final userStatisticsProvider = FutureProvider.family<UserStatistics, String>(
  (ref, userId) {
    final statisticsService = ref.watch(statisticsServiceProvider);
    return statisticsService.getUserStatistics(userId);
  },
);

final categoryStatisticsProvider = FutureProvider.family<CategoryStatistics, (String, String)>(
  (ref, params) {
    final (userId, categoryId) = params;
    final statisticsService = ref.watch(statisticsServiceProvider);
    return statisticsService.getCategoryStatistics(userId, categoryId);
  },
);
```

## Data Models

### Firebase Collections

#### Updated categories/{categoryId}

```dart
{
  'title': String,
  'description': String,
  'order': int,
  'iconName': String,
  'isPremium': bool,
  'questionCounter': int,  // NEW: Total active questions in this category
}
```

#### users/{userId}/questionStates/{questionId}

```dart
{
  'questionId': String,
  'seenCount': int,           // Number of times seen
  'correctCount': int,        // Number of times answered correctly
  'lastSeenAt': Timestamp,
  'mastered': bool,           // true when correctCount >= 3
}
```

### Firestore Indexes

Required indexes:

1. **categories collection**:
   - `order` ASC (for sorting)

2. **users/{userId}/questionStates subcollection**:
   - `mastered` (for counting mastered questions)
   - `seenCount` (for counting seen questions)

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Category Question Counter Properties

**Property 1: Question counter increments on question addition**
_For any_ category and any new active question added to it, the category's `questionCounter` should increment by 1
**Validates: Requirements 1.2**

**Property 2: Question counter decrements on question removal**
_For any_ category and any active question removed from it, the category's `questionCounter` should decrement by 1
**Validates: Requirements 1.3**

**Property 3: Fallback to query when counter missing**
_For any_ category without a `questionCounter` field, the system should still return the correct count by querying active questions
**Validates: Requirements 1.5**

### Statistics Calculation Properties

**Property 4: Seen questions count accuracy**
_For any_ user and any set of question states, the count of seen questions should equal the number of question states where `seenCount > 0`
**Validates: Requirements 2.1**

**Property 5: Correct questions count accuracy**
_For any_ user and any set of question states, the count of correct questions should equal the number of question states where `correctCount > 0`
**Validates: Requirements 2.2**

**Property 6: Mastered questions count accuracy**
_For any_ user and any set of question states, the count of mastered questions should equal the number of question states where `mastered == true`
**Validates: Requirements 2.3**

**Property 7: Question state updates on answer**
_For any_ user answering a question, the corresponding `questionState` document should be updated with the new `seenCount` and `correctCount` values
**Validates: Requirements 2.4**

### Category Statistics Properties

**Property 8: Category answered count accuracy**
_For any_ category and any user, the count of answered questions in that category should equal the number of question states for that category where `seenCount > 0`
**Validates: Requirements 5.2**

**Property 9: Category mastered count accuracy**
_For any_ category and any user, the count of mastered questions in that category should equal the number of question states for that category where `mastered == true`
**Validates: Requirements 5.3**

**Property 10: Category seen count accuracy**
_For any_ category and any user, the count of seen questions in that category should equal the number of question states for that category where `seenCount > 0`
**Validates: Requirements 5.4**

**Property 11: Empty category statistics**
_For any_ category with no question states, all statistics should be 0
**Validates: Requirements 5.5**

### Statistics Aggregation Properties

**Property 12: Total statistics sum to category totals**
_For any_ user, the sum of answered questions across all categories should equal the total answered questions
**Validates: Requirements 2.1, 2.2, 2.3**

**Property 13: Statistics consistency across calls**
_For any_ user, calling getUserStatistics twice in succession should return identical results
**Validates: Requirements 2.1, 2.2, 2.3**

## Error Handling

### Statistics Service Errors

1. **Missing Category**: When a category referenced in questionStates doesn't exist
   - Log warning
   - Skip that question state
   - Continue calculating for other questions

2. **Missing Question**: When a question referenced in questionStates doesn't exist
   - Log warning
   - Skip that question state
   - Continue calculating for other questions

3. **Firebase Connection Issues**: When Firestore operations fail
   - Catch `FirebaseException`
   - Retry once after 2-second delay
   - Show "Failed to load statistics. Please try again." message

4. **Invalid Question Counter**: When `questionCounter` is negative or inconsistent
   - Log error
   - Fall back to querying active questions
   - Continue with calculated count

### UI Error Handling

1. **Statistics Screen Load Failure**
   - Show error message with retry button
   - Display last known statistics if available
   - Log error for debugging

2. **Category Statistics Load Failure**
   - Show error for that category
   - Display other categories normally
   - Provide retry option

## Testing Strategy

### Unit Testing

Unit tests will verify specific examples and edge cases:

1. **Category Question Counter**
   - Test counter field exists on category
   - Test counter value matches active question count
   - Test fallback when counter is missing

2. **Statistics Calculation**
   - Test counting seen questions (seenCount > 0)
   - Test counting correct questions (correctCount > 0)
   - Test counting mastered questions (mastered == true)
   - Test empty question states (all counts = 0)

3. **Category Statistics**
   - Test category-level aggregation
   - Test multiple categories
   - Test categories with no questions

4. **Error Handling**
   - Test missing categories
   - Test missing questions
   - Test invalid counter values

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using the `test` package:

**Testing Framework**: Dart's built-in `test` package with custom generators

**Configuration**: Each property test should run a minimum of 100 iterations

**Test Tagging**: Each property-based test must include a comment with this format:

```dart
// **Feature: statistics-and-counting-fixes, Property N: [property text]**
```

**Property Test Implementation**:

1. **Property 4: Seen questions count accuracy** (Requirements 2.1)
   - Generate random question states with various seenCount values
   - Count states where seenCount > 0
   - Verify system count matches manual count

2. **Property 5: Correct questions count accuracy** (Requirements 2.2)
   - Generate random question states with various correctCount values
   - Count states where correctCount > 0
   - Verify system count matches manual count

3. **Property 6: Mastered questions count accuracy** (Requirements 2.3)
   - Generate random question states with various mastered values
   - Count states where mastered == true
   - Verify system count matches manual count

4. **Property 8: Category answered count accuracy** (Requirements 5.2)
   - Generate random categories with random question states
   - Calculate category-level answered count
   - Verify system count matches manual count

5. **Property 9: Category mastered count accuracy** (Requirements 5.3)
   - Generate random categories with random question states
   - Calculate category-level mastered count
   - Verify system count matches manual count

6. **Property 12: Total statistics sum to category totals** (Requirements 2.1, 2.2, 2.3)
   - Generate random user with multiple categories
   - Sum category statistics
   - Verify total equals sum of categories

7. **Property 13: Statistics consistency across calls** (Requirements 2.1, 2.2, 2.3)
   - Generate random user
   - Call getUserStatistics twice
   - Verify both calls return identical results

### Integration Testing

Integration tests will verify end-to-end workflows:

1. **Complete Statistics Flow**
   - User answers questions in multiple categories
   - Navigate to statistics screen
   - Verify all statistics display correctly
   - Verify category breakdown is accurate

2. **Statistics Update Flow**
   - User answers a question
   - Statistics are updated
   - Verify new statistics reflect the answer

3. **Category Statistics Flow**
   - User answers questions in specific category
   - View category statistics
   - Verify category stats are accurate

## Migration Strategy

### Phase 1: Add questionCounter Field

1. Add `questionCounter` field to Category model
2. Deploy code that can read both with and without the field
3. Update QuizService to use field with fallback

### Phase 2: Populate questionCounter

Run migration script to populate `questionCounter` for all categories:

```dart
Future<void> migrateCategories() async {
  final categoriesSnapshot = await FirebaseFirestore.instance
      .collection('categories')
      .get();

  for (final doc in categoriesSnapshot.docs) {
    final categoryId = doc.id;

    // Count active questions
    final questionCount = await FirebaseFirestore.instance
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    // Update category with counter
    await doc.reference.update({
      'questionCounter': questionCount.count ?? 0,
    });
  }
}
```

### Phase 3: Add Statistics Service

1. Create StatisticsService
2. Add statistics providers
3. Deploy code that calculates statistics from questionStates

### Phase 4: Add Statistics Screen

1. Create StatisticsScreen widget
2. Add statistics tab to main navigation
3. Update MainNavigation to include statistics route

### Phase 5: Cleanup

1. Remove old statistics calculation code
2. Remove stored statistics fields from user documents (optional - can keep for backward compatibility)
3. Update documentation

## UI/UX Considerations

### Statistics Screen Layout

```
┌─────────────────────────────────────┐
│  Statistics                         │
├─────────────────────────────────────┤
│                                     │
│  Overall Progress                   │
│  ┌─────────────────────────────┐   │
│  │ Answered: 45 / 120          │   │
│  │ Mastered: 12 / 120          │   │
│  │ Seen: 45 / 120              │   │
│  └─────────────────────────────┘   │
│                                     │
│  By Category                        │
│  ┌─────────────────────────────┐   │
│  │ [Icon] Sleep                │   │
│  │ Answered: 10 / 30           │   │
│  │ Mastered: 3 / 30            │   │
│  │ [Progress bar]              │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ [Icon] Nutrition            │   │
│  │ Answered: 15 / 40           │   │
│  │ Mastered: 5 / 40            │   │
│  │ [Progress bar]              │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Navigation Integration

Add statistics as the last tab in the main navigation bar:

```
Home | Quiz | Friends | Leaderboard | Statistics
```

### Loading and Error States

- Show loading indicator while fetching statistics
- Display error message with retry button on failure
- Show last known statistics if available during error
