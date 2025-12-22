import 'package:flutter_test/flutter_test.dart';
import 'package:eduparo/models/question_state.dart';

void main() {
  group('QuestionState Enhanced Model Tests', () {
    test('should create QuestionState with pool-specific fields', () {
      // Arrange
      final now = DateTime.now();
      
      // Act
      final questionState = QuestionState(
        questionId: 'test_question_1',
        seenCount: 2,
        correctCount: 1,
        lastSeenAt: now,
        mastered: false,
        categoryId: 'test_category',
        difficulty: 'medium',
        randomSeed: 0.5,
        sequence: 100,
        addedToPoolAt: now,
        poolBatch: 1,
      );
      
      // Assert
      expect(questionState.questionId, equals('test_question_1'));
      expect(questionState.seenCount, equals(2));
      expect(questionState.correctCount, equals(1));
      expect(questionState.lastSeenAt, equals(now));
      expect(questionState.mastered, equals(false));
      expect(questionState.categoryId, equals('test_category'));
      expect(questionState.difficulty, equals('medium'));
      expect(questionState.randomSeed, equals(0.5));
      expect(questionState.sequence, equals(100));
      expect(questionState.addedToPoolAt, equals(now));
      expect(questionState.poolBatch, equals(1));
    });

    test('should have correct computed properties', () {
      // Test isUnseen property
      final unseenState = QuestionState(
        questionId: 'test_question_1',
        seenCount: 0,
        correctCount: 0,
        mastered: false,
      );
      expect(unseenState.isUnseen, isTrue);
      expect(unseenState.isUnmastered, isTrue);

      // Test seen state
      final seenState = QuestionState(
        questionId: 'test_question_2',
        seenCount: 2,
        correctCount: 1,
        mastered: false,
      );
      expect(seenState.isUnseen, isFalse);
      expect(seenState.isUnmastered, isTrue);

      // Test mastered state
      final masteredState = QuestionState(
        questionId: 'test_question_3',
        seenCount: 5,
        correctCount: 3,
        mastered: true,
      );
      expect(masteredState.isUnseen, isFalse);
      expect(masteredState.isUnmastered, isFalse);
    });

    test('should create QuestionState for pool using factory constructor', () {
      // Act
      final questionState = QuestionState.createForPool(
        questionId: 'pool_question_1',
        categoryId: 'health',
        difficulty: 'easy',
        randomSeed: 0.75,
        sequence: 250,
        poolBatch: 2,
      );
      
      // Assert
      expect(questionState.questionId, equals('pool_question_1'));
      expect(questionState.seenCount, equals(0));
      expect(questionState.correctCount, equals(0));
      expect(questionState.lastSeenAt, isNull);
      expect(questionState.mastered, isFalse);
      expect(questionState.categoryId, equals('health'));
      expect(questionState.difficulty, equals('easy'));
      expect(questionState.randomSeed, equals(0.75));
      expect(questionState.sequence, equals(250));
      expect(questionState.poolBatch, equals(2));
      expect(questionState.addedToPoolAt, isNotNull);
      expect(questionState.isUnseen, isTrue);
      expect(questionState.isUnmastered, isTrue);
    });

    test('should serialize and deserialize correctly with pool fields', () {
      // Arrange
      final now = DateTime.now();
      final originalState = QuestionState(
        questionId: 'serialize_test',
        seenCount: 3,
        correctCount: 2,
        lastSeenAt: now,
        mastered: false,
        categoryId: 'education',
        difficulty: 'hard',
        randomSeed: 0.25,
        sequence: 500,
        addedToPoolAt: now,
        poolBatch: 3,
      );
      
      // Act
      final map = originalState.toMap();
      final deserializedState = QuestionState.fromMap(map);
      
      // Assert
      expect(deserializedState.questionId, equals(originalState.questionId));
      expect(deserializedState.seenCount, equals(originalState.seenCount));
      expect(deserializedState.correctCount, equals(originalState.correctCount));
      expect(deserializedState.lastSeenAt, equals(originalState.lastSeenAt));
      expect(deserializedState.mastered, equals(originalState.mastered));
      expect(deserializedState.categoryId, equals(originalState.categoryId));
      expect(deserializedState.difficulty, equals(originalState.difficulty));
      expect(deserializedState.randomSeed, equals(originalState.randomSeed));
      expect(deserializedState.sequence, equals(originalState.sequence));
      expect(deserializedState.addedToPoolAt, equals(originalState.addedToPoolAt));
      expect(deserializedState.poolBatch, equals(originalState.poolBatch));
    });

    test('should handle null values in serialization', () {
      // Arrange
      final stateWithNulls = QuestionState(
        questionId: 'null_test',
        seenCount: 0,
        correctCount: 0,
        mastered: false,
        // All optional fields are null
      );
      
      // Act
      final map = stateWithNulls.toMap();
      final deserializedState = QuestionState.fromMap(map);
      
      // Assert
      expect(deserializedState.questionId, equals('null_test'));
      expect(deserializedState.seenCount, equals(0));
      expect(deserializedState.correctCount, equals(0));
      expect(deserializedState.lastSeenAt, isNull);
      expect(deserializedState.mastered, isFalse);
      expect(deserializedState.categoryId, isNull);
      expect(deserializedState.difficulty, isNull);
      expect(deserializedState.randomSeed, isNull);
      expect(deserializedState.sequence, isNull);
      expect(deserializedState.addedToPoolAt, isNull);
      expect(deserializedState.poolBatch, isNull);
    });
  });
}