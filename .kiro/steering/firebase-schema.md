---
inclusion: always
---

# Firebase Firestore Schema

## Collections

### users/{userId}

User documents with the following fields:

```dart
{
  'displayName': String,
  'email': String,
  'avatarPath': String?,          // Optional local asset path (e.g., 'assets/app_images/avatars/avatar_1.png')
  'createdAt': Timestamp,
  'lastActiveAt': Timestamp,
  'friendCode': String,           // 6-8 character alphanumeric
  'totalXp': int,
  'currentLevel': int,
  'weeklyXpCurrent': int,
  'weeklyXpWeekStart': Timestamp, // Monday of current week
  'streakCurrent': int,
  'streakLongest': int,
  'duelsPlayed': int,
  'duelsWon': int,
  'duelsLost': int,
  'duelPoints': int,
}
```

### users/{userId}/questionStates/{questionId}

Tracks user progress per question:

```dart
{
  'questionId': String,
  'seenCount': int,
  'correctCount': int,
  'lastSeenAt': Timestamp,
  'mastered': bool,              // true when correctCount >= 3
}
```

### users/{userId}/friends/{friendUserId}

Friend relationships:

```dart
{
  'friendUserId': String,
  'status': String,              // "accepted" for MVP
  'createdAt': Timestamp,
  'createdBy': String,           // userId who initiated
}
```

### users/{userId}/history/{date}

Weekly points history (date format: yyyy-MM-dd):

```dart
{
  'date': String,                // yyyy-MM-dd (Monday of week)
  'weekStart': Timestamp,
  'weekEnd': Timestamp,
  'points': int,
  'sessionsCompleted': int,
  'questionsAnswered': int,
  'correctAnswers': int,
}
```

### categories/{categoryId}

Quiz categories:

```dart
{
  'title': String,
  'description': String,
  'order': int,
  'iconName': String,
  'isPremium': bool,
}
```

### questions/{questionId}

Quiz questions:

```dart
{
  'categoryId': String,
  'text': String,
  'options': List<String>,       // 3-4 answer options
  'correctIndices': List<int>,   // Supports multiple correct answers
  'explanation': String,
  'tips': String?,               // Optional practical tips/advice
  'sourceLabel': String?,
  'sourceUrl': String?,
  'difficulty': int,
  'isActive': bool,
}
```

## Indexes Required

For optimal query performance:

1. **users collection:**

   - `friendCode` (for friend lookup)
   - `weeklyXpCurrent` DESC (for leaderboard)

2. **questions collection:**
   - `categoryId`, `isActive` (for question selection)

## Data Access Patterns

- **User data**: Real-time stream for current user
- **Questions**: One-time fetch per quiz session
- **Leaderboard**: One-time fetch, sorted by weeklyXpCurrent
- **Friends**: Real-time stream for friends list
- **History**: One-time fetch for analytics
