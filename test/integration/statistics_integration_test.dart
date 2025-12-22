import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/statistics_service.dart';
import 'package:eduparo/services/user_service.dart';
import 'package:eduparo/services/quiz_service.dart';
import 'package:eduparo/models/category.dart';
import 'package:eduparo/models/question.dart';
import 'package:eduparo/models/question_state.dart';
import 'package:eduparo/models/user_statistics.dart';
import 'package:eduparo/models/category_statistics.dart';

void main() {
  group('Statistics Integration Tests', () {
    late FakeFirebaseFirestore firestore;
    late StatisticsService statisticsService;
    late UserService userService;
    late QuizService quizService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      statisticsService = StatisticsService(firestore: firestore);
      userService = UserService(firestore: firestore);
      quizService = QuizService(firestore: firestore);
    });

    /// Helper to create test categories
    Future<List<Category>> createTestCategories() async {
      final categories = [
        Category(
          id: 'sleep',
          title: 'Sleep',
          description: 'Sleep and rest questions',
          order: 1,
          iconName: 'sleep',
          isPremium: false,
          questionCounter: 30,
        ),
        Category(
          id: 'nutrition',
          title: 'Nutrition',
          description: 'Nutrition and feeding questions',
          order: 2,
          iconName: 'nutrition',
          isPremium: false,
          questionCounter: 40,
        ),
        Category(
          id: 'health',
          title: 'Health',
          description: 'Health and wellness questions',
          order: 3,
          iconName: 'health',
          isPremium: false,
          questionCounter: 25,
        ),
      ];

      for (final category in categories) {
        await firestore
            .collection('categories')
            .doc(category.id)
            .set(category.toMap());
      }

      return categories;
    }

    /// Helper to create test questions for categories
    Future<List<Question>> createTestQuestions(List<Category> categories) async {
      final questions = <Question>[];

      for (final category in categories) {
        for (int i = 0; i < category.questionCounter; i++) {
          final question = Question(
            id: '${category.id}_question_$i',
            categoryId: category.id,
            text: 'Question $i for ${category.title}',
            options: ['Option A', 'Option B', 'Option C'],
            correctIndices: [0],
            explanation: 'Explanation for question $i',
            tips: null,
            sourceLabel: null,
            sourceUrl: null,
            difficulty: 1,
            isActive: true,
            sequence: i + 1, // Add sequence field
          );

          await firestore
              .collection('questions')
              .doc(question.id)
              .set(question.toMap());

          questions.add(question);
        }
      }

      return questions;
    }

    /// Helper to simulate answering questions and updating question states
    Future<void> simulateAnsweringQuestions(
      String userId,
      List<Question> questions,
      Map<String, bool> answers,
    ) async {
      for (final question in questions) {
        final isCorrect = answers[question.id] ?? false;
        await userService.updateQuestionState(userId, question.id, isCorrect);
      }
    }

    // Requirements: 2.1, 2.2, 2.3, 5.2, 5.3, 5.4
    group('Complete Flow Integration Tests', () {
      testWidgets(
        'should accurately track statistics through complete answer → view flow',
        (WidgetTester tester) async {
          // Arrange: Set up test data
          const userId = 'test_user';
          final categories = await createTestCategories();
          final questions = await createTestQuestions(categories);

          // Simulate user answering questions across categories
          final answers = <String, bool>{};

          // Sleep category: Answer 10 questions, 7 correct (3 mastered)
          final sleepQuestions = questions
              .where((q) => q.categoryId == 'sleep')
              .take(10)
              .toList();
          for (int i = 0; i < sleepQuestions.length; i++) {
            final question = sleepQuestions[i];
            final isCorrect = i < 7; // First 7 are correct
            answers[question.id] = isCorrect;

            // Simulate multiple attempts for mastery (first 3 questions)
            if (i < 3) {
              // Answer correctly 3 times to achieve mastery
              for (int attempt = 0; attempt < 3; attempt++) {
                await userService.updateQuestionState(userId, question.id, true);
              }
            } else {
              // Answer once
              await userService.updateQuestionState(userId, question.id, isCorrect);
            }
          }

          // Nutrition category: Answer 15 questions, 12 correct (5 mastered)
          final nutritionQuestions = questions
              .where((q) => q.categoryId == 'nutrition')
              .take(15)
              .toList();
          for (int i = 0; i < nutritionQuestions.length; i++) {
            final question = nutritionQuestions[i];
            final isCorrect = i < 12; // First 12 are correct
            answers[question.id] = isCorrect;

            // Simulate multiple attempts for mastery (first 5 questions)
            if (i < 5) {
              // Answer correctly 3 times to achieve mastery
              for (int attempt = 0; attempt < 3; attempt++) {
                await userService.updateQuestionState(userId, question.id, true);
              }
            } else {
              // Answer once
              await userService.updateQuestionState(userId, question.id, isCorrect);
            }
          }

          // Health category: Answer 5 questions, 3 correct (1 mastered)
          final healthQuestions = questions
              .where((q) => q.categoryId == 'health')
              .take(5)
              .toList();
          for (int i = 0; i < healthQuestions.length; i++) {
            final question = healthQuestions[i];
            final isCorrect = i < 3; // First 3 are correct
            answers[question.id] = isCorrect;

            // Simulate multiple attempts for mastery (first question only)
            if (i == 0) {
              // Answer correctly 3 times to achieve mastery
              for (int attempt = 0; attempt < 3; attempt++) {
                await userService.updateQuestionState(userId, question.id, true);
              }
            } else {
              // Answer once
              await userService.updateQuestionState(userId, question.id, isCorrect);
            }
          }

          // Act: Get user statistics (simulating viewing statistics screen)
          final userStats = await statisticsService.getUserStatistics(userId);

          // Assert: Verify overall statistics
          expect(userStats.totalQuestionsAnswered, equals(30)); // 10 + 15 + 5
          expect(userStats.totalQuestionsMastered, equals(9)); // 3 + 5 + 1
          expect(userStats.totalQuestionsSeen, equals(30)); // All answered questions

          // Assert: Verify category-level statistics
          expect(userStats.categoryStats.length, equals(3));

          // Sleep category verification
          final sleepStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == 'sleep');
          expect(sleepStats.categoryTitle, equals('Sleep'));
          expect(sleepStats.categoryIconName, equals('sleep'));
          expect(sleepStats.totalQuestions, equals(30));
          expect(sleepStats.questionsAnswered, equals(10));
          expect(sleepStats.questionsMastered, equals(3));
          expect(sleepStats.questionsSeen, equals(10));
          expect(sleepStats.percentageAnswered, closeTo(10 / 30, 0.01));

          // Nutrition category verification
          final nutritionStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == 'nutrition');
          expect(nutritionStats.categoryTitle, equals('Nutrition'));
          expect(nutritionStats.categoryIconName, equals('nutrition'));
          expect(nutritionStats.totalQuestions, equals(40));
          expect(nutritionStats.questionsAnswered, equals(15));
          expect(nutritionStats.questionsMastered, equals(5));
          expect(nutritionStats.questionsSeen, equals(15));
          expect(nutritionStats.percentageAnswered, closeTo(15 / 40, 0.01));

          // Health category verification
          final healthStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == 'health');
          expect(healthStats.categoryTitle, equals('Health'));
          expect(healthStats.categoryIconName, equals('health'));
          expect(healthStats.totalQuestions, equals(25));
          expect(healthStats.questionsAnswered, equals(5));
          expect(healthStats.questionsMastered, equals(1));
          expect(healthStats.questionsSeen, equals(5));
          expect(healthStats.percentageAnswered, closeTo(5 / 25, 0.01));
        },
      );

      testWidgets(
        'should handle empty statistics correctly',
        (WidgetTester tester) async {
          // Arrange: Set up categories but no answered questions
          const userId = 'empty_user';
          await createTestCategories();

          // Act: Get statistics for user with no question states
          final userStats = await statisticsService.getUserStatistics(userId);

          // Assert: All statistics should be zero
          expect(userStats.totalQuestionsAnswered, equals(0));
          expect(userStats.totalQuestionsMastered, equals(0));
          expect(userStats.totalQuestionsSeen, equals(0));
          expect(userStats.categoryStats, isEmpty);
        },
      );
    });

    // Requirements: 5.2, 5.3, 5.4
    group('Category Statistics Accuracy Tests', () {
      testWidgets(
        'should accurately calculate category statistics for multiple categories',
        (WidgetTester tester) async {
          // Arrange: Set up test data
          const userId = 'category_test_user';
          final categories = await createTestCategories();
          final questions = await createTestQuestions(categories);

          // Create specific test scenario for each category
          // Sleep: 20 seen, 15 correct, 8 mastered
          final sleepQuestions = questions
              .where((q) => q.categoryId == 'sleep')
              .take(20)
              .toList();

          for (int i = 0; i < sleepQuestions.length; i++) {
            final question = sleepQuestions[i];
            final isCorrect = i < 15; // First 15 are correct

            if (i < 8) {
              // First 8 questions: answer correctly 3+ times for mastery
              for (int attempt = 0; attempt < 4; attempt++) {
                await userService.updateQuestionState(userId, question.id, true);
              }
            } else if (i < 15) {
              // Questions 8-14: answer correctly once (not mastered)
              await userService.updateQuestionState(userId, question.id, true);
            } else {
              // Questions 15-19: answer incorrectly
              await userService.updateQuestionState(userId, question.id, false);
            }
          }

          // Act: Get category statistics
          final sleepStats = await statisticsService.getCategoryStatistics(
            userId,
            'sleep',
          );

          // Assert: Verify category statistics accuracy
          expect(sleepStats.categoryId, equals('sleep'));
          expect(sleepStats.categoryTitle, equals('Sleep'));
          expect(sleepStats.totalQuestions, equals(30));
          expect(sleepStats.questionsAnswered, equals(20));
          expect(sleepStats.questionsMastered, equals(8));
          expect(sleepStats.questionsSeen, equals(20));
          expect(sleepStats.percentageAnswered, closeTo(20 / 30, 0.01));
          expect(sleepStats.percentageMastered, closeTo(8 / 30, 0.01));
        },
      );

      testWidgets(
        'should handle category with no answered questions',
        (WidgetTester tester) async {
          // Arrange: Set up categories but don't answer any questions
          const userId = 'no_answers_user';
          await createTestCategories();

          // Act & Assert: Should throw exception for category with no stats
          expect(
            () => statisticsService.getCategoryStatistics(userId, 'sleep'),
            throwsA(isA<Exception>()),
          );
        },
      );
    });

    // Requirements: 2.1, 2.2, 2.3
    group('Statistics Update After Answering Questions', () {
      testWidgets(
        'should update statistics immediately after answering questions',
        (WidgetTester tester) async {
          // Arrange: Set up test data
          const userId = 'update_test_user';
          final categories = await createTestCategories();
          final questions = await createTestQuestions(categories);

          // Get initial statistics (should be empty)
          var userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(0));
          expect(userStats.totalQuestionsMastered, equals(0));
          expect(userStats.totalQuestionsSeen, equals(0));

          // Act 1: Answer first question correctly
          final firstQuestion = questions.first;
          await userService.updateQuestionState(userId, firstQuestion.id, true);

          // Assert 1: Statistics should update immediately
          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(1));
          expect(userStats.totalQuestionsMastered, equals(0)); // Not mastered yet
          expect(userStats.totalQuestionsSeen, equals(1));

          // Act 2: Answer same question correctly 2 more times (total 3 = mastered)
          await userService.updateQuestionState(userId, firstQuestion.id, true);
          await userService.updateQuestionState(userId, firstQuestion.id, true);

          // Assert 2: Should now be mastered
          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(1)); // Still 1 unique question
          expect(userStats.totalQuestionsMastered, equals(1)); // Now mastered
          expect(userStats.totalQuestionsSeen, equals(1));

          // Act 3: Answer second question incorrectly
          final secondQuestion = questions[1];
          await userService.updateQuestionState(userId, secondQuestion.id, false);

          // Assert 3: Should increment seen and answered but not mastered
          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(2));
          expect(userStats.totalQuestionsMastered, equals(1)); // Still 1 mastered
          expect(userStats.totalQuestionsSeen, equals(2));

          // Act 4: Answer third question from different category
          final thirdQuestion = questions
              .firstWhere((q) => q.categoryId != firstQuestion.categoryId);
          await userService.updateQuestionState(userId, thirdQuestion.id, true);

          // Assert 4: Should update overall and category stats
          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(3));
          expect(userStats.totalQuestionsMastered, equals(1));
          expect(userStats.totalQuestionsSeen, equals(3));

          // Verify category-level updates
          expect(userStats.categoryStats.length, equals(2)); // Two categories now have stats

          final firstCategoryStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == firstQuestion.categoryId);
          expect(firstCategoryStats.questionsAnswered, equals(2));
          expect(firstCategoryStats.questionsMastered, equals(1));

          final secondCategoryStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == thirdQuestion.categoryId);
          expect(secondCategoryStats.questionsAnswered, equals(1));
          expect(secondCategoryStats.questionsMastered, equals(0));
        },
      );

      testWidgets(
        'should maintain consistency across multiple question sessions',
        (WidgetTester tester) async {
          // Arrange: Set up test data
          const userId = 'consistency_test_user';
          final categories = await createTestCategories();
          final questions = await createTestQuestions(categories);

          // Simulate multiple quiz sessions over time
          final sleepQuestions = questions
              .where((q) => q.categoryId == 'sleep')
              .take(10)
              .toList();

          // Session 1: Answer 5 questions
          for (int i = 0; i < 5; i++) {
            await userService.updateQuestionState(
              userId,
              sleepQuestions[i].id,
              i < 3, // First 3 correct
            );
          }

          var userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(5));
          expect(userStats.totalQuestionsMastered, equals(0)); // None mastered yet

          // Session 2: Re-answer first 3 questions correctly (should become mastered)
          for (int i = 0; i < 3; i++) {
            // Answer 2 more times each (total 3 correct = mastered)
            await userService.updateQuestionState(userId, sleepQuestions[i].id, true);
            await userService.updateQuestionState(userId, sleepQuestions[i].id, true);
          }

          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(5)); // Still 5 unique questions
          expect(userStats.totalQuestionsMastered, equals(3)); // Now 3 mastered

          // Session 3: Answer remaining 5 questions
          for (int i = 5; i < 10; i++) {
            await userService.updateQuestionState(
              userId,
              sleepQuestions[i].id,
              i < 8, // 3 more correct
            );
          }

          userStats = await statisticsService.getUserStatistics(userId);
          expect(userStats.totalQuestionsAnswered, equals(10));
          expect(userStats.totalQuestionsMastered, equals(3)); // Still 3 mastered
          expect(userStats.totalQuestionsSeen, equals(10));

          // Verify category stats consistency
          final sleepStats = userStats.categoryStats
              .firstWhere((stat) => stat.categoryId == 'sleep');
          expect(sleepStats.questionsAnswered, equals(10));
          expect(sleepStats.questionsMastered, equals(3));
          expect(sleepStats.questionsSeen, equals(10));
        },
      );
    });

    group('Edge Cases and Error Handling', () {
      testWidgets(
        'should handle missing categories gracefully',
        (WidgetTester tester) async {
          // Arrange: Create question states for non-existent category
          const userId = 'missing_category_user';

          // Create a question state for a category that doesn't exist
          await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc('orphan_question')
              .set({
            'questionId': 'orphan_question',
            'seenCount': 5,
            'correctCount': 3,
            'lastSeenAt': DateTime.now(),
            'mastered': true,
          });

          // Create a question for non-existent category
          await firestore
              .collection('questions')
              .doc('orphan_question')
              .set({
            'categoryId': 'non_existent_category',
            'text': 'Orphan question',
            'options': ['A', 'B', 'C'],
            'correctIndices': [0],
            'explanation': 'Explanation',
            'difficulty': 1,
            'isActive': true,
          });

          // Act: Get statistics (should handle missing category gracefully)
          final userStats = await statisticsService.getUserStatistics(userId);

          // Assert: Should return empty stats (orphan question ignored)
          expect(userStats.totalQuestionsAnswered, equals(0));
          expect(userStats.totalQuestionsMastered, equals(0));
          expect(userStats.totalQuestionsSeen, equals(0));
          expect(userStats.categoryStats, isEmpty);
        },
      );

      testWidgets(
        'should handle missing questions gracefully',
        (WidgetTester tester) async {
          // Arrange: Create question state for non-existent question
          const userId = 'missing_question_user';
          await createTestCategories();

          // Create question state for question that doesn't exist
          await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc('missing_question')
              .set({
            'questionId': 'missing_question',
            'seenCount': 3,
            'correctCount': 2,
            'lastSeenAt': DateTime.now(),
            'mastered': false,
          });

          // Act: Get statistics (should handle missing question gracefully)
          final userStats = await statisticsService.getUserStatistics(userId);

          // Assert: Should return empty stats (missing question ignored)
          expect(userStats.totalQuestionsAnswered, equals(0));
          expect(userStats.totalQuestionsMastered, equals(0));
          expect(userStats.totalQuestionsSeen, equals(0));
          expect(userStats.categoryStats, isEmpty);
        },
      );
    });
  });
}