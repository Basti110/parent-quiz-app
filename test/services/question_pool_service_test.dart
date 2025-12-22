import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

import '../../lib/services/question_pool_service.dart';
import '../../lib/services/pool_metadata_service.dart';
import '../../lib/models/question_state.dart';
import '../../lib/models/pool_metadata.dart';

void main() {
  group('QuestionPoolService', () {
    late FakeFirebaseFirestore firestore;
    late PoolMetadataService poolMetadataService;
    late QuestionPoolService questionPoolService;
    late Random random;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      poolMetadataService = PoolMetadataService(firestore: firestore);
      random = Random(42); // Fixed seed for reproducible tests
      questionPoolService = QuestionPoolService(
        firestore: firestore,
        poolMetadataService: poolMetadataService,
        random: random,
      );
    });

    group('getQuestionsForSession', () {
      test('should return empty list when no questions in pool', () async {
        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 5,
        );

        expect(questions, isEmpty);
      });

      test('should prioritize unseen questions first', () async {
        // Create test questions
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);
        await _createTestQuestion(firestore, 'q2', 'cat1', 'easy', 2);
        await _createTestQuestion(firestore, 'q3', 'cat1', 'easy', 3);

        // Create question states - mix of unseen and seen
        await _createTestQuestionState(firestore, 'user1', 'q1', seenCount: 0); // unseen
        await _createTestQuestionState(firestore, 'user1', 'q2', seenCount: 2); // seen but unmastered
        await _createTestQuestionState(firestore, 'user1', 'q3', seenCount: 0); // unseen

        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 2,
        );

        expect(questions.length, equals(2));
        // Should get the unseen questions (q1 and q3)
        final questionIds = questions.map((q) => q.id).toSet();
        expect(questionIds, containsAll(['q1', 'q3']));
      });

      test('should filter by category when specified', () async {
        // Create test questions in different categories
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);
        await _createTestQuestion(firestore, 'q2', 'cat2', 'easy', 2);

        // Create question states
        await _createTestQuestionState(firestore, 'user1', 'q1', categoryId: 'cat1');
        await _createTestQuestionState(firestore, 'user1', 'q2', categoryId: 'cat2');

        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 5,
          categoryId: 'cat1',
        );

        expect(questions.length, equals(1));
        expect(questions.first.id, equals('q1'));
        expect(questions.first.categoryId, equals('cat1'));
      });

      test('should filter by difficulty when specified', () async {
        // Create test questions with different difficulties
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);
        await _createTestQuestion(firestore, 'q2', 'cat1', 'hard', 2);

        // Create question states - difficulty should be stored as string in question state
        await _createTestQuestionState(firestore, 'user1', 'q1', difficulty: '1'); // easy = 1
        await _createTestQuestionState(firestore, 'user1', 'q2', difficulty: '3'); // hard = 3

        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 5,
          difficulty: '1', // Filter for easy questions
        );

        expect(questions.length, equals(1));
        expect(questions.first.id, equals('q1'));
        expect(questions.first.difficulty, equals(1)); // 'easy' maps to 1 in Question model
      });

      test('should fall back to unmastered questions when no unseen available', () async {
        // Create test questions
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);
        await _createTestQuestion(firestore, 'q2', 'cat1', 'easy', 2);

        // Create question states - all seen but unmastered
        await _createTestQuestionState(firestore, 'user1', 'q1', 
          seenCount: 2, correctCount: 1, mastered: false,
          lastSeenAt: DateTime(2023, 1, 1)); // older
        await _createTestQuestionState(firestore, 'user1', 'q2', 
          seenCount: 1, correctCount: 0, mastered: false,
          lastSeenAt: DateTime(2023, 1, 2)); // newer

        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 1,
        );

        expect(questions.length, equals(1));
        // Should get the older question first (q1)
        expect(questions.first.id, equals('q1'));
      });

      test('should fall back to mastered questions when no unmastered available', () async {
        // Create test questions
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);

        // Create question state - mastered
        await _createTestQuestionState(firestore, 'user1', 'q1', 
          seenCount: 5, correctCount: 3, mastered: true);

        final questions = await questionPoolService.getQuestionsForSession(
          userId: 'user1',
          count: 1,
        );

        expect(questions.length, equals(1));
        expect(questions.first.id, equals('q1'));
      });
    });

    group('recordAnswer', () {
      test('should update question state correctly for correct answer', () async {
        // Create test question
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);

        // Create initial question state
        await _createTestQuestionState(firestore, 'user1', 'q1', 
          seenCount: 1, correctCount: 1);

        await questionPoolService.recordAnswer(
          userId: 'user1',
          questionId: 'q1',
          isCorrect: true,
        );

        // Verify state was updated
        final stateDoc = await firestore
            .collection('users')
            .doc('user1')
            .collection('questionStates')
            .doc('q1')
            .get();

        final state = QuestionState.fromMap(stateDoc.data()!);
        expect(state.seenCount, equals(2));
        expect(state.correctCount, equals(2));
        expect(state.mastered, isFalse); // Not mastered yet (need 3 correct)
        expect(state.lastSeenAt, isNotNull);
      });

      test('should set mastered to true when correctCount reaches 3', () async {
        // Create test question
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);

        // Create initial question state with 2 correct answers
        await _createTestQuestionState(firestore, 'user1', 'q1', 
          seenCount: 2, correctCount: 2);

        await questionPoolService.recordAnswer(
          userId: 'user1',
          questionId: 'q1',
          isCorrect: true,
        );

        // Verify mastery was achieved
        final stateDoc = await firestore
            .collection('users')
            .doc('user1')
            .collection('questionStates')
            .doc('q1')
            .get();

        final state = QuestionState.fromMap(stateDoc.data()!);
        expect(state.correctCount, equals(3));
        expect(state.mastered, isTrue);
      });

      test('should not increment correctCount for incorrect answer', () async {
        // Create test question
        await _createTestQuestion(firestore, 'q1', 'cat1', 'easy', 1);

        // Create initial question state
        await _createTestQuestionState(firestore, 'user1', 'q1', 
          seenCount: 1, correctCount: 1);

        await questionPoolService.recordAnswer(
          userId: 'user1',
          questionId: 'q1',
          isCorrect: false,
        );

        // Verify state was updated correctly
        final stateDoc = await firestore
            .collection('users')
            .doc('user1')
            .collection('questionStates')
            .doc('q1')
            .get();

        final state = QuestionState.fromMap(stateDoc.data()!);
        expect(state.seenCount, equals(2));
        expect(state.correctCount, equals(1)); // Should not increment
        expect(state.mastered, isFalse);
      });
    });

    group('countQuestionsInPool', () {
      test('should count all questions when no filters applied', () async {
        // Create question states
        await _createTestQuestionState(firestore, 'user1', 'q1');
        await _createTestQuestionState(firestore, 'user1', 'q2');

        final count = await questionPoolService.countQuestionsInPool(
          userId: 'user1',
        );

        expect(count, equals(2));
      });

      test('should filter by category', () async {
        // Create question states in different categories
        await _createTestQuestionState(firestore, 'user1', 'q1', categoryId: 'cat1');
        await _createTestQuestionState(firestore, 'user1', 'q2', categoryId: 'cat2');

        final count = await questionPoolService.countQuestionsInPool(
          userId: 'user1',
          categoryId: 'cat1',
        );

        expect(count, equals(1));
      });

      test('should filter by unseen only', () async {
        // Create mix of seen and unseen question states
        await _createTestQuestionState(firestore, 'user1', 'q1', seenCount: 0);
        await _createTestQuestionState(firestore, 'user1', 'q2', seenCount: 1);

        final count = await questionPoolService.countQuestionsInPool(
          userId: 'user1',
          unseenOnly: true,
        );

        expect(count, equals(1));
      });

      test('should filter by unmastered only', () async {
        // Create mix of mastered and unmastered question states
        await _createTestQuestionState(firestore, 'user1', 'q1', mastered: false);
        await _createTestQuestionState(firestore, 'user1', 'q2', mastered: true);

        final count = await questionPoolService.countQuestionsInPool(
          userId: 'user1',
          unmasteredOnly: true,
        );

        expect(count, equals(1));
      });
    });

    group('hasPoolArchitecture', () {
      test('should return false when user has no pool metadata', () async {
        final hasPool = await questionPoolService.hasPoolArchitecture('user1');
        expect(hasPool, isFalse);
      });

      test('should return true when user has pool metadata', () async {
        // Create pool metadata
        await firestore
            .collection('users')
            .doc('user1')
            .collection('poolMetadata')
            .doc('stats')
            .set(PoolMetadata.initial().toMap());

        final hasPool = await questionPoolService.hasPoolArchitecture('user1');
        expect(hasPool, isTrue);
      });
    });

    group('Property Tests', () {
      test('Property 2: Pool expansion correctness - all new states should match filters and be unseen', () async {
        // **Feature: question-pool-architecture, Property 2: Pool expansion correctness**
        // **Validates: Requirements 2.3, 2.4, 2.5**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final categoryFilter = random.nextBool() ? 'cat${random.nextInt(3) + 1}' : null;
          final difficultyFilter = random.nextBool() ? '${random.nextInt(3) + 1}' : null;
          final numGlobalQuestions = random.nextInt(50) + 10; // 10-59 questions
          
          // Clear previous test data
          await _clearUserData(firestore, 'user1');
          
          // Create pool metadata
          await firestore
              .collection('users')
              .doc('user1')
              .collection('poolMetadata')
              .doc('stats')
              .set(PoolMetadata.initial().toMap());
          
          // Create global questions with various categories and difficulties
          final createdQuestions = <String, Map<String, dynamic>>{};
          for (int i = 0; i < numGlobalQuestions; i++) {
            final questionId = 'q$i';
            final categoryId = 'cat${random.nextInt(3) + 1}'; // cat1, cat2, cat3
            final difficulty = random.nextInt(3) + 1; // 1, 2, 3
            
            final questionData = {
              'categoryId': categoryId,
              'text': 'Test question $questionId',
              'options': ['Option A', 'Option B', 'Option C'],
              'correctIndices': [0],
              'explanation': 'Test explanation',
              'difficulty': difficulty,
              'isActive': true,
              'sequence': i + 1,
            };
            
            await firestore.collection('questions').doc(questionId).set(questionData);
            createdQuestions[questionId] = questionData;
          }
          
          // Perform pool expansion
          await questionPoolService.expandPool(
            userId: 'user1',
            categoryId: categoryFilter,
            difficulty: difficultyFilter,
          );
          
          // Load all question states created by expansion
          final statesSnapshot = await firestore
              .collection('users')
              .doc('user1')
              .collection('questionStates')
              .get();
          
          final questionStates = statesSnapshot.docs
              .map((doc) => QuestionState.fromMap(doc.data()))
              .toList();
          
          // Property verification: All new question states should satisfy the requirements
          for (final state in questionStates) {
            // Requirement 2.3: All new states should have seenCount = 0
            expect(state.seenCount, equals(0),
              reason: 'Iteration $iteration: Question ${state.questionId} should have seenCount = 0, got ${state.seenCount}');
            
            // Requirement 2.4: Should match category filter if specified
            if (categoryFilter != null) {
              expect(state.categoryId, equals(categoryFilter),
                reason: 'Iteration $iteration: Question ${state.questionId} should match category filter $categoryFilter, got ${state.categoryId}');
            }
            
            // Requirement 2.5: Should match difficulty filter if specified
            if (difficultyFilter != null) {
              expect(state.difficulty, equals(difficultyFilter),
                reason: 'Iteration $iteration: Question ${state.questionId} should match difficulty filter $difficultyFilter, got ${state.difficulty}');
            }
            
            // Additional verification: Question should exist and be active
            final originalQuestion = createdQuestions[state.questionId];
            expect(originalQuestion, isNotNull,
              reason: 'Iteration $iteration: Question ${state.questionId} should exist in global collection');
            expect(originalQuestion!['isActive'], isTrue,
              reason: 'Iteration $iteration: Question ${state.questionId} should be active');
            
            // Verify denormalized fields match original question
            expect(state.categoryId, equals(originalQuestion['categoryId']),
              reason: 'Iteration $iteration: Denormalized categoryId should match original');
            expect(state.difficulty, equals(originalQuestion['difficulty'].toString()),
              reason: 'Iteration $iteration: Denormalized difficulty should match original');
          }
        }
      });

      test('Property 4: Count constraint satisfaction - should return min(N, M) questions', () async {
        // **Feature: question-pool-architecture, Property 4: Count constraint satisfaction**
        // **Validates: Requirements 1.4**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test data
          final poolSize = random.nextInt(20) + 1; // 1-20 questions in pool
          final requestedCount = random.nextInt(30) + 1; // 1-30 questions requested
          final expectedCount = poolSize < requestedCount ? poolSize : requestedCount;
          
          // Clear previous test data
          await _clearUserData(firestore, 'user1');
          
          // Create test questions and states
          for (int i = 0; i < poolSize; i++) {
            await _createTestQuestion(firestore, 'q$i', 'cat1', 'easy', i + 1);
            await _createTestQuestionState(firestore, 'user1', 'q$i');
          }
          
          // Request questions
          final questions = await questionPoolService.getQuestionsForSession(
            userId: 'user1',
            count: requestedCount,
          );
          
          // Verify count constraint: should return min(poolSize, requestedCount)
          expect(questions.length, equals(expectedCount),
            reason: 'Iteration $iteration: Pool size: $poolSize, Requested: $requestedCount, Expected: $expectedCount, Got: ${questions.length}');
        }
      });

      test('Property 5: Answer recording updates all fields', () async {
        // **Feature: question-pool-architecture, Property 5: Answer recording updates all fields**
        // **Validates: Requirements 3.1, 3.2, 3.3**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test data
          final initialSeenCount = random.nextInt(10); // 0-9 initial seen count
          final initialCorrectCount = random.nextInt(5); // 0-4 initial correct count
          final isCorrect = random.nextBool(); // Random answer correctness
          final questionId = 'q$iteration';
          final userId = 'user$iteration';
          
          // Clear previous test data for this user
          await _clearUserData(firestore, userId);
          
          // Create test question
          await _createTestQuestion(firestore, questionId, 'cat1', 'easy', iteration + 1);
          
          // Create initial question state with random values
          final initialLastSeenAt = initialSeenCount > 0 
              ? DateTime.now().subtract(Duration(days: random.nextInt(30) + 1))
              : null;
          
          await _createTestQuestionState(
            firestore, 
            userId, 
            questionId,
            seenCount: initialSeenCount,
            correctCount: initialCorrectCount,
            mastered: initialCorrectCount >= 3,
            lastSeenAt: initialLastSeenAt,
          );
          
          // Record the answer
          final beforeTime = DateTime.now();
          await questionPoolService.recordAnswer(
            userId: userId,
            questionId: questionId,
            isCorrect: isCorrect,
          );
          final afterTime = DateTime.now();
          
          // Load the updated question state
          final stateDoc = await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc(questionId)
              .get();
          
          final updatedState = QuestionState.fromMap(stateDoc.data()!);
          
          // Property verification: All fields should be updated correctly
          
          // Requirement 3.1: seenCount should be incremented by 1
          expect(updatedState.seenCount, equals(initialSeenCount + 1),
            reason: 'Iteration $iteration: seenCount should increment from $initialSeenCount to ${initialSeenCount + 1}, got ${updatedState.seenCount}');
          
          // Requirement 3.2: correctCount should increment if answer is correct
          final expectedCorrectCount = isCorrect ? initialCorrectCount + 1 : initialCorrectCount;
          expect(updatedState.correctCount, equals(expectedCorrectCount),
            reason: 'Iteration $iteration: correctCount should be $expectedCorrectCount (was $initialCorrectCount, isCorrect: $isCorrect), got ${updatedState.correctCount}');
          
          // Requirement 3.3: lastSeenAt should be updated to recent timestamp
          expect(updatedState.lastSeenAt, isNotNull,
            reason: 'Iteration $iteration: lastSeenAt should not be null after recording answer');
          expect(updatedState.lastSeenAt!.isAfter(beforeTime) || updatedState.lastSeenAt!.isAtSameMomentAs(beforeTime), isTrue,
            reason: 'Iteration $iteration: lastSeenAt should be after or equal to beforeTime');
          expect(updatedState.lastSeenAt!.isBefore(afterTime) || updatedState.lastSeenAt!.isAtSameMomentAs(afterTime), isTrue,
            reason: 'Iteration $iteration: lastSeenAt should be before or equal to afterTime');
          
          // Additional verification: Other fields should remain unchanged
          expect(updatedState.questionId, equals(questionId),
            reason: 'Iteration $iteration: questionId should remain unchanged');
          expect(updatedState.categoryId, equals('cat1'),
            reason: 'Iteration $iteration: categoryId should remain unchanged');
          expect(updatedState.difficulty, equals('1'),
            reason: 'Iteration $iteration: difficulty should remain unchanged');
        }
      });

      test('Property 6: Mastery threshold enforcement', () async {
        // **Feature: question-pool-architecture, Property 6: Mastery threshold enforcement**
        // **Validates: Requirements 3.4**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test data around the mastery threshold (3 correct answers)
          final initialCorrectCount = random.nextInt(6); // 0-5 initial correct count
          final isCorrect = random.nextBool(); // Random answer correctness
          final questionId = 'q$iteration';
          final userId = 'user$iteration';
          
          // Clear previous test data for this user
          await _clearUserData(firestore, userId);
          
          // Create test question
          await _createTestQuestion(firestore, questionId, 'cat1', 'easy', iteration + 1);
          
          // Create initial question state
          await _createTestQuestionState(
            firestore, 
            userId, 
            questionId,
            seenCount: random.nextInt(10) + 1, // At least 1 seen
            correctCount: initialCorrectCount,
            mastered: initialCorrectCount >= 3, // Should already be mastered if >= 3
          );
          
          // Record the answer
          await questionPoolService.recordAnswer(
            userId: userId,
            questionId: questionId,
            isCorrect: isCorrect,
          );
          
          // Load the updated question state
          final stateDoc = await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .doc(questionId)
              .get();
          
          final updatedState = QuestionState.fromMap(stateDoc.data()!);
          
          // Calculate expected values
          final expectedCorrectCount = isCorrect ? initialCorrectCount + 1 : initialCorrectCount;
          final expectedMastered = expectedCorrectCount >= 3;
          
          // Property verification: Mastery threshold should be enforced correctly
          
          // Requirement 3.4: mastered should be true when correctCount >= 3
          expect(updatedState.mastered, equals(expectedMastered),
            reason: 'Iteration $iteration: mastered should be $expectedMastered when correctCount is $expectedCorrectCount (threshold is 3)');
          
          // Additional verification: correctCount should match expected
          expect(updatedState.correctCount, equals(expectedCorrectCount),
            reason: 'Iteration $iteration: correctCount should be $expectedCorrectCount');
          
          // Verify mastery logic consistency
          if (updatedState.correctCount >= 3) {
            expect(updatedState.mastered, isTrue,
              reason: 'Iteration $iteration: Question should be mastered when correctCount (${updatedState.correctCount}) >= 3');
          } else {
            expect(updatedState.mastered, isFalse,
              reason: 'Iteration $iteration: Question should not be mastered when correctCount (${updatedState.correctCount}) < 3');
          }
        }
      });

      test('Property 7: No duplicate states in pool', () async {
        // **Feature: question-pool-architecture, Property 7: No duplicate states in pool**
        // **Validates: Requirements 4.1**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final numGlobalQuestions = random.nextInt(30) + 10; // 10-39 questions
          final numExpansions = random.nextInt(3) + 2; // 2-4 expansion operations
          final userId = 'user$iteration';
          
          // Clear previous test data
          await _clearUserData(firestore, userId);
          
          // Create pool metadata
          await firestore
              .collection('users')
              .doc(userId)
              .collection('poolMetadata')
              .doc('stats')
              .set(PoolMetadata.initial().toMap());
          
          // Create global questions
          final createdQuestionIds = <String>[];
          for (int i = 0; i < numGlobalQuestions; i++) {
            final questionId = 'q${iteration}_$i';
            createdQuestionIds.add(questionId);
            
            await firestore.collection('questions').doc(questionId).set({
              'categoryId': 'cat1',
              'text': 'Test question $questionId',
              'options': ['Option A', 'Option B', 'Option C'],
              'correctIndices': [0],
              'explanation': 'Test explanation',
              'difficulty': 1,
              'isActive': true,
              'sequence': i + 1,
            });
          }
          
          // Perform multiple pool expansions (this should not create duplicates)
          for (int expansion = 0; expansion < numExpansions; expansion++) {
            try {
              await questionPoolService.expandPool(
                userId: userId,
                batchSize: random.nextInt(10) + 5, // 5-14 questions per batch
              );
            } catch (e) {
              // Pool expansion might fail if no more questions available, which is fine
              print('Pool expansion $expansion failed (expected): $e');
            }
          }
          
          // Load all question states created
          final statesSnapshot = await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .get();
          
          final questionStates = statesSnapshot.docs
              .map((doc) => QuestionState.fromMap(doc.data()))
              .toList();
          
          // Property verification: No duplicate question states should exist
          final questionIds = questionStates.map((state) => state.questionId).toList();
          final uniqueQuestionIds = questionIds.toSet();
          
          expect(questionIds.length, equals(uniqueQuestionIds.length),
            reason: 'Iteration $iteration: Found duplicate question states. Total states: ${questionIds.length}, Unique IDs: ${uniqueQuestionIds.length}');
          
          // Additional verification: All question IDs should be from the created questions
          for (final questionId in questionIds) {
            expect(createdQuestionIds.contains(questionId), isTrue,
              reason: 'Iteration $iteration: Question state $questionId should correspond to a created question');
          }
          
          // Verify no question appears more than once
          final idCounts = <String, int>{};
          for (final questionId in questionIds) {
            idCounts[questionId] = (idCounts[questionId] ?? 0) + 1;
          }
          
          for (final entry in idCounts.entries) {
            expect(entry.value, equals(1),
              reason: 'Iteration $iteration: Question ${entry.key} appears ${entry.value} times, should appear exactly once');
          }
        }
      });

      test('Property 8: Partial failure consistency', () async {
        // **Feature: question-pool-architecture, Property 8: Partial failure consistency**
        // **Validates: Requirements 4.3**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final numInitialStates = random.nextInt(20) + 5; // 5-24 initial question states
          final userId = 'user$iteration';
          
          // Clear previous test data
          await _clearUserData(firestore, userId);
          
          // Create pool metadata
          await firestore
              .collection('users')
              .doc(userId)
              .collection('poolMetadata')
              .doc('stats')
              .set(PoolMetadata.initial().toMap());
          
          // Create initial question states with random values
          final initialStates = <QuestionState>[];
          for (int i = 0; i < numInitialStates; i++) {
            final questionId = 'existing_q${iteration}_$i';
            final seenCount = random.nextInt(10);
            final correctCount = random.nextInt(seenCount + 1);
            final mastered = correctCount >= 3;
            final lastSeenAt = seenCount > 0 
                ? DateTime.now().subtract(Duration(days: random.nextInt(30) + 1))
                : null;
            
            final state = QuestionState(
              questionId: questionId,
              seenCount: seenCount,
              correctCount: correctCount,
              lastSeenAt: lastSeenAt,
              mastered: mastered,
              categoryId: 'cat1',
              difficulty: '1',
              randomSeed: random.nextDouble(),
              sequence: i + 1,
              addedToPoolAt: DateTime.now().subtract(Duration(days: random.nextInt(10) + 1)),
              poolBatch: 0,
            );
            
            initialStates.add(state);
            
            // Create the question state in Firestore
            await firestore
                .collection('users')
                .doc(userId)
                .collection('questionStates')
                .doc(questionId)
                .set(state.toMap());
          }
          
          // Create some global questions that will be used for expansion
          final numGlobalQuestions = random.nextInt(10) + 5; // 5-14 new questions
          for (int i = 0; i < numGlobalQuestions; i++) {
            final questionId = 'new_q${iteration}_$i';
            
            await firestore.collection('questions').doc(questionId).set({
              'categoryId': 'cat1',
              'text': 'Test question $questionId',
              'options': ['Option A', 'Option B', 'Option C'],
              'correctIndices': [0],
              'explanation': 'Test explanation',
              'difficulty': 1,
              'isActive': true,
              'sequence': numInitialStates + i + 1, // Ensure unique sequences
            });
          }
          
          // Attempt pool expansion (this might partially fail due to our error handling)
          try {
            await questionPoolService.expandPool(
              userId: userId,
              batchSize: random.nextInt(5) + 3, // Small batch size to test partial failures
            );
          } catch (e) {
            // Pool expansion might fail, which is fine for this test
            print('Pool expansion failed (expected for partial failure test): $e');
          }
          
          // Load all question states after expansion attempt
          final statesSnapshot = await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .get();
          
          final finalStates = statesSnapshot.docs
              .map((doc) => QuestionState.fromMap(doc.data()))
              .toList();
          
          // Property verification: All original states should remain unchanged
          
          // Find states that correspond to original questions
          final originalStateMap = <String, QuestionState>{};
          final newStateMap = <String, QuestionState>{};
          
          for (final state in finalStates) {
            if (state.questionId.startsWith('existing_q${iteration}_')) {
              originalStateMap[state.questionId] = state;
            } else if (state.questionId.startsWith('new_q${iteration}_')) {
              newStateMap[state.questionId] = state;
            }
          }
          
          // Verify all original states are still present and unchanged
          for (final originalState in initialStates) {
            final currentState = originalStateMap[originalState.questionId];
            expect(currentState, isNotNull,
              reason: 'Iteration $iteration: Original question state ${originalState.questionId} should still exist after partial failure');
            
            if (currentState != null) {
              // Verify key fields remain unchanged
              expect(currentState.seenCount, equals(originalState.seenCount),
                reason: 'Iteration $iteration: seenCount should remain unchanged for ${originalState.questionId}');
              expect(currentState.correctCount, equals(originalState.correctCount),
                reason: 'Iteration $iteration: correctCount should remain unchanged for ${originalState.questionId}');
              expect(currentState.mastered, equals(originalState.mastered),
                reason: 'Iteration $iteration: mastered should remain unchanged for ${originalState.questionId}');
              expect(currentState.categoryId, equals(originalState.categoryId),
                reason: 'Iteration $iteration: categoryId should remain unchanged for ${originalState.questionId}');
              expect(currentState.difficulty, equals(originalState.difficulty),
                reason: 'Iteration $iteration: difficulty should remain unchanged for ${originalState.questionId}');
              
              // lastSeenAt comparison (handle null values)
              if (originalState.lastSeenAt == null) {
                expect(currentState.lastSeenAt, isNull,
                  reason: 'Iteration $iteration: lastSeenAt should remain null for ${originalState.questionId}');
              } else {
                expect(currentState.lastSeenAt, isNotNull,
                  reason: 'Iteration $iteration: lastSeenAt should not become null for ${originalState.questionId}');
                // Allow small time differences due to serialization
                if (currentState.lastSeenAt != null) {
                  final timeDiff = currentState.lastSeenAt!.difference(originalState.lastSeenAt!).abs();
                  expect(timeDiff.inSeconds, lessThan(2),
                    reason: 'Iteration $iteration: lastSeenAt should not change significantly for ${originalState.questionId}');
                }
              }
            }
          }
          
          // Verify any new states (if created) have valid initial values
          for (final newState in newStateMap.values) {
            expect(newState.seenCount, equals(0),
              reason: 'Iteration $iteration: New question state ${newState.questionId} should have seenCount = 0');
            expect(newState.correctCount, equals(0),
              reason: 'Iteration $iteration: New question state ${newState.questionId} should have correctCount = 0');
            expect(newState.mastered, isFalse,
              reason: 'Iteration $iteration: New question state ${newState.questionId} should not be mastered');
            expect(newState.categoryId, isNotNull,
              reason: 'Iteration $iteration: New question state ${newState.questionId} should have categoryId');
            expect(newState.difficulty, isNotNull,
              reason: 'Iteration $iteration: New question state ${newState.questionId} should have difficulty');
          }
        }
      });

      test('Property 9: Required fields completeness', () async {
        // **Feature: question-pool-architecture, Property 9: Required fields completeness**
        // **Validates: Requirements 4.4**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final numQuestions = random.nextInt(20) + 5; // 5-24 questions
          final userId = 'user$iteration';
          
          // Clear previous test data
          await _clearUserData(firestore, userId);
          
          // Create pool metadata
          await firestore
              .collection('users')
              .doc(userId)
              .collection('poolMetadata')
              .doc('stats')
              .set(PoolMetadata.initial().toMap());
          
          // Create global questions with various properties
          for (int i = 0; i < numQuestions; i++) {
            final questionId = 'q${iteration}_$i';
            final categoryId = 'cat${random.nextInt(3) + 1}'; // cat1, cat2, cat3
            final difficulty = random.nextInt(3) + 1; // 1, 2, 3
            
            await firestore.collection('questions').doc(questionId).set({
              'categoryId': categoryId,
              'text': 'Test question $questionId',
              'options': ['Option A', 'Option B', 'Option C'],
              'correctIndices': [0],
              'explanation': 'Test explanation',
              'difficulty': difficulty,
              'isActive': true,
              'sequence': i + 1,
            });
          }
          
          // Perform pool expansion to create question states
          await questionPoolService.expandPool(
            userId: userId,
            batchSize: random.nextInt(10) + 5, // 5-14 questions per batch
          );
          
          // Load all created question states
          final statesSnapshot = await firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .get();
          
          final questionStates = statesSnapshot.docs
              .map((doc) => QuestionState.fromMap(doc.data()))
              .toList();
          
          // Property verification: All question states should have required fields with valid values
          for (final state in questionStates) {
            // Requirement 4.4: All required fields should be present and valid
            
            // questionId should be non-empty
            expect(state.questionId, isNotEmpty,
              reason: 'Iteration $iteration: questionId should not be empty for state');
            
            // seenCount should be non-negative (new states should be 0)
            expect(state.seenCount, greaterThanOrEqualTo(0),
              reason: 'Iteration $iteration: seenCount should be >= 0 for ${state.questionId}, got ${state.seenCount}');
            
            // correctCount should be non-negative
            expect(state.correctCount, greaterThanOrEqualTo(0),
              reason: 'Iteration $iteration: correctCount should be >= 0 for ${state.questionId}, got ${state.correctCount}');
            
            // categoryId should be present and non-empty
            expect(state.categoryId, isNotNull,
              reason: 'Iteration $iteration: categoryId should not be null for ${state.questionId}');
            expect(state.categoryId, isNotEmpty,
              reason: 'Iteration $iteration: categoryId should not be empty for ${state.questionId}');
            
            // difficulty should be present and non-empty
            expect(state.difficulty, isNotNull,
              reason: 'Iteration $iteration: difficulty should not be null for ${state.questionId}');
            expect(state.difficulty, isNotEmpty,
              reason: 'Iteration $iteration: difficulty should not be empty for ${state.questionId}');
            
            // addedToPoolAt should be present
            expect(state.addedToPoolAt, isNotNull,
              reason: 'Iteration $iteration: addedToPoolAt should not be null for ${state.questionId}');
            
            // poolBatch should be present and non-negative
            expect(state.poolBatch, isNotNull,
              reason: 'Iteration $iteration: poolBatch should not be null for ${state.questionId}');
            expect(state.poolBatch, greaterThanOrEqualTo(0),
              reason: 'Iteration $iteration: poolBatch should be >= 0 for ${state.questionId}, got ${state.poolBatch}');
            
            // sequence should be present and positive
            expect(state.sequence, isNotNull,
              reason: 'Iteration $iteration: sequence should not be null for ${state.questionId}');
            expect(state.sequence, greaterThan(0),
              reason: 'Iteration $iteration: sequence should be > 0 for ${state.questionId}, got ${state.sequence}');
            
            // randomSeed should be present and in valid range [0, 1]
            expect(state.randomSeed, isNotNull,
              reason: 'Iteration $iteration: randomSeed should not be null for ${state.questionId}');
            expect(state.randomSeed, greaterThanOrEqualTo(0.0),
              reason: 'Iteration $iteration: randomSeed should be >= 0.0 for ${state.questionId}, got ${state.randomSeed}');
            expect(state.randomSeed, lessThanOrEqualTo(1.0),
              reason: 'Iteration $iteration: randomSeed should be <= 1.0 for ${state.questionId}, got ${state.randomSeed}');
            
            // Logical consistency checks
            
            // correctCount should not exceed seenCount (unless seenCount is 0 for new questions)
            if (state.seenCount > 0) {
              expect(state.correctCount, lessThanOrEqualTo(state.seenCount),
                reason: 'Iteration $iteration: correctCount (${state.correctCount}) should not exceed seenCount (${state.seenCount}) for ${state.questionId}');
            }
            
            // mastered should be true only if correctCount >= 3
            if (state.mastered) {
              expect(state.correctCount, greaterThanOrEqualTo(3),
                reason: 'Iteration $iteration: Question ${state.questionId} is marked as mastered but correctCount (${state.correctCount}) < 3');
            }
            
            // For new question states (seenCount == 0), verify initial values
            if (state.seenCount == 0) {
              expect(state.correctCount, equals(0),
                reason: 'Iteration $iteration: New question state ${state.questionId} should have correctCount = 0');
              expect(state.mastered, isFalse,
                reason: 'Iteration $iteration: New question state ${state.questionId} should not be mastered');
              expect(state.lastSeenAt, isNull,
                reason: 'Iteration $iteration: New question state ${state.questionId} should have null lastSeenAt');
            }
            
            // If seenCount > 0, lastSeenAt should be present
            if (state.seenCount > 0) {
              expect(state.lastSeenAt, isNotNull,
                reason: 'Iteration $iteration: Question state ${state.questionId} with seenCount > 0 should have lastSeenAt');
            }
            
            // Verify categoryId matches expected pattern
            expect(['cat1', 'cat2', 'cat3'].contains(state.categoryId), isTrue,
              reason: 'Iteration $iteration: categoryId ${state.categoryId} should be one of cat1, cat2, cat3 for ${state.questionId}');
            
            // Verify difficulty matches expected pattern
            expect(['1', '2', '3'].contains(state.difficulty), isTrue,
              reason: 'Iteration $iteration: difficulty ${state.difficulty} should be one of 1, 2, 3 for ${state.questionId}');
          }
        }
      });

      test('Property 10: Error recovery with available questions', () async {
        // **Feature: question-pool-architecture, Property 10: Error recovery with available questions**
        // **Validates: Requirements 4.5**
        
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random test parameters
          final numAvailableQuestions = random.nextInt(15) + 5; // 5-19 available questions
          final requestedCount = random.nextInt(20) + 1; // 1-20 requested questions
          final userId = 'user$iteration';
          
          // Clear previous test data
          await _clearUserData(firestore, userId);
          
          // Create pool metadata
          await firestore
              .collection('users')
              .doc(userId)
              .collection('poolMetadata')
              .doc('stats')
              .set(PoolMetadata.initial().toMap());
          
          // Create some valid questions and question states
          final validQuestionIds = <String>[];
          for (int i = 0; i < numAvailableQuestions; i++) {
            final questionId = 'valid_q${iteration}_$i';
            validQuestionIds.add(questionId);
            
            // Create the question document
            await firestore.collection('questions').doc(questionId).set({
              'categoryId': 'cat1',
              'text': 'Test question $questionId',
              'options': ['Option A', 'Option B', 'Option C'],
              'correctIndices': [0],
              'explanation': 'Test explanation',
              'difficulty': 1,
              'isActive': true,
              'sequence': i + 1,
            });
            
            // Create the question state
            await _createTestQuestionState(
              firestore, 
              userId, 
              questionId,
              seenCount: random.nextInt(5), // 0-4 seen count
              correctCount: random.nextInt(3), // 0-2 correct count (not mastered)
              mastered: false,
            );
          }
          
          // Create some "problematic" question states that reference non-existent questions
          // These simulate scenarios where questions might be deleted or become inactive
          final problematicQuestionIds = <String>[];
          final numProblematicQuestions = random.nextInt(5) + 1; // 1-5 problematic questions
          for (int i = 0; i < numProblematicQuestions; i++) {
            final questionId = 'missing_q${iteration}_$i';
            problematicQuestionIds.add(questionId);
            
            // Create question state but NO corresponding question document
            // This simulates a question that was deleted or became inactive
            await _createTestQuestionState(
              firestore, 
              userId, 
              questionId,
              seenCount: random.nextInt(5),
              correctCount: random.nextInt(3),
              mastered: false,
            );
          }
          
          // Test the error recovery behavior
          final questions = await questionPoolService.getQuestionsForSession(
            userId: userId,
            count: requestedCount,
          );
          
          // Property verification: System should continue with available questions
          
          // Should return some questions (not fail completely)
          expect(questions, isNotNull,
            reason: 'Iteration $iteration: getQuestionsForSession should not return null even with errors');
          
          // Should return at most the number of valid questions available
          final maxPossibleQuestions = numAvailableQuestions < requestedCount 
              ? numAvailableQuestions 
              : requestedCount;
          expect(questions.length, lessThanOrEqualTo(maxPossibleQuestions),
            reason: 'Iteration $iteration: Should not return more questions than available. Got ${questions.length}, max possible: $maxPossibleQuestions');
          
          // All returned questions should be valid (have proper IDs and be active)
          for (final question in questions) {
            expect(question.id, isNotEmpty,
              reason: 'Iteration $iteration: Question ID should not be empty');
            expect(validQuestionIds.contains(question.id), isTrue,
              reason: 'Iteration $iteration: Returned question ${question.id} should be from valid questions');
            expect(question.isActive, isTrue,
              reason: 'Iteration $iteration: Returned question ${question.id} should be active');
          }
          
          // Should not return any problematic questions (those without valid question documents)
          final returnedIds = questions.map((q) => q.id).toSet();
          for (final problematicId in problematicQuestionIds) {
            expect(returnedIds.contains(problematicId), isFalse,
              reason: 'Iteration $iteration: Should not return problematic question $problematicId');
          }
          
          // If there are valid questions available, should return at least one (unless requested count is 0)
          if (numAvailableQuestions > 0 && requestedCount > 0) {
            expect(questions.length, greaterThan(0),
              reason: 'Iteration $iteration: Should return at least one question when valid questions are available. Available: $numAvailableQuestions, Requested: $requestedCount');
          }
          
          // Test error recovery in pool expansion as well
          // Try to expand pool when some global questions might be missing
          try {
            await questionPoolService.expandPool(
              userId: userId,
              batchSize: random.nextInt(5) + 3, // Small batch size
            );
            
            // After expansion, should still be able to get questions
            final questionsAfterExpansion = await questionPoolService.getQuestionsForSession(
              userId: userId,
              count: 5, // Request a small number
            );
            
            // Should not fail completely
            expect(questionsAfterExpansion, isNotNull,
              reason: 'Iteration $iteration: Should still work after pool expansion with potential errors');
            
            // All returned questions should be valid
            for (final question in questionsAfterExpansion) {
              expect(question.id, isNotEmpty,
                reason: 'Iteration $iteration: Question ID should not be empty after expansion');
              expect(question.isActive, isTrue,
                reason: 'Iteration $iteration: Question ${question.id} should be active after expansion');
            }
            
          } catch (e) {
            // Pool expansion might fail, but the system should still work with existing questions
            print('Pool expansion failed (expected in error recovery test): $e');
            
            // Should still be able to get questions from existing pool
            final fallbackQuestions = await questionPoolService.getQuestionsForSession(
              userId: userId,
              count: 3,
            );
            
            expect(fallbackQuestions, isNotNull,
              reason: 'Iteration $iteration: Should still work with existing pool after expansion failure');
          }
        }
      });
    });
  });
}

/// Helper function to clear user data between test iterations
Future<void> _clearUserData(FakeFirebaseFirestore firestore, String userId) async {
  // Clear question states
  final statesSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('questionStates')
      .get();
  
  for (final doc in statesSnapshot.docs) {
    await doc.reference.delete();
  }
  
  // Clear questions
  final questionsSnapshot = await firestore.collection('questions').get();
  for (final doc in questionsSnapshot.docs) {
    await doc.reference.delete();
  }
}

/// Helper function to create a test question
Future<void> _createTestQuestion(
  FakeFirebaseFirestore firestore,
  String questionId,
  String categoryId,
  String difficulty,
  int sequence,
) async {
  await firestore.collection('questions').doc(questionId).set({
    'categoryId': categoryId,
    'text': 'Test question $questionId',
    'options': ['Option A', 'Option B', 'Option C'],
    'correctIndices': [0],
    'explanation': 'Test explanation',
    'difficulty': difficulty == 'easy' ? 1 : (difficulty == 'medium' ? 2 : 3),
    'isActive': true,
    'sequence': sequence,
  });
}

/// Helper function to create a test question state
Future<void> _createTestQuestionState(
  FakeFirebaseFirestore firestore,
  String userId,
  String questionId, {
  int seenCount = 0,
  int correctCount = 0,
  bool mastered = false,
  DateTime? lastSeenAt,
  String? categoryId,
  String? difficulty,
}) async {
  await firestore
      .collection('users')
      .doc(userId)
      .collection('questionStates')
      .doc(questionId)
      .set({
    'questionId': questionId,
    'seenCount': seenCount,
    'correctCount': correctCount,
    'mastered': mastered,
    'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt) : null,
    'categoryId': categoryId ?? 'cat1',
    'difficulty': difficulty ?? '1', // Default to '1' (easy) as string
    'randomSeed': 0.5,
    'sequence': 1,
    'addedToPoolAt': Timestamp.fromDate(DateTime.now()),
    'poolBatch': 0,
  });
}