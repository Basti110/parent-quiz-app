# Implementation Plan: Simplified Gamification System

## Overview

This implementation plan covers the transition from XP-based gamification to a streak-based system, plus the addition of asynchronous duels and VS Mode improvements (explanations + time-based tiebreaker).

**Key VS Mode Timing Approach**: Time is tracked only during question answering, NOT during explanation viewing. The timer starts when a question is displayed, pauses when an answer is submitted, and resumes when the next question is displayed. This ensures fair competition based on answering speed rather than how quickly players skip through educational content.

## Task List

- [x] 1. Update data models for simplified gamification
- [x] 1.1 Update UserModel to remove XP fields and add streak/daily goal fields

  - Remove: totalXp, currentLevel, weeklyXpCurrent, weeklyXpWeekStart
  - Add: streakPoints, dailyGoal, questionsAnsweredToday, lastDailyReset, totalQuestionsAnswered, totalCorrectAnswers, totalMasteredQuestions
  - Update: duelsPlayed → duelsCompleted, remove duelsLost, remove duelPoints
  - _Requirements: 6.1, 6.2_

- [x] 1.2 Create DuelModel for asynchronous duels

  - Fields: id, challengerId, opponentId, status, timestamps, questionIds
  - Fields: challengerAnswers (Map<String, bool>), challengerScore, challengerCompletedAt
  - Fields: opponentAnswers (Map<String, bool>), opponentScore, opponentCompletedAt
  - Method: getWinnerId() for winner determination
  - _Requirements: 15.1, 15.2, 15.3_

- [x] 1.3 Update VSModeSession model for time tracking and explanations

  - Add: playerAElapsedSeconds, playerBElapsedSeconds (accumulated time, questions only)
  - Add: playerAExplanationsViewed, playerBExplanationsViewed (Map<String, bool>)
  - Add computed properties: playerATimeSeconds, playerBTimeSeconds (return elapsed seconds)
  - _Requirements: 18.1, 18.2, 18.3, 18.5, 21.1, 21.2_

- [x] 1.4 Update VSModeResult model for time-based tiebreaker

  - Add: playerATimeSeconds, playerBTimeSeconds, wonByTime
  - Add method: formatTime(int? seconds) for MM:SS formatting
  - Update outcome calculation to consider time when scores are equal
  - _Requirements: 19.1, 19.2, 19.5, 20.2_

- [x] 1.5 Create FriendModel for head-to-head statistics

  - Fields: friendUserId, status, createdAt, createdBy
  - Fields: myWins, theirWins, ties, totalDuels (all default to 0)
  - Method: getRecordString() returns formatted record (e.g., "5-3-1")
  - Method: isLeading() returns true if myWins > theirWins
  - Method: isTied() returns true if myWins == theirWins
  - _Requirements: 15a.1, 15a.5_

- [x] 2. Update UserService for streak-based system
- [x] 2.1 Implement daily goal management methods

  - updateDailyGoal(userId, newGoal) with validation (1-50)
  - incrementQuestionsAnsweredToday(userId)
  - resetDailyProgressIfNeeded(userId) - check lastDailyReset
  - _Requirements: 1.3, 1.4, 1.5, 5.5_

- [x] 2.2 Implement streak management methods

  - checkAndUpdateStreak(userId) - check consecutive days
  - calculateStreakPoints(currentStreak) - 0 for days 1-2, 3 for day 3+
  - awardStreakPoints(userId, points)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3_

- [x] 2.3 Implement question statistics methods

  - incrementTotalQuestions(userId, correct) - update both counters
  - updateMasteredCount(userId) - count mastered questions from questionStates
  - _Requirements: 4.1, 4.3, 4.5_

- [x] 2.4 Write property test for daily goal bounds

  - **Property 1: Daily goal bounds**
  - **Validates: Requirements 1.3**

- [ ]\* 2.5 Write property test for streak continuation

  - **Property 5: Streak continuation**
  - **Validates: Requirements 2.2**

- [x] 2.6 Write property test for streak reset

  - **Property 6: Streak reset**
  - **Validates: Requirements 2.3**

- [x] 2.7 Write property test for streak points calculation

  - **Property 10: Three points per additional day**
  - **Validates: Requirements 3.2**

- [x] 3. Create DuelService for asynchronous duels
- [x] 3.1 Implement duel creation and management

  - createDuel(challengerId, opponentId) - generate 5 questions
  - acceptDuel(duelId, userId) - update status to accepted
  - declineDuel(duelId, userId) - update status to declined
  - _Requirements: 10.2, 11.1, 11.2, 11.3_

- [x] 3.2 Implement duel gameplay methods

  - submitAnswer(duelId, userId, questionIndex, questionId, isCorrect)
  - Increment score if correct, store answer in map
  - completeDuel(duelId, userId) - mark completion timestamp
  - When both players complete, call \_updateHeadToHeadStats for both users
  - _Requirements: 12.2, 12.3, 12.4, 13.2, 15a.2_

- [x] 3.3 Implement duel query methods

  - getPendingDuels(userId) - stream of pending challenges
  - getActiveDuels(userId) - stream of accepted, incomplete duels
  - getCompletedDuels(userId) - stream of finished duels
  - getDuel(duelId) - single duel fetch
  - _Requirements: 14.1, 14.2, 14.4, 15.4_

- [x] 3.4 Implement helper methods

  - \_generateDuelQuestions() - select 5 random active questions
  - \_updateDuelStatistics(winnerId, loserId, isTie) - update user stats
  - \_updateHeadToHeadStats(userId, friendId, userWon, isTie) - update friendship documents for both users
  - _Requirements: 11.5, 13.4, 15a.2_

- [x] 3.5 Write property test for duel question consistency

  - **Property 18: Duel question consistency**
  - **Validates: Requirements 11.5**

- [x] 3.6 Write property test for duel score calculation

  - **Property 19: Duel score calculation**
  - **Validates: Requirements 13.2**

- [x] 3.7 Write property test for duel winner determination

  - **Property 20: Duel winner determination**
  - **Validates: Requirements 13.4**

- [ ]\* 3.8 Write property test for head-to-head record accuracy

  - **Property 25: Head-to-head record accuracy**
  - **Validates: Requirements 15a.2**

- [ ]\* 3.9 Write property test for head-to-head symmetry

  - **Property 26: Head-to-head symmetry**
  - **Validates: Requirements 15a.2**

- [-] 4. Update VSModeService for time tracking and explanations
- [x] 4.1 Implement time tracking methods

  - recordQuestionStart(session, playerId, startTime) - called when question displayed
  - recordQuestionEnd(session, playerId, endTime) - called when answer submitted, accumulates elapsed time
  - recordExplanationViewed(session, playerId, questionId) - tracks explanation views
  - _Requirements: 18.1, 18.2, 18.5, 17.4, 22.2, 22.3_

- [x] 4.2 Update calculateResult for time-based tiebreaker

  - Compare scores first
  - If tied, compare completion times
  - Set wonByTime flag when winner determined by time
  - Handle missing time data for backward compatibility
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 24.1, 24.2, 24.3_

- [x] 4.3 Implement XP calculation for VS Mode

  - calculatePlayerXP(answers, explanationsViewed, questionsPerPlayer)
  - Apply same XP rules as solo mode (10/5/2 XP)
  - Apply session bonuses (completion + perfect)
  - _Requirements: 25.1, 25.2, 25.3, 25.4_

- [x] 4.4 Write property test for VS Mode time calculation

  - **Property 35: VS Mode Completion Time Calculation**
  - **Validates: Requirements 18.3**

- [x] 4.4b Write property test for VS Mode explanation time exclusion

  - **Property 48b: VS Mode Explanation Time Exclusion**
  - **Validates: Requirements 18.5, 22.3**

- [ ]\* 4.5 Write property test for VS Mode score-first winner determination

  - **Property 38: VS Mode Score-First Winner Determination**
  - **Validates: Requirements 19.4**

- [ ]\* 4.6 Write property test for VS Mode time-based tiebreaker

  - **Property 39: VS Mode Time-Based Tiebreaker**
  - **Validates: Requirements 19.1, 19.2**

- [ ]\* 4.7 Write property test for VS Mode time formatting

  - **Property 42: VS Mode Time Formatting**
  - **Validates: Requirements 20.2**

- [ ]\* 4.8 Write property test for VS Mode elapsed time accumulation

  - **Property 48: VS Mode Elapsed Time Accumulation**
  - **Validates: Requirements 22.5, 22.2**

- [x] 5. Update home screen for daily progress
- [x] 5.1 Replace XP display with daily progress

  - Show "X/Y questions" progress bar
  - Show current streak with fire icon
  - Show streak points total
  - Remove level and XP displays
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 5.2 Add daily goal completion indicator

  - Show checkmark when goal met
  - Show celebration animation on goal completion
  - _Requirements: 5.4_

- [x] 6. Update leaderboard for streak points
- [x] 6.1 Change leaderboard query to sort by streakPoints

  - Query users collection ordered by streakPoints DESC
  - Remove weekly reset logic
  - Show current streak alongside streak points
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 6.2 Update leaderboard UI

  - Display streak points instead of weekly XP
  - Show current streak for each user
  - Show user's rank
  - Handle users with 0 points
  - _Requirements: 7.5_

- [x] 6.3 Display head-to-head statistics for friends

  - For each friend on leaderboard, show head-to-head record (e.g., "5-3-1")
  - Indicate if user is leading, tied, or trailing
  - Format as "vs You: X-Y-Z" where X=their wins, Y=their losses, Z=ties
  - _Requirements: 15a.3, 15a.4_

- [x] 7. Update settings screen for daily goal
- [x] 7.1 Add daily goal adjustment control

  - Slider or number input (1-50 range)
  - Show current value
  - Validate input before saving
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 7.2 Implement daily goal save logic

  - Call UserService.updateDailyGoal
  - Show error for invalid values
  - Show success confirmation
  - _Requirements: 9.4, 9.5_

- [x] 8. Update friends screen for duel challenges
- [x] 8.1 Display friend avatars prominently

  - Show avatar images in friend list
  - Make avatars tappable
  - _Requirements: 10.1_

- [x] 8.2 Implement duel challenge flow

  - Tap avatar to initiate challenge
  - Show confirmation dialog
  - Call DuelService.createDuel
  - Show success/error feedback
  - _Requirements: 10.2, 10.3_

- [x] 8.3 Add pending duel indicators

  - Show badge on friends with pending challenges
  - Display pending challenge count
  - _Requirements: 10.4, 10.5, 14.1_

- [x] 8.4 Display head-to-head statistics on friends screen

  - Show win-loss-tie record for each friend
  - Display "You: X, Them: Y" format
  - Show total duels completed
  - _Requirements: 15a.3, 15a.4_

- [x] 9. Create duel screens
- [x] 9.1 Create duel challenge acceptance screen

  - Show challenger's name and avatar
  - Display accept/decline buttons
  - Call DuelService.acceptDuel or declineDuel
  - Navigate to duel question screen on accept
  - _Requirements: 11.1, 11.2, 11.3_

- [x] 9.2 Create duel question screen

  - Reuse quiz question UI components
  - Show "Duel with [opponent]" header
  - Display question counter (1/5, 2/5, etc.)
  - Show explanation after each answer
  - Track answers in DuelModel format
  - _Requirements: 12.1, 12.2, 16.1, 16.2, 16.3_

- [x] 9.3 Implement duel question submission

  - Call DuelService.submitAnswer after each question
  - Navigate to explanation screen
  - Track explanation views
  - Continue to next question or completion
  - _Requirements: 12.3, 12.4, 17.4_

- [x] 9.4 Create duel results screen

  - Show both participants' avatars and names
  - Display scores side-by-side
  - Show question-by-question breakdown
  - Highlight winner or show tie
  - Display "Results available" notification
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 14.5_

- [x] 10. Update VSModeQuizScreen for explanations and timing
- [x] 10.1 Remove inline explanation display

  - Remove \_showExplanation flag
  - Remove explanation UI from quiz screen
  - _Requirements: 16.1, 17.1_

- [x] 10.2 Implement time tracking in VS Mode

  - Add \_questionStartTime field (tracks current question start)
  - Record start time when question is displayed (initState and after explanation)
  - Record end time when answer is submitted (before explanation)
  - Call VSModeService.recordQuestionStart when question displays
  - Call VSModeService.recordQuestionEnd when answer submitted
  - Timer pauses during explanation screens
  - _Requirements: 18.1, 18.2, 18.5, 22.1, 22.2, 22.3_

- [x] 10.3 Navigate to explanation screen after each answer

  - Stop timer before navigating to explanation
  - Pass isVSMode: true flag
  - Pass question, isCorrect, isLastQuestion
  - Handle return from explanation
  - Track explanation views
  - Restart timer when next question displays
  - _Requirements: 16.4, 16.5, 17.4, 18.5, 22.3_

- [x] 10.4 Update navigation flow

  - After explanation: next question or handoff/results
  - Pass session with timing data to handoff/results
  - _Requirements: 26.1, 26.2, 26.3_

- [x] 11. Update QuizExplanationScreen for VS Mode
- [x] 11.1 Add VS Mode support flag

  - Accept isVSMode parameter in arguments
  - Skip user stat updates when isVSMode is true
  - Adjust button text based on mode
  - _Requirements: 17.1, 17.2, 17.3, 17.5_

- [x] 11.2 Maintain consistent UI

  - Use same layout and styling
  - Show same information fields
  - Display source links and tips
  - _Requirements: 16.2, 16.3, 17.2, 17.3_

- [x] 12. Update VSModeResultScreen for time display
- [x] 12.1 Display completion times

  - Show formatted time (MM:SS) for each player
  - Highlight faster time with icon
  - Handle missing times for old sessions
  - _Requirements: 20.1, 20.2, 20.4, 24.2_

- [x] 12.2 Show tiebreaker indicator

  - Display "Won by speed!" when wonByTime is true
  - Display "Perfect Tie!" when scores and times equal
  - _Requirements: 20.3, 20.5_

- [x] 12.3 Update results layout

  - Show scores and times side-by-side
  - Display question breakdown
  - Show winner/tie status clearly
  - _Requirements: 26.5_

- [x] 13. Implement data migration
- [x] 13.1 Create migration script

  - Preserve existing streak data
  - Preserve question state data
  - Remove XP-related fields
  - Initialize new fields with defaults
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 13.2 Test migration on sample data

  - Create test users with old schema
  - Run migration
  - Verify all fields correct
  - Verify no data loss

- [x] 13.3 Deploy migration to production

  - Backup database before migration
  - Run migration script
  - Verify all users migrated successfully
  - Monitor for errors

- [x] 14. Update Firestore indexes
- [x] 14.1 Create streak points index

  - Index: users collection, streakPoints DESC
  - _Requirements: 7.1_

- [x] 14.2 Create duel indexes

  - Index: duels collection, challengerId + status
  - Index: duels collection, opponentId + status
  - Index: duels collection, status + createdAt
  - _Requirements: 15.4_

- [x] 15. Update Firestore security rules
- [x] 15.1 Add duel collection rules

  - Allow read for participants
  - Allow update for participants (MVP)
  - Document future Cloud Function rules
  - _Requirements: 23.3_

- [x] 15.2 Update user collection rules

  - Ensure users can update their own daily goal
  - Ensure users can update their own stats

- [x] 16. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Property-based tests are marked with \* and are optional for MVP
- All core functionality must be implemented and working
- Migration should be tested thoroughly before production deployment
- Firestore indexes may take time to build in production
- Consider feature flags for gradual rollout of new features
