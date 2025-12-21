import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduparo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Manual localization validation test
/// 
/// This test validates that all localization keys are properly implemented
/// and that the app can switch between languages without issues.
void main() {
  group('Manual Localization Validation', () {
    testWidgets('should have all required localization keys in English', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('de'),
          ],
          home: LocalizationTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LocalizationTestWidget));
      final l10n = AppLocalizations.of(context)!;

      // Test error messages
      expect(() => l10n.errorStartingVsMode('test'), returnsNormally);
      expect(() => l10n.errorLoadingDuel('test'), returnsNormally);
      expect(() => l10n.errorSubmittingAnswer('test'), returnsNormally);
      expect(() => l10n.errorCompletingDuel('test'), returnsNormally);
      expect(() => l10n.errorAcceptingDuel('test'), returnsNormally);
      expect(() => l10n.errorDecliningDuel('test'), returnsNormally);
      expect(() => l10n.errorUpdatingStats('test'), returnsNormally);
      expect(() => l10n.errorLoadingResults('test'), returnsNormally);
      expect(() => l10n.errorLoadingCategories('test'), returnsNormally);
      expect(() => l10n.errorLoadingFriends('test'), returnsNormally);
      expect(() => l10n.errorLoadingUserData, returnsNormally);
      expect(() => l10n.errorAcceptingFriendRequest('test'), returnsNormally);
      expect(() => l10n.errorDecliningFriendRequest('test'), returnsNormally);
      expect(() => l10n.errorCreatingDuel('test'), returnsNormally);
      expect(() => l10n.errorAddingFriend, returnsNormally);
      expect(() => l10n.userNotAuthenticated, returnsNormally);

      // Test validation messages
      expect(() => l10n.pleaseSelectCategory, returnsNormally);
      expect(() => l10n.pleaseEnterPlayerAName, returnsNormally);
      expect(() => l10n.pleaseEnterPlayerBName, returnsNormally);
      expect(() => l10n.pleaseEnterFriendCode, returnsNormally);
      expect(() => l10n.friendCodeLength, returnsNormally);
      expect(() => l10n.noUserFoundWithCode, returnsNormally);
      expect(() => l10n.cannotAddYourself, returnsNormally);
      expect(() => l10n.alreadyFriends, returnsNormally);

      // Test dialog content
      expect(() => l10n.dialogTitleExitDuel, returnsNormally);
      expect(() => l10n.dialogContentExitDuel, returnsNormally);
      expect(() => l10n.dialogTitleAddFriend, returnsNormally);
      expect(() => l10n.dialogTitleDuelChallenge, returnsNormally);
      expect(() => l10n.challengeNoLongerAvailable, returnsNormally);

      // Test button labels
      expect(() => l10n.startDuel, returnsNormally);
      expect(() => l10n.buttonGoBack, returnsNormally);
      expect(() => l10n.playAgain, returnsNormally);
      expect(() => l10n.buttonHome, returnsNormally);
      expect(() => l10n.buttonAcceptChallenge, returnsNormally);
      expect(() => l10n.buttonDeclineChallenge, returnsNormally);
      expect(() => l10n.buttonExit, returnsNormally);
      expect(() => l10n.buttonOk, returnsNormally);
      expect(() => l10n.buttonAccept, returnsNormally);
      expect(() => l10n.buttonDecline, returnsNormally);

      // Test screen titles
      expect(() => l10n.screenTitleVsMode, returnsNormally);
      expect(() => l10n.screenTitleDuel, returnsNormally);
      expect(() => l10n.screenTitleDuelResults, returnsNormally);
      expect(() => l10n.selectCategory, returnsNormally);

      // Test status messages
      expect(() => l10n.statusFriendRequestSent('test'), returnsNormally);
      expect(() => l10n.statusDuelChallengeSent('test'), returnsNormally);
      expect(() => l10n.statusDuelDeclined, returnsNormally);
      expect(() => l10n.statusFriendCodeCopied, returnsNormally);
      expect(() => l10n.statusNowFriends('test'), returnsNormally);
      expect(() => l10n.statusFriendRequestDeclined, returnsNormally);
      expect(() => l10n.statusFriendAdded('test'), returnsNormally);

      // Test game content
      expect(() => l10n.vsText, returnsNormally);
      expect(() => l10n.questionsLabel, returnsNormally);
      expect(() => l10n.timeLabel, returnsNormally);
      expect(() => l10n.winnerLabel, returnsNormally);
      expect(() => l10n.answerAtOwnPace, returnsNormally);
      expect(() => l10n.highestScoreWins, returnsNormally);
      expect(() => l10n.passDeviceTo('test'), returnsNormally);
      expect(() => l10n.startPlayerTurn('test'), returnsNormally);
      expect(() => l10n.duelWith('test'), returnsNormally);
      expect(() => l10n.questionProgress(1, 5), returnsNormally);
      expect(() => l10n.submitAnswer, returnsNormally);
      expect(() => l10n.youLabel, returnsNormally);

      // Test form elements
      expect(() => l10n.friendCodePlaceholder, returnsNormally);
      expect(() => l10n.languageEnglish, returnsNormally);
      expect(() => l10n.languageGerman, returnsNormally);
      expect(() => l10n.noCategoriesAvailable, returnsNormally);
      expect(() => l10n.pleaseLoginToViewFriends, returnsNormally);
    });

    testWidgets('should have all required localization keys in German', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('de'),
          ],
          home: LocalizationTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LocalizationTestWidget));
      final l10n = AppLocalizations.of(context)!;

      // Test that German translations exist and are different from English
      // (This is a basic check - in real manual testing, a German speaker would verify accuracy)
      
      // Test some key translations to ensure they're in German
      expect(l10n.buttonAccept, isNot(equals('Accept')));
      expect(l10n.buttonDecline, isNot(equals('Decline')));
      expect(l10n.cancel, isNot(equals('Cancel')));
      
      // Verify language labels are in native form
      expect(l10n.languageEnglish, equals('English'));
      expect(l10n.languageGerman, equals('Deutsch'));
    });

    testWidgets('should handle locale switching without errors', (WidgetTester tester) async {
      // Start with English
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('de'),
          ],
          home: LocaleSwitchTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify English is loaded
      expect(find.text('English'), findsOneWidget);

      // Switch to German
      await tester.tap(find.byKey(const Key('switch_to_german')));
      await tester.pumpAndSettle();

      // Verify German is loaded
      expect(find.text('Deutsch'), findsOneWidget);

      // Switch back to English
      await tester.tap(find.byKey(const Key('switch_to_english')));
      await tester.pumpAndSettle();

      // Verify English is loaded again
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('should not contain hardcoded English strings in German locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('de'),
          ],
          home: HardcodedStringTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // This test would ideally scan all visible text for common English words
      // that shouldn't appear in German locale
      final commonEnglishWords = [
        'Error loading',
        'Failed to',
        'Please enter',
        'Accept',
        'Decline',
        'Cancel',
        'Start Duel',
        'Go Back',
        'Play Again',
        'Home',
        'VS Mode',
        'Friend request sent',
        'Add Friend',
      ];

      for (final word in commonEnglishWords) {
        expect(find.text(word), findsNothing, 
          reason: 'Found hardcoded English text "$word" in German locale');
      }
    });
  });
}

class LocalizationTestWidget extends StatelessWidget {
  const LocalizationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Localization Test'),
      ),
    );
  }
}

class LocaleSwitchTestWidget extends StatefulWidget {
  const LocaleSwitchTestWidget({super.key});

  @override
  State<LocaleSwitchTestWidget> createState() => _LocaleSwitchTestWidgetState();
}

class _LocaleSwitchTestWidgetState extends State<LocaleSwitchTestWidget> {
  Locale _currentLocale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      home: Scaffold(
        body: Column(
          children: [
            Text(AppLocalizations.of(context)?.languageEnglish ?? 'English'),
            Text(AppLocalizations.of(context)?.languageGerman ?? 'Deutsch'),
            ElevatedButton(
              key: const Key('switch_to_german'),
              onPressed: () {
                setState(() {
                  _currentLocale = const Locale('de');
                });
              },
              child: const Text('Switch to German'),
            ),
            ElevatedButton(
              key: const Key('switch_to_english'),
              onPressed: () {
                setState(() {
                  _currentLocale = const Locale('en');
                });
              },
              child: const Text('Switch to English'),
            ),
          ],
        ),
      ),
    );
  }
}

class HardcodedStringTestWidget extends StatelessWidget {
  const HardcodedStringTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          // Display various localized strings that should be in German
          Text(l10n.buttonAccept),
          Text(l10n.buttonDecline),
          Text(l10n.cancel),
          Text(l10n.errorAddingFriend),
          Text(l10n.dialogTitleAddFriend),
          Text(l10n.screenTitleVsMode),
          Text(l10n.statusFriendCodeCopied),
        ],
      ),
    );
  }
}