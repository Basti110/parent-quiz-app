import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/statistics_service.dart';
import 'dart:math';

void main() {
  group('StatisticsService - Property Tests', () {
    late FakeFirebaseFirestore firestore;
    late StatisticsService statisticsService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      statisticsService = StatisticsService(firestore: firestore);
    });

    // **Feature: statistics-and-counting-fixes, Property 8: Category answered count accuracy**
    // **Validates: Requirements 5.2**
    test('Property 8: Category answered count matches manual count from questionStates', () async {
      const iterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      for (int i = 0; i < iterations; i++) {
        // Arrange: Create fresh firestore for each iteration
        firestore = FakeFirebaseFirestore();
        statisticsService = StatisticsService(firestore: firestore);

        const userId = 'test_user';
        const categoryId = 'test_category';

        // Create category
        await firestore.collection('categories').doc(categoryId).set({
          'title': 'Test Category',
          'description': 'Test Description',
          'order': 1,
          'iconName': 'health',
          'isPremium': false,
          'questionCounter': 50,
        });

        // Generate random number of questions (1-20)
        final numQuestions = random.nextInt(20) + 1;
        final questionIds = <String>[];
        int expectedAnswered = 0;

        for (int q = 0; q < numQuestions; q++) {
          final questionId = 'question_$i\_$q';
          questionIds.add(questionId);

          // Create question
          await firestore.collection('questions').doc(questionId).set({
            'categoryId': categoryId,
            'text': 'Question $q',
            'options': ['A', 'B', 'C'],
            'correctIndices': [0],
            'explanation': 'Explanation',
            'difficulty': 1,
            'isActive': true,
          });

          // Generate random question state
          final seenCount = random.nextInt(10); // 0-9
          final correctCount = random.nextInt(seenCount + 1); // 0 to seenCount
          final mastered = correctCount >= 3;

          // Count expected answered (seenCount > 0)
          if (seenCount > 0) {
            expectedAnswered++;
          }

          // Create question state
          await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc(questionId)
              .set({
            'questionId': questionId,
            'seenCount': seenCount,
            'correctCount': correctCount,
            'lastSeenAt': DateTime.now(),
            'mastered': mastered,
          });
        }

        // Act: Get category statistics
        final categoryStats = await statisticsService.getCategoryStatistics(
          userId,
          categoryId,
        );

        // Assert: Answered count should match manual count
        expect(
          categoryStats.questionsAnswered,
          equals(expectedAnswered),
          reason: 'Iteration $i: Category answered count should match questions with seenCount > 0',
        );
      }
    });

    // **Feature: statistics-and-counting-fixes, Property 13: Statistics consistency across calls**
    // **Validates: Requirements 2.1, 2.2, 2.3**
    test('Property 13: Calling getUserStatistics twice returns identical results', () async {
      const iterations = 100;
      final random = Random(123); // Fixed seed for reproducibility

      for (int i = 0; i < iterations; i++) {
        // Arrange: Create fresh firestore for each iteration
        firestore = FakeFirebaseFirestore();
        statisticsService = StatisticsService(firestore: firestore);

        const userId = 'test_user';

        // Generate random number of categories (1-5)
        final numCategories = random.nextInt(5) + 1;

        for (int c = 0; c < numCategories; c++) {
          final categoryId = 'category_$i\_$c';

          // Create category
          await firestore.collection('categories').doc(categoryId).set({
            'title': 'Category $c',
            'description': 'Description $c',
            'order': c,
            'iconName': 'health',
            'isPremium': false,
            'questionCounter': 30,
          });

          // Generate random number of questions per category (1-10)
          final numQuestions = random.nextInt(10) + 1;

          for (int q = 0; q < numQuestions; q++) {
            final questionId = 'question_$i\_$c\_$q';

            // Create question
            await firestore.collection('questions').doc(questionId).set({
              'categoryId': categoryId,
              'text': 'Question $q',
              'options': ['A', 'B', 'C'],
              'correctIndices': [0],
              'explanation': 'Explanation',
              'difficulty': 1,
              'isActive': true,
            });

            // Generate random question state
            final seenCount = random.nextInt(10);
            final correctCount = random.nextInt(seenCount + 1);
            final mastered = correctCount >= 3;

            // Create question state
            await firestore
                .collection('users')
                .doc(userId)
                .collection('questionStates')
                .doc(questionId)
                .set({
              'questionId': questionId,
              'seenCount': seenCount,
              'correctCount': correctCount,
              'lastSeenAt': DateTime.now(),
              'mastered': mastered,
            });
          }
        }

        // Act: Call getUserStatistics twice
        final stats1 = await statisticsService.getUserStatistics(userId);
        final stats2 = await statisticsService.getUserStatistics(userId);

        // Assert: Both calls should return identical results
        expect(
          stats1.totalQuestionsAnswered,
          equals(stats2.totalQuestionsAnswered),
          reason: 'Iteration $i: Total answered should be consistent',
        );
        expect(
          stats1.totalQuestionsMastered,
          equals(stats2.totalQuestionsMastered),
          reason: 'Iteration $i: Total mastered should be consistent',
        );
        expect(
          stats1.totalQuestionsSeen,
          equals(stats2.totalQuestionsSeen),
          reason: 'Iteration $i: Total seen should be consistent',
        );
        expect(
          stats1.categoryStats.length,
          equals(stats2.categoryStats.length),
          reason: 'Iteration $i: Number of categories should be consistent',
        );

        // Check each category's statistics
        for (int c = 0; c < stats1.categoryStats.length; c++) {
          final cat1 = stats1.categoryStats[c];
          final cat2 = stats2.categoryStats.firstWhere(
            (cat) => cat.categoryId == cat1.categoryId,
          );

          expect(
            cat1.questionsAnswered,
            equals(cat2.questionsAnswered),
            reason: 'Iteration $i, Category ${cat1.categoryId}: Answered count should be consistent',
          );
          expect(
            cat1.questionsMastered,
            equals(cat2.questionsMastered),
            reason: 'Iteration $i, Category ${cat1.categoryId}: Mastered count should be consistent',
          );
          expect(
            cat1.questionsSeen,
            equals(cat2.questionsSeen),
            reason: 'Iteration $i, Category ${cat1.categoryId}: Seen count should be consistent',
          );
        }
      }
    });
  });
}
