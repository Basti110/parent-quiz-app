# Requirements Document

## Introduction

This specification defines a simplified gamification system for the parent quiz app that removes the XP-based progression in favor of a streak-based system focused on daily goals, question mastery, and consistent engagement.

## Glossary

- **System**: The parent quiz application
- **User**: A parent using the quiz application
- **Daily Goal**: The target number of questions a user aims to answer per day (adjustable, default 10)
- **Streak**: Consecutive days where the user meets their daily goal
- **Streak Points**: Points earned for maintaining consecutive day streaks
- **Mastered Question**: A question answered correctly 3 or more times
- **Question State**: Tracking data for each question per user (seen count, correct count, mastery status)
- **Duel**: An asynchronous competitive quiz challenge between two friends consisting of 5 questions
- **Challenger**: The user who initiates a duel
- **Opponent**: The user who receives and accepts a duel challenge
- **Duel Status**: The current state of a duel (pending, accepted, in-progress, completed)
- **Head-to-Head Record**: Win-loss-tie statistics between two specific friends (e.g., "5-3-1" means 5 wins, 3 losses, 1 tie)

## Requirements

### Requirement 1: Daily Goal Management

**User Story:** As a user, I want to set and adjust my daily question goal, so that I can customize the app to fit my schedule and commitment level.

#### Acceptance Criteria

1. WHEN a user first registers THEN the System SHALL set the daily goal to 10 questions
2. WHEN a user accesses settings THEN the System SHALL display the current daily goal value
3. WHEN a user modifies the daily goal in settings THEN the System SHALL accept values between 1 and 50 questions
4. WHEN a user saves a new daily goal THEN the System SHALL persist the value to the user profile
5. WHEN a user completes questions THEN the System SHALL track progress toward the current daily goal

### Requirement 2: Streak Tracking

**User Story:** As a user, I want to build and maintain daily streaks, so that I stay motivated to use the app consistently.

#### Acceptance Criteria

1. WHEN a user meets their daily goal for the first time THEN the System SHALL set the current streak to 1
2. WHEN a user meets their daily goal on consecutive days THEN the System SHALL increment the current streak by 1
3. WHEN a user fails to meet their daily goal for a calendar day THEN the System SHALL reset the current streak to 0
4. WHEN a user achieves a new highest streak THEN the System SHALL update the longest streak value
5. WHILE tracking streaks THEN the System SHALL use calendar days based on the user's local timezone

### Requirement 3: Streak Points Calculation

**User Story:** As a user, I want to earn streak points for maintaining consecutive days, so that I can see tangible rewards for my consistency.

#### Acceptance Criteria

1. WHEN a user completes 3 consecutive days of meeting their daily goal THEN the System SHALL award 3 streak points
2. WHEN a user completes each additional consecutive day after day 3 THEN the System SHALL award 3 streak points per day
3. WHEN a user completes day 1 or day 2 of a streak THEN the System SHALL award 0 streak points
4. WHEN streak points are awarded THEN the System SHALL add them to the user's total streak points
5. WHEN a streak is broken THEN the System SHALL continue tracking total streak points without reduction

### Requirement 4: Question Statistics Tracking

**User Story:** As a user, I want to see how many questions I've answered correctly and mastered, so that I can track my learning progress.

#### Acceptance Criteria

1. WHEN a user answers a question correctly THEN the System SHALL increment the total correct answers count
2. WHEN a user answers a question incorrectly THEN the System SHALL not increment the total correct answers count
3. WHEN a user answers any question THEN the System SHALL increment the total questions answered count
4. WHEN a user's correct count for a specific question reaches 3 THEN the System SHALL mark that question as mastered
5. WHEN displaying statistics THEN the System SHALL show total questions answered, total correct answers, and total mastered questions

### Requirement 5: Daily Progress Display

**User Story:** As a user, I want to see my progress toward my daily goal, so that I know how many more questions I need to answer today.

#### Acceptance Criteria

1. WHEN a user views the home screen THEN the System SHALL display the number of questions answered today
2. WHEN a user views the home screen THEN the System SHALL display the daily goal target
3. WHEN a user views the home screen THEN the System SHALL display a visual progress indicator showing completion percentage
4. WHEN a user meets their daily goal THEN the System SHALL display a completion indicator
5. WHEN a new calendar day begins THEN the System SHALL reset the daily progress counter to 0

### Requirement 6: User Profile Updates

**User Story:** As a user, I want my profile to reflect the new gamification metrics, so that the system accurately represents my progress.

#### Acceptance Criteria

1. WHEN storing user data THEN the System SHALL include daily goal, current streak, longest streak, and total streak points
2. WHEN storing user data THEN the System SHALL include total questions answered, total correct answers, and total mastered questions
3. WHEN storing user data THEN the System SHALL include the last active date for streak calculation
4. WHEN storing user data THEN the System SHALL include the count of questions answered today
5. WHEN a user profile is created THEN the System SHALL initialize all gamification fields with appropriate default values

### Requirement 7: Leaderboard Adaptation

**User Story:** As a user, I want to see how my streak points compare to other users, so that I can engage in friendly competition.

#### Acceptance Criteria

1. WHEN displaying the leaderboard THEN the System SHALL rank users by total streak points in descending order
2. WHEN displaying the leaderboard THEN the System SHALL show each user's current streak
3. WHEN displaying the leaderboard THEN the System SHALL show each user's total streak points
4. WHEN displaying the leaderboard THEN the System SHALL show the current user's rank
5. WHEN a user has no streak points THEN the System SHALL display them on the leaderboard with 0 points

### Requirement 8: Migration from XP System

**User Story:** As a system administrator, I want to migrate existing users from the XP system to the new streak system, so that users can continue using the app without data loss.

#### Acceptance Criteria

1. WHEN migrating user data THEN the System SHALL preserve existing streak data (current streak, longest streak)
2. WHEN migrating user data THEN the System SHALL preserve question state data (seen count, correct count, mastered status)
3. WHEN migrating user data THEN the System SHALL remove XP-related fields (totalXp, currentLevel, weeklyXpCurrent)
4. WHEN migrating user data THEN the System SHALL initialize streak points to 0 for all users
5. WHEN migrating user data THEN the System SHALL set daily goal to 10 for all existing users

### Requirement 9: Settings Screen Updates

**User Story:** As a user, I want to adjust my daily goal in the settings screen, so that I can easily customize my experience.

#### Acceptance Criteria

1. WHEN a user opens settings THEN the System SHALL display a daily goal adjustment control
2. WHEN a user adjusts the daily goal slider or input THEN the System SHALL show the new value in real-time
3. WHEN a user saves settings THEN the System SHALL validate the daily goal is between 1 and 50
4. WHEN a user saves an invalid daily goal THEN the System SHALL display an error message and prevent saving
5. WHEN a user saves a valid daily goal THEN the System SHALL update the user profile and confirm success

### Requirement 10: Asynchronous Duel System

**User Story:** As a user, I want to challenge my friends to duels and complete them at my own pace, so that we can compete without needing to be online at the same time.

#### Acceptance Criteria

1. WHEN a user views their friends list THEN the System SHALL display each friend's avatar
2. WHEN a user taps on a friend's avatar THEN the System SHALL initiate a duel challenge
3. WHEN a duel challenge is created THEN the System SHALL send a notification to the challenged friend
4. WHEN a friend receives a duel challenge THEN the System SHALL display a pending challenge indicator
5. WHEN a friend views a pending challenge THEN the System SHALL show the challenger's name and avatar

### Requirement 11: Duel Challenge Acceptance

**User Story:** As a user, I want to accept or decline duel challenges from friends, so that I can control when I participate in competitive gameplay.

#### Acceptance Criteria

1. WHEN a user views a pending duel challenge THEN the System SHALL display accept and decline options
2. WHEN a user accepts a duel challenge THEN the System SHALL change the duel status to accepted
3. WHEN a user declines a duel challenge THEN the System SHALL remove the challenge and notify the challenger
4. WHEN a duel is accepted THEN the System SHALL generate 5 random questions for the duel
5. WHEN questions are generated THEN the System SHALL ensure both participants receive the same questions in the same order

### Requirement 12: Duel Question Completion

**User Story:** As a user, I want to answer duel questions at my own pace, so that I can participate in duels when convenient for me.

#### Acceptance Criteria

1. WHEN a user starts an accepted duel THEN the System SHALL present 5 questions sequentially
2. WHEN a user answers a duel question THEN the System SHALL record the answer and whether it was correct
3. WHEN a user completes all 5 duel questions THEN the System SHALL mark their participation as complete
4. WHEN a user exits mid-duel THEN the System SHALL save their progress and allow resumption
5. WHILE a duel is in progress THEN the System SHALL not reveal the opponent's answers or score

### Requirement 13: Duel Results Display

**User Story:** As a user, I want to see a comparison of my performance against my friend after we both complete the duel, so that I can see who performed better.

#### Acceptance Criteria

1. WHEN both participants complete the duel THEN the System SHALL display a comparison screen
2. WHEN displaying duel results THEN the System SHALL show each participant's avatar, name, and score
3. WHEN displaying duel results THEN the System SHALL show a question-by-question breakdown with both participants' answers
4. WHEN displaying duel results THEN the System SHALL highlight the winner or indicate a tie
5. WHEN displaying duel results THEN the System SHALL show which answers were correct or incorrect for both participants

### Requirement 14: Duel Notifications

**User Story:** As a user, I want to receive notifications about duel status changes, so that I know when to take action.

#### Acceptance Criteria

1. WHEN a user receives a duel challenge THEN the System SHALL display a notification indicator
2. WHEN a duel challenge is accepted THEN the System SHALL notify the challenger
3. WHEN a duel challenge is declined THEN the System SHALL notify the challenger
4. WHEN an opponent completes their duel questions THEN the System SHALL notify the other participant
5. WHEN both participants complete the duel THEN the System SHALL notify both users that results are available

### Requirement 15: Duel State Management

**User Story:** As a user, I want the system to track all my active and completed duels, so that I can manage multiple challenges simultaneously.

#### Acceptance Criteria

1. WHEN storing duel data THEN the System SHALL include challenger ID, opponent ID, status, and creation timestamp
2. WHEN storing duel data THEN the System SHALL include the 5 question IDs and both participants' answers
3. WHEN storing duel data THEN the System SHALL track completion status for each participant separately
4. WHEN a user has multiple active duels THEN the System SHALL display all pending and in-progress duels
5. WHEN a duel is completed by both participants THEN the System SHALL archive the duel after 7 days

### Requirement 15a: Head-to-Head Duel Statistics

**User Story:** As a user, I want to see my win-loss record against each friend, so that I can track my competitive performance with specific friends.

#### Acceptance Criteria

1. WHEN storing friendship data THEN the System SHALL include head-to-head duel statistics (myWins, theirWins, ties, totalDuels)
2. WHEN a duel is completed THEN the System SHALL update both users' friendship documents with the result
3. WHEN displaying a friend on the leaderboard THEN the System SHALL show the head-to-head record (e.g., "5-3-1")
4. WHEN displaying a friend's profile THEN the System SHALL show how many times I won against them and how many times they won against me
5. WHEN initializing a new friendship THEN the System SHALL set all head-to-head statistics to 0

### Requirement 16: VS Mode Explanation Screens

**User Story:** As a VS Mode player, I want to see explanations after answering each question, so that I can learn from my answers just like in solo mode.

#### Acceptance Criteria

1. WHEN a player answers a question in VS Mode THEN the System SHALL display the explanation screen showing whether the answer was correct or incorrect
2. WHEN the explanation screen is displayed THEN the System SHALL show the question text, correct answer, and explanation text
3. WHEN the explanation screen is displayed THEN the System SHALL show any available source links or tips
4. WHEN a player views the explanation screen THEN the System SHALL provide a "Continue" or "Next" button to proceed
5. WHEN a player taps the continue button THEN the System SHALL advance to the next question or handoff screen

### Requirement 17: VS Mode Explanation Consistency

**User Story:** As a user, I want the VS Mode explanation experience to match solo mode, so that the app feels consistent across different play modes.

#### Acceptance Criteria

1. WHEN displaying explanations in VS Mode THEN the System SHALL use the same explanation screen component as solo mode
2. WHEN displaying explanations in VS Mode THEN the System SHALL show the same information fields as solo mode
3. WHEN displaying explanations in VS Mode THEN the System SHALL use the same visual layout and styling as solo mode
4. WHEN a player reads an explanation THEN the System SHALL track that the explanation was viewed for XP calculation purposes
5. WHEN transitioning between questions THEN the System SHALL maintain the same flow pattern as solo mode

### Requirement 18: VS Mode Completion Time Tracking

**User Story:** As a VS Mode player, I want my completion time to be tracked only during question answering, so that ties can be resolved fairly based on answering speed rather than explanation reading speed.

#### Acceptance Criteria

1. WHEN a player's first question is displayed THEN the System SHALL record the start timestamp
2. WHEN a player submits an answer to their last question THEN the System SHALL record the end timestamp
3. WHEN both timestamps are recorded THEN the System SHALL calculate the total completion time in seconds
4. WHEN storing VS Mode results THEN the System SHALL save the completion time for each player
5. WHILE a player is viewing explanation screens THEN the System SHALL NOT include that time in the completion time calculation

### Requirement 19: VS Mode Time-Based Tiebreaker

**User Story:** As a VS Mode player, I want ties to be resolved by completion time, so that there is always a clear winner and the game feels more competitive.

#### Acceptance Criteria

1. WHEN both players have equal scores THEN the System SHALL compare their completion times
2. WHEN completion times differ THEN the System SHALL declare the player with the shorter completion time as the winner
3. WHEN completion times are identical THEN the System SHALL declare a tie
4. WHEN determining the winner THEN the System SHALL first compare scores, then completion times if scores are equal
5. WHEN a winner is determined by time THEN the System SHALL indicate this in the results display

### Requirement 20: VS Mode Results Display

**User Story:** As a VS Mode player, I want to see completion times on the results screen, so that I understand how the winner was determined.

#### Acceptance Criteria

1. WHEN displaying VS Mode results THEN the System SHALL show each player's score and completion time
2. WHEN displaying VS Mode results THEN the System SHALL format completion time in minutes and seconds (e.g., "2:34")
3. WHEN a winner is determined by tiebreaker THEN the System SHALL display a message indicating the winner was faster
4. WHEN displaying completion times THEN the System SHALL highlight the faster time visually
5. WHEN both players have the same score and time THEN the System SHALL display "Perfect Tie!" message

### Requirement 21: VS Mode Data Model Updates

**User Story:** As a developer, I want the VS Mode data model to include completion times, so that the system can properly track and compare player performance.

#### Acceptance Criteria

1. WHEN storing VS Mode session data THEN the System SHALL include challengerTimeSeconds field
2. WHEN storing VS Mode session data THEN the System SHALL include opponentTimeSeconds field
3. WHEN storing VS Mode session data THEN the System SHALL ensure time values are non-negative integers
4. WHEN retrieving VS Mode session data THEN the System SHALL load both score and time data for each player
5. WHEN a VS Mode session is incomplete THEN the System SHALL store null or 0 for completion times until both players finish

### Requirement 22: VS Mode Timer Accuracy

**User Story:** As a VS Mode player, I want the timer to accurately reflect my question-answering performance, so that tiebreakers are fair.

#### Acceptance Criteria

1. WHEN timing a player's session THEN the System SHALL use high-precision timestamps (millisecond accuracy)
2. WHEN calculating completion time THEN the System SHALL accumulate only the time spent on question screens, excluding explanation screens
3. WHEN a player views an explanation THEN the System SHALL pause the timer until the next question is displayed
4. WHEN a player returns to a question screen THEN the System SHALL resume timing
5. WHEN storing time data THEN the System SHALL accumulate elapsed seconds across all questions for each player

### Requirement 23: VS Mode Client-Side Implementation

**User Story:** As a developer, I want the VS Mode logic implemented client-side for MVP while maintaining a data structure that can transition to Cloud Functions later, so that we can scale without major refactoring.

#### Acceptance Criteria

1. WHEN implementing VS Mode logic THEN the System SHALL execute all game logic, timing, and winner determination on the client
2. WHEN storing VS Mode data THEN the System SHALL structure documents to support future Cloud Function triggers
3. WHEN writing VS Mode results THEN the System SHALL use Firestore security rules that allow users to write their own session data
4. WHEN designing the data model THEN the System SHALL separate user-writable fields from future computed fields
5. WHEN implementing winner determination THEN the System SHALL use logic that can be easily moved to a Cloud Function in future iterations

### Requirement 24: VS Mode Backward Compatibility

**User Story:** As a developer, I want the changes to be backward compatible with existing VS Mode sessions, so that the app doesn't break for users mid-game.

#### Acceptance Criteria

1. WHEN loading an old VS Mode session without time data THEN the System SHALL handle missing time fields gracefully
2. WHEN displaying results for old sessions THEN the System SHALL show scores without time information
3. WHEN comparing old sessions THEN the System SHALL use score-only comparison without tiebreaker
4. WHEN migrating to the new system THEN the System SHALL not require data migration for completed sessions
5. WHEN creating new VS Mode sessions THEN the System SHALL always include time tracking fields

### Requirement 25: VS Mode XP Calculation

**User Story:** As a VS Mode player, I want to earn appropriate XP based on whether I view explanations, so that the XP system remains consistent with solo mode.

#### Acceptance Criteria

1. WHEN a player answers correctly in VS Mode THEN the System SHALL award 10 XP
2. WHEN a player answers incorrectly and views the explanation THEN the System SHALL award 5 XP
3. WHEN a player answers incorrectly and skips the explanation THEN the System SHALL award 2 XP
4. WHEN calculating session XP THEN the System SHALL apply the same bonuses as solo mode (session completion, perfect score)
5. WHEN a VS Mode session ends THEN the System SHALL update only the logged-in user's XP and stats

### Requirement 26: VS Mode UI Flow

**User Story:** As a user, I want the VS Mode flow to feel natural with explanation screens, so that the experience is smooth and intuitive.

#### Acceptance Criteria

1. WHEN a player completes a question THEN the System SHALL transition smoothly to the explanation screen
2. WHEN a player finishes viewing an explanation THEN the System SHALL show clear navigation to the next step
3. WHEN the last question's explanation is viewed THEN the System SHALL transition to the handoff screen (for Player A) or results screen (for Player B)
4. WHEN displaying the handoff screen THEN the System SHALL indicate that Player A has completed their questions including explanations
5. WHEN both players complete their sessions THEN the System SHALL display the results screen with scores and times
