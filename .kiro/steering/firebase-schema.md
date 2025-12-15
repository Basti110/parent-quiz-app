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
  'avatarUrl': String?,           // Optional local asset path (e.g., 'assets/app_images/avatars/avatar_1.png')
  'createdAt': Timestamp,
  'lastActiveAt': Timestamp,
  'friendCode': String,           // 6-8 character alphanumeric

  // Streak system
  'streakCurrent': int,
  'streakLongest': int,
  'streakPoints': int,

  // Daily goal system
  'dailyGoal': int,               // Default: 10, range: 1-50
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

Accepted friend relationships (only created after request is accepted):

```dart
{
  'friendUserId': String,
  'status': String,              // Always "accepted" (only accepted friends are in this collection)
  'createdAt': Timestamp,
  'createdBy': String,           // userId who initiated the original friend request

  // Head-to-head duel statistics
  'myWins': int,                 // How many times I beat this friend
  'theirWins': int,              // How many times they beat me
  'ties': int,                   // How many ties between us
  'totalDuels': int,             // Total duels completed between us

  // Active challenge tracking
  'openChallenge': {             // null when no active challenge
    'duelId': String,
    'challengerId': String,      // Who sent the challenge
    'createdAt': Timestamp,
    'status': String,            // 'pending' or 'accepted'
  }?,

  // Challenge history (optional for MVP)
  'challengeHistory': List<{
    'duelId': String,
    'challengerId': String,
    'result': String,            // 'won', 'lost', 'tied', 'declined', 'expired'
    'completedAt': Timestamp,
  }>?,
}
```

### users/{userId}/requests/{requesterId}

Pending friend requests (incoming):

```dart
{
  'fromUserId': String,          // User ID of the person who sent the request
  'createdAt': Timestamp,
}
```

**Friend Request Flow:**

1. **Send Request**: User A enters User B's friend code
   - Creates a request document in User B's `requests` subcollection
   - Document ID is User A's ID, contains `fromUserId: userA`
   
2. **Pending State**: 
   - User A sees "Friend request sent" confirmation
   - User B sees "Friend request from User A" with Accept/Decline buttons in their requests section
   
3. **Accept Request**: User B accepts
   - Creates friendship documents in both users' `friends` subcollections with `status: 'accepted'`
   - Deletes the request document from User B's `requests` subcollection
   - Both users can now see each other in friends list and challenge each other
   
4. **Decline Request**: User B declines
   - Deletes the request document from User B's `requests` subcollection
   - Users are not friends and can send new requests later

### duels/{duelId}

Asynchronous duel challenges:

```dart
{
  'challengerId': String,
  'opponentId': String,
  'status': String,              // 'pending', 'accepted', 'completed', 'declined', 'expired'
  'createdAt': Timestamp,
  'acceptedAt': Timestamp?,
  'completedAt': Timestamp?,

  // Questions (same for both)
  'questionIds': List<String>,   // 5 question IDs

  // Challenger data
  'challengerAnswers': Map<String, bool>,  // questionId -> isCorrect
  'challengerScore': int,                  // Incremented after each correct answer
  'challengerCompletedAt': Timestamp?,

  // Opponent data
  'opponentAnswers': Map<String, bool>,    // questionId -> isCorrect
  'opponentScore': int,                    // Incremented after each correct answer
  'opponentCompletedAt': Timestamp?,
}
```

### vsModeSession/{sessionId}

VS Mode (pass-and-play) sessions:

```dart
{
  'playerAId': String,
  'playerBId': String,
  'status': String,              // 'setup', 'playerA', 'handoff', 'playerB', 'completed'
  'createdAt': Timestamp,
  'completedAt': Timestamp?,

  // Questions and answers
  'questionIds': List<String>,
  'playerAAnswers': Map<String, bool>,
  'playerBAnswers': Map<String, bool>,

  // Timing data
  'playerAElapsedSeconds': int,  // Accumulated time during questions only
  'playerBElapsedSeconds': int,  // Accumulated time during questions only

  // Explanation tracking
  'playerAExplanationsViewed': Map<String, bool>,
  'playerBExplanationsViewed': Map<String, bool>,
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
   - `streakPoints` DESC (for leaderboard)

2. **questions collection:**
   - `categoryId`, `isActive` (for question selection)

3. **duels collection:**
   - `challengerId`, `status` (for user's challenges)
   - `opponentId`, `status` (for user's received duels)
   - `status`, `createdAt` (for cleanup of expired duels)

## Data Access Patterns

- **User data**: Real-time stream for current user
- **Questions**: One-time fetch per quiz session
- **Leaderboard**: One-time fetch, sorted by streakPoints
- **Friends**: Real-time stream for friends list with head-to-head stats
- **Duels**: Real-time streams for pending, active, and completed duels
- **VS Mode**: Real-time stream for active session
