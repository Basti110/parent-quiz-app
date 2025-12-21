import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/l10n/app_localizations.dart';

void main() {
  group('UI Layout Validation Tests', () {
    testWidgets('German text layout - Basic UI elements', (WidgetTester tester) async {
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
              appBar: AppBar(
                title: const Text('VS Modus Einrichtung'),
              ),
              body: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Willkommen zurück!'),
                    Text('Bitte melde dich an, um die Bestenliste anzuzeigen'),
                    Text('Authentifizierung fehlgeschlagen. Bitte überprüfe deine Anmeldedaten.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for text overflow in German
      expect(tester.takeException(), isNull);
      
      // Verify key German text elements are displayed
      expect(find.text('VS Modus Einrichtung'), findsOneWidget);
      expect(find.text('Willkommen zurück!'), findsOneWidget);
    });

    testWidgets('Text length comparison - English vs German', (WidgetTester tester) async {
      // Test that German translations don't cause layout issues
      const testCases = [
        ('Login', 'Anmelden'),
        ('Register', 'Registrieren'),
        ('Settings', 'Einstellungen'),
        ('Friends', 'Freunde'),
        ('Leaderboard', 'Bestenliste'),
        ('VS Mode Setup', 'VS Modus Einrichtung'),
        ('Select Category', 'Kategorie auswählen'),
        ('Questions Answered', 'Beantwortete Fragen'),
        ('Questions Mastered', 'Gemeisterte Fragen'),
        ('Friend Code', 'Freundescode'),
        ('Add Friend', 'Freund hinzufügen'),
        ('Challenge to duel', 'Zum Duell herausfordern'),
        ('Authentication failed. Please check your credentials.', 
         'Authentifizierung fehlgeschlagen. Bitte überprüfe deine Anmeldedaten.'),
      ];

      for (final (english, german) in testCases) {
        // German text should not be excessively longer than English
        // Generally, German can be 20-30% longer, but shouldn't exceed 100%
        final lengthRatio = german.length / english.length;
        expect(lengthRatio, lessThan(2.0), 
          reason: 'German text "$german" is too much longer than English "$english" (ratio: ${lengthRatio.toStringAsFixed(2)})');
      }
    });

    testWidgets('Button text layout validation', (WidgetTester tester) async {
      // Test button text in German doesn't overflow
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 200, // Constrained width to test overflow
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Herausforderung annehmen'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Freund hinzufügen'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Duell starten'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Kategorie auswählen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for text overflow
      expect(tester.takeException(), isNull);
      
      // Verify all button texts are visible
      expect(find.text('Herausforderung annehmen'), findsOneWidget);
      expect(find.text('Freund hinzufügen'), findsOneWidget);
      expect(find.text('Duell starten'), findsOneWidget);
      expect(find.text('Kategorie auswählen'), findsOneWidget);
    });

    testWidgets('Dialog text layout validation', (WidgetTester tester) async {
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
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Duell beenden?'),
                        content: const Text('Dein Fortschritt wird gespeichert und du kannst später fortfahren.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Beenden'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check for text overflow in dialog
      expect(tester.takeException(), isNull);
      
      // Verify dialog content is displayed properly
      expect(find.text('Duell beenden?'), findsOneWidget);
      expect(find.text('Dein Fortschritt wird gespeichert und du kannst später fortfahren.'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Beenden'), findsOneWidget);
    });

    testWidgets('Form field layout validation', (WidgetTester tester) async {
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
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Freundescode',
                        hintText: 'z.B. ABC123',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Anzeigename',
                        hintText: 'Gib deinen Namen ein',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'E-Mail-Adresse',
                        hintText: 'beispiel@email.com',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for text overflow in form fields
      expect(tester.takeException(), isNull);
      
      // Verify form field labels are displayed properly
      expect(find.text('Freundescode'), findsOneWidget);
      expect(find.text('Anzeigename'), findsOneWidget);
      expect(find.text('E-Mail-Adresse'), findsOneWidget);
    });

    testWidgets('Long German compound words layout test', (WidgetTester tester) async {
      // Test some of the longest German translations
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test long German words in constrained containers
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text('Authentifizierung fehlgeschlagen. Bitte überprüfe deine Anmeldedaten.'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text('Freundschaftsanfrage'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text('Herausforderung annehmen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for text overflow
      expect(tester.takeException(), isNull);
      
      // Verify long German texts are handled properly
      expect(find.text('Authentifizierung fehlgeschlagen. Bitte überprüfe deine Anmeldedaten.'), findsOneWidget);
      expect(find.text('Freundschaftsanfrage'), findsOneWidget);
      expect(find.text('Herausforderung annehmen'), findsOneWidget);
    });
  });
}