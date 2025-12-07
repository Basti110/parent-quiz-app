import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks user progress for a specific category
class CategoryProgress {
  final int questionsAnswered;
  final int questionsMastered;
  final DateTime lastUpdated;

  CategoryProgress({
    required this.questionsAnswered,
    required this.questionsMastered,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionsAnswered': questionsAnswered,
      'questionsMastered': questionsMastered,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory CategoryProgress.fromMap(Map<String, dynamic> map) {
    return CategoryProgress(
      questionsAnswered: map['questionsAnswered'] as int? ?? 0,
      questionsMastered: map['questionsMastered'] as int? ?? 0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CategoryProgress.empty() {
    return CategoryProgress(
      questionsAnswered: 0,
      questionsMastered: 0,
      lastUpdated: DateTime.now(),
    );
  }
}
