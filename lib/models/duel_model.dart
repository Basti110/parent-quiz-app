import 'package:cloud_firestore/cloud_firestore.dart';

enum DuelStatus {
  pending,      // Waiting for opponent to accept
  accepted,     // Accepted, waiting for both to complete
  completed,    // Both participants finished
  declined,     // Opponent declined
  expired,      // Expired after 7 days
}

class DuelModel {
  final String id;
  final String challengerId;
  final String opponentId;
  final DuelStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  // Questions (same 5 for both participants)
  final List<String> questionIds;

  // Challenger's data
  final Map<String, bool> challengerAnswers;  // questionId -> isCorrect
  final int challengerScore;                   // Calculated incrementally
  final DateTime? challengerCompletedAt;

  // Opponent's data
  final Map<String, bool> opponentAnswers;     // questionId -> isCorrect
  final int opponentScore;                     // Calculated incrementally
  final DateTime? opponentCompletedAt;

  DuelModel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.questionIds,
    this.challengerAnswers = const {},
    this.challengerScore = 0,
    this.challengerCompletedAt,
    this.opponentAnswers = const {},
    this.opponentScore = 0,
    this.opponentCompletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengerId': challengerId,
      'opponentId': opponentId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'questionIds': questionIds,
      'challengerAnswers': challengerAnswers,
      'challengerScore': challengerScore,
      'challengerCompletedAt': challengerCompletedAt != null 
          ? Timestamp.fromDate(challengerCompletedAt!) 
          : null,
      'opponentAnswers': opponentAnswers,
      'opponentScore': opponentScore,
      'opponentCompletedAt': opponentCompletedAt != null 
          ? Timestamp.fromDate(opponentCompletedAt!) 
          : null,
    };
  }

  factory DuelModel.fromMap(Map<String, dynamic> map, String id) {
    return DuelModel(
      id: id,
      challengerId: map['challengerId'] as String,
      opponentId: map['opponentId'] as String,
      status: DuelStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DuelStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null 
          ? (map['acceptedAt'] as Timestamp).toDate() 
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      questionIds: List<String>.from(map['questionIds'] as List),
      challengerAnswers: Map<String, bool>.from(map['challengerAnswers'] as Map? ?? {}),
      challengerScore: map['challengerScore'] as int? ?? 0,
      challengerCompletedAt: map['challengerCompletedAt'] != null 
          ? (map['challengerCompletedAt'] as Timestamp).toDate() 
          : null,
      opponentAnswers: Map<String, bool>.from(map['opponentAnswers'] as Map? ?? {}),
      opponentScore: map['opponentScore'] as int? ?? 0,
      opponentCompletedAt: map['opponentCompletedAt'] != null 
          ? (map['opponentCompletedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Determines the winner of the duel
  /// Returns null if duel is not complete or if it's a tie
  String? getWinnerId() {
    // Only determine winner when both have completed
    if (challengerCompletedAt == null || opponentCompletedAt == null) {
      return null;
    }

    if (challengerScore > opponentScore) {
      return challengerId;
    }
    if (opponentScore > challengerScore) {
      return opponentId;
    }
    return null; // Tie
  }
}
