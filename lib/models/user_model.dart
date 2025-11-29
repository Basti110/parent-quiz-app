import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
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

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
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
    );
  }
}
