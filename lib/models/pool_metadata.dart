import 'package:cloud_firestore/cloud_firestore.dart';

class PoolMetadata {
  final int totalPoolSize;
  final int unseenCount;
  final int maxSequenceInPool;
  final DateTime? lastExpansionAt;
  final int? expansionBatchCount;
  final Map<String, int>? categoryCounts;

  PoolMetadata({
    required this.totalPoolSize,
    required this.unseenCount,
    required this.maxSequenceInPool,
    this.lastExpansionAt,
    this.expansionBatchCount,
    this.categoryCounts,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPoolSize': totalPoolSize,
      'unseenCount': unseenCount,
      'maxSequenceInPool': maxSequenceInPool,
      'lastExpansionAt': lastExpansionAt != null 
          ? Timestamp.fromDate(lastExpansionAt!) 
          : null,
      'expansionBatchCount': expansionBatchCount,
      'categoryCounts': categoryCounts,
    };
  }

  factory PoolMetadata.fromMap(Map<String, dynamic> map) {
    return PoolMetadata(
      totalPoolSize: map['totalPoolSize'] as int? ?? 0,
      unseenCount: map['unseenCount'] as int? ?? 0,
      maxSequenceInPool: map['maxSequenceInPool'] as int? ?? 0,
      lastExpansionAt: map['lastExpansionAt'] != null 
          ? (map['lastExpansionAt'] as Timestamp).toDate() 
          : null,
      expansionBatchCount: map['expansionBatchCount'] as int?,
      categoryCounts: map['categoryCounts'] != null 
          ? Map<String, int>.from(map['categoryCounts'] as Map)
          : null,
    );
  }

  /// Create initial pool metadata for a new user
  factory PoolMetadata.initial() {
    return PoolMetadata(
      totalPoolSize: 0,
      unseenCount: 0,
      maxSequenceInPool: 0,
      lastExpansionAt: null,
      expansionBatchCount: 0,
      categoryCounts: <String, int>{},
    );
  }

  /// Create a copy with updated values
  PoolMetadata copyWith({
    int? totalPoolSize,
    int? unseenCount,
    int? maxSequenceInPool,
    DateTime? lastExpansionAt,
    int? expansionBatchCount,
    Map<String, int>? categoryCounts,
  }) {
    return PoolMetadata(
      totalPoolSize: totalPoolSize ?? this.totalPoolSize,
      unseenCount: unseenCount ?? this.unseenCount,
      maxSequenceInPool: maxSequenceInPool ?? this.maxSequenceInPool,
      lastExpansionAt: lastExpansionAt ?? this.lastExpansionAt,
      expansionBatchCount: expansionBatchCount ?? this.expansionBatchCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
    );
  }
}