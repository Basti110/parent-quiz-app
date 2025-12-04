import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:babycation/services/user_service.dart';
import 'package:babycation/models/user_model.dart';
import 'dart:math';

void main() {
  group('UserService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
    });

    // Helper to create a test user
    Future<UserModel> createTestUser({
      required String userId,
      required DateTime lastActiveAt,
      required int streakCurrent,
      required int streakLongest,
    }) async {
      final now = DateTime.now();
      final currentMonday = _getMondayOfWeek(now);

      final user = UserModel(
        id: userId,
        displayName: 'Test User',
        email: 'test@example.com',
        avatarUrl: null,
        createdAt: now,
        lastActiveAt: lastActiveAt,
        friendCode: 'TEST123',
        totalXp: 0,
        currentLevel: 1,
        weeklyXpCurrent: 0,
        weeklyXpWeekStart: currentMonday,
        streakCurrent: streakCurrent,
        streakLongest: streakLongest,
        duelsPlayed: 0,
        duelsWon: 0,
        duelsLost: 0,
        duelPoints: 0,
      );

      await fakeFirestore.collection('users').doc(userId).set(user.toMap());
      return user;
    }

    // Feature: parent-quiz-app, Property 15: Streak continuation
    // Validates: Requirements 6.2
    group('Property 15: Streak continuation', () {
      test(
        'for any user whose lastActiveAt is yesterday, completing a session should increment streakCurrent by 1',
        () async {
          final random = Random(42); // Seed for reproducibility
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Generate random test data
            final userId = 'user_$i';
            final now = DateTime.now();
            final yesterday = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 1));
            final initialStreak = random.nextInt(50); // Random streak 0-49
            final initialLongest =
                initialStreak + random.nextInt(10); // Longest >= current

            // Create user with lastActiveAt = yesterday
            await createTestUser(
              userId: userId,
              lastActiveAt: yesterday,
              streakCurrent: initialStreak,
              streakLongest: initialLongest,
            );

            // Update streak
            await userService.updateStreak(userId);

            // Verify streak incremented by 1
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.streakCurrent,
              equals(initialStreak + 1),
              reason:
                  'Streak should increment by 1 when lastActiveAt is yesterday (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: parent-quiz-app, Property 16: Streak reset
    // Validates: Requirements 6.3
    group('Property 16: Streak reset', () {
      test(
        'for any user whose lastActiveAt is more than 1 day ago, completing a session should reset streakCurrent to 1',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_reset_$i';
            final now = DateTime.now();

            // Generate lastActiveAt that's 2-30 days ago (more than 1 day)
            final daysAgo = 2 + random.nextInt(29);
            final lastActiveAt = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: daysAgo));

            final initialStreak =
                1 + random.nextInt(100); // Random streak 1-100
            final initialLongest = initialStreak + random.nextInt(50);

            // Create user with old lastActiveAt
            await createTestUser(
              userId: userId,
              lastActiveAt: lastActiveAt,
              streakCurrent: initialStreak,
              streakLongest: initialLongest,
            );

            // Update streak
            await userService.updateStreak(userId);

            // Verify streak reset to 1
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.streakCurrent,
              equals(1),
              reason:
                  'Streak should reset to 1 when lastActiveAt is $daysAgo days ago (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: parent-quiz-app, Property 18: Level calculation
    // Validates: Requirements 7.1
    group('Property 18: Level calculation', () {
      test(
        'for any totalXp value, currentLevel should equal floor(totalXp / 100) + 1',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Generate random XP values from 0 to 10000
            final totalXp = random.nextInt(10001);

            // Calculate expected level
            final expectedLevel = (totalXp ~/ 100) + 1;

            // Test the calculation
            final actualLevel = userService.calculateLevel(totalXp);

            expect(
              actualLevel,
              equals(expectedLevel),
              reason:
                  'Level calculation failed for totalXp=$totalXp (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: parent-quiz-app, Property 21: Weekly XP accumulation
    // Validates: Requirements 8.2
    group('Property 21: Weekly XP accumulation', () {
      test(
        'for any session completed within the current week, the session XP should be added to weeklyXpCurrent',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_weekly_$i';
            final now = DateTime.now();
            final currentMonday = _getMondayOfWeek(now);

            // Generate random initial weekly XP
            final initialWeeklyXp = random.nextInt(1000);

            // Create user with weeklyXpWeekStart = current Monday
            final user = UserModel(
              id: userId,
              displayName: 'Test User',
              email: 'test@example.com',
              avatarUrl: null,
              createdAt: now,
              lastActiveAt: now,
              friendCode: 'TEST$i',
              totalXp: 0,
              currentLevel: 1,
              weeklyXpCurrent: initialWeeklyXp,
              weeklyXpWeekStart: currentMonday,
              streakCurrent: 0,
              streakLongest: 0,
              duelsPlayed: 0,
              duelsWon: 0,
              duelsLost: 0,
              duelPoints: 0,
            );

            await fakeFirestore
                .collection('users')
                .doc(userId)
                .set(user.toMap());

            // Generate random XP gain
            final xpGained = 10 + random.nextInt(100);

            // Update weekly XP
            await userService.updateWeeklyXP(userId, xpGained);

            // Verify XP was added
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.weeklyXpCurrent,
              equals(initialWeeklyXp + xpGained),
              reason:
                  'Weekly XP should accumulate when in same week (iteration $i)',
            );
          }
        },
      );
    });

    // Feature: parent-quiz-app, Property 22: Weekly XP reset
    // Validates: Requirements 8.3
    group('Property 22: Weekly XP reset', () {
      test(
        'for any session completed after the current week ends, weeklyXpCurrent should be reset',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_reset_weekly_$i';
            final now = DateTime.now();
            final currentMonday = _getMondayOfWeek(now);

            // Set weeklyXpWeekStart to a previous week (1-4 weeks ago)
            final weeksAgo = 1 + random.nextInt(4);
            final oldMonday = currentMonday.subtract(
              Duration(days: 7 * weeksAgo),
            );

            // Generate random old weekly XP
            final oldWeeklyXp = 100 + random.nextInt(900);

            // Create user with old week start
            final user = UserModel(
              id: userId,
              displayName: 'Test User',
              email: 'test@example.com',
              avatarUrl: null,
              createdAt: now,
              lastActiveAt: now,
              friendCode: 'TEST$i',
              totalXp: 0,
              currentLevel: 1,
              weeklyXpCurrent: oldWeeklyXp,
              weeklyXpWeekStart: oldMonday,
              streakCurrent: 0,
              streakLongest: 0,
              duelsPlayed: 0,
              duelsWon: 0,
              duelsLost: 0,
              duelPoints: 0,
            );

            await fakeFirestore
                .collection('users')
                .doc(userId)
                .set(user.toMap());

            // Generate random XP gain for new week
            final xpGained = 10 + random.nextInt(100);

            // Update weekly XP (should trigger reset)
            await userService.updateWeeklyXP(userId, xpGained);

            // Verify XP was reset to just the new XP
            final updatedUser = await userService.getUserData(userId);
            expect(
              updatedUser.weeklyXpCurrent,
              equals(xpGained),
              reason:
                  'Weekly XP should reset to new session XP when new week starts (iteration $i)',
            );

            // Verify weeklyXpWeekStart was updated to current Monday
            expect(
              updatedUser.weeklyXpWeekStart.year,
              equals(currentMonday.year),
            );
            expect(
              updatedUser.weeklyXpWeekStart.month,
              equals(currentMonday.month),
            );
            expect(
              updatedUser.weeklyXpWeekStart.day,
              equals(currentMonday.day),
            );
          }
        },
      );
    });
  });
}

DateTime _getMondayOfWeek(DateTime date) {
  final daysFromMonday = date.weekday - DateTime.monday;
  final monday = date.subtract(Duration(days: daysFromMonday));
  return DateTime(monday.year, monday.month, monday.day);
}
