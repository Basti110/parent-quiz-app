import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/user_service.dart';
import 'package:eduparo/models/user_model.dart';
import 'dart:math';

void main() {
  group('UserService - Streak-Based System', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
    });

    // Helper to create a test user with new schema
    Future<UserModel> createTestUser({
      required String userId,
      required DateTime lastActiveAt,
      required int streakCurrent,
      required int streakLongest,
      int dailyGoal = 10,
      int questionsAnsweredToday = 0,
      DateTime? lastDailyReset,
    }) async {
      final now = DateTime.now();

      final user = UserModel(
        id: userId,
        displayName: 'Test User',
        email: 'test@example.com',
        avatarUrl: null,
        createdAt: now,
        lastActiveAt: lastActiveAt,
        friendCode: 'TEST123',
        streakCurrent: streakCurrent,
        streakLongest: streakLongest,
        streakPoints: 0,
        dailyGoal: dailyGoal,
        questionsAnsweredToday: questionsAnsweredToday,
        lastDailyReset: lastDailyReset ?? now,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalMasteredQuestions: 0,
        duelsCompleted: 0,
        duelsWon: 0,
      );

      await fakeFirestore.collection('users').doc(userId).set(user.toMap());
      return user;
    }

    // ========================================================================
    // PROPERTY TESTS FOR STREAK-BASED SYSTEM (Task 2)
    // ========================================================================

    // Feature: simplified-gamification, Property 1: Daily goal bounds
    // Validates: Requirements 1.3
    group('Property 1: Daily goal bounds', () {
      test(
        'for any daily goal value, the system should only accept values between 1 and 50 (inclusive)',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_daily_goal_$i';

            // Create a test user with new schema
            await createTestUser(
              userId: userId,
              lastActiveAt: DateTime.now(),
              streakCurrent: 0,
              streakLongest: 0,
            );

            // Test valid values (1-50)
            final validGoal = 1 + random.nextInt(50); // 1 to 50
            await userService.updateDailyGoal(userId, validGoal);
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.dailyGoal,
              equals(validGoal),
              reason: 'Valid goal $validGoal should be accepted (iteration $i)',
            );

            // Test invalid values (< 1 or > 50)
            final invalidGoals = [
              0,
              -1,
              -random.nextInt(100),
              51,
              52,
              51 + random.nextInt(100),
            ];

            for (final invalidGoal in invalidGoals) {
              expect(
                () => userService.updateDailyGoal(userId, invalidGoal),
                throwsA(isA<ArgumentError>()),
                reason:
                    'Invalid goal $invalidGoal should be rejected (iteration $i)',
              );
            }
          }
        },
      );
    });

    // Feature: simplified-gamification, Property 6: Streak reset
    // Validates: Requirements 2.3
    group('Property 6: Streak reset', () {
      test(
        'for any user who fails to meet their daily goal for a calendar day, the current streak should reset to 0',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_streak_reset_$i';
            final now = DateTime.now();

            // Generate lastActiveAt that's 2-30 days ago (missed days)
            final daysAgo = 2 + random.nextInt(29);
            final lastActiveAt = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: daysAgo));

            final initialStreak = 1 + random.nextInt(100); // Random streak 1-100
            final dailyGoal = 5 + random.nextInt(20); // Random goal 5-24
            final questionsAnswered = dailyGoal; // Met goal today

            // Create user with old lastActiveAt and current streak
            await createTestUser(
              userId: userId,
              lastActiveAt: lastActiveAt,
              streakCurrent: initialStreak,
              streakLongest: initialStreak + random.nextInt(50),
              dailyGoal: dailyGoal,
              questionsAnsweredToday: questionsAnswered,
            );

            // Check and update streak (should reset because of gap)
            await userService.checkAndUpdateStreak(userId);

            // Verify streak reset to 0
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.streakCurrent,
              equals(0),
              reason:
                  'Streak should reset to 0 when lastActiveAt is $daysAgo days ago (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: simplified-gamification, Property 10: Three points per additional day
    // Validates: Requirements 3.2
    group('Property 10: Three points per additional day', () {
      test(
        'for any user with a streak greater than 3, each additional consecutive day should award exactly 3 streak points',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Test streaks from 4 to 100
            final currentStreak = 4 + random.nextInt(97);

            // Calculate expected points
            final expectedPoints = userService.calculateStreakPoints(currentStreak);

            expect(
              expectedPoints,
              equals(3),
              reason:
                  'Streak day $currentStreak should award 3 points (iteration $i)',
            );
          }
        },
      );

      test(
        'for any user with streak of 1 or 2, no streak points should be awarded',
        () {
          expect(userService.calculateStreakPoints(1), equals(0));
          expect(userService.calculateStreakPoints(2), equals(0));
        },
      );

      test(
        'for any user reaching exactly 3 consecutive days, exactly 3 streak points should be awarded',
        () {
          expect(userService.calculateStreakPoints(3), equals(3));
        },
      );
    });
  });
}
