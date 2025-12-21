import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduparo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('Language Selection Localization Tests', () {
    testWidgets('should have correct language labels in English', (WidgetTester tester) async {
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
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Get the localization instance
      final context = tester.element(find.byType(TestWidget));
      final l10n = AppLocalizations.of(context)!;

      // Verify language labels are in their native form
      expect(l10n.languageEnglish, equals('English'));
      expect(l10n.languageGerman, equals('Deutsch'));
    });

    testWidgets('should have same language labels in German locale', (WidgetTester tester) async {
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
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Get the localization instance
      final context = tester.element(find.byType(TestWidget));
      final l10n = AppLocalizations.of(context)!;

      // Verify language labels are still in their native form (same as English)
      expect(l10n.languageEnglish, equals('English'));
      expect(l10n.languageGerman, equals('Deutsch'));
      
      // Verify other text is properly localized to German
      expect(l10n.language, equals('Sprache'));
      expect(l10n.cancel, equals('Abbrechen'));
    });

    testWidgets('should display language names correctly in UI', (WidgetTester tester) async {
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
          home: LanguageSelectionTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both language names are displayed
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
    });
  });
}

// Simple test widget to access localization
class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Test'),
      ),
    );
  }
}

// Test widget that displays language selection similar to the real implementation
class LanguageSelectionTestWidget extends StatelessWidget {
  const LanguageSelectionTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          Text(l10n.languageEnglish),
          Text(l10n.languageGerman),
        ],
      ),
    );
  }
}