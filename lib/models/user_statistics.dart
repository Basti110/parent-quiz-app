import 'category_statistics.dart';

/// Aggregated statistics for a user across all categories
class UserStatistics {
  final int totalQuestionsAnswered;
  final int totalQuestionsMastered;
  final int totalQuestionsSeen;
  final List<CategoryStatistics> categoryStats;

  UserStatistics({
    required this.totalQuestionsAnswered,
    required this.totalQuestionsMastered,
    required this.totalQuestionsSeen,
    required this.categoryStats,
  });

  /// Calculate percentage of questions answered
  double get percentageAnswered =>
      totalQuestionsSeen > 0 ? totalQuestionsAnswered / totalQuestionsSeen : 0.0;

  /// Calculate percentage of questions mastered
  double get percentageMastered =>
      totalQuestionsSeen > 0 ? totalQuestionsMastered / totalQuestionsSeen : 0.0;
}
