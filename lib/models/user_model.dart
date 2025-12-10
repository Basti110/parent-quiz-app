import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_progress.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String friendCode;
  
  // Streak tracking
  final int streakCurrent;
  final int streakLongest;
  final int streakPoints;
  
  // Daily goal system
  final int dailyGoal;
  final int questionsAnsweredToday;
  final DateTime lastDailyReset;
  
  // Question statistics
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int totalMasteredQuestions;
  
  // Duel statistics (simplified)
  final int duelsCompleted;
  final int duelsWon;
  
  final Map<String, CategoryProgress> categoryProgress;

  /// Calculate duels lost from completed and won
  int get duelsLost => duelsCompleted - duelsWon;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.avatarPath,
    required this.createdAt,
    required this.lastActiveAt,
    required this.friendCode,
    required this.streakCurrent,
    required this.streakLongest,
    required this.streakPoints,
    required this.dailyGoal,
    required this.questionsAnsweredToday,
    required this.lastDailyReset,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.totalMasteredQuestions,
    required this.duelsCompleted,
    required this.duelsWon,
    this.categoryProgress = const {},
  });

  Map<String, dynamic> toMap() {
    final categoryProgressMap = <String, dynamic>{};
    categoryProgress.forEach((key, value) {
      categoryProgressMap[key] = value.toMap();
    });

    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'avatarPath': avatarPath,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'friendCode': friendCode,
      'streakCurrent': streakCurrent,
      'streakLongest': streakLongest,
      'streakPoints': streakPoints,
      'dailyGoal': dailyGoal,
      'questionsAnsweredToday': questionsAnsweredToday,
      'lastDailyReset': Timestamp.fromDate(lastDailyReset),
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalMasteredQuestions': totalMasteredQuestions,
      'duelsCompleted': duelsCompleted,
      'duelsWon': duelsWon,
      'categoryProgress': categoryProgressMap,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final categoryProgressMap = <String, CategoryProgress>{};
    final progressData = map['categoryProgress'] as Map<String, dynamic>?;
    if (progressData != null) {
      progressData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          categoryProgressMap[key] = CategoryProgress.fromMap(value);
        }
      });
    }

    return UserModel(
      id: id,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      avatarPath: map['avatarPath'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp).toDate(),
      friendCode: map['friendCode'] as String,
      streakCurrent: map['streakCurrent'] as int? ?? 0,
      streakLongest: map['streakLongest'] as int? ?? 0,
      streakPoints: map['streakPoints'] as int? ?? 0,
      dailyGoal: map['dailyGoal'] as int? ?? 10,
      questionsAnsweredToday: map['questionsAnsweredToday'] as int? ?? 0,
      lastDailyReset: map['lastDailyReset'] != null 
          ? (map['lastDailyReset'] as Timestamp).toDate()
          : DateTime.now(),
      totalQuestionsAnswered: map['totalQuestionsAnswered'] as int? ?? 0,
      totalCorrectAnswers: map['totalCorrectAnswers'] as int? ?? 0,
      totalMasteredQuestions: map['totalMasteredQuestions'] as int? ?? 0,
      duelsCompleted: map['duelsCompleted'] as int? ?? (map['duelsPlayed'] as int? ?? 0),
      duelsWon: map['duelsWon'] as int? ?? 0,
      categoryProgress: categoryProgressMap,
    );
  }

  /// Get progress for a specific category
  CategoryProgress getCategoryProgress(String categoryId) {
    return categoryProgress[categoryId] ?? CategoryProgress.empty();
  }
}
