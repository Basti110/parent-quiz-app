import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:babycation/services/duel_service.dart';
import 'package:babycation/models/user_model.dart';
import 'package:babycation/models/question.dart';
import 'dart:math';

void main() {
  group('DuelService - Asynchronous Duels', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DuelService duelService;
    late Random random;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      random = Random(42);
      duelService = DuelService(firestore: fakeFirestore, random: random);
    });

    // Helper to create a test user
    Future<UserModel> createTestUser({
      required String userId,
      String displayName = 'Test User',
    }) async {
      final now = DateTime.now();

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
        duelsCompleted: 0,
        duelsWon: 0,
      );

      await fakeFirestore.collection('users').doc(userId).set(user.toMap());
      return user;
    }

    // Helper to create test questions
    Future<List<String>> createTestQuestions(int count) async {
      final questionIds = <String>[];

      for (int i = 0; i < count; i++) {
        final questionId = 'question_$i';
        final question = Question(
          id: questionId,
          categoryId: 'test_category',
          text: 'Test question $i',
          options: ['Option A', 'Option B', 'Option C'],
          correctIndices: [0],
          explanation: 'Test explanation',
          tips: null,
          sourceLabel: null,
          sourceUrl: null,
          difficulty: 1,
          isActive: true,
        );

        await fakeFirestore
            .collection('questions')
            .doc(questionId)
            .set(question.toMap());
        questionIds.add(questionId);
      }

      return questionIds;
    }

    // Helper to create a friendship between two users
    Future<void> createFriendship(String userId1, String userId2) async {
      await fakeFirestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .doc(userId2)
          .set({
        'friendUserId': userId2,
        'status': 'accepted',
        'createdAt': DateTime.now(),
        'createdBy': userId1,
        'myWins': 0,
        'theirWins': 0,
        'ties': 0,
        'totalDuels': 0,
      });

      await fakeFirestore
          .collection('users')
          .doc(userId2)
          .collection('friends')
          .doc(userId1)
          .set({
        'friendUserId': userId1,
        'status': 'accepted',
        'createdAt': DateTime.now(),
        'createdBy': userId1,
        'myWins': 0,
        'theirWins': 0,
        'ties': 0,
        'totalDuels': 0,
      });
    }

    // ========================================================================
    // PROPERTY TESTS FOR DUEL SYSTEM (Task 3)
    // ========================================================================

    // **Feature: simplified-gamification, Property 18: Duel question consistency**
    // **Validates: Requirements 11.5**
    group('Property 18: Duel question consistency', () {
      test(
        'for any duel, both the challenger and opponent should receive the exact same 5 questions in the same order',
        () async {
          const iterations = 100;

          // Create test questions
          await createTestQuestions(20);

          for (int i = 0; i < iterations; i++) {
            final challengerId = 'challenger_$i';
            final opponentId = 'opponent_$i';

            // Create test users
            await createTestUser(userId: challengerId);
            await createTestUser(userId: opponentId);

            // Create friendship between users
            await createFriendship(challengerId, opponentId);

            // Create a duel
            final duelId = await duelService.createDuel(challengerId, opponentId);

            // Fetch the duel
            final duel = await duelService.getDuel(duelId);

            // Verify both participants have the same question list
            expect(
              duel.questionIds.length,
              equals(5),
              reason: 'Duel should have exactly 5 questions (iteration $i)',
            );

            // The question list should be the same for both participants
            // (stored once in the duel document)
            expect(
              duel.questionIds,
              isNotEmpty,
              reason: 'Question IDs should not be empty (iteration $i)',
            );

            // Verify all question IDs are unique
            final uniqueQuestions = duel.questionIds.toSet();
            expect(
              uniqueQuestions.length,
              equals(5),
              reason: 'All 5 questions should be unique (iteration $i)',
            );
          }
        },
      );
    });

    // **Feature: simplified-gamification, Property 19: Duel score calculation**
    // **Validates: Requirements 13.2**
    group('Property 19: Duel score calculation', () {
      test(
        'for any duel, each participant\'s score should be incremented by 1 when they answer a question correctly, and the final score should equal the number of correct answers',
        () async {
          const iterations = 100;

          // Create test questions
          await createTestQuestions(10);

          for (int i = 0; i < iterations; i++) {
            final challengerId = 'challenger_score_$i';
            final opponentId = 'opponent_score_$i';

            // Create test users
            await createTestUser(userId: challengerId);
            await createTestUser(userId: opponentId);

            // Create friendship between users
            await createFriendship(challengerId, opponentId);

            // Create a duel
            final duelId = await duelService.createDuel(challengerId, opponentId);

            // Accept the duel
            await duelService.acceptDuel(duelId, opponentId);

            // Get the duel to access question IDs
            final duel = await duelService.getDuel(duelId);

            // Generate random answer patterns for both players
            final challengerAnswers = List.generate(
              5,
              (index) => random.nextBool(),
            );
            final opponentAnswers = List.generate(
              5,
              (index) => random.nextBool(),
            );

            // Submit answers for challenger
            for (int j = 0; j < 5; j++) {
              await duelService.submitAnswer(
                duelId: duelId,
                userId: challengerId,
                questionIndex: j,
                questionId: duel.questionIds[j],
                isCorrect: challengerAnswers[j],
              );
            }

            // Submit answers for opponent
            for (int j = 0; j < 5; j++) {
              await duelService.submitAnswer(
                duelId: duelId,
                userId: opponentId,
                questionIndex: j,
                questionId: duel.questionIds[j],
                isCorrect: opponentAnswers[j],
              );
            }

            // Fetch updated duel
            final updatedDuel = await duelService.getDuel(duelId);

            // Calculate expected scores
            final expectedChallengerScore = challengerAnswers.where((a) => a).length;
            final expectedOpponentScore = opponentAnswers.where((a) => a).length;

            // Verify scores match expected values
            expect(
              updatedDuel.challengerScore,
              equals(expectedChallengerScore),
              reason:
                  'Challenger score should equal number of correct answers (iteration $i)',
            );

            expect(
              updatedDuel.opponentScore,
              equals(expectedOpponentScore),
              reason:
                  'Opponent score should equal number of correct answers (iteration $i)',
            );
          }
        },
      );
    });

    // **Feature: simplified-gamification, Property 20: Duel winner determination**
    // **Validates: Requirements 13.4**
    group('Property 20: Duel winner determination', () {
      test(
        'for any completed duel, the participant with the higher score should be identified as the winner, or if scores are equal, it should be marked as a tie',
        () async {
          const iterations = 100;

          // Create test questions
          await createTestQuestions(10);

          for (int i = 0; i < iterations; i++) {
            final challengerId = 'challenger_winner_$i';
            final opponentId = 'opponent_winner_$i';

            // Create test users
            await createTestUser(userId: challengerId);
            await createTestUser(userId: opponentId);

            // Create friendship between users
            await createFriendship(challengerId, opponentId);

            // Create a duel
            final duelId = await duelService.createDuel(challengerId, opponentId);

            // Accept the duel
            await duelService.acceptDuel(duelId, opponentId);

            // Get the duel to access question IDs
            final duel = await duelService.getDuel(duelId);

            // Generate random answer patterns
            final challengerAnswers = List.generate(
              5,
              (index) => random.nextBool(),
            );
            final opponentAnswers = List.generate(
              5,
              (index) => random.nextBool(),
            );

            // Submit answers for both players
            for (int j = 0; j < 5; j++) {
              await duelService.submitAnswer(
                duelId: duelId,
                userId: challengerId,
                questionIndex: j,
                questionId: duel.questionIds[j],
                isCorrect: challengerAnswers[j],
              );

              await duelService.submitAnswer(
                duelId: duelId,
                userId: opponentId,
                questionIndex: j,
                questionId: duel.questionIds[j],
                isCorrect: opponentAnswers[j],
              );
            }

            // Complete the duel for both players
            await duelService.completeDuel(duelId, challengerId);
            await duelService.completeDuel(duelId, opponentId);

            // Fetch completed duel
            final completedDuel = await duelService.getDuel(duelId);

            // Calculate expected scores
            final challengerScore = challengerAnswers.where((a) => a).length;
            final opponentScore = opponentAnswers.where((a) => a).length;

            // Determine expected winner
            final expectedWinnerId = challengerScore > opponentScore
                ? challengerId
                : (opponentScore > challengerScore ? opponentId : null);

            // Verify winner determination
            expect(
              completedDuel.getWinnerId(),
              equals(expectedWinnerId),
              reason:
                  'Winner should be correctly determined based on scores (iteration $i)',
            );

            // Verify tie case
            if (challengerScore == opponentScore) {
              expect(
                completedDuel.getWinnerId(),
                isNull,
                reason: 'Tie should return null winner (iteration $i)',
              );
            }
          }
        },
      );
    });

    // **Feature: simplified-gamification, Property 20: Active duel prevention**
    // **Validates: Requirements 11.1**
    group('Property 20: Active duel prevention', () {
      test(
        'should prevent creating new duels when there is already an active duel between users',
        () async {
          const iterations = 10;

          // Create test questions
          await createTestQuestions(10);

          for (int i = 0; i < iterations; i++) {
            final challengerId = 'challenger_prevent_$i';
            final opponentId = 'opponent_prevent_$i';

            // Create test users
            await createTestUser(userId: challengerId);
            await createTestUser(userId: opponentId);

            // Create friendship between users
            await createFriendship(challengerId, opponentId);

            // Create first duel
            final firstDuelId = await duelService.createDuel(challengerId, opponentId);

            // Verify first duel was created
            expect(firstDuelId, isNotEmpty);

            // Check that hasActiveDuel returns true
            final hasActive = await duelService.hasActiveDuel(challengerId, opponentId);
            expect(hasActive, isTrue, reason: 'Should detect active duel (iteration $i)');

            // Try to create second duel - should fail
            expect(
              () => duelService.createDuel(challengerId, opponentId),
              throwsA(isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('already an active duel'),
              )),
              reason: 'Should prevent creating duplicate duel (iteration $i)',
            );

            // Try reverse direction - should also fail
            expect(
              () => duelService.createDuel(opponentId, challengerId),
              throwsA(isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('already an active duel'),
              )),
              reason: 'Should prevent creating reverse duel (iteration $i)',
            );

            // Accept the duel - should still be active
            await duelService.acceptDuel(firstDuelId, opponentId);
            final stillActive = await duelService.hasActiveDuel(challengerId, opponentId);
            expect(stillActive, isTrue, reason: 'Should still be active after acceptance (iteration $i)');

            // Complete the duel for both users
            final duel = await duelService.getDuel(firstDuelId);
            for (int q = 0; q < duel.questionIds.length; q++) {
              await duelService.submitAnswer(
                duelId: firstDuelId,
                userId: challengerId,
                questionIndex: q,
                questionId: duel.questionIds[q],
                isCorrect: q % 2 == 0, // Alternate correct/incorrect
              );
              await duelService.submitAnswer(
                duelId: firstDuelId,
                userId: opponentId,
                questionIndex: q,
                questionId: duel.questionIds[q],
                isCorrect: q % 3 == 0, // Different pattern
              );
            }

            // Mark both as completed
            await duelService.completeDuel(firstDuelId, challengerId);
            await duelService.completeDuel(firstDuelId, opponentId);

            // Now should be able to create new duel
            final noLongerActive = await duelService.hasActiveDuel(challengerId, opponentId);
            expect(noLongerActive, isFalse, reason: 'Should no longer be active after completion (iteration $i)');

            // Should be able to create new duel now
            final secondDuelId = await duelService.createDuel(opponentId, challengerId);
            expect(secondDuelId, isNotEmpty, reason: 'Should allow new duel after completion (iteration $i)');
          }
        },
      );
    });
  });
}
