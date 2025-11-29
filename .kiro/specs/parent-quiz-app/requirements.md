# Requirements Document

## Introduction

ParentQuiz is an evidence-based, gamified quiz application for parents built with Flutter and Firebase. The app helps parents learn about child development, media usage, sleep, bonding, and other parenting topics through short quiz sessions. Users earn XP, maintain streaks, progress through levels, and compete on leaderboards. The MVP (Phase 2) includes Firebase backend integration without Cloud Functions, featuring solo quiz mode, pass-and-play VS mode, and a friends system.

## Glossary

- **ParentQuiz**: The mobile quiz application system
- **User**: A registered parent using the application
- **Quiz Session**: A single round of questions (5 or 10 questions)
- **Category**: A topic area for quiz questions (e.g., "Development 0-6 months", "Sleep", "Media")
- **Question State**: User-specific data tracking how many times a question has been seen and answered correctly
- **XP (Experience Points)**: Points earned through quiz participation and correct answers
- **Streak**: Consecutive days a user has completed at least one quiz session
- **Mastery**: Achievement status when a user answers a question correctly 3+ times
- **Weekly Leaderboard**: Ranking of users based on XP earned in the current 7-day rolling window
- **VS Mode**: Pass-and-play competitive mode where two players alternate on the same device
- **Friend Code**: Unique alphanumeric code used to add friends
- **Firebase Auth**: Authentication service for user login and registration
- **Cloud Firestore**: NoSQL database storing all application data
- **Solo Mode**: Single-player quiz mode where users answer questions individually

## Requirements

### Requirement 1

**User Story:** As a new user, I want to register with my name and email, so that I can create an account and start using the app.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time THEN the ParentQuiz SHALL display onboarding screens explaining the app purpose
2. WHEN a user completes onboarding THEN the ParentQuiz SHALL present login and registration options
3. WHEN a user provides name, email, and password for registration THEN the ParentQuiz SHALL create a Firebase Auth account and user document
4. WHEN a user document is created THEN the ParentQuiz SHALL generate a unique 6-8 character friend code for that user
5. WHEN registration succeeds THEN the ParentQuiz SHALL navigate the user to the home screen

### Requirement 2

**User Story:** As a returning user, I want to log in with my credentials, so that I can access my progress and continue learning.

#### Acceptance Criteria

1. WHEN a user enters valid email and password THEN the ParentQuiz SHALL authenticate via Firebase Auth and load user data
2. WHEN authentication succeeds THEN the ParentQuiz SHALL update the lastActiveAt timestamp in the user document
3. WHEN authentication fails THEN the ParentQuiz SHALL display an error message and keep the user on the login screen
4. WHEN a user is already authenticated THEN the ParentQuiz SHALL navigate directly to the home screen on app launch

### Requirement 3

**User Story:** As a user, I want to see available quiz categories on the home screen, so that I can choose topics that interest me.

#### Acceptance Criteria

1. WHEN a user reaches the home screen THEN the ParentQuiz SHALL display a "Play" button, "VS Mode" button, and progress section
2. WHEN a user taps the "Play" button THEN the ParentQuiz SHALL load and display all active categories from the category collection
3. WHEN categories are displayed THEN the ParentQuiz SHALL show title, description, and icon for each category
4. WHEN a user selects a category THEN the ParentQuiz SHALL present quiz length options (5 or 10 questions)

### Requirement 4

**User Story:** As a user, I want to answer quiz questions and receive immediate feedback, so that I can learn from my responses.

#### Acceptance Criteria

1. WHEN a quiz session starts THEN the ParentQuiz SHALL select questions prioritizing unseen questions (seenCount = 0) from the chosen category
2. WHEN no unseen questions exist THEN the ParentQuiz SHALL select questions with the oldest lastSeenAt timestamp
3. WHEN a question is displayed THEN the ParentQuiz SHALL show question text and 3-4 answer options
4. WHEN a user selects an answer THEN the ParentQuiz SHALL immediately indicate whether the answer is correct or incorrect
5. WHEN an answer is submitted THEN the ParentQuiz SHALL display the explanation text and optional source link
6. WHEN a question is answered THEN the ParentQuiz SHALL update the questionStates subcollection with incremented seenCount and correctCount (if correct)

### Requirement 5

**User Story:** As a user, I want to earn XP for participating in quizzes, so that I feel motivated to continue learning.

#### Acceptance Criteria

1. WHEN a user answers a question correctly THEN the ParentQuiz SHALL award 10 XP
2. WHEN a user answers incorrectly and views the explanation THEN the ParentQuiz SHALL award 5 XP
3. WHEN a user answers incorrectly without viewing the explanation THEN the ParentQuiz SHALL award 2 XP
4. WHEN a user completes a 5-question session THEN the ParentQuiz SHALL award a 10 XP bonus
5. WHEN a user completes a 10-question session THEN the ParentQuiz SHALL award a 25 XP bonus
6. WHEN a user answers all questions correctly in a session THEN the ParentQuiz SHALL award an additional 10 XP bonus
7. WHEN a session ends THEN the ParentQuiz SHALL update totalXp and weeklyXpCurrent in the user document

### Requirement 6

**User Story:** As a user, I want to maintain a daily streak, so that I stay motivated to practice regularly.

#### Acceptance Criteria

1. WHEN a user completes at least one quiz session on a calendar day THEN the ParentQuiz SHALL update lastActiveAt to the current date
2. WHEN lastActiveAt equals yesterday's date THEN the ParentQuiz SHALL increment streakCurrent by 1
3. WHEN lastActiveAt is more than 1 day ago THEN the ParentQuiz SHALL reset streakCurrent to 1
4. WHEN streakCurrent exceeds streakLongest THEN the ParentQuiz SHALL update streakLongest to match streakCurrent
5. WHEN a user views their progress THEN the ParentQuiz SHALL display both streakCurrent and streakLongest

### Requirement 7

**User Story:** As a user, I want to see my level and progress, so that I can track my learning journey.

#### Acceptance Criteria

1. WHEN a user earns XP THEN the ParentQuiz SHALL calculate currentLevel based on totalXp (100 XP per level)
2. WHEN a user views their progress THEN the ParentQuiz SHALL display totalXp, currentLevel, and progress toward next level
3. WHEN a question reaches correctCount of 3 or more THEN the ParentQuiz SHALL mark mastered as true in questionStates
4. WHEN a user views category progress THEN the ParentQuiz SHALL calculate and display mastery percentage for each category

### Requirement 8

**User Story:** As a user, I want to see a weekly leaderboard, so that I can compare my performance with other active players.

#### Acceptance Criteria

1. WHEN a quiz session ends THEN the ParentQuiz SHALL check if the session falls within the current week starting from weeklyXpWeekStart
2. WHEN the session is within the current week THEN the ParentQuiz SHALL add session XP to weeklyXpCurrent
3. WHEN the session is in a new week THEN the ParentQuiz SHALL reset weeklyXpCurrent to the session XP and update weeklyXpWeekStart to the current week's Monday
4. WHEN a user views the leaderboard THEN the ParentQuiz SHALL query the user collection sorted by weeklyXpCurrent in descending order
5. WHEN the leaderboard is displayed THEN the ParentQuiz SHALL show the current user's rank and the top 50 players

### Requirement 9

**User Story:** As a user, I want to play a pass-and-play VS mode with another person, so that I can compete with my partner or friend.

#### Acceptance Criteria

1. WHEN a user taps "VS Mode" THEN the ParentQuiz SHALL display category selection and quiz length options (5 or 10 questions per player)
2. WHEN quiz settings are selected THEN the ParentQuiz SHALL prompt for two player names with defaults (current user's name and editable second name)
3. WHEN player names are confirmed THEN the ParentQuiz SHALL start Player A's question sequence
4. WHEN Player A completes their questions THEN the ParentQuiz SHALL display a handoff screen prompting to pass the device to Player B
5. WHEN Player B completes their questions THEN the ParentQuiz SHALL display results showing each player's score and declare a winner
6. WHEN the logged-in user wins a duel THEN the ParentQuiz SHALL increment duelsPlayed, duelsWon, and add 3 to duelPoints
7. WHEN the logged-in user ties a duel THEN the ParentQuiz SHALL increment duelsPlayed and add 1 to duelPoints
8. WHEN the logged-in user loses a duel THEN the ParentQuiz SHALL increment duelsPlayed and duelsLost

### Requirement 10

**User Story:** As a user, I want to add friends using a friend code, so that I can compare progress with people I know.

#### Acceptance Criteria

1. WHEN a user navigates to the friends screen THEN the ParentQuiz SHALL display the user's own friend code and an "Add Friend" button
2. WHEN a user taps "Add Friend" THEN the ParentQuiz SHALL prompt for a friend code input
3. WHEN a user enters a friend code THEN the ParentQuiz SHALL query the user collection where friendCode equals the input
4. WHEN a matching user is found THEN the ParentQuiz SHALL create a friend document in the current user's friends subcollection with status "accepted"
5. WHEN a friend is added THEN the ParentQuiz SHALL display the friend in the friends list
6. WHEN a user views the friends leaderboard THEN the ParentQuiz SHALL load all friend user documents and display them sorted by weeklyXpCurrent

### Requirement 11

**User Story:** As a developer, I want all user data stored in Firestore with a clear schema, so that the app can scale and be extended with Cloud Functions later.

#### Acceptance Criteria

1. WHEN a user is created THEN the ParentQuiz SHALL store a document at user/{userId} with fields: displayName, email, createdAt, lastActiveAt, friendCode, totalXp, currentLevel, weeklyXpCurrent, weeklyXpWeekStart, streakCurrent, streakLongest, duelsPlayed, duelsWon, duelsLost, duelPoints
2. WHEN a question is answered THEN the ParentQuiz SHALL store or update a document at user/{userId}/questionStates/{questionId} with fields: questionId, seenCount, correctCount, lastSeenAt, mastered
3. WHEN a friend is added THEN the ParentQuiz SHALL store a document at user/{userId}/friends/{friendUserId} with fields: friendUserId, status, createdAt, createdBy
4. WHEN categories are loaded THEN the ParentQuiz SHALL read from the category collection with fields: title, description, order, iconName, isPremium
5. WHEN questions are loaded THEN the ParentQuiz SHALL read from the question collection with fields: categoryId, text, options, correctIndices (list supporting multiple correct answers), explanation, sourceLabel, sourceUrl, difficulty, isActive

### Requirement 12

**User Story:** As a user, I want a modern but simple UI design, so that I can focus on learning without visual distractions.

#### Acceptance Criteria

1. WHEN any screen is displayed THEN the ParentQuiz SHALL use standard Flutter Material Design components
2. WHEN UI elements are rendered THEN the ParentQuiz SHALL maintain consistent spacing and alignment using standard Flutter layouts
3. WHEN the app is used THEN the ParentQuiz SHALL provide a clean, minimal interface without custom theming or complex visual effects
4. WHEN navigation occurs THEN the ParentQuiz SHALL use standard Flutter navigation patterns and transitions
5. WHEN forms are displayed THEN the ParentQuiz SHALL use standard TextFormField and button widgets with default styling
