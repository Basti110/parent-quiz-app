import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String friendUserId;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final String? avatarPath;
  final int wins;
  final int losses;

  Friend({
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.avatarPath,
    this.wins = 0,
    this.losses = 0,
  });

  /// Total number of games played between the user and this friend
  int get totalGames => wins + losses;

  /// Win rate as a decimal between 0.0 and 1.0
  double get winRate => totalGames > 0 ? wins / totalGames : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'friendUserId': friendUserId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'avatarPath': avatarPath,
      'wins': wins,
      'losses': losses,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      friendUserId: map['friendUserId'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      avatarPath: map['avatarPath'] as String?,
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
    );
  }
}
