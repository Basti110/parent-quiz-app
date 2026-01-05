import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Label for dashboard navigation tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Label for VS Mode navigation tab
  ///
  /// In en, this message translates to:
  /// **'VS Mode'**
  String get vsMode;

  /// Label for leaderboard navigation tab
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Label for settings navigation tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for correct answers count
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get correctAnswers;

  /// Button to start a random quiz
  ///
  /// In en, this message translates to:
  /// **'Start Random Quiz'**
  String get startRandomQuiz;

  /// Label for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for change avatar option
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get changeAvatar;

  /// Label for logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Button to add a friend
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// Label for friend code input
  ///
  /// In en, this message translates to:
  /// **'Friend Code'**
  String get friendCode;

  /// Label for number of wins
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// Label for number of losses
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// Message when user has no friends
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Add friends to compete!'**
  String get noFriends;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Display name input label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Confirm password input label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Create account header
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Link to login from register
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Link to register from login
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign up button label
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Welcome message on onboarding
  ///
  /// In en, this message translates to:
  /// **'Welcome to Parent Quiz!'**
  String get welcome;

  /// Onboarding description
  ///
  /// In en, this message translates to:
  /// **'Learn about parenting through fun quizzes and compete with friends!'**
  String get onboardingDescription;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Select category screen title
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Select quiz length screen title
  ///
  /// In en, this message translates to:
  /// **'Select Quiz Length'**
  String get selectQuizLength;

  /// Questions label
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// Start button label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Question label
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Submit button label
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Correct answer feedback
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// Incorrect answer feedback
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// Explanation section label
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// Quiz results screen title
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResults;

  /// Score label
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// XP earned label
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get xpEarned;

  /// Back to home button
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// Weekly leaderboard title
  ///
  /// In en, this message translates to:
  /// **'Weekly Leaderboard'**
  String get weeklyLeaderboard;

  /// Rank label
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// Player label
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// Points label
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// Label for current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Friends screen title
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// Your friend code label
  ///
  /// In en, this message translates to:
  /// **'Your Friend Code'**
  String get yourFriendCode;

  /// Enter friend code hint
  ///
  /// In en, this message translates to:
  /// **'Enter Friend Code'**
  String get enterFriendCode;

  /// VS Mode setup screen title
  ///
  /// In en, this message translates to:
  /// **'VS Mode Setup'**
  String get vsModeSetup;

  /// Select opponent label
  ///
  /// In en, this message translates to:
  /// **'Select Opponent'**
  String get selectOpponent;

  /// Select questions label
  ///
  /// In en, this message translates to:
  /// **'Select Number of Questions'**
  String get selectQuestions;

  /// Start duel button
  ///
  /// In en, this message translates to:
  /// **'Start Duel'**
  String get startDuel;

  /// Player 1 label
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get player1;

  /// Player 2 label
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get player2;

  /// Handoff device message
  ///
  /// In en, this message translates to:
  /// **'Hand off device to {playerName}'**
  String handoffDevice(String playerName);

  /// Ready button label
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// VS Mode results screen title
  ///
  /// In en, this message translates to:
  /// **'VS Mode Results'**
  String get vsModeResults;

  /// Winner label
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// Tie game message
  ///
  /// In en, this message translates to:
  /// **'It\'s a Tie!'**
  String get tie;

  /// Play again button
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// Level label
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Streak label
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Days label
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Total XP label
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXP;

  /// Select avatar screen title
  ///
  /// In en, this message translates to:
  /// **'Select Avatar'**
  String get selectAvatar;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Tips section label
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// Next question button
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// Finish quiz button
  ///
  /// In en, this message translates to:
  /// **'Finish Quiz'**
  String get finishQuiz;

  /// App name
  ///
  /// In en, this message translates to:
  /// **'ParentQuiz'**
  String get parentQuiz;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Name length validation error
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// Password match validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Name input label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Onboarding welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to ParentQuiz'**
  String get welcomeToParentQuiz;

  /// Onboarding welcome description
  ///
  /// In en, this message translates to:
  /// **'Learn evidence-based parenting through fun, bite-sized quizzes'**
  String get onboardingWelcomeDescription;

  /// Onboarding XP title
  ///
  /// In en, this message translates to:
  /// **'Earn XP & Level Up'**
  String get earnXpLevelUp;

  /// Onboarding XP description
  ///
  /// In en, this message translates to:
  /// **'Answer questions correctly, maintain streaks, and track your progress'**
  String get onboardingXpDescription;

  /// Onboarding friends title
  ///
  /// In en, this message translates to:
  /// **'Compete with Friends'**
  String get competeWithFriends;

  /// Onboarding friends description
  ///
  /// In en, this message translates to:
  /// **'Add friends, compare scores on leaderboards, and challenge them in VS Mode'**
  String get onboardingFriendsDescription;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Quiz screen title
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// Multiple choice instruction
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get selectAllThatApply;

  /// Single choice instruction
  ///
  /// In en, this message translates to:
  /// **'Select one answer'**
  String get selectOneAnswer;

  /// Answer selection validation
  ///
  /// In en, this message translates to:
  /// **'Please select an answer'**
  String get pleaseSelectAnswer;

  /// Submit answer button
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// Show tip tooltip
  ///
  /// In en, this message translates to:
  /// **'Show tip'**
  String get showTip;

  /// Tip dialog title
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// Got it button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Authentication error message
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No questions error message
  ///
  /// In en, this message translates to:
  /// **'No questions available for this category'**
  String get noQuestionsAvailable;

  /// Error loading questions message
  ///
  /// In en, this message translates to:
  /// **'Error loading questions: {error}'**
  String errorLoadingQuestions(String error);

  /// Error finishing quiz message
  ///
  /// In en, this message translates to:
  /// **'Error finishing quiz: {error}'**
  String errorFinishingQuiz(String error);

  /// Quiz complete title
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizComplete;

  /// Perfect score message
  ///
  /// In en, this message translates to:
  /// **'Perfect Score! 🎉'**
  String get perfectScore;

  /// Excellent work message
  ///
  /// In en, this message translates to:
  /// **'Excellent Work! 🌟'**
  String get excellentWork;

  /// Good job message
  ///
  /// In en, this message translates to:
  /// **'Good Job! 👍'**
  String get goodJob;

  /// Keep learning message
  ///
  /// In en, this message translates to:
  /// **'Keep Learning! 📚'**
  String get keepLearning;

  /// Your score label
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get yourScore;

  /// Percent correct label
  ///
  /// In en, this message translates to:
  /// **'{percent}% Correct'**
  String percentCorrect(int percent);

  /// XP breakdown label
  ///
  /// In en, this message translates to:
  /// **'XP Breakdown:'**
  String get xpBreakdown;

  /// Correct answers XP label
  ///
  /// In en, this message translates to:
  /// **'Correct answers'**
  String get correctAnswersXp;

  /// Incorrect with explanation XP label
  ///
  /// In en, this message translates to:
  /// **'Incorrect (with explanation)'**
  String get incorrectWithExplanation;

  /// Session bonus XP label
  ///
  /// In en, this message translates to:
  /// **'Session bonus'**
  String get sessionBonus;

  /// Perfect bonus XP label
  ///
  /// In en, this message translates to:
  /// **'Perfect bonus'**
  String get perfectBonus;

  /// All correct message
  ///
  /// In en, this message translates to:
  /// **'All correct!'**
  String get allCorrect;

  /// Current streak label
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// Days count label
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysCount(int count);

  /// Longest streak label
  ///
  /// In en, this message translates to:
  /// **'Longest: {count} days'**
  String longest(int count);

  /// Error loading user data message
  ///
  /// In en, this message translates to:
  /// **'Error loading user data'**
  String get errorLoadingUserData;

  /// View source button
  ///
  /// In en, this message translates to:
  /// **'View Source'**
  String get viewSource;

  /// Could not open link error
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// Login required message for leaderboard
  ///
  /// In en, this message translates to:
  /// **'Please log in to view leaderboard'**
  String get pleaseLoginToViewLeaderboard;

  /// Global leaderboard tab
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No players message
  ///
  /// In en, this message translates to:
  /// **'No players on the leaderboard yet'**
  String get noPlayersYet;

  /// Error loading leaderboard message
  ///
  /// In en, this message translates to:
  /// **'Error loading leaderboard: {error}'**
  String errorLoadingLeaderboard(String error);

  /// No friends message
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// Add friends message
  ///
  /// In en, this message translates to:
  /// **'Add friends to see their rankings'**
  String get addFriendsToSeeRankings;

  /// Add friends button
  ///
  /// In en, this message translates to:
  /// **'Add Friends'**
  String get addFriendsButton;

  /// Error loading friends leaderboard message
  ///
  /// In en, this message translates to:
  /// **'Error loading friends leaderboard: {error}'**
  String errorLoadingFriendsLeaderboard(String error);

  /// Your rank label
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// Weekly XP label
  ///
  /// In en, this message translates to:
  /// **'Weekly XP'**
  String get weeklyXp;

  /// XP label
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// Exit quiz dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit Quiz'**
  String get exitQuiz;

  /// Exit quiz confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit? Your progress will be lost.'**
  String get exitQuizConfirmation;

  /// Daily goal label
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// Questions per day label
  ///
  /// In en, this message translates to:
  /// **'Questions per day'**
  String get questionsPerDay;

  /// Daily goal description
  ///
  /// In en, this message translates to:
  /// **'Set how many questions you want to answer each day'**
  String get dailyGoalDescription;

  /// Daily goal updated success message
  ///
  /// In en, this message translates to:
  /// **'Daily goal updated successfully'**
  String get dailyGoalUpdated;

  /// Invalid daily goal error message
  ///
  /// In en, this message translates to:
  /// **'Daily goal must be between 1 and 50'**
  String get invalidDailyGoal;

  /// Statistics screen title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Overall progress section title
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// Questions answered label
  ///
  /// In en, this message translates to:
  /// **'Questions Answered'**
  String get questionsAnswered;

  /// Questions mastered label
  ///
  /// In en, this message translates to:
  /// **'Questions Mastered'**
  String get questionsMastered;

  /// Questions seen label
  ///
  /// In en, this message translates to:
  /// **'Questions Seen'**
  String get questionsSeen;

  /// By category section title
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// Answered label
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// Mastered label
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// Progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No category statistics message
  ///
  /// In en, this message translates to:
  /// **'No category statistics yet. Start answering questions!'**
  String get noCategoryStatistics;

  /// Failed to load statistics error
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStatistics;

  /// Please try again message
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// Error starting VS Mode message
  ///
  /// In en, this message translates to:
  /// **'Error starting VS Mode: {error}'**
  String errorStartingVsMode(String error);

  /// Error loading duel message
  ///
  /// In en, this message translates to:
  /// **'Error loading duel: {error}'**
  String errorLoadingDuel(String error);

  /// Error submitting answer message
  ///
  /// In en, this message translates to:
  /// **'Error submitting answer: {error}'**
  String errorSubmittingAnswer(String error);

  /// Error completing duel message
  ///
  /// In en, this message translates to:
  /// **'Error completing duel: {error}'**
  String errorCompletingDuel(String error);

  /// Error accepting duel message
  ///
  /// In en, this message translates to:
  /// **'Failed to accept duel: {error}'**
  String errorAcceptingDuel(String error);

  /// Error declining duel message
  ///
  /// In en, this message translates to:
  /// **'Failed to decline duel: {error}'**
  String errorDecliningDuel(String error);

  /// Error updating stats message
  ///
  /// In en, this message translates to:
  /// **'Error updating stats: {error}'**
  String errorUpdatingStats(String error);

  /// Error loading results message
  ///
  /// In en, this message translates to:
  /// **'Error loading results: {error}'**
  String errorLoadingResults(String error);

  /// Error loading categories message
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String errorLoadingCategories(String error);

  /// Error loading friends message
  ///
  /// In en, this message translates to:
  /// **'Error loading friends: {error}'**
  String errorLoadingFriends(String error);

  /// Error accepting friend request message
  ///
  /// In en, this message translates to:
  /// **'Failed to accept friend request: {error}'**
  String errorAcceptingFriendRequest(String error);

  /// Error declining friend request message
  ///
  /// In en, this message translates to:
  /// **'Failed to decline friend request: {error}'**
  String errorDecliningFriendRequest(String error);

  /// Error creating duel message
  ///
  /// In en, this message translates to:
  /// **'Failed to create duel: {error}'**
  String errorCreatingDuel(String error);

  /// Error adding friend message
  ///
  /// In en, this message translates to:
  /// **'Failed to add friend. Please try again.'**
  String get errorAddingFriend;

  /// Validation message for category selection
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// Validation message for Player A name
  ///
  /// In en, this message translates to:
  /// **'Please enter Player A name'**
  String get pleaseEnterPlayerAName;

  /// Validation message for Player B name
  ///
  /// In en, this message translates to:
  /// **'Please enter Player B name'**
  String get pleaseEnterPlayerBName;

  /// Validation message for friend code
  ///
  /// In en, this message translates to:
  /// **'Please enter a friend code'**
  String get pleaseEnterFriendCode;

  /// Validation message for friend code length
  ///
  /// In en, this message translates to:
  /// **'Friend code must be 6-8 characters'**
  String get friendCodeLength;

  /// Error message when friend code not found
  ///
  /// In en, this message translates to:
  /// **'No user found with this friend code'**
  String get noUserFoundWithCode;

  /// Error message when trying to add self
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself as a friend'**
  String get cannotAddYourself;

  /// Error message when already friends
  ///
  /// In en, this message translates to:
  /// **'You are already friends with this user'**
  String get alreadyFriends;

  /// Exit duel dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit Duel?'**
  String get dialogTitleExitDuel;

  /// Exit duel dialog content
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved and you can continue later.'**
  String get dialogContentExitDuel;

  /// Add friend dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get dialogTitleAddFriend;

  /// Duel challenge dialog title
  ///
  /// In en, this message translates to:
  /// **'Duel Challenge'**
  String get dialogTitleDuelChallenge;

  /// Challenge unavailable message
  ///
  /// In en, this message translates to:
  /// **'This challenge is no longer available'**
  String get challengeNoLongerAvailable;

  /// Go back button label
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get buttonGoBack;

  /// Home button label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get buttonHome;

  /// Accept challenge button label
  ///
  /// In en, this message translates to:
  /// **'Accept Challenge'**
  String get buttonAcceptChallenge;

  /// Decline challenge button label
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get buttonDeclineChallenge;

  /// Exit button label
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get buttonExit;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOk;

  /// Accept button label
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get buttonAccept;

  /// Decline button label
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get buttonDecline;

  /// VS Mode screen title
  ///
  /// In en, this message translates to:
  /// **'VS Mode'**
  String get screenTitleVsMode;

  /// Duel screen title
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get screenTitleDuel;

  /// Duel results screen title
  ///
  /// In en, this message translates to:
  /// **'Duel Results'**
  String get screenTitleDuelResults;

  /// Friend request sent status message
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name}!'**
  String statusFriendRequestSent(String name);

  /// Duel challenge sent status message
  ///
  /// In en, this message translates to:
  /// **'Duel challenge sent to {name}!'**
  String statusDuelChallengeSent(String name);

  /// Duel declined status message
  ///
  /// In en, this message translates to:
  /// **'Duel declined'**
  String get statusDuelDeclined;

  /// Friend code copied status message
  ///
  /// In en, this message translates to:
  /// **'Friend code copied to clipboard'**
  String get statusFriendCodeCopied;

  /// Now friends status message
  ///
  /// In en, this message translates to:
  /// **'You are now friends with {name}!'**
  String statusNowFriends(String name);

  /// Friend request declined status message
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get statusFriendRequestDeclined;

  /// Friend added status message
  ///
  /// In en, this message translates to:
  /// **'{name} added as friend!'**
  String statusFriendAdded(String name);

  /// VS text label
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vsText;

  /// Questions label
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsLabel;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// Winner label
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winnerLabel;

  /// Answer at own pace instruction
  ///
  /// In en, this message translates to:
  /// **'Answer at your own pace'**
  String get answerAtOwnPace;

  /// Highest score wins instruction
  ///
  /// In en, this message translates to:
  /// **'Highest score wins'**
  String get highestScoreWins;

  /// Pass device instruction
  ///
  /// In en, this message translates to:
  /// **'Pass device to {playerName}'**
  String passDeviceTo(String playerName);

  /// Start player turn button
  ///
  /// In en, this message translates to:
  /// **'START {playerName}\'S TURN'**
  String startPlayerTurn(String playerName);

  /// Duel with player label
  ///
  /// In en, this message translates to:
  /// **'Duel with {playerName}'**
  String duelWith(String playerName);

  /// Question progress label
  ///
  /// In en, this message translates to:
  /// **'Question {current} / {total}'**
  String questionProgress(int current, int total);

  /// You label
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// Friend code placeholder text
  ///
  /// In en, this message translates to:
  /// **'ABC123'**
  String get friendCodePlaceholder;

  /// English language label
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// German language label
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No categories available message
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// Login required message for friends
  ///
  /// In en, this message translates to:
  /// **'Please log in to view friends'**
  String get pleaseLoginToViewFriends;

  /// Day streak label
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// Leading status in head-to-head
  ///
  /// In en, this message translates to:
  /// **'Leading'**
  String get leading;

  /// Trailing status in head-to-head
  ///
  /// In en, this message translates to:
  /// **'Trailing'**
  String get trailing;

  /// Tied status in head-to-head
  ///
  /// In en, this message translates to:
  /// **'Tied'**
  String get tied;

  /// Head-to-head record label
  ///
  /// In en, this message translates to:
  /// **'Head-to-Head Record'**
  String get headToHeadRecord;

  /// Ties label
  ///
  /// In en, this message translates to:
  /// **'Ties'**
  String get ties;

  /// Avatar selection validation message
  ///
  /// In en, this message translates to:
  /// **'Please select an avatar'**
  String get pleaseSelectAvatar;

  /// Friend requests section title with count
  ///
  /// In en, this message translates to:
  /// **'Friend Requests ({count})'**
  String friendRequests(int count);

  /// Friend request description
  ///
  /// In en, this message translates to:
  /// **'Wants to be your friend'**
  String get wantsToBeYourFriend;

  /// Your friend code section label
  ///
  /// In en, this message translates to:
  /// **'Your Friend Code'**
  String get yourFriendCodeLabel;

  /// Friend code sharing instruction
  ///
  /// In en, this message translates to:
  /// **'Share this code with friends so they can add you'**
  String get shareCodeWithFriends;

  /// No friends title
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYetTitle;

  /// Add friends instruction
  ///
  /// In en, this message translates to:
  /// **'Add friends using their friend code'**
  String get addFriendsUsingCode;

  /// View results button
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get viewResults;

  /// Send challenge button
  ///
  /// In en, this message translates to:
  /// **'Send Challenge'**
  String get sendChallenge;

  /// Duel completed message
  ///
  /// In en, this message translates to:
  /// **'Duel with {playerName} completed!'**
  String duelWithPlayerCompleted(String playerName);

  /// Waiting for player message
  ///
  /// In en, this message translates to:
  /// **'Waiting for {playerName} to complete'**
  String waitingForPlayerToComplete(String playerName);

  /// Duel ready message
  ///
  /// In en, this message translates to:
  /// **'Duel with {playerName} is ready!'**
  String duelWithPlayerReady(String playerName);

  /// Duel completed instruction
  ///
  /// In en, this message translates to:
  /// **'Duel completed - tap banner to view results'**
  String get duelCompletedTapBanner;

  /// Waiting for opponent message
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent to complete'**
  String get waitingForOpponentToComplete;

  /// Duel ready instruction
  ///
  /// In en, this message translates to:
  /// **'Duel ready - tap banner to start'**
  String get duelReadyTapBanner;

  /// Accept/decline instruction
  ///
  /// In en, this message translates to:
  /// **'Tap banner to accept or decline'**
  String get tapBannerToAcceptDecline;

  /// Challenge sent status
  ///
  /// In en, this message translates to:
  /// **'Challenge sent - waiting for response'**
  String get challengeSentWaiting;

  /// View results tooltip
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get viewResultsTooltip;

  /// Start duel tooltip
  ///
  /// In en, this message translates to:
  /// **'Start duel'**
  String get startDuelTooltip;

  /// Challenge to duel tooltip
  ///
  /// In en, this message translates to:
  /// **'Challenge to duel'**
  String get challengeToDuel;

  /// Challenge pending tooltip
  ///
  /// In en, this message translates to:
  /// **'Challenge pending'**
  String get challengePending;

  /// Waiting for opponent tooltip
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent'**
  String get waitingForOpponent;

  /// Error loading duel status message
  ///
  /// In en, this message translates to:
  /// **'Error loading duel status'**
  String get errorLoadingDuelStatus;

  /// Challenge player dialog title
  ///
  /// In en, this message translates to:
  /// **'Challenge {playerName}?'**
  String challengePlayerQuestion(String playerName);

  /// Duel challenge description
  ///
  /// In en, this message translates to:
  /// **'5 questions • Answer at your own pace'**
  String get fiveQuestionsOwnPace;

  /// Add friend dialog instruction
  ///
  /// In en, this message translates to:
  /// **'Enter your friend\'s code to add them'**
  String get enterFriendCodeToAdd;

  /// Friend code input label
  ///
  /// In en, this message translates to:
  /// **'Friend Code'**
  String get friendCodeLabel;

  /// Friend code input hint
  ///
  /// In en, this message translates to:
  /// **'e.g., ABC123'**
  String get friendCodeHint;

  /// Friend request already sent error
  ///
  /// In en, this message translates to:
  /// **'Friend request already sent to this user'**
  String get friendRequestAlreadySent;

  /// Player A form field label
  ///
  /// In en, this message translates to:
  /// **'Player A'**
  String get playerALabel;

  /// Player B form field label
  ///
  /// In en, this message translates to:
  /// **'Player B'**
  String get playerBLabel;

  /// Questions per player label
  ///
  /// In en, this message translates to:
  /// **'Questions per Player'**
  String get questionsPerPlayer;

  /// Questions label lowercase
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get questionsLowercase;

  /// Avatar saved success message
  ///
  /// In en, this message translates to:
  /// **'Avatar saved'**
  String get avatarSaved;

  /// Generic authentication error message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your credentials.'**
  String get authenticationError;

  /// Generic registration error message
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationError;

  /// Loading categories message
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// Loading questions message
  ///
  /// In en, this message translates to:
  /// **'Loading questions...'**
  String get loadingQuestions;

  /// Loading results message
  ///
  /// In en, this message translates to:
  /// **'Loading results...'**
  String get loadingResults;

  /// Loading friends message
  ///
  /// In en, this message translates to:
  /// **'Loading friends...'**
  String get loadingFriends;

  /// Loading leaderboard message
  ///
  /// In en, this message translates to:
  /// **'Loading leaderboard...'**
  String get loadingLeaderboard;

  /// Loading statistics message
  ///
  /// In en, this message translates to:
  /// **'Loading statistics...'**
  String get loadingStatistics;

  /// No data available message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Empty friends list message
  ///
  /// In en, this message translates to:
  /// **'Your friends list is empty'**
  String get emptyFriendsList;

  /// Empty leaderboard message
  ///
  /// In en, this message translates to:
  /// **'No players on the leaderboard'**
  String get emptyLeaderboard;

  /// Saving changes message
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get savingChanges;

  /// Changes saved success message
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSaved;

  /// Generic operation failed message
  ///
  /// In en, this message translates to:
  /// **'Operation failed. Please try again.'**
  String get operationFailed;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// Daily goal validation error message
  ///
  /// In en, this message translates to:
  /// **'Daily goal must be between 1 and 50'**
  String get dailyGoalValidationError;

  /// VS Mode setup title
  ///
  /// In en, this message translates to:
  /// **'Pass & Play Duel'**
  String get passAndPlayDuel;

  /// VS Mode setup description
  ///
  /// In en, this message translates to:
  /// **'Compete with a friend on the same device'**
  String get competeWithFriendSameDevice;

  /// Player names section title
  ///
  /// In en, this message translates to:
  /// **'Player Names'**
  String get playerNames;

  /// Score display with correct count
  ///
  /// In en, this message translates to:
  /// **'{score} correct'**
  String scoreCorrect(int score);

  /// Score placeholder when not available
  ///
  /// In en, this message translates to:
  /// **'---'**
  String get scorePlaceholder;

  /// Perfect tie result message
  ///
  /// In en, this message translates to:
  /// **'Perfect Tie!'**
  String get perfectTie;

  /// Winner announcement message
  ///
  /// In en, this message translates to:
  /// **'{winner} Wins!'**
  String winnerWins(String winner);

  /// Won by speed indicator
  ///
  /// In en, this message translates to:
  /// **'Won by speed!'**
  String get wonBySpeed;

  /// Duel points earned section title
  ///
  /// In en, this message translates to:
  /// **'Duel Points Earned'**
  String get duelPointsEarned;

  /// Duel points for tie result
  ///
  /// In en, this message translates to:
  /// **'+1 Duel Point (Tie)'**
  String get duelPointsTie;

  /// Duel points for win result
  ///
  /// In en, this message translates to:
  /// **'+3 Duel Points (Win)'**
  String get duelPointsWin;

  /// Duel points for loss result
  ///
  /// In en, this message translates to:
  /// **'No Duel Points (Loss)'**
  String get duelPointsLoss;

  /// You won message
  ///
  /// In en, this message translates to:
  /// **'You Won!'**
  String get youWon;

  /// You lost message
  ///
  /// In en, this message translates to:
  /// **'You Lost'**
  String get youLost;

  /// Results availability message
  ///
  /// In en, this message translates to:
  /// **'Results will be available when both players complete the duel'**
  String get resultsAvailableWhenBothComplete;

  /// Question breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Question Breakdown'**
  String get questionBreakdown;

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// Challenge message
  ///
  /// In en, this message translates to:
  /// **'{playerName} challenges you!'**
  String challengesYou(String playerName);

  /// Five questions label
  ///
  /// In en, this message translates to:
  /// **'5 questions'**
  String get fiveQuestions;

  /// Feedback screen title
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Report issue button text
  ///
  /// In en, this message translates to:
  /// **'Report an issue with this question'**
  String get reportIssue;

  /// Issue type selection label
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// Typo issue type
  ///
  /// In en, this message translates to:
  /// **'Typo'**
  String get typo;

  /// Content outdated issue type
  ///
  /// In en, this message translates to:
  /// **'Content Outdated'**
  String get contentOutdated;

  /// Broken link issue type
  ///
  /// In en, this message translates to:
  /// **'Broken Link'**
  String get brokenLink;

  /// Other issue type
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Additional comments field label
  ///
  /// In en, this message translates to:
  /// **'Additional Comments'**
  String get additionalComments;

  /// Describe issue placeholder text
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue you found...'**
  String get describeIssue;

  /// Validation message for issue description
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue'**
  String get pleaseDescribeIssue;

  /// Validation message for short comments
  ///
  /// In en, this message translates to:
  /// **'Comment must be at least 10 characters'**
  String get commentTooShort;

  /// Submit feedback button text
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// Feedback submitted success message
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully!'**
  String get feedbackSubmitted;

  /// Feedback submitted thank you message
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback! We\'ll review it soon.'**
  String get feedbackSubmittedThankYou;

  /// Sign in required message
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit feedback'**
  String get pleaseSignIn;

  /// Feedback form introduction title
  ///
  /// In en, this message translates to:
  /// **'Your Feedback Matters'**
  String get yourFeedbackMatters;

  /// Feedback form introduction description
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app by sharing your thoughts and experiences.'**
  String get feedbackDescription;

  /// Overall experience section title
  ///
  /// In en, this message translates to:
  /// **'Overall Experience'**
  String get overallExperience;

  /// App rating slider label
  ///
  /// In en, this message translates to:
  /// **'App Rating'**
  String get appRating;

  /// App rating description
  ///
  /// In en, this message translates to:
  /// **'How would you rate the overall app experience?'**
  String get appRatingDescription;

  /// Theme rating slider label
  ///
  /// In en, this message translates to:
  /// **'Theme & Design'**
  String get themeRating;

  /// Theme rating description
  ///
  /// In en, this message translates to:
  /// **'How do you like the app\'s visual design and theme?'**
  String get themeRatingDescription;

  /// Duel mode rating slider label
  ///
  /// In en, this message translates to:
  /// **'Duel Mode'**
  String get duelModeRating;

  /// Duel mode rating description
  ///
  /// In en, this message translates to:
  /// **'How enjoyable is the duel mode with friends?'**
  String get duelModeRatingDescription;

  /// Learning and trust section title
  ///
  /// In en, this message translates to:
  /// **'Learning & Trust'**
  String get learningAndTrust;

  /// Learning factor slider label
  ///
  /// In en, this message translates to:
  /// **'Learning Factor'**
  String get learningFactor;

  /// Learning factor description
  ///
  /// In en, this message translates to:
  /// **'How much are you learning from the questions?'**
  String get learningFactorDescription;

  /// Scientific trust slider label
  ///
  /// In en, this message translates to:
  /// **'Scientific Trust'**
  String get scientificTrust;

  /// Scientific trust description
  ///
  /// In en, this message translates to:
  /// **'How much do you trust the scientific accuracy of the content?'**
  String get scientificTrustDescription;

  /// Additional feedback section title
  ///
  /// In en, this message translates to:
  /// **'Additional Feedback'**
  String get additionalFeedback;

  /// General comment field label
  ///
  /// In en, this message translates to:
  /// **'General Comment'**
  String get generalComment;

  /// General comment placeholder
  ///
  /// In en, this message translates to:
  /// **'Share your overall thoughts about the app...'**
  String get shareYourThoughts;

  /// Validation message for general comment
  ///
  /// In en, this message translates to:
  /// **'Please share your thoughts'**
  String get pleaseShareThoughts;

  /// Improvement suggestions field label
  ///
  /// In en, this message translates to:
  /// **'What can we do better?'**
  String get whatCanWeDoBetter;

  /// Improvement suggestions placeholder
  ///
  /// In en, this message translates to:
  /// **'Suggest improvements or report issues...'**
  String get suggestImprovements;

  /// Future features field label
  ///
  /// In en, this message translates to:
  /// **'Future Features'**
  String get futureFeatures;

  /// Future features placeholder
  ///
  /// In en, this message translates to:
  /// **'What features would you like to see in the future?'**
  String get suggestFeatures;

  /// Feedback privacy note
  ///
  /// In en, this message translates to:
  /// **'Your feedback is anonymous and helps us improve the app. We may contact you if you\'ve provided contact information.'**
  String get feedbackPrivacyNote;

  /// Optional field indicator
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
