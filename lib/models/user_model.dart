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
  final int totalXp;
  final int currentLevel;
  final int weeklyXpCurrent;
  final DateTime weeklyXpWeekStart;
  final int streakCurrent;
  final int streakLongest;
  final int duelsPlayed;
  final int duelsWon;
  final int duelsLost;
  final int duelPoints;
  final Map<String, CategoryProgress> categoryProgress;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.avatarPath,
    required this.createdAt,
    required this.lastActiveAt,
    required this.friendCode,
    required this.totalXp,
    required this.currentLevel,
    required this.weeklyXpCurrent,
    required this.weeklyXpWeekStart,
    required this.streakCurrent,
    required this.streakLongest,
    required this.duelsPlayed,
    required this.duelsWon,
    required this.duelsLost,
    required this.duelPoints,
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
      'totalXp': totalXp,
      'currentLevel': currentLevel,
      'weeklyXpCurrent': weeklyXpCurrent,
      'weeklyXpWeekStart': Timestamp.fromDate(weeklyXpWeekStart),
      'streakCurrent': streakCurrent,
      'streakLongest': streakLongest,
      'duelsPlayed': duelsPlayed,
      'duelsWon': duelsWon,
      'duelsLost': duelsLost,
      'duelPoints': duelPoints,
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
      totalXp: map['totalXp'] as int,
      currentLevel: map['currentLevel'] as int,
      weeklyXpCurrent: map['weeklyXpCurrent'] as int,
      weeklyXpWeekStart: (map['weeklyXpWeekStart'] as Timestamp).toDate(),
      streakCurrent: map['streakCurrent'] as int,
      streakLongest: map['streakLongest'] as int,
      duelsPlayed: map['duelsPlayed'] as int,
      duelsWon: map['duelsWon'] as int,
      duelsLost: map['duelsLost'] as int,
      duelPoints: map['duelPoints'] as int,
      categoryProgress: categoryProgressMap,
    );
  }

  /// Get progress for a specific category
  CategoryProgress getCategoryProgress(String categoryId) {
    return categoryProgress[categoryId] ?? CategoryProgress.empty();
  }
}
