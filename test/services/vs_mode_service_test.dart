import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:babycation/services/vs_mode_service.dart';
import 'package:babycation/models/vs_mode_session.dart';
import 'dart:math';

void main() {
  group('VSModeService - Time Tracking and Explanations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late VSModeService vsModeService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      vsModeService = VSModeService(firestore: fakeFirestore);
    });

    // Helper to create a test session
    VSModeSession createTestSession({
      int questionsPerPlayer = 5,
      String playerAName = 'Player A',
      String playerBName = 'Player B',
      int playerAElapsedSeconds = 0,
      int playerBElapsedSeconds = 0,
      Map<String, bool>? playerAExplanationsViewed,
      Map<String, bool>? playerBExplanationsViewed,
    }) {
      final questionIds = List.generate(
        questionsPerPlayer * 2,
        (i) => 'question_$i',
      );

      return VSModeSession(
        categoryId: 'test_category',
        questionsPerPlayer: questionsPerPlayer,
        playerAName: playerAName,
        playerBName: playerBName,
        playerAQuestionIds: questionIds.sublist(0, questionsPerPlayer),
        playerBQuestionIds: questionIds.sublist(questionsPerPlayer),
        playerAElapsedSeconds: playerAElapsedSeconds,
        playerBElapsedSeconds: playerBElapsedSeconds,
        playerAExplanationsViewed: playerAExplanationsViewed ?? {},
        playerBExplanationsViewed: playerBExplanationsViewed ?? {},
      );
    }

    // ========================================================================
    // PROPERTY TESTS FOR VS MODE TIME TRACKING
    // ========================================================================

    // **Feature: simplified-gamification, Property 48b: VS Mode Explanation Time Exclusion**
    // **Validates: Requirements 18.5, 22.3**
    group('Property 48b: VS Mode Explanation Time Exclusion', () {
      test(
        'for any player who spends T seconds total on explanation screens in VS Mode, '
        'the completion time should not include any of those T seconds',
        () {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Generate random number of questions (3-10)
            final numQuestions = 3 + random.nextInt(8);
            
            // Create initial session
            var session = createTestSession(
              questionsPerPlayer: numQuestions,
            );

            // Simulate answering questions with time tracking
            // We'll track question time and explanation time separately
            int totalQuestionTime = 0;
            int totalExplanationTime = 0;

            for (int q = 0; q < numQuestions; q++) {
              final questionId = session.playerAQuestionIds[q];
              
              // Generate random question answering time (5-60 seconds)
              final questionDuration = 5 + random.nextInt(56);
              totalQuestionTime += questionDuration;
              
              // Simulate question start and end
              final questionStart = DateTime.now();
              final questionEnd = questionStart.add(Duration(seconds: questionDuration));
              
              // Record question time (this should be included in elapsed time)
              session = vsModeService.recordQuestionEnd(
                session: session,
                playerId: 'playerA',
                endTime: questionEnd,
                startTime: questionStart,
              );
              
              // Generate random explanation viewing time (0-30 seconds)
              // This time should NOT be included in elapsed time
              final explanationDuration = random.nextInt(31);
              totalExplanationTime += explanationDuration;
              
              // Record explanation viewed (but don't add time)
              session = vsModeService.recordExplanationViewed(
                session: session,
                playerId: 'playerA',
                questionId: questionId,
              );
              
              // Note: We're NOT calling recordQuestionEnd for explanation time
              // The explanation time is just simulated but not recorded
            }

            // Verify that elapsed time equals ONLY question time, NOT explanation time
            expect(
              session.playerAElapsedSeconds,
              equals(totalQuestionTime),
              reason: 'Elapsed time should equal question time ($totalQuestionTime seconds), '
                  'not include explanation time ($totalExplanationTime seconds) '
                  '(iteration $i, $numQuestions questions)',
            );

            // Verify that elapsed time does NOT include explanation time
            expect(
              session.playerAElapsedSeconds,
              lessThan(totalQuestionTime + totalExplanationTime),
              reason: 'Elapsed time should not include explanation time '
                  '(iteration $i, $numQuestions questions)',
            );

            // Verify explanation views were recorded
            expect(
              session.playerAExplanationsViewed.length,
              equals(numQuestions),
              reason: 'All explanations should be recorded as viewed '
                  '(iteration $i, $numQuestions questions)',
            );
          }
        },
      );

      test(
        'for any player, viewing explanations should not affect elapsed time accumulation',
        () {
          final random = Random(42);
          const iterations = 50;

          for (int i = 0; i < iterations; i++) {
            final numQuestions = 3 + random.nextInt(5);
            var session = createTestSession(questionsPerPlayer: numQuestions);

            // Track elapsed time after each question
            final elapsedTimes = <int>[];

            for (int q = 0; q < numQuestions; q++) {
              final questionId = session.playerAQuestionIds[q];
              final questionDuration = 5 + random.nextInt(30);
              
              final questionStart = DateTime.now();
              final questionEnd = questionStart.add(Duration(seconds: questionDuration));
              
              // Record question time
              session = vsModeService.recordQuestionEnd(
                session: session,
                playerId: 'playerA',
                endTime: questionEnd,
                startTime: questionStart,
              );
              
              // Store elapsed time after question
              final elapsedAfterQuestion = session.playerAElapsedSeconds;
              elapsedTimes.add(elapsedAfterQuestion);
              
              // View explanation (should not change elapsed time)
              session = vsModeService.recordExplanationViewed(
                session: session,
                playerId: 'playerA',
                questionId: questionId,
              );
              
              // Verify elapsed time didn't change after viewing explanation
              expect(
                session.playerAElapsedSeconds,
                equals(elapsedAfterQuestion),
                reason: 'Elapsed time should not change after viewing explanation '
                    '(iteration $i, question $q)',
              );
            }

            // Verify elapsed times are monotonically increasing
            for (int j = 1; j < elapsedTimes.length; j++) {
              expect(
                elapsedTimes[j],
                greaterThan(elapsedTimes[j - 1]),
                reason: 'Elapsed time should increase with each question '
                    '(iteration $i, question $j)',
              );
            }
          }
        },
      );

      test(
        'for both players, explanation viewing should be tracked independently from time',
        () {
          final random = Random(42);
          const iterations = 50;

          for (int i = 0; i < iterations; i++) {
            final numQuestions = 3 + random.nextInt(5);
            var session = createTestSession(questionsPerPlayer: numQuestions);

            // Player A answers questions and views some explanations
            int playerAQuestionTime = 0;
            final playerAViewedExplanations = <String>{};
            
            for (int q = 0; q < numQuestions; q++) {
              final questionId = session.playerAQuestionIds[q];
              final questionDuration = 5 + random.nextInt(20);
              playerAQuestionTime += questionDuration;
              
              final questionStart = DateTime.now();
              final questionEnd = questionStart.add(Duration(seconds: questionDuration));
              
              session = vsModeService.recordQuestionEnd(
                session: session,
                playerId: 'playerA',
                endTime: questionEnd,
                startTime: questionStart,
              );
              
              // Randomly view explanation (50% chance)
              if (random.nextBool()) {
                session = vsModeService.recordExplanationViewed(
                  session: session,
                  playerId: 'playerA',
                  questionId: questionId,
                );
                playerAViewedExplanations.add(questionId);
              }
            }

            // Player B answers questions and views different explanations
            int playerBQuestionTime = 0;
            final playerBViewedExplanations = <String>{};
            
            for (int q = 0; q < numQuestions; q++) {
              final questionId = session.playerBQuestionIds[q];
              final questionDuration = 5 + random.nextInt(20);
              playerBQuestionTime += questionDuration;
              
              final questionStart = DateTime.now();
              final questionEnd = questionStart.add(Duration(seconds: questionDuration));
              
              session = vsModeService.recordQuestionEnd(
                session: session,
                playerId: 'playerB',
                endTime: questionEnd,
                startTime: questionStart,
              );
              
              // Randomly view explanation (50% chance)
              if (random.nextBool()) {
                session = vsModeService.recordExplanationViewed(
                  session: session,
                  playerId: 'playerB',
                  questionId: questionId,
                );
                playerBViewedExplanations.add(questionId);
              }
            }

            // Verify elapsed times match question times only
            expect(
              session.playerAElapsedSeconds,
              equals(playerAQuestionTime),
              reason: 'Player A elapsed time should equal question time only '
                  '(iteration $i)',
            );

            expect(
              session.playerBElapsedSeconds,
              equals(playerBQuestionTime),
              reason: 'Player B elapsed time should equal question time only '
                  '(iteration $i)',
            );

            // Verify explanation views are tracked correctly
            expect(
              session.playerAExplanationsViewed.length,
              equals(playerAViewedExplanations.length),
              reason: 'Player A explanation views should be tracked '
                  '(iteration $i)',
            );

            expect(
              session.playerBExplanationsViewed.length,
              equals(playerBViewedExplanations.length),
              reason: 'Player B explanation views should be tracked '
                  '(iteration $i)',
            );
          }
        },
      );
    });
  });
}
