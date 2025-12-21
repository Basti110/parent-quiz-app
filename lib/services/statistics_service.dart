import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/category_statistics.dart';
import '../models/question_state.dart';
import '../models/user_statistics.dart';

class StatisticsService {
  final FirebaseFirestore _firestore;

  StatisticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user statistics calculated from questionStates
  /// Property 4: Seen questions count accuracy - count where seenCount > 0
  /// Property 5: Correct questions count accuracy - count where correctCount > 0
  /// Property 6: Mastered questions count accuracy - count where mastered == true
  /// Requirements: 2.1, 2.2, 2.3
  Future<UserStatistics> getUserStatistics(String userId) async {
    try {
      // Load all question states for the user
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      // Load all categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get();

      final categories = <String, Category>{};
      for (final doc in categoriesSnapshot.docs) {
        final category = Category.fromMap(doc.data(), doc.id);
        categories[category.id] = category;
      }

      // Load all questions to map questionId -> categoryId
      final questionsSnapshot = await _firestore
          .collection('questions')
          .get();

      final questionToCategory = <String, String>{};
      for (final doc in questionsSnapshot.docs) {
        final data = doc.data();
        questionToCategory[doc.id] = data['categoryId'] as String;
      }

      // Calculate statistics by category
      final categoryStatsMap = <String, _CategoryStatsBuilder>{};
      int totalAnswered = 0;
      int totalMastered = 0;
      int totalSeen = 0;

      for (final stateDoc in statesSnapshot.docs) {
        final questionState = QuestionState.fromMap(stateDoc.data());
        final categoryId = questionToCategory[questionState.questionId];

        if (categoryId == null) continue;

        // Initialize category stats if needed
        if (!categoryStatsMap.containsKey(categoryId)) {
          final category = categories[categoryId];
          if (category != null) {
            categoryStatsMap[categoryId] = _CategoryStatsBuilder(
              categoryId: categoryId,
              categoryTitle: category.title,
              categoryIconName: category.iconName,
              totalQuestions: category.questionCounter,
            );
          }
        }

        final statsBuilder = categoryStatsMap[categoryId];
        if (statsBuilder != null) {
          // Count seen questions (seenCount > 0)
          if (questionState.seenCount > 0) {
            statsBuilder.questionsAnswered++;
            statsBuilder.questionsSeen++;
            totalAnswered++;
            totalSeen++;
          }

          // Count mastered questions (mastered == true)
          if (questionState.mastered) {
            statsBuilder.questionsMastered++;
            totalMastered++;
          }
        }
      }

      // Build final category statistics list
      final categoryStats = categoryStatsMap.values
          .map((builder) => CategoryStatistics(
                categoryId: builder.categoryId,
                categoryTitle: builder.categoryTitle,
                categoryIconName: builder.categoryIconName,
                totalQuestions: builder.totalQuestions,
                questionsAnswered: builder.questionsAnswered,
                questionsMastered: builder.questionsMastered,
                questionsSeen: builder.questionsSeen,
              ))
          .toList();

      return UserStatistics(
        totalQuestionsAnswered: totalAnswered,
        totalQuestionsMastered: totalMastered,
        totalQuestionsSeen: totalSeen,
        categoryStats: categoryStats,
      );
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      throw Exception('Failed to load statistics');
    }
  }

  /// Get statistics for a specific category
  /// Property 8: Category answered count accuracy
  /// Requirements: 5.2
  Future<CategoryStatistics> getCategoryStatistics(
    String userId,
    String categoryId,
  ) async {
    try {
      final userStats = await getUserStatistics(userId);
      final categoryStats = userStats.categoryStats
          .firstWhere((stat) => stat.categoryId == categoryId);
      return categoryStats;
    } catch (e) {
      print('Error loading category statistics: $e');
      throw Exception('Failed to load category statistics');
    }
  }
}

/// Helper class to build category statistics
class _CategoryStatsBuilder {
  final String categoryId;
  final String categoryTitle;
  final String categoryIconName;
  final int totalQuestions;
  int questionsAnswered = 0;
  int questionsMastered = 0;
  int questionsSeen = 0;

  _CategoryStatsBuilder({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIconName,
    required this.totalQuestions,
  });
}
