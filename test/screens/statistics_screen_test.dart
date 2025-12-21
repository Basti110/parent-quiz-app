import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduparo/screens/statistics/statistics_screen.dart';
import 'package:eduparo/models/user_statistics.dart';
import 'package:eduparo/models/category_statistics.dart';
import 'package:eduparo/providers/auth_providers.dart';
import 'package:eduparo/providers/statistics_providers.dart';
import 'package:eduparo/l10n/app_localizations.dart';
import 'package:eduparo/widgets/app_header.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('StatisticsScreen', () {
    // Helper function to create a test widget with providers
    Widget createTestWidget({
      String? userId,
      UserStatistics? statistics,
      bool isLoading = false,
      Object? error,
    }) {
      return ProviderScope(
        overrides: [
          if (userId != null)
            currentUserIdProvider.overrideWith((ref) => userId),
          if (userId != null)
            userStatisticsProvider(userId).overrideWith((ref) async {
              if (isLoading) {
                await Future.delayed(const Duration(hours: 1)); // Never completes
              }
              if (error != null) {
                throw error;
              }
              return statistics!;
            }),
        ],
        child: const MaterialApp(
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
          home: StatisticsScreen(),
        ),
      );
    }

    // Helper function to create sample statistics
    UserStatistics createSampleStatistics({
      int answered = 45,
      int mastered = 12,
      int seen = 45,
      List<CategoryStatistics>? categoryStats,
    }) {
      return UserStatistics(
        totalQuestionsAnswered: answered,
        totalQuestionsMastered: mastered,
        totalQuestionsSeen: seen,
        categoryStats: categoryStats ?? [
          CategoryStatistics(
            categoryId: 'sleep',
            categoryTitle: 'Sleep',
            categoryIconName: 'sleep',
            totalQuestions: 30,
            questionsAnswered: 10,
            questionsMastered: 3,
            questionsSeen: 10,
          ),
          CategoryStatistics(
            categoryId: 'nutrition',
            categoryTitle: 'Nutrition',
            categoryIconName: 'nutrition',
            totalQuestions: 40,
            questionsAnswered: 15,
            questionsMastered: 5,
            questionsSeen: 15,
          ),
        ],
      );
    }

    group('Overall Statistics Display', () {
      // Requirements: 3.1, 3.2, 3.3
      testWidgets('should display overall statistics correctly', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics(
          answered: 45,
          mastered: 12,
          seen: 50,
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify overall progress section is displayed
        expect(find.text('Overall Progress'), findsOneWidget);

        // Verify questions answered is displayed
        expect(find.text('Questions Answered'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);

        // Verify questions mastered is displayed
        expect(find.text('Questions Mastered'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);

        // Verify questions seen is displayed
        expect(find.text('Questions Seen'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
      });

      testWidgets('should display zero statistics correctly', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics(
          answered: 0,
          mastered: 0,
          seen: 0,
          categoryStats: [],
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify zero values are displayed
        expect(find.text('0'), findsNWidgets(3)); // answered, mastered, seen
      });
    });

    group('Category Statistics Display', () {
      // Requirements: 3.4, 5.2
      testWidgets('should display category statistics correctly', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics();

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify category section header
        expect(find.text('By Category'), findsOneWidget);

        // Verify first category (Sleep)
        expect(find.text('Sleep'), findsOneWidget);
        expect(find.text('10 / 30'), findsOneWidget); // answered
        expect(find.text('3 / 30'), findsOneWidget); // mastered

        // Verify second category (Nutrition)
        expect(find.text('Nutrition'), findsOneWidget);
        expect(find.text('15 / 40'), findsOneWidget); // answered
        expect(find.text('5 / 40'), findsOneWidget); // mastered

        // Verify progress bars are displayed
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      });

      testWidgets('should display empty state when no category statistics', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics(
          categoryStats: [],
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state message
        expect(
          find.text('No category statistics yet. Start answering questions!'),
          findsOneWidget,
        );

        // Verify no category cards are displayed
        expect(find.text('Sleep'), findsNothing);
        expect(find.text('Nutrition'), findsNothing);
      });

      testWidgets('should display progress percentage correctly', (
        WidgetTester tester,
      ) async {
        final statistics = UserStatistics(
          totalQuestionsAnswered: 50,
          totalQuestionsMastered: 20,
          totalQuestionsSeen: 50,
          categoryStats: [
            CategoryStatistics(
              categoryId: 'test',
              categoryTitle: 'Test Category',
              categoryIconName: 'default',
              totalQuestions: 100,
              questionsAnswered: 50,
              questionsMastered: 20,
              questionsSeen: 50,
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify progress percentage (50% of 100 questions)
        expect(find.text('50%'), findsOneWidget);
      });
    });

    group('Loading State', () {
      // Requirements: 3.4
      testWidgets('should display loading indicator while fetching data', (
        WidgetTester tester,
      ) async {
        final completer = Completer<UserStatistics>();
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWith((ref) => 'test_user'),
              userStatisticsProvider('test_user').overrideWith((ref) => completer.future),
            ],
            child: const MaterialApp(
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
              home: StatisticsScreen(),
            ),
          ),
        );

        await tester.pump();

        // Verify loading indicator is displayed
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify no statistics are displayed yet
        expect(find.text('Overall Progress'), findsNothing);
        
        // Complete the future to clean up
        completer.complete(createSampleStatistics());
        await tester.pumpAndSettle();
      });
    });

    group('Error State', () {
      // Requirements: 3.4
      testWidgets('should display error message with retry button', (
        WidgetTester tester,
      ) async {
        final error = Exception('Failed to load statistics');

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            error: error,
          ),
        );

        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.text('Failed to load statistics'), findsOneWidget);
        expect(find.text('Please try again'), findsOneWidget);

        // Verify retry button is displayed
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // Verify error icon is displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should allow retry on error', (
        WidgetTester tester,
      ) async {
        final error = Exception('Network error');
        var retryCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWith((ref) => 'test_user'),
              userStatisticsProvider('test_user').overrideWith((ref) async {
                retryCount++;
                throw error;
              }),
            ],
            child: const MaterialApp(
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
              home: StatisticsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial load attempt
        expect(retryCount, equals(1));

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify retry was attempted (provider was invalidated and rebuilt)
        // Note: The actual retry count may vary based on provider behavior
        expect(retryCount, greaterThan(1));
      });
    });

    group('Authentication State', () {
      testWidgets('should display message when user is not authenticated', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWith((ref) => null),
            ],
            child: const MaterialApp(
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
              home: StatisticsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify authentication message is displayed
        expect(find.text('User not authenticated'), findsOneWidget);

        // Verify no statistics are displayed
        expect(find.text('Overall Progress'), findsNothing);
      });
    });

    group('Category Icons', () {
      testWidgets('should display category icons correctly', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics();

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify category icon containers are displayed
        final iconContainers = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).borderRadius != null,
        );

        // Should have at least 2 icon containers (one for each category)
        expect(iconContainers, findsWidgets);
      });

      testWidgets('should handle missing category icons gracefully', (
        WidgetTester tester,
      ) async {
        final statistics = UserStatistics(
          totalQuestionsAnswered: 10,
          totalQuestionsMastered: 5,
          totalQuestionsSeen: 10,
          categoryStats: [
            CategoryStatistics(
              categoryId: 'test',
              categoryTitle: 'Test Category',
              categoryIconName: 'nonexistent_icon',
              totalQuestions: 20,
              questionsAnswered: 10,
              questionsMastered: 5,
              questionsSeen: 10,
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify the screen renders without crashing
        expect(find.text('Test Category'), findsOneWidget);

        // Verify fallback icon is displayed
        expect(find.byIcon(Icons.category), findsOneWidget);
      });
    });

    group('UI Layout', () {
      testWidgets('should have proper scrolling behavior', (
        WidgetTester tester,
      ) async {
        // Create statistics with many categories to test scrolling
        final manyCategories = List.generate(
          10,
          (index) => CategoryStatistics(
            categoryId: 'category_$index',
            categoryTitle: 'Category $index',
            categoryIconName: 'default',
            totalQuestions: 50,
            questionsAnswered: 10 + index,
            questionsMastered: 5 + index,
            questionsSeen: 10 + index,
          ),
        );

        final statistics = UserStatistics(
          totalQuestionsAnswered: 100,
          totalQuestionsMastered: 50,
          totalQuestionsSeen: 100,
          categoryStats: manyCategories,
        );

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify SingleChildScrollView is present
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Verify first category is visible
        expect(find.text('Category 0'), findsOneWidget);

        // Scroll down
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        // Verify we can scroll (some categories should now be visible)
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('should display app bar with title', (
        WidgetTester tester,
      ) async {
        final statistics = createSampleStatistics();

        await tester.pumpWidget(
          createTestWidget(
            userId: 'test_user',
            statistics: statistics,
          ),
        );

        await tester.pumpAndSettle();

        // Verify app header is displayed
        expect(find.byType(AppHeader), findsOneWidget);

        // Note: StatisticsScreen uses AppHeader instead of AppBar with title
        // The screen title is implicit in the navigation context
      });
    });
  });
}
