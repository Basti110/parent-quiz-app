import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:babycation/services/history_service.dart';
import 'package:babycation/models/weekly_points.dart';
import 'dart:math';

void main() {
  group('HistoryService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late HistoryService historyService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      historyService = HistoryService(firestore: fakeFirestore);
    });

    // Feature: parent-quiz-app, Property 36: Weekly points persistence
    // Validates: Requirements 11.1
    group('Property 36: Weekly points persistence', () {
      test(
        'for any completed week, a history document should be created with all required fields',
        () async {
          final random = Random(42); // Seed for reproducibility
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_$i';

            // Generate random week start (Monday)
            final now = DateTime.now();
            final weeksAgo = random.nextInt(52); // 0-51 weeks ago
            final weekStart = _getMondayOfWeek(
              now,
            ).subtract(Duration(days: 7 * weeksAgo));

            // Generate random weekly data
            final points = random.nextInt(1000);
            final sessionsCompleted = random.nextInt(50);
            final questionsAnswered = random.nextInt(500);
            final correctAnswers = random.nextInt(questionsAnswered + 1);

            // Save weekly points
            await historyService.saveWeeklyPoints(
              userId,
              weekStart,
              points,
              sessionsCompleted: sessionsCompleted,
              questionsAnswered: questionsAnswered,
              correctAnswers: correctAnswers,
            );

            // Retrieve the saved document
            final dateKey = _formatDate(weekStart);
            final doc = await fakeFirestore
                .collection('users')
                .doc(userId)
                .collection('history')
                .doc(dateKey)
                .get();

            // Verify document exists
            expect(
              doc.exists,
              isTrue,
              reason: 'History document should exist (iteration $i)',
            );

            // Verify all required fields are present
            final data = doc.data()!;
            expect(
              data.containsKey('date'),
              isTrue,
              reason: 'Document should contain date field (iteration $i)',
            );
            expect(
              data.containsKey('weekStart'),
              isTrue,
              reason: 'Document should contain weekStart field (iteration $i)',
            );
            expect(
              data.containsKey('weekEnd'),
              isTrue,
              reason: 'Document should contain weekEnd field (iteration $i)',
            );
            expect(
              data.containsKey('points'),
              isTrue,
              reason: 'Document should contain points field (iteration $i)',
            );
            expect(
              data.containsKey('sessionsCompleted'),
              isTrue,
              reason:
                  'Document should contain sessionsCompleted field (iteration $i)',
            );
            expect(
              data.containsKey('questionsAnswered'),
              isTrue,
              reason:
                  'Document should contain questionsAnswered field (iteration $i)',
            );
            expect(
              data.containsKey('correctAnswers'),
              isTrue,
              reason:
                  'Document should contain correctAnswers field (iteration $i)',
            );

            // Verify field values
            final weeklyPoints = WeeklyPoints.fromMap(data, dateKey);
            expect(
              weeklyPoints.points,
              equals(points),
              reason: 'Points should match (iteration $i)',
            );
            expect(
              weeklyPoints.sessionsCompleted,
              equals(sessionsCompleted),
              reason: 'Sessions completed should match (iteration $i)',
            );
            expect(
              weeklyPoints.questionsAnswered,
              equals(questionsAnswered),
              reason: 'Questions answered should match (iteration $i)',
            );
            expect(
              weeklyPoints.correctAnswers,
              equals(correctAnswers),
              reason: 'Correct answers should match (iteration $i)',
            );

            // Verify weekEnd is 6 days after weekStart
            final expectedWeekEnd = weekStart.add(const Duration(days: 6));
            expect(
              weeklyPoints.weekEnd.year,
              equals(expectedWeekEnd.year),
              reason: 'Week end year should be correct (iteration $i)',
            );
            expect(
              weeklyPoints.weekEnd.month,
              equals(expectedWeekEnd.month),
              reason: 'Week end month should be correct (iteration $i)',
            );
            expect(
              weeklyPoints.weekEnd.day,
              equals(expectedWeekEnd.day),
              reason: 'Week end day should be correct (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: parent-quiz-app, Property 37: History date format
    // Validates: Requirements 11.1
    group('Property 37: History date format', () {
      test(
        'for any history document, the date field should be in yyyy-MM-dd format representing the Monday',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_date_$i';

            // Generate random week start (Monday)
            final now = DateTime.now();
            final weeksAgo = random.nextInt(52);
            final weekStart = _getMondayOfWeek(
              now,
            ).subtract(Duration(days: 7 * weeksAgo));

            final points = random.nextInt(1000);

            // Save weekly points
            await historyService.saveWeeklyPoints(userId, weekStart, points);

            // Retrieve the saved document
            final dateKey = _formatDate(weekStart);
            final doc = await fakeFirestore
                .collection('users')
                .doc(userId)
                .collection('history')
                .doc(dateKey)
                .get();

            final data = doc.data()!;
            final weeklyPoints = WeeklyPoints.fromMap(data, dateKey);

            // Verify date format is yyyy-MM-dd
            final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
            expect(
              dateRegex.hasMatch(weeklyPoints.date),
              isTrue,
              reason: 'Date should match yyyy-MM-dd format (iteration $i)',
            );

            // Verify date represents the Monday
            final dateParts = weeklyPoints.date.split('-');
            final year = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final day = int.parse(dateParts[2]);

            expect(
              year,
              equals(weekStart.year),
              reason: 'Date year should match weekStart year (iteration $i)',
            );
            expect(
              month,
              equals(weekStart.month),
              reason: 'Date month should match weekStart month (iteration $i)',
            );
            expect(
              day,
              equals(weekStart.day),
              reason: 'Date day should match weekStart day (iteration $i)',
            );

            // Verify the date is actually a Monday
            final parsedDate = DateTime(year, month, day);
            expect(
              parsedDate.weekday,
              equals(DateTime.monday),
              reason: 'Date should represent a Monday (iteration $i)',
            );
          }
        },
      );
    });

    group('getPointsHistory', () {
      test('should retrieve history ordered by date descending', () async {
        final userId = 'user_history';
        final now = DateTime.now();
        final currentMonday = _getMondayOfWeek(now);

        // Create history for 3 weeks
        for (int i = 0; i < 3; i++) {
          final weekStart = currentMonday.subtract(Duration(days: 7 * i));
          await historyService.saveWeeklyPoints(
            userId,
            weekStart,
            100 * (i + 1),
          );
        }

        // Retrieve history
        final history = await historyService.getPointsHistory(userId);

        // Verify we got 3 entries
        expect(history.length, equals(3));

        // Verify they're ordered by date descending (most recent first)
        for (int i = 0; i < history.length - 1; i++) {
          expect(
            history[i].weekStart.isAfter(history[i + 1].weekStart) ||
                history[i].weekStart.isAtSameMomentAs(history[i + 1].weekStart),
            isTrue,
            reason: 'History should be ordered by date descending',
          );
        }
      });

      test('should respect limit parameter', () async {
        final userId = 'user_limit';
        final now = DateTime.now();
        final currentMonday = _getMondayOfWeek(now);

        // Create history for 5 weeks
        for (int i = 0; i < 5; i++) {
          final weekStart = currentMonday.subtract(Duration(days: 7 * i));
          await historyService.saveWeeklyPoints(
            userId,
            weekStart,
            100 * (i + 1),
          );
        }

        // Retrieve with limit
        final history = await historyService.getPointsHistory(userId, limit: 3);

        // Verify we got only 3 entries
        expect(history.length, equals(3));
      });
    });
  });
}

DateTime _getMondayOfWeek(DateTime date) {
  final daysFromMonday = date.weekday - DateTime.monday;
  final monday = date.subtract(Duration(days: daysFromMonday));
  return DateTime(monday.year, monday.month, monday.day);
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
