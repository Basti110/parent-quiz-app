import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/pool_metadata.dart';
import 'pool_metadata_service.dart';

/// Service for migrating existing users to the pool architecture
/// 
/// This service handles the migration of existing question states to include
/// pool-specific fields and creates initial pool metadata for users.
/// 
/// Migration is performed lazily when users first access pool functionality.
/// Requirements: 4.1, 4.4
class PoolMigrationService {
  final FirebaseFirestore _firestore;
  final PoolMetadataService _poolMetadataService;
  final Random _random;

  PoolMigrationService({
    FirebaseFirestore? firestore,
    PoolMetadataService? poolMetadataService,
    Random? random,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _poolMetadataService = poolMetadataService ?? PoolMetadataService(firestore: firestore),
       _random = random ?? Random();

  /// Check if user has been migrated to pool architecture
  /// 
  /// Returns true if user has pool metadata, false otherwise.
  Future<bool> isUserMigrated(String userId) async {
    try {
      return await _poolMetadataService.hasPoolMetadata(userId);
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Migrate user to pool architecture (lazy migration)
  /// 
  /// This method:
  /// 1. Checks if user is already migrated
  /// 2. Loads existing question states
  /// 3. Adds pool-specific fields to existing states
  /// 4. Creates pool metadata
  /// 
  /// Requirements: 4.1, 4.4
  Future<void> migrateUserToPoolArchitecture(String userId) async {
    try {
      // Check if already migrated
      if (await isUserMigrated(userId)) {
        print('User $userId already migrated to pool architecture');
        return;
      }

      print('Starting pool architecture migration for user $userId');

      // Get existing question states
      final existingStatesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      print('Found ${existingStatesSnapshot.docs.length} existing question states');

      if (existingStatesSnapshot.docs.isEmpty) {
        // User has no question states, just create empty pool metadata
        await _createInitialPoolMetadata(userId, 0);
        print('Created empty pool metadata for user $userId');
        return;
      }

      // Process existing states and add pool-specific fields
      final migratedStates = <QuestionState>[];
      final questionIds = <String>[];
      int maxSequence = 0;

      for (final doc in existingStatesSnapshot.docs) {
        try {
          final existingState = QuestionState.fromMap(doc.data());
          questionIds.add(existingState.questionId);
        } catch (e) {
          print('Warning: Failed to parse existing question state ${doc.id}: $e');
          // Continue with other states
        }
      }

      // Load question documents to get pool-specific data
      final questionData = await _loadQuestionDataForMigration(questionIds);

      // Create migrated states with pool-specific fields
      for (final doc in existingStatesSnapshot.docs) {
        try {
          final existingState = QuestionState.fromMap(doc.data());
          final questionInfo = questionData[existingState.questionId];

          if (questionInfo != null) {
            final migratedState = QuestionState(
              questionId: existingState.questionId,
              seenCount: existingState.seenCount,
              correctCount: existingState.correctCount,
              lastSeenAt: existingState.lastSeenAt,
              mastered: existingState.mastered,
              // Add pool-specific fields
              categoryId: questionInfo['categoryId'] as String,
              difficulty: questionInfo['difficulty'].toString(),
              randomSeed: questionInfo['randomSeed'] as double? ?? _random.nextDouble(),
              sequence: questionInfo['sequence'] as int? ?? 0,
              addedToPoolAt: DateTime.now(),
              poolBatch: 0, // Existing questions are batch 0
            );

            migratedStates.add(migratedState);

            // Track max sequence
            final sequence = questionInfo['sequence'] as int? ?? 0;
            if (sequence > maxSequence) {
              maxSequence = sequence;
            }
          } else {
            print('Warning: Question ${existingState.questionId} not found, skipping migration');
          }
        } catch (e) {
          print('Warning: Failed to migrate question state ${doc.id}: $e');
          // Continue with other states
        }
      }

      // Update question states with pool-specific fields
      await _updateQuestionStatesWithPoolFields(userId, migratedStates);

      // Create pool metadata
      await _createInitialPoolMetadata(userId, maxSequence, migratedStates.length);

      print('Successfully migrated ${migratedStates.length} question states for user $userId');

    } on FirebaseException catch (e) {
      print('Firebase error during migration: ${e.code} - ${e.message}');
      throw Exception('Failed to migrate user to pool architecture');
    } catch (e) {
      print('Error during migration: $e');
      throw Exception('Failed to migrate user to pool architecture');
    }
  }

  /// Load question data needed for migration
  /// 
  /// Returns a map of questionId -> question data for efficient lookup.
  Future<Map<String, Map<String, dynamic>>> _loadQuestionDataForMigration(
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) {
      return {};
    }

    final questionData = <String, Map<String, dynamic>>{};

    try {
      // Load questions in batches to avoid Firestore 'in' query limit (10 items)
      for (int i = 0; i < questionIds.length; i += 10) {
        final chunk = questionIds.skip(i).take(10).toList();

        try {
          final futures = chunk.map((id) => 
              _firestore.collection('questions').doc(id).get()
          ).toList();

          final snapshots = await Future.wait(futures);

          for (int j = 0; j < snapshots.length; j++) {
            final snapshot = snapshots[j];
            if (snapshot.exists) {
              final data = snapshot.data()!;
              questionData[chunk[j]] = data;
            } else {
              print('Warning: Question ${chunk[j]} not found during migration');
            }
          }
        } catch (e) {
          print('Warning: Failed to load question chunk during migration: $e');
          // Continue with other chunks
        }
      }

      return questionData;

    } catch (e) {
      print('Error loading question data for migration: $e');
      throw Exception('Failed to load question data for migration');
    }
  }

  /// Update question states with pool-specific fields
  /// 
  /// Uses batch operations for efficiency and consistency.
  /// Requirements: 4.1, 4.4
  Future<void> _updateQuestionStatesWithPoolFields(
    String userId,
    List<QuestionState> migratedStates,
  ) async {
    if (migratedStates.isEmpty) {
      return;
    }

    try {
      // Process in batches of 500 (Firestore batch limit)
      const batchSize = 500;

      for (int i = 0; i < migratedStates.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < migratedStates.length) 
            ? i + batchSize 
            : migratedStates.length;

        for (int j = i; j < endIndex; j++) {
          final state = migratedStates[j];
          final stateRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc(state.questionId);

          batch.update(stateRef, {
            'categoryId': state.categoryId,
            'difficulty': state.difficulty,
            'randomSeed': state.randomSeed,
            'sequence': state.sequence,
            'addedToPoolAt': state.addedToPoolAt != null 
                ? Timestamp.fromDate(state.addedToPoolAt!) 
                : null,
            'poolBatch': state.poolBatch,
          });
        }

        await batch.commit();
        print('Updated batch ${(i ~/ batchSize) + 1}/${(migratedStates.length / batchSize).ceil()}');
      }

    } catch (e) {
      print('Error updating question states with pool fields: $e');
      throw Exception('Failed to update question states with pool fields');
    }
  }

  /// Create initial pool metadata for migrated user
  /// 
  /// Requirements: 4.1, 4.4
  Future<void> _createInitialPoolMetadata(
    String userId,
    int maxSequence, [
    int? existingStatesCount,
  ]) async {
    try {
      final poolMetadata = PoolMetadata(
        totalPoolSize: existingStatesCount ?? 0,
        unseenCount: 0, // Existing states are all seen
        maxSequenceInPool: maxSequence,
        lastExpansionAt: null,
        expansionBatchCount: 0,
        categoryCounts: <String, int>{},
      );

      await _poolMetadataService.updatePoolMetadata(userId, poolMetadata);

    } catch (e) {
      print('Error creating initial pool metadata: $e');
      throw Exception('Failed to create initial pool metadata');
    }
  }

  /// Migrate multiple users in batch (for admin use)
  /// 
  /// This method can be used to migrate multiple users at once.
  /// It includes error handling to continue with other users if one fails.
  Future<Map<String, String>> migrateMultipleUsers(List<String> userIds) async {
    final results = <String, String>{};

    for (final userId in userIds) {
      try {
        await migrateUserToPoolArchitecture(userId);
        results[userId] = 'success';
      } catch (e) {
        results[userId] = 'error: $e';
        print('Failed to migrate user $userId: $e');
      }
    }

    return results;
  }

  /// Verify migration for a user
  /// 
  /// Checks that:
  /// 1. Pool metadata exists
  /// 2. All question states have pool-specific fields
  /// 3. Data integrity is maintained
  Future<bool> verifyUserMigration(String userId) async {
    try {
      // Check 1: Pool metadata exists
      final hasMetadata = await _poolMetadataService.hasPoolMetadata(userId);
      if (!hasMetadata) {
        print('Verification failed: No pool metadata found for user $userId');
        return false;
      }

      // Check 2: Question states have pool-specific fields
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .limit(10) // Sample check
          .get();

      for (final doc in statesSnapshot.docs) {
        try {
          final state = QuestionState.fromMap(doc.data());
          
          // Check required pool fields
          if (state.categoryId == null || state.categoryId!.isEmpty) {
            print('Verification failed: Question state ${state.questionId} missing categoryId');
            return false;
          }
          
          if (state.difficulty == null || state.difficulty!.isEmpty) {
            print('Verification failed: Question state ${state.questionId} missing difficulty');
            return false;
          }
          
          if (state.addedToPoolAt == null) {
            print('Verification failed: Question state ${state.questionId} missing addedToPoolAt');
            return false;
          }
          
          if (state.poolBatch == null) {
            print('Verification failed: Question state ${state.questionId} missing poolBatch');
            return false;
          }
          
        } catch (e) {
          print('Verification failed: Invalid question state format: $e');
          return false;
        }
      }

      print('Migration verification passed for user $userId');
      return true;

    } catch (e) {
      print('Error during migration verification: $e');
      return false;
    }
  }

  /// Get migration statistics for monitoring
  /// 
  /// Returns information about migration status across users.
  Future<Map<String, int>> getMigrationStatistics() async {
    try {
      // Get total users
      final usersSnapshot = await _firestore
          .collection('users')
          .count()
          .get();
      
      final totalUsers = usersSnapshot.count ?? 0;

      // Get users with pool metadata (migrated users)
      final migratedUsersSnapshot = await _firestore
          .collectionGroup('poolMetadata')
          .count()
          .get();
      
      final migratedUsers = migratedUsersSnapshot.count ?? 0;

      return {
        'totalUsers': totalUsers,
        'migratedUsers': migratedUsers,
        'pendingMigration': totalUsers - migratedUsers,
      };

    } catch (e) {
      print('Error getting migration statistics: $e');
      return {
        'totalUsers': 0,
        'migratedUsers': 0,
        'pendingMigration': 0,
      };
    }
  }
}