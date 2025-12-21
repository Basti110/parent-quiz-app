/// Statistics for a specific category
class CategoryStatistics {
  final String categoryId;
  final String categoryTitle;
  final String categoryIconName;
  final int totalQuestions;
  final int questionsAnswered;
  final int questionsMastered;
  final int questionsSeen;

  CategoryStatistics({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIconName,
    required this.totalQuestions,
    required this.questionsAnswered,
    required this.questionsMastered,
    required this.questionsSeen,
  });

  /// Calculate percentage of questions answered
  double get percentageAnswered =>
      totalQuestions > 0 ? questionsAnswered / totalQuestions : 0.0;

  /// Calculate percentage of questions mastered
  double get percentageMastered =>
      totalQuestions > 0 ? questionsMastered / totalQuestions : 0.0;
}
