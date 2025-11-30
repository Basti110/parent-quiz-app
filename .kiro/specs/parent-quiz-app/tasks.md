# Implementation Plan

- [x] 1. Setup project dependencies and Firebase configuration

  - Add required packages to pubspec.yaml: firebase_core, firebase_auth, cloud_firestore, flutter_riverpod
  - Configure Firebase for iOS and Android using firebase.ts credentials
  - Initialize Firebase in main.dart with ProviderScope
  - _Requirements: 11.1_

- [x] 2. Create data models

  - [x] 2.1 Implement UserModel with all fields and serialization
    - Create UserModel class with toMap() and fromMap() methods
    - Include all fields: displayName, email, friendCode, XP, streaks, duel stats
    - _Requirements: 11.1_
  - [ ]\* 2.2 Write property test for UserModel serialization
    - **Property 1: User document creation completeness**
    - **Validates: Requirements 1.3, 11.1**
  - [x] 2.3 Implement Category model
    - Create Category class with toMap() and fromMap()
    - _Requirements: 11.4_
  - [ ]\* 2.4 Write property test for Category structure
    - **Property 33: Category data structure**
    - **Validates: Requirements 11.4**
  - [x] 2.5 Implement Question model with multiple correct answers support
    - Create Question class with correctIndices list
    - Add helper methods: isSingleChoice, isMultipleChoice, isCorrectAnswer()
    - _Requirements: 11.5_
  - [ ]\* 2.6 Write property test for Question structure and validation
    - **Property 34: Question data structure**
    - **Property 35: Multiple correct answers validation**
    - **Validates: Requirements 11.5**
  - [x] 2.7 Implement QuestionState model
    - Create QuestionState class for tracking user progress per question
    - _Requirements: 11.2_
  - [ ]\* 2.8 Write property test for QuestionState structure
    - **Property 31: Question state structure**
    - **Validates: Requirements 11.2**
  - [x] 2.9 Implement Friend and WeeklyPoints models
    - Create Friend class for friends subcollection
    - Create WeeklyPoints class for history tracking
    - _Requirements: 11.3_
  - [ ]\* 2.10 Write property test for Friend document structure
    - **Property 32: Friend document structure**
    - **Validates: Requirements 11.3**

- [x] 3. Implement AuthService and authentication flow

  - [x] 3.1 Create AuthService with Firebase Auth integration
    - Implement registerWithEmail, signInWithEmail, signOut methods
    - Implement generateFriendCode() for unique 6-8 character codes
    - Add authStateChanges stream
    - _Requirements: 1.3, 1.4, 2.1_
  - [ ]\* 3.2 Write property test for friend code generation
    - **Property 2: Friend code format**
    - **Validates: Requirements 1.4**
  - [ ]\* 3.3 Write property test for authentication error handling
    - **Property 4: Authentication error handling**
    - **Validates: Requirements 2.3**
  - [x] 3.4 Create Riverpod providers for auth state
    - Implement authStateProvider and authServiceProvider
    - Implement currentUserIdProvider
    - _Requirements: 2.1, 2.2_
  - [ ]\* 3.5 Write property test for authentication timestamp update
    - **Property 3: Authentication timestamp update**
    - **Validates: Requirements 2.2**

- [x] 4. Build authentication UI screens

  - [x] 4.1 Create OnboardingScreen with introduction slides
    - Build simple onboarding flow explaining app purpose
    - _Requirements: 1.1, 1.2_
  - [x] 4.2 Create LoginScreen with email/password form
    - Build login form with validation
    - Handle authentication errors with user-friendly messages
    - _Requirements: 2.1, 2.3_
  - [x] 4.3 Create RegisterScreen with name, email, password fields
    - Build registration form with validation
    - Create user document in Firestore after successful registration
    - Navigate to home screen on success
    - _Requirements: 1.3, 1.5_

- [x] 5. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement UserService for user data management

  - [x] 6.1 Create UserService with Firestore operations
    - Implement getUserData, getUserStream methods
    - Implement updateStreak with date comparison logic
    - Implement calculateLevel (100 XP per level)
    - _Requirements: 6.1, 6.2, 6.3, 7.1_
  - [x] 6.2 Write property test for streak continuation
    - **Property 15: Streak continuation**
    - **Validates: Requirements 6.2**
  - [x] 6.3 Write property test for streak reset
    - **Property 16: Streak reset**
    - **Validates: Requirements 6.3**
  - [ ]\* 6.4 Write property test for longest streak invariant
    - **Property 17: Longest streak invariant**
    - **Validates: Requirements 6.4**
  - [ ]\* 6.5 Write property test for level calculation
    - **Property 18: Level calculation**
    - **Validates: Requirements 7.1**
  - [x] 6.6 Implement updateWeeklyXP with week rollover logic
    - Check if session is in current week
    - Reset weeklyXpCurrent if new week started
    - Save previous week to history subcollection
    - _Requirements: 8.1, 8.2, 8.3_
  - [x] 6.7 Write property test for weekly XP accumulation
    - **Property 21: Weekly XP accumulation**
    - **Validates: Requirements 8.2**
  - [x] 6.8 Write property test for weekly XP reset
    - **Property 22: Weekly XP reset**
    - **Validates: Requirements 8.3**
  - [x] 6.9 Implement updateQuestionState for mastery tracking
    - Increment seenCount and correctCount
    - Mark mastered when correctCount >= 3
    - _Requirements: 4.6, 7.3_
  - [ ]\* 6.10 Write property test for question state updates
    - **Property 7: Question state update on answer**
    - **Validates: Requirements 4.6**
  - [ ]\* 6.11 Write property test for mastery threshold
    - **Property 19: Question mastery threshold**
    - **Validates: Requirements 7.3**
  - [x] 6.12 Implement getCategoryMastery for progress calculation
    - Calculate percentage of mastered questions per category
    - _Requirements: 7.4_
  - [ ]\* 6.13 Write property test for category mastery calculation
    - **Property 20: Category mastery calculation**
    - **Validates: Requirements 7.4**
  - [x] 6.14 Create Riverpod providers for user data
    - Implement userDataProvider and userServiceProvider
    - _Requirements: 2.2, 6.1_

- [x] 7. Implement HistoryService for points tracking

  - [x] 7.1 Create HistoryService with weekly points persistence
    - Implement saveWeeklyPoints to store completed weeks
    - Implement getPointsHistory for retrieving historical data
    - _Requirements: 11.1_
  - [x] 7.2 Write property test for weekly points persistence
    - **Property 36: Weekly points persistence**
    - **Validates: Requirements 11.1**
  - [x] 7.3 Write property test for history date format
    - **Property 37: History date format**
    - **Validates: Requirements 11.1**

- [x] 8. Implement QuizService and question selection logic

  - [x] 8.1 Create QuizService with Firestore integration
    - Implement getCategories to load all active categories
    - _Requirements: 3.2, 11.4_
  - [x] 8.2 Implement question selection algorithm
    - Load questions for category where isActive = true
    - Load user's questionStates
    - Prioritize unseen questions (seenCount = 0)
    - Fallback to oldest lastSeenAt
    - Randomly select from prioritized pool
    - _Requirements: 4.1, 4.2_
  - [ ]\* 8.3 Write property test for unseen question prioritization
    - **Property 5: Unseen question prioritization**
    - **Validates: Requirements 4.1**
  - [ ]\* 8.4 Write property test for oldest question fallback
    - **Property 6: Oldest question fallback**
    - **Validates: Requirements 4.2**
  - [x] 8.5 Implement XP calculation logic
    - Correct answer: +10 XP
    - Incorrect + explanation viewed: +5 XP
    - Incorrect without explanation: +2 XP
    - Session bonuses: 5q (+10), 10q (+25), perfect (+10)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  - [ ]\* 8.6 Write property test for correct answer XP
    - **Property 8: Correct answer XP**
    - **Validates: Requirements 5.1**
  - [ ]\* 8.7 Write property test for incorrect answer XP (with explanation)
    - **Property 9: Incorrect answer with explanation XP**
    - **Validates: Requirements 5.2**
  - [ ]\* 8.8 Write property test for incorrect answer XP (without explanation)
    - **Property 10: Incorrect answer without explanation XP**
    - **Validates: Requirements 5.3**
  - [ ]\* 8.9 Write property test for 5-question session bonus
    - **Property 11: Five-question session bonus**
    - **Validates: Requirements 5.4**
  - [ ]\* 8.10 Write property test for 10-question session bonus
    - **Property 12: Ten-question session bonus**
    - **Validates: Requirements 5.5**
  - [ ]\* 8.11 Write property test for perfect session bonus
    - **Property 13: Perfect session bonus**
    - **Validates: Requirements 5.6**
  - [x] 8.12 Implement updateUserXP to persist XP gains
    - Update totalXp and weeklyXpCurrent
    - Update currentLevel based on totalXp
    - _Requirements: 5.7, 7.1_
  - [ ]\* 8.13 Write property test for session XP persistence
    - **Property 14: Session XP persistence**
    - **Validates: Requirements 5.7**
  - [x] 8.14 Create Riverpod providers for quiz state
    - Implement quizServiceProvider, activeQuizProvider, categoriesProvider
    - _Requirements: 3.2, 4.1_

- [x] 9. Build quiz UI screens

  - [x] 9.1 Create HomeScreen with navigation buttons
    - Display Play, VS Mode buttons
    - Show user progress: level, XP, streak
    - _Requirements: 3.1, 7.2_
  - [x] 9.2 Create CategorySelectionScreen
    - Display categories in grid/list with icons
    - Show title and description for each category
    - _Requirements: 3.2, 3.3_
  - [x] 9.3 Create QuizLengthScreen for session size selection
    - Offer 5 or 10 questions options
    - _Requirements: 3.4_
  - [x] 9.4 Create QuizScreen for question display and answering
    - Display question text and options
    - Support both single-choice (radio) and multiple-choice (checkbox)
    - Show immediate feedback on answer submission
    - Display explanation and optional source link
    - _Requirements: 4.3, 4.4, 4.5_
  - [x] 9.5 Create QuizResultScreen showing session summary
    - Display total XP earned with breakdown
    - Show streak status
    - Show correct/incorrect count
    - _Requirements: 5.7, 6.5_

- [x] 10. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Implement LeaderboardService

  - [x] 11.1 Create LeaderboardService with ranking queries
    - Implement getGlobalLeaderboard sorted by weeklyXpCurrent DESC
    - Implement getUserRank to find current user's position
    - _Requirements: 8.4, 8.5_
  - [ ]\* 11.2 Write property test for leaderboard sorting
    - **Property 23: Leaderboard sorting**
    - **Validates: Requirements 8.4**
  - [x] 11.3 Create Riverpod providers for leaderboard
    - Implement leaderboardServiceProvider and globalLeaderboardProvider
    - _Requirements: 8.4_

- [x] 12. Build LeaderboardScreen

  - [x] 12.1 Create LeaderboardScreen with tabs
    - Display Global and Friends tabs
    - Show current user's rank prominently
    - Display top 50 players with rank, name, and weekly XP
    - _Requirements: 8.5_

- [x] 13. Implement FriendsService

  - [x] 13.1 Create FriendsService with friend management
    - Implement findUserByFriendCode query
    - Implement addFriend to create friend document
    - Implement getFriends and getFriendsStream
    - Implement getFriendsLeaderboard sorted by weeklyXpCurrent
    - _Requirements: 10.3, 10.4, 10.6_
  - [ ]\* 13.2 Write property test for friend code lookup
    - **Property 28: Friend code lookup**
    - **Validates: Requirements 10.3**
  - [ ]\* 13.3 Write property test for friend document creation
    - **Property 29: Friend document creation**
    - **Validates: Requirements 10.4**
  - [ ]\* 13.4 Write property test for friends leaderboard sorting
    - **Property 30: Friends leaderboard sorting**
    - **Validates: Requirements 10.6**
  - [x] 13.5 Create Riverpod providers for friends
    - Implement friendsServiceProvider and friendsListProvider
    - _Requirements: 10.3, 10.6_

- [x] 14. Build FriendsScreen and friend management UI

  - [x] 14.1 Create FriendsScreen displaying friend code and list
    - Show user's own friend code prominently
    - Display Add Friend button
    - Show list of current friends
    - _Requirements: 10.1, 10.5_
  - [x] 14.2 Create AddFriendDialog for friend code input
    - Input field for friend code
    - Handle friend code lookup and validation
    - Display appropriate error messages
    - _Requirements: 10.2, 10.3, 10.4_

- [-] 15. Implement VS Mode services

  - [x] 15.1 Create VSModeService for pass-and-play duels
    - Implement startVSMode to initialize duel session
    - Implement submitPlayerAnswer to track answers per player
    - Implement calculateResult to determine winner
    - Implement updateDuelStats for logged-in user
    - _Requirements: 9.2, 9.3, 9.5, 9.6, 9.7, 9.8_
  - [ ]\* 15.2 Write property test for duel winner determination
    - **Property 24: Duel winner determination**
    - **Validates: Requirements 9.5**
  - [ ]\* 15.3 Write property test for duel win stats
    - **Property 25: Duel win stats update**
    - **Validates: Requirements 9.6**
  - [ ]\* 15.4 Write property test for duel tie stats
    - **Property 26: Duel tie stats update**
    - **Validates: Requirements 9.7**
  - [ ]\* 15.5 Write property test for duel loss stats
    - **Property 27: Duel loss stats update**
    - **Validates: Requirements 9.8**

- [x] 16. Build VS Mode UI screens

  - [x] 16.1 Create VSModeSetupScreen
    - Category selection
    - Quiz length selection (5 or 10 questions per player)
    - Player name inputs with defaults
    - _Requirements: 9.1, 9.2_
  - [x] 16.2 Create VSModeQuizScreen with player indicator
    - Reuse quiz question display logic
    - Show current player name prominently
    - Track answers per player
    - _Requirements: 9.3_
  - [x] 16.3 Create VSModeHandoffScreen
    - Display "Pass device to Player B" message
    - Continue button to proceed
    - _Requirements: 9.4_
  - [x] 16.4 Create VSModeResultScreen
    - Show both players' scores
    - Declare winner or tie
    - Display XP earned (for logged-in user only)
    - _Requirements: 9.5_

- [x] 17. Implement navigation and routing

  - [x] 17.1 Set up named routes in main.dart
    - Configure all screen routes
    - Handle initial route based on auth state
    - _Requirements: 1.1, 1.2, 2.4_

- [x] 18. Add error handling and loading states

  - [x] 18.1 Implement error handling for all Firestore operations
    - Wrap operations in try-catch blocks
    - Display user-friendly error messages via SnackBar
    - Print errors to debug console for debugging purposes
    - Handle offline scenarios with caching where possible
    - _Requirements: 2.3, 4.1, 10.3_
  - [x] 18.2 Add loading indicators for async operations
    - Show CircularProgressIndicator during data loads
    - Disable buttons during processing
    - _Requirements: 3.2, 4.1, 8.4_

- [x] 19. Final checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 20. Implement SettingsService and theme management

  - [x] 20.1 Add shared_preferences package to pubspec.yaml
    - Add dependency for local storage of theme preference
    - _Requirements: 13.5_
  - [x] 20.2 Create SettingsService with theme and account management
    - Implement updateDisplayName to update user document
    - Implement setThemeMode and getThemeMode for theme persistence
    - Implement logout method
    - _Requirements: 13.2, 13.3, 13.4, 13.5_
  - [ ]\* 20.3 Write property test for display name update
    - **Property 38: Display name update persistence**
    - **Validates: Requirements 13.3**
  - [ ]\* 20.4 Write property test for theme mode persistence
    - **Property 39: Theme mode persistence**
    - **Validates: Requirements 13.4, 13.5**
  - [ ]\* 20.5 Write property test for logout state cleanup
    - **Property 40: Logout state cleanup**
    - **Validates: Requirements 13.2**
  - [x] 20.6 Create Riverpod providers for settings and theme
    - Implement settingsServiceProvider and themeModeProvider
    - Create ThemeModeNotifier for theme state management
    - _Requirements: 13.4, 13.5_

- [x] 21. Build SettingsScreen UI

  - [x] 21.1 Create SettingsScreen with account and appearance sections
    - Display current display name with edit button
    - Add logout button with confirmation dialog
    - Add theme selector (Light, Dark, System)
    - _Requirements: 13.1, 13.2, 13.3, 13.4_
  - [x] 21.2 Integrate theme provider with MaterialApp
    - Update main.dart to use themeModeProvider
    - Define light and dark theme data
    - _Requirements: 13.4, 13.5_
  - [x] 21.3 Add settings navigation from HomeScreen
    - Add settings icon/button to HomeScreen AppBar
    - Navigate to SettingsScreen on tap
    - _Requirements: 13.1_

- [ ] 22. Seed Firestore with test data
  - [ ] 22.1 Create sample categories
    - Add 5-10 categories with German titles and descriptions
    - _Requirements: 11.4_
  - [ ] 22.2 Create sample questions
    - Add 50-100 questions across categories
    - Include both single-choice and multiple-choice questions
    - Add explanations and sources
    - _Requirements: 11.5_
