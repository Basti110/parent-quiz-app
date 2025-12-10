# Firestore Security Rules Documentation

## Overview

This document explains the Firestore security rules for the parent quiz application, including the current MVP implementation and future migration plans.

## Current Implementation (MVP)

### User Collection Rules

Users can:
- **Read**: Any authenticated user can read user profiles (for leaderboard, friends list, etc.)
- **Create**: Users can create their own profile during registration
- **Update**: Users can update their own profile, including:
  - Daily goal settings (1-50 questions)
  - Streak data (streakCurrent, streakLongest, streakPoints)
  - Question statistics (totalQuestionsAnswered, totalCorrectAnswers, totalMasteredQuestions)
  - Daily progress (questionsAnsweredToday, lastDailyReset)
  - Duel statistics (duelsCompleted, duelsWon)
- **Delete**: Prevented for data integrity

### Duel Collection Rules (MVP - Client-Side)

The duel system is currently implemented client-side for MVP. Users can:
- **Read**: Participants (challenger or opponent) can read duel data
- **Create**: Authenticated users can create duels when challenging friends
- **Update**: Participants can update duels (for submitting answers and scores)
- **Delete**: Prevented for data integrity

**Important**: The client-side implementation allows users to write their own answers and scores. This is acceptable for MVP but will be migrated to Cloud Functions for production.

### Subcollections

#### questionStates/{questionId}
- Users can read and write their own question state data
- Tracks: seenCount, correctCount, lastSeenAt, mastered status

#### friends/{friendUserId}
- Users can read and write their own friendship data
- Tracks: friendUserId, status, createdAt, createdBy, head-to-head stats

#### history/{date}
- Users can read and write their own weekly history
- Tracks: weekly XP, sessions, questions answered, correct answers

### Read-Only Collections

#### categories/{categoryId}
- All authenticated users can read
- Only admins can modify (via Firebase Console)

#### questions/{questionId}
- All authenticated users can read
- Only admins can modify (via Firebase Console)

## Future Migration: Cloud Functions

### Duel Collection (Future Implementation)

When migrating to Cloud Functions, the duel rules will change to:

```javascript
match /duels/{duelId} {
  // Allow read for participants
  allow read: if isAuthenticated() && 
    (resource.data.challengerId == request.auth.uid ||
     resource.data.opponentId == request.auth.uid);
  
  // No direct write access - must go through Cloud Function
  allow write: if false;
}
```

### Cloud Function Implementation

The Cloud Function will:
1. Validate answer correctness server-side (prevent cheating)
2. Update scores and completion status
3. Trigger notifications when duels are completed
4. Update head-to-head statistics for both users
5. Archive completed duels after 7 days

### Migration Benefits

1. **Security**: Server validates correctness, preventing cheating
2. **Consistency**: Single source of truth for answer validation
3. **Auditability**: Server logs all answer submissions
4. **Extensibility**: Easy to add features like time limits, hints, power-ups

### Data Model Compatibility

The current data model is designed to support both client-side and Cloud Function implementations without requiring schema changes:

```dart
{
  'challengerAnswers': {
    'question_id_1': true,   // Can be written by client OR Cloud Function
    'question_id_2': false,
  },
  'challengerScore': 1,      // Can be incremented by client OR Cloud Function
}
```

## Security Considerations

### Current MVP Limitations

1. **Client-Side Answer Validation**: Users could theoretically modify client code to mark incorrect answers as correct
2. **Score Manipulation**: Users could increment scores without actually answering questions
3. **No Server-Side Audit Trail**: All operations happen client-side

### Mitigation Strategies

For MVP, these limitations are acceptable because:
1. The app is for educational purposes, not competitive rankings with prizes
2. Users are primarily competing with friends who trust each other
3. The focus is on learning, not winning
4. Migration to Cloud Functions is planned for production

### Production Requirements

Before production launch:
1. Implement Cloud Functions for duel answer submission
2. Update security rules to prevent direct client writes to duels
3. Add server-side logging and monitoring
4. Implement rate limiting to prevent abuse
5. Add admin tools for reviewing suspicious activity

## Deployment

### Deploying Security Rules

To deploy these rules to Firebase:

```bash
firebase deploy --only firestore:rules
```

### Testing Security Rules

Use the Firebase Emulator Suite to test rules locally:

```bash
firebase emulators:start
```

Then run tests against the emulator:

```bash
flutter test
```

### Monitoring

Monitor security rule violations in the Firebase Console:
1. Go to Firestore → Usage tab
2. Check for denied read/write operations
3. Review patterns of rule violations
4. Adjust rules if legitimate operations are being blocked

## Best Practices

1. **Principle of Least Privilege**: Only grant the minimum permissions needed
2. **Validate on Write**: Use `request.resource.data` to validate incoming data
3. **Prevent Deletion**: Preserve data integrity by preventing deletions
4. **Use Helper Functions**: Keep rules DRY with reusable functions
5. **Document Future Changes**: Comment rules that will change during migration
6. **Test Thoroughly**: Use emulator to test all access patterns before deployment

## Related Documentation

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions Migration Guide](./scripts/MIGRATION_GUIDE.md)
- [Design Document](./.kiro/specs/simplified-gamification/design.md)
- [Requirements Document](./.kiro/specs/simplified-gamification/requirements.md)
