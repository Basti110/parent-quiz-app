import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionState {
  final String questionId;
  final int seenCount;
  final int correctCount;
  final DateTime? lastSeenAt;
  final bool mastered;
  
  // New pool-specific fields
  final String? categoryId;        // Denormalized for efficient filtering
  final String? difficulty;       // Denormalized for efficient filtering
  final double? randomSeed;        // For consistent randomization
  final int? sequence;             // Denormalized from question (for tracking)
  final DateTime? addedToPoolAt;   // When added to user's pool
  final int? poolBatch;            // Which expansion batch this came from

  QuestionState({
    required this.questionId,
    required this.seenCount,
    required this.correctCount,
    this.lastSeenAt,
    required this.mastered,
    this.categoryId,
    this.difficulty,
    this.randomSeed,
    this.sequence,
    this.addedToPoolAt,
    this.poolBatch,
  });

  // Computed properties
  bool get isUnseen => seenCount == 0;
  bool get isUnmastered => !mastered;

  /// Factory constructor for creating question states when adding to pool
  factory QuestionState.createForPool({
    required String questionId,
    required String categoryId,
    required String difficulty,
    required double randomSeed,
    required int sequence,
    required int poolBatch,
  }) {
    return QuestionState(
      questionId: questionId,
      seenCount: 0,
      correctCount: 0,
      lastSeenAt: null,
      mastered: false,
      categoryId: categoryId,
      difficulty: difficulty,
      randomSeed: randomSeed,
      sequence: sequence,
      addedToPoolAt: DateTime.now(),
      poolBatch: poolBatch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'seenCount': seenCount,
      'correctCount': correctCount,
      'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt!) : null,
      'mastered': mastered,
      'categoryId': categoryId,
      'difficulty': difficulty,
      'randomSeed': randomSeed,
      'sequence': sequence,
      'addedToPoolAt': addedToPoolAt != null ? Timestamp.fromDate(addedToPoolAt!) : null,
      'poolBatch': poolBatch,
    };
  }

  factory QuestionState.fromMap(Map<String, dynamic> map) {
    return QuestionState(
      questionId: map['questionId'] as String,
      seenCount: map['seenCount'] as int,
      correctCount: map['correctCount'] as int,
      lastSeenAt: map['lastSeenAt'] != null 
          ? (map['lastSeenAt'] as Timestamp).toDate() 
          : null,
      mastered: map['mastered'] as bool,
      categoryId: map['categoryId'] as String?,
      difficulty: map['difficulty'] as String?,
      randomSeed: map['randomSeed'] as double?,
      sequence: map['sequence'] as int?,
      addedToPoolAt: map['addedToPoolAt'] != null 
          ? (map['addedToPoolAt'] as Timestamp).toDate() 
          : null,
      poolBatch: map['poolBatch'] as int?,
    );
  }
}
