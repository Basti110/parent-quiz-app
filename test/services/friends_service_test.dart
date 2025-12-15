import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/friends_service.dart';
import 'package:eduparo/models/user_model.dart';
import 'package:eduparo/models/friend.dart';
import 'dart:math';

void main() {
  group('FriendsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FriendsService friendsService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      friendsService = FriendsService(firestore: fakeFirestore);
    });

    // Helper to create a test user
    Future<UserModel> createTestUser({
      required String userId,
      required String displayName,
      required int duelsWon,
      required int duelsLost,
    }) async {
      final now = DateTime.now();
      final currentMonday = _getMondayOfWeek(now);

      final user = UserModel(
        id: userId,
        displayName: displayName,
        email: '$userId@example.com',
        avatarUrl: null,
        createdAt: now,
        lastActiveAt: now,
        friendCode: 'CODE$userId',
        streakCurrent: 0,
        streakLongest: 0,
        streakPoints: 0,
        dailyGoal: 10,
        questionsAnsweredToday: 0,
        lastDailyReset: now,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalMasteredQuestions: 0,
        duelsCompleted: duelsWon + duelsLost,
        duelsWon: duelsWon,
      );

      await fakeFirestore.collection('users').doc(userId).set(user.toMap());
      return user;
    }

    // Helper to add a friend relationship
    Future<void> addFriendRelationship(
      String userId,
      String friendUserId,
    ) async {
      final friend = Friend(
        friendUserId: friendUserId,
        status: 'accepted',
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendUserId)
          .set(friend.toMap());
    }

    // Feature: ui-redesign-i18n, Property 7: Friend list ordering
    // Validates: Requirements 3.2
    group('Property 7: Friend list ordering', () {
      test(
        'for any friends list, calling getFriends multiple times should return friends in consistent order',
        () async {
          final random = Random(42); // Seed for reproducibility
          const iterations = 50;

          for (int i = 0; i < iterations; i++) {
            // Create a new user for this iteration
            final userId = 'user_$i';
            await createTestUser(
              userId: userId,
              displayName: 'User $i',
              duelsWon: 0,
              duelsLost: 0,
            );

            // Generate random number of friends (3-10)
            final numFriends = 3 + random.nextInt(8);
            final friendIds = <String>[];

            // Create friends with random stats
            for (int j = 0; j < numFriends; j++) {
              final friendId = 'friend_${i}_$j';
              friendIds.add(friendId);

              await createTestUser(
                userId: friendId,
                displayName:
                    'Friend ${String.fromCharCode(65 + j)}', // A, B, C, etc.
                duelsWon: random.nextInt(50),
                duelsLost: random.nextInt(50),
              );

              // Add friend relationship
              await addFriendRelationship(userId, friendId);
            }

            // Call getFriends multiple times
            final firstCall = await friendsService.getFriends(userId);
            final secondCall = await friendsService.getFriends(userId);
            final thirdCall = await friendsService.getFriends(userId);

            // Extract display names for comparison
            final firstOrder = firstCall.map((f) => f.displayName).toList();
            final secondOrder = secondCall.map((f) => f.displayName).toList();
            final thirdOrder = thirdCall.map((f) => f.displayName).toList();

            // Verify all calls return the same order
            expect(
              secondOrder,
              equals(firstOrder),
              reason:
                  'Second call should return friends in same order as first call (iteration $i)',
            );

            expect(
              thirdOrder,
              equals(firstOrder),
              reason:
                  'Third call should return friends in same order as first call (iteration $i)',
            );

            // Verify the list is not empty
            expect(
              firstCall.length,
              equals(numFriends),
              reason: 'Should return all $numFriends friends (iteration $i)',
            );
          }
        },
      );

      test(
        'for any friends list, friends should be ordered by display name alphabetically',
        () async {
          final random = Random(42);
          const iterations = 50;

          for (int i = 0; i < iterations; i++) {
            final userId = 'user_alpha_$i';
            await createTestUser(
              userId: userId,
              displayName: 'User $i',
              duelsWon: 0,
              duelsLost: 0,
            );

            // Generate random number of friends (3-10)
            final numFriends = 3 + random.nextInt(8);
            final expectedNames = <String>[];

            // Create friends with random names
            for (int j = 0; j < numFriends; j++) {
              final friendId = 'friend_alpha_${i}_$j';

              // Generate random name to ensure varied ordering
              final nameIndex = random.nextInt(26);
              final displayName =
                  'Friend ${String.fromCharCode(65 + nameIndex)}$j';
              expectedNames.add(displayName);

              await createTestUser(
                userId: friendId,
                displayName: displayName,
                duelsWon: random.nextInt(50),
                duelsLost: random.nextInt(50),
              );

              await addFriendRelationship(userId, friendId);
            }

            // Sort expected names alphabetically
            expectedNames.sort();

            // Get friends
            final friends = await friendsService.getFriends(userId);
            final actualNames = friends.map((f) => f.displayName).toList();

            // Verify friends are ordered alphabetically by display name
            expect(
              actualNames,
              equals(expectedNames),
              reason:
                  'Friends should be ordered alphabetically by display name (iteration $i)',
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
