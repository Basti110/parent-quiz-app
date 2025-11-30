---
inclusion: always
---

# XP and Gamification Rules

## XP Calculation

### Per-Question XP

- **Correct answer**: +10 XP
- **Incorrect + explanation viewed**: +5 XP
- **Incorrect without explanation**: +2 XP

### Session Bonuses

- **5-question session completion**: +10 XP bonus
- **10-question session completion**: +25 XP bonus
- **Perfect session (all correct)**: +10 XP bonus (in addition to session bonus)

### Example Calculations

**5-question session, 4 correct, 1 incorrect (explanation viewed):**

- 4 × 10 = 40 XP (correct answers)
- 1 × 5 = 5 XP (incorrect with explanation)
- 10 XP (session bonus)
- **Total: 55 XP**

**10-question session, all correct:**

- 10 × 10 = 100 XP (correct answers)
- 25 XP (session bonus)
- 10 XP (perfect bonus)
- **Total: 135 XP**

## Level System

- **Level calculation**: `floor(totalXp / 100) + 1`
- **Level 1**: 0-99 XP
- **Level 2**: 100-199 XP
- **Level 3**: 200-299 XP
- And so on...

## Streak System

### Streak Rules

1. Complete at least one quiz session per calendar day
2. Consecutive days increment `streakCurrent`
3. Missing a day resets `streakCurrent` to 1 (not 0)
4. `streakLongest` tracks the highest streak ever achieved

### Streak Logic

```dart
if (isSameDay(now, lastActiveAt)) {
  // Same day, no change
} else if (isYesterday(lastActiveAt, now)) {
  // Consecutive day
  streakCurrent++;
  if (streakCurrent > streakLongest) {
    streakLongest = streakCurrent;
  }
} else {
  // Streak broken
  streakCurrent = 1;
}
```

## Weekly Leaderboard

- **Week definition**: Monday to Sunday
- **Reset timing**: Every Monday at 00:00
- **Tracking**: `weeklyXpCurrent` accumulates XP for current week
- **History**: Previous week's data saved to `history` subcollection

## Question Mastery

- **Mastery threshold**: Answer correctly 3+ times
- **Tracking**: `correctCount` in `questionStates` subcollection
- **Status**: `mastered` field set to `true` when threshold reached
- **Category mastery**: Percentage of mastered questions in category

## VS Mode (Duel) Points

- **Win**: +3 duel points, increment `duelsWon` and `duelsPlayed`
- **Tie**: +1 duel point, increment `duelsPlayed`
- **Loss**: +0 duel points, increment `duelsLost` and `duelsPlayed`

Note: Only the logged-in user's stats are updated in pass-and-play mode.

## Question Selection Algorithm

### Priority Order

1. **Unseen questions first**: `seenCount == 0`
2. **Oldest questions next**: Sorted by `lastSeenAt` ascending
3. **Random selection**: From prioritized pool

This ensures users see new content while reviewing older material.
