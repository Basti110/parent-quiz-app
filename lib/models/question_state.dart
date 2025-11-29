import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionState {
  final String questionId;
  final int seenCount;
  final int correctCount;
  final DateTime lastSeenAt;
  final bool mastered;

  QuestionState({
    required this.questionId,
    required this.seenCount,
    required this.correctCount,
    required this.lastSeenAt,
    required this.mastered,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'seenCount': seenCount,
      'correctCount': correctCount,
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
      'mastered': mastered,
    };
  }

  factory QuestionState.fromMap(Map<String, dynamic> map) {
    return QuestionState(
      questionId: map['questionId'] as String,
      seenCount: map['seenCount'] as int,
      correctCount: map['correctCount'] as int,
      lastSeenAt: (map['lastSeenAt'] as Timestamp).toDate(),
      mastered: map['mastered'] as bool,
    );
  }
}
