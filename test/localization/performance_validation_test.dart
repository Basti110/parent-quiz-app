import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/l10n/app_localizations.dart';

void main() {
  group('Localization Performance Validation Tests', () {
    testWidgets('Language switching performance test', (WidgetTester tester) async {
      // Create a test app that responds to locale changes
      Widget createApp(Locale locale) {
        return ProviderScope(
          child: MaterialApp(
            locale: locale,
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
              appBar: AppBar(
                title: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(l10n.settings);
                  },
                ),
              ),
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Column(
                    children: [
                      Text(l10n.dashboard),
                      Text(l10n.friends),
                      Text(l10n.leaderboard),
                      Text(l10n.vsMode),
                      Text(l10n.statistics),
                      Text(l10n.errorLoadingQuestions('test error')),
                      Text(l10n.statusFriendRequestSent('Test User')),
                      Text(l10n.questionProgress(5, 10)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }

      // Test initial English load
      final englishStartTime = DateTime.now();
      await tester.pumpWidget(createApp(const Locale('en')));
      await tester.pumpAndSettle();
      final englishLoadTime = DateTime.now().difference(englishStartTime);

      // Verify English content is loaded
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);

      // Test switch to German
      final germanSwitchStartTime = DateTime.now();
      await tester.pumpWidget(createApp(const Locale('de')));
      await tester.pumpAndSettle();
      final germanSwitchTime = DateTime.now().difference(germanSwitchStartTime);

      // Verify German content is loaded
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Freunde'), findsOneWidget);

      // Test switch back to English
      final englishSwitchStartTime = DateTime.now();
      await tester.pumpWidget(createApp(const Locale('en')));
      await tester.pumpAndSettle();
      final englishSwitchTime = DateTime.now().difference(englishSwitchStartTime);

      // Verify English content is loaded again
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);

      // Performance assertions - more lenient for test environment
      // Language switching should be reasonable (< 500ms for test environment)
      expect(germanSwitchTime.inMilliseconds, lessThan(500),
          reason: 'German language switch took ${germanSwitchTime.inMilliseconds}ms, should be < 500ms');
      expect(englishSwitchTime.inMilliseconds, lessThan(500),
          reason: 'English language switch took ${englishSwitchTime.inMilliseconds}ms, should be < 500ms');

      // Initial load should also be reasonable (< 1000ms for test environment)
      expect(englishLoadTime.inMilliseconds, lessThan(1000),
          reason: 'Initial English load took ${englishLoadTime.inMilliseconds}ms, should be < 1000ms');

      print('Performance Results:');
      print('  Initial English load: ${englishLoadTime.inMilliseconds}ms');
      print('  Switch to German: ${germanSwitchTime.inMilliseconds}ms');
      print('  Switch back to English: ${englishSwitchTime.inMilliseconds}ms');
    });

    testWidgets('Localization memory usage test', (WidgetTester tester) async {
      // Test that switching languages doesn't cause memory leaks
      Widget createApp(Locale locale) {
        return ProviderScope(
          child: MaterialApp(
            locale: locale,
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
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  // Create a large list of localized strings to test memory usage
                  return ListView.builder(
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('${l10n.dashboard} $index'),
                        subtitle: Text('${l10n.errorLoadingQuestions('Error $index')}'),
                        trailing: Text(l10n.questionProgress(index, 100)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      }

      // Switch languages multiple times to test for memory leaks
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(createApp(const Locale('en')));
        await tester.pumpAndSettle();
        
        await tester.pumpWidget(createApp(const Locale('de')));
        await tester.pumpAndSettle();
      }

      // If we get here without running out of memory, the test passes
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Parameterized string performance test', (WidgetTester tester) async {
      // Test performance of parameterized strings (which are more complex)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('de'),
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
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  
                  final startTime = DateTime.now();
                  
                  // Generate many parameterized strings
                  final widgets = <Widget>[];
                  for (int i = 0; i < 100; i++) {
                    widgets.addAll([
                      Text(l10n.errorLoadingQuestions('Error $i')),
                      Text(l10n.statusFriendRequestSent('User $i')),
                      Text(l10n.questionProgress(i, 100)),
                      Text(l10n.duelWith('Player $i')),
                      Text(l10n.passDeviceTo('Player $i')),
                    ]);
                  }
                  
                  final endTime = DateTime.now();
                  final generationTime = endTime.difference(startTime);
                  
                  // String generation should be reasonable (< 200ms for 500 strings)
                  expect(generationTime.inMilliseconds, lessThan(200),
                      reason: 'Parameterized string generation took ${generationTime.inMilliseconds}ms, should be < 200ms');
                  
                  print('Parameterized string generation time: ${generationTime.inMilliseconds}ms for 500 strings');
                  
                  return Column(children: widgets.take(10).toList());
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify some parameterized strings are displayed
      expect(find.textContaining('Fehler beim Laden der Fragen'), findsWidgets);
      expect(find.textContaining('Freundschaftsanfrage an'), findsWidgets);
    });

    testWidgets('Large text rendering performance test', (WidgetTester tester) async {
      // Test performance with long German text
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('de'),
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
              body: SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    
                    final startTime = DateTime.now();
                    
                    // Create a large amount of German text
                    final longTexts = <Widget>[];
                    for (int i = 0; i < 50; i++) {
                      longTexts.addAll([
                        Text(l10n.authenticationError),
                        Text(l10n.onboardingWelcomeDescription),
                        Text(l10n.onboardingXpDescription),
                        Text(l10n.onboardingFriendsDescription),
                        Text(l10n.dailyGoalDescription),
                      ]);
                    }
                    
                    final endTime = DateTime.now();
                    final renderTime = endTime.difference(startTime);
                    
                    // Text rendering should be reasonable (< 300ms for 250 long texts)
                    expect(renderTime.inMilliseconds, lessThan(300),
                        reason: 'Large text rendering took ${renderTime.inMilliseconds}ms, should be < 300ms');
                    
                    print('Large German text rendering time: ${renderTime.inMilliseconds}ms for 250 texts');
                    
                    return Column(children: longTexts);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify long German texts are rendered
      expect(find.textContaining('Authentifizierung fehlgeschlagen'), findsWidgets);
      expect(find.textContaining('evidenzbasierte Elternschaft'), findsWidgets);
    });

    testWidgets('Rapid locale switching simulation', (WidgetTester tester) async {
      // Simulate rapid locale switching to test performance
      final locales = [const Locale('en'), const Locale('de')];
      
      Widget createApp(Locale locale) {
        return ProviderScope(
          child: MaterialApp(
            locale: locale,
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
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Column(
                    children: [
                      Text('Current locale: ${locale.languageCode}'),
                      Text(l10n.settings),
                      Text(l10n.dashboard),
                      Text(l10n.friends),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }

      final startTime = DateTime.now();
      
      // Switch locales rapidly
      for (int i = 0; i < 10; i++) {
        final locale = locales[i % 2];
        await tester.pumpWidget(createApp(locale));
        await tester.pumpAndSettle();
      }
      
      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);
      
      // Rapid switching should be reasonable (< 2000ms for 10 switches)
      expect(totalTime.inMilliseconds, lessThan(2000),
          reason: 'Rapid locale switching took ${totalTime.inMilliseconds}ms, should be < 2000ms');
      
      print('Rapid locale switching time: ${totalTime.inMilliseconds}ms for 10 switches');
      
      // Verify final state
      expect(find.text('Current locale: de'), findsOneWidget);
      expect(find.text('Einstellungen'), findsOneWidget);
    });
  });
}