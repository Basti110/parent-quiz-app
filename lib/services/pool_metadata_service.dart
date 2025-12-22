import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pool_metadata.dart';

class PoolMetadataService {
  final FirebaseFirestore _firestore;

  PoolMetadataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Load pool metadata for a user
  /// Returns null if no metadata exists (user hasn't been migrated to pool architecture)
  /// Requirements: 2.1, 4.1
  Future<PoolMetadata?> loadPoolMetadata(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .get();

      if (!doc.exists) {
        return null;
      }

      return PoolMetadata.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      print('Firebase error loading pool metadata: ${e.code} - ${e.message}');
      throw Exception('Failed to load pool metadata');
    } catch (e) {
      print('Error loading pool metadata: $e');
      throw Exception('Failed to load pool metadata');
    }
  }

  /// Update pool metadata for a user
  /// Uses merge: true to allow partial updates
  /// Requirements: 2.1, 4.1
  Future<void> updatePoolMetadata(
    String userId, 
    PoolMetadata metadata,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .set(metadata.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      print('Firebase error updating pool metadata: ${e.code} - ${e.message}');
      throw Exception('Failed to update pool metadata');
    } catch (e) {
      print('Error updating pool metadata: $e');
      throw Exception('Failed to update pool metadata');
    }
  }

  /// Update pool metadata with incremental changes
  /// Useful for atomic updates during pool expansion
  /// Requirements: 2.1, 4.1
  Future<void> updatePoolMetadataIncremental(
    String userId, {
    int? incrementTotalPoolSize,
    int? incrementUnseenCount,
    int? newMaxSequenceInPool,
    DateTime? lastExpansionAt,
    int? expansionBatchCount,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (incrementTotalPoolSize != null) {
        updates['totalPoolSize'] = FieldValue.increment(incrementTotalPoolSize);
      }

      if (incrementUnseenCount != null) {
        updates['unseenCount'] = FieldValue.increment(incrementUnseenCount);
      }

      if (newMaxSequenceInPool != null) {
        updates['maxSequenceInPool'] = newMaxSequenceInPool;
      }

      if (lastExpansionAt != null) {
        updates['lastExpansionAt'] = Timestamp.fromDate(lastExpansionAt);
      }

      if (expansionBatchCount != null) {
        updates['expansionBatchCount'] = expansionBatchCount;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set(updates, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      print('Firebase error updating pool metadata incrementally: ${e.code} - ${e.message}');
      throw Exception('Failed to update pool metadata');
    } catch (e) {
      print('Error updating pool metadata incrementally: $e');
      throw Exception('Failed to update pool metadata');
    }
  }

  /// Create initial pool metadata for a new user
  /// Requirements: 4.1
  Future<void> createInitialPoolMetadata(String userId) async {
    try {
      final initialMetadata = PoolMetadata.initial();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .set(initialMetadata.toMap());
    } on FirebaseException catch (e) {
      print('Firebase error creating initial pool metadata: ${e.code} - ${e.message}');
      throw Exception('Failed to create initial pool metadata');
    } catch (e) {
      print('Error creating initial pool metadata: $e');
      throw Exception('Failed to create initial pool metadata');
    }
  }

  /// Check if user has pool metadata (i.e., has been migrated to pool architecture)
  /// Requirements: 4.1
  Future<bool> hasPoolMetadata(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .get();

      return doc.exists;
    } on FirebaseException catch (e) {
      print('Firebase error checking pool metadata existence: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Error checking pool metadata existence: $e');
      return false;
    }
  }

  /// Delete pool metadata (for testing or cleanup)
  Future<void> deletePoolMetadata(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .delete();
    } on FirebaseException catch (e) {
      print('Firebase error deleting pool metadata: ${e.code} - ${e.message}');
      throw Exception('Failed to delete pool metadata');
    } catch (e) {
      print('Error deleting pool metadata: $e');
      throw Exception('Failed to delete pool metadata');
    }
  }
}