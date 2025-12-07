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

  /// Error label
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
  /// **'Error loading user data: {error}'**
  String errorLoadingUserData(String error);

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
