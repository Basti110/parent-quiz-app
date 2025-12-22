import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/pool_metadata_service.dart';
import 'package:eduparo/models/pool_metadata.dart';

void main() {
  group('PoolMetadataService', () {
    late FakeFirebaseFirestore firestore;
    late PoolMetadataService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = PoolMetadataService(firestore: firestore);
    });

    group('loadPoolMetadata', () {
      test('returns null when no metadata exists', () async {
        // Act
        final result = await service.loadPoolMetadata('user123');

        // Assert
        expect(result, isNull);
      });

      test('returns PoolMetadata when document exists', () async {
        // Arrange
        const userId = 'user123';
        final testData = {
          'totalPoolSize': 100,
          'unseenCount': 50,
          'maxSequenceInPool': 200,
          'expansionBatchCount': 2,
        };

        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set(testData);

        // Act
        final result = await service.loadPoolMetadata(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.totalPoolSize, equals(100));
        expect(result.unseenCount, equals(50));
        expect(result.maxSequenceInPool, equals(200));
        expect(result.expansionBatchCount, equals(2));
      });

      test('handles missing fields with defaults', () async {
        // Arrange
        const userId = 'user123';
        final testData = {
          'totalPoolSize': 25,
          // Missing other fields
        };

        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set(testData);

        // Act
        final result = await service.loadPoolMetadata(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.totalPoolSize, equals(25));
        expect(result.unseenCount, equals(0)); // Default value
        expect(result.maxSequenceInPool, equals(0)); // Default value
      });
    });

    group('updatePoolMetadata', () {
      test('creates new document when none exists', () async {
        // Arrange
        const userId = 'user123';
        final metadata = PoolMetadata(
          totalPoolSize: 150,
          unseenCount: 75,
          maxSequenceInPool: 300,
          expansionBatchCount: 3,
        );

        // Act
        await service.updatePoolMetadata(userId, metadata);

        // Assert
        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['totalPoolSize'], equals(150));
        expect(data['unseenCount'], equals(75));
        expect(data['maxSequenceInPool'], equals(300));
        expect(data['expansionBatchCount'], equals(3));
      });

      test('updates existing document with merge', () async {
        // Arrange
        const userId = 'user123';
        
        // Create initial document
        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set({
          'totalPoolSize': 100,
          'unseenCount': 50,
          'maxSequenceInPool': 200,
          'existingField': 'should remain',
        });

        final updatedMetadata = PoolMetadata(
          totalPoolSize: 200,
          unseenCount: 100,
          maxSequenceInPool: 400,
        );

        // Act
        await service.updatePoolMetadata(userId, updatedMetadata);

        // Assert
        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();

        final data = doc.data()!;
        expect(data['totalPoolSize'], equals(200));
        expect(data['unseenCount'], equals(100));
        expect(data['maxSequenceInPool'], equals(400));
        expect(data['existingField'], equals('should remain')); // Merge preserves existing fields
      });
    });

    group('updatePoolMetadataIncremental', () {
      test('increments fields correctly', () async {
        // Arrange
        const userId = 'user123';
        
        // Create initial document
        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set({
          'totalPoolSize': 100,
          'unseenCount': 50,
          'maxSequenceInPool': 200,
        });

        // Act
        await service.updatePoolMetadataIncremental(
          userId,
          incrementTotalPoolSize: 25,
          incrementUnseenCount: 15,
          newMaxSequenceInPool: 250,
        );

        // Assert
        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();

        final data = doc.data()!;
        expect(data['totalPoolSize'], equals(125)); // 100 + 25
        expect(data['unseenCount'], equals(65)); // 50 + 15
        expect(data['maxSequenceInPool'], equals(250)); // Set to new value
      });

      test('does nothing when no updates provided', () async {
        // Arrange
        const userId = 'user123';
        
        // Create initial document
        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set({
          'totalPoolSize': 100,
          'unseenCount': 50,
        });

        // Act
        await service.updatePoolMetadataIncremental(userId);

        // Assert - document should remain unchanged
        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();

        final data = doc.data()!;
        expect(data['totalPoolSize'], equals(100));
        expect(data['unseenCount'], equals(50));
      });
    });

    group('createInitialPoolMetadata', () {
      test('creates initial metadata with default values', () async {
        // Arrange
        const userId = 'user123';

        // Act
        await service.createInitialPoolMetadata(userId);

        // Assert
        final doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['totalPoolSize'], equals(0));
        expect(data['unseenCount'], equals(0));
        expect(data['maxSequenceInPool'], equals(0));
        expect(data['expansionBatchCount'], equals(0));
      });
    });

    group('hasPoolMetadata', () {
      test('returns false when no metadata exists', () async {
        // Act
        final result = await service.hasPoolMetadata('user123');

        // Assert
        expect(result, isFalse);
      });

      test('returns true when metadata exists', () async {
        // Arrange
        const userId = 'user123';
        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set({'totalPoolSize': 0});

        // Act
        final result = await service.hasPoolMetadata(userId);

        // Assert
        expect(result, isTrue);
      });
    });

    group('deletePoolMetadata', () {
      test('deletes existing metadata', () async {
        // Arrange
        const userId = 'user123';
        await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .set({'totalPoolSize': 100});

        // Verify it exists
        var doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();
        expect(doc.exists, isTrue);

        // Act
        await service.deletePoolMetadata(userId);

        // Assert
        doc = await firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats')
            .get();
        expect(doc.exists, isFalse);
      });
    });
  });

  group('PoolMetadata Model', () {
    test('toMap converts all fields correctly', () {
      // Arrange
      final metadata = PoolMetadata(
        totalPoolSize: 100,
        unseenCount: 50,
        maxSequenceInPool: 200,
        lastExpansionAt: DateTime(2023, 12, 1),
        expansionBatchCount: 2,
        categoryCounts: {'category1': 30, 'category2': 70},
      );

      // Act
      final map = metadata.toMap();

      // Assert
      expect(map['totalPoolSize'], equals(100));
      expect(map['unseenCount'], equals(50));
      expect(map['maxSequenceInPool'], equals(200));
      expect(map['lastExpansionAt'], isNotNull);
      expect(map['expansionBatchCount'], equals(2));
      expect(map['categoryCounts'], equals({'category1': 30, 'category2': 70}));
    });

    test('fromMap creates object with all fields', () {
      // Arrange
      final map = {
        'totalPoolSize': 100,
        'unseenCount': 50,
        'maxSequenceInPool': 200,
        'expansionBatchCount': 2,
        'categoryCounts': {'category1': 30, 'category2': 70},
      };

      // Act
      final metadata = PoolMetadata.fromMap(map);

      // Assert
      expect(metadata.totalPoolSize, equals(100));
      expect(metadata.unseenCount, equals(50));
      expect(metadata.maxSequenceInPool, equals(200));
      expect(metadata.expansionBatchCount, equals(2));
      expect(metadata.categoryCounts, equals({'category1': 30, 'category2': 70}));
    });

    test('fromMap handles missing fields with defaults', () {
      // Arrange
      final map = {
        'totalPoolSize': 100,
        // Missing other fields
      };

      // Act
      final metadata = PoolMetadata.fromMap(map);

      // Assert
      expect(metadata.totalPoolSize, equals(100));
      expect(metadata.unseenCount, equals(0)); // Default
      expect(metadata.maxSequenceInPool, equals(0)); // Default
      expect(metadata.expansionBatchCount, isNull);
      expect(metadata.categoryCounts, isNull);
    });

    test('initial factory creates default metadata', () {
      // Act
      final metadata = PoolMetadata.initial();

      // Assert
      expect(metadata.totalPoolSize, equals(0));
      expect(metadata.unseenCount, equals(0));
      expect(metadata.maxSequenceInPool, equals(0));
      expect(metadata.lastExpansionAt, isNull);
      expect(metadata.expansionBatchCount, equals(0));
      expect(metadata.categoryCounts, equals({}));
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      final original = PoolMetadata(
        totalPoolSize: 100,
        unseenCount: 50,
        maxSequenceInPool: 200,
      );

      // Act
      final updated = original.copyWith(
        totalPoolSize: 150,
        unseenCount: 75,
      );

      // Assert
      expect(updated.totalPoolSize, equals(150));
      expect(updated.unseenCount, equals(75));
      expect(updated.maxSequenceInPool, equals(200)); // Unchanged
    });
  });
}