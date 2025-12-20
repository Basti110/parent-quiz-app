---
inclusion: always
---

# Simplified Gamification Rules

## Daily Goal System

### Daily Goal Management

- **Default daily goal**: 10 questions per day
- **Adjustable range**: 1-50 questions per day
- **Progress tracking**: Questions answered today vs. daily goal
- **Reset timing**: Daily progress resets at midnight (user's local timezone)

### Daily Progress Display

- Show progress as "X/Y questions" (e.g., "7/10 questions")
- Visual progress bar showing completion percentage
- Checkmark indicator when daily goal is met
- Celebration animation on goal completion

## Streak System

### Streak Rules

1. **Streak start**: Meet daily goal for the first time → streak = 1
2. **Streak continuation**: Meet daily goal on consecutive days → increment by 1
3. **Streak reset**: Fail to meet daily goal for a calendar day → reset to 0
4. **Longest streak**: Track highest streak ever achieved
5. **Timezone**: Use user's local timezone for day calculations

### Streak Logic

```dart
if (isSameDay(now, lastActiveAt)) {
  // Same day, no change to streak
} else if (isYesterday(lastActiveAt, now) && metDailyGoalYesterday) {
  // Consecutive day with goal met
  streakCurrent++;
  if (streakCurrent > streakLongest) {
    streakLongest = streakCurrent;
  }
} else {
  // Streak broken (missed a day or didn't meet goal)
  streakCurrent = 0;
}
```

## Streak Points System

### Streak Points Calculation

- **Days 1-2**: 0 streak points (building momentum)
- **Day 3**: Award 3 streak points
- **Day 4+**: Award 3 streak points per additional consecutive day
- **Total accumulation**: Streak points never decrease, only increase
- **Leaderboard ranking**: Users ranked by total streak points

### Example Calculations

**7-day streak:**
- Days 1-2: 0 points
- Day 3: +3 points
- Day 4: +3 points  
- Day 5: +3 points
- Day 6: +3 points
- Day 7: +3 points
- **Total: 15 streak points**

## Question Statistics

### Progress Tracking

- **Total questions answered**: Lifetime count of all questions attempted
- **Total correct answers**: Lifetime count of correctly answered questions
- **Total mastered questions**: Count of questions answered correctly 3+ times

### Question Mastery

- **Mastery threshold**: Answer correctly 3+ times
- **Tracking**: `correctCount` in `questionStates` subcollection
- **Status**: `mastered` field set to `true` when threshold reached
- **Category mastery**: Percentage of mastered questions in category

### Statistics Screen

**Navigation**: Accessible via dedicated statistics tab in main navigation (last tab)

**Overall Statistics Display:**
- Total questions answered across all categories
- Total questions mastered across all categories  
- Total questions seen across all categories
- Visual progress indicators and percentages

**Category-Level Breakdown:**
- Statistics grouped by category with category icons
- Per-category counts: answered, mastered, seen
- Progress bars showing completion percentage per category
- Categories with no progress show 0 for all statistics

**Data Source**: Statistics calculated dynamically from `questionStates` subcollection (not stored as denormalized counts)

**Performance**: Uses `questionCounter` field from category documents to avoid expensive question counting queries

## Leaderboard System

### Ranking Logic

- **Primary ranking**: Total streak points (descending)
- **Secondary display**: Current streak length
- **User rank**: Show current user's position
- **Zero points**: Users with 0 points still appear on leaderboard

### Head-to-Head Statistics

- **Friend records**: Show win-loss-tie record against each friend (e.g., "5-3-1")
- **Display format**: "vs You: X-Y-Z" where X=their wins, Y=their losses, Z=ties
- **Leading indicator**: Show if user is leading, tied, or trailing

## Asynchronous Duel System

### Duel Mechanics

- **Challenge creation**: Tap friend's avatar or challenge button to initiate duel
- **Question count**: 5 questions per duel
- **Question consistency**: Both participants get identical questions in same order
- **Asynchronous play**: Complete at your own pace
- **Score tracking**: Increment score for each correct answer

### Challenge State Management (Single Source of Truth)

The `openChallenge` field in the friendship document is the **single source of truth** for active duels:

**Field Structure:**
```dart
'openChallenge': {
  'duelId': String,
  'challengerId': String,
  'createdAt': Timestamp,
  'status': String,  // 'pending' or 'accepted'
}
```

**Status Lifecycle:**
1. **Challenge Created**: `openChallenge` set with `status: 'pending'`
2. **Challenge Accepted**: `status` updated to `'accepted'`
3. **Both Complete**: `openChallenge` remains (for "View Results")
4. **Results Viewed**: `openChallenge` cleared (can create new challenges)

**Prevention Logic:**
- If `openChallenge` exists → Block new challenges
- Check friendship document (not duels collection) for efficiency
- Real-time updates via friendship document stream

### Duel Completion Tracking

**Completion Status:**
- Tracked in duel document: `challengerCompletedAt`, `opponentCompletedAt`
- Real-time updates via `duelStreamProvider`
- UI updates automatically when either user completes

**UI States:**
- **Pending (Incoming)**: Blue banner with Accept/Decline buttons
- **Pending (Outgoing)**: Yellow indicator, waiting for response
- **Accepted (Ready)**: Green banner with "Start Duel" button
- **Accepted (User Done)**: Yellow banner, "Waiting for opponent"
- **Both Complete**: Blue banner with "View Results" button

### Duel Statistics

- **Duel completion**: Track total duels completed
- **Win tracking**: Track wins against all opponents
- **Head-to-head**: Maintain win-loss-tie record per friend
- **Symmetric updates**: Both users' friendship documents updated with results

## VS Mode (Pass-and-Play) Enhancements

### Time-Based Tiebreaker

- **Time tracking**: Only during question answering (not explanations)
- **Timer start**: When question is displayed
- **Timer pause**: When answer is submitted, during explanations
- **Timer resume**: When next question is displayed
- **Tiebreaker**: If scores equal, faster completion time wins

### XP Calculation (VS Mode only)

- **Correct answer**: +10 XP
- **Incorrect + explanation viewed**: +5 XP
- **Incorrect without explanation**: +2 XP
- **Session bonuses**: Same as solo mode
- **Update scope**: Only logged-in user's stats updated

## Question Selection Algorithm

### Priority Order

1. **Unseen questions first**: `seenCount == 0`
2. **Oldest questions next**: Sorted by `lastSeenAt` ascending
3. **Random selection**: From prioritized pool

This ensures users see new content while reviewing older material.
