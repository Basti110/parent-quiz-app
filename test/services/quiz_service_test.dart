import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/quiz_service.dart';
import 'package:eduparo/services/question_pool_service.dart';
import 'package:eduparo/models/category.dart';
import 'dart:math';

void main() {
  group('QuizService - Pool Architecture Integration', () {
    late FakeFirebaseFirestore firestore;
    late QuestionPoolService poolService;
    late QuizService quizService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      poolService = QuestionPoolService(firestore: firestore);
      quizService = QuizService(
        firestore: firestore,
        questionPoolService: poolService,
        usePoolArchitecture: true,
      );
    });

    test('getQuestionsForSession uses pool architecture when enabled', () async {
      const userId = 'test_user';
      const categoryId = 'test_category';

      // Create questions with sequence field for pool architecture
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Pool Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1, // int, not string
        'isActive': true,
        'sequence': 1,
      });
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Pool Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1, // int, not string
        'isActive': true,
        'sequence': 2,
      });

      // Create pool metadata to indicate user is migrated
      await firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .set({
        'totalPoolSize': 0,
        'unseenCount': 0,
        'maxSequenceInPool': 0,
        'lastExpansionAt': DateTime.now(),
      });

      // Act: Get questions using pool architecture
      final questions = await quizService.getQuestionsForSession(categoryId, 2, userId);

      // Assert: Should return questions (pool will auto-expand)
      expect(questions.length, greaterThan(0));
    });

    test('getQuestionsFromAllCategories uses pool architecture when enabled', () async {
      const userId = 'test_user';

      // Create questions from multiple categories with sequence field
      await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Pool Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1, // int, not string
        'isActive': true,
        'sequence': 1,
      });
      await firestore.collection('questions').add({
        'categoryId': 'category2',
        'text': 'Pool Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1, // int, not string
        'isActive': true,
        'sequence': 2,
      });

      // Create pool metadata to indicate user is migrated
      await firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .set({
        'totalPoolSize': 0,
        'unseenCount': 0,
        'maxSequenceInPool': 0,
        'lastExpansionAt': DateTime.now(),
      });

      // Act: Get questions from all categories using pool architecture
      final questions = await quizService.getQuestionsFromAllCategories(2, userId);

      // Assert: Should return questions (pool will auto-expand)
      expect(questions.length, greaterThan(0));
    });

    test('recordAnswer uses pool architecture when enabled', () async {
      const userId = 'test_user';
      const questionId = 'test_question';

      // Create a question
      await firestore.collection('questions').doc(questionId).set({
        'categoryId': 'test_category',
        'text': 'Test Question',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1, // int, not string
        'isActive': true,
        'sequence': 1,
      });

      // Create pool metadata to indicate user is migrated
      await firestore
          .collection('users')
          .doc(userId)
          .collection('poolMetadata')
          .doc('stats')
          .set({
        'totalPoolSize': 1,
        'unseenCount': 1,
        'maxSequenceInPool': 1,
        'lastExpansionAt': DateTime.now(),
      });

      // Create question state in pool
      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(questionId)
          .set({
        'questionId': questionId,
        'seenCount': 0,
        'correctCount': 0,
        'lastSeenAt': null,
        'mastered': false,
        'categoryId': 'test_category',
        'difficulty': '1', // string in question state
        'randomSeed': 0.5,
        'sequence': 1,
        'addedToPoolAt': DateTime.now(),
        'poolBatch': 0,
      });

      // Act: Record an answer using pool architecture
      await quizService.recordAnswer(
        userId: userId,
        questionId: questionId,
        isCorrect: true,
      );

      // Assert: Question state should be updated
      final stateDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(questionId)
          .get();

      expect(stateDoc.exists, isTrue);
      final stateData = stateDoc.data()!;
      expect(stateData['seenCount'], equals(1));
      expect(stateData['correctCount'], equals(1));
      expect(stateData['mastered'], equals(false)); // Not mastered yet (need 3 correct)
    });

    test('falls back to legacy algorithm when pool architecture fails', () async {
      // Create a QuizService with pool architecture enabled but no pool service
      final legacyQuizService = QuizService(
        firestore: firestore,
        questionPoolService: null, // No pool service
        usePoolArchitecture: true,
      );

      const userId = 'test_user';
      const categoryId = 'test_category';

      // Create questions without sequence field (legacy format)
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Legacy Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Act: Should fall back to legacy algorithm
      final questions = await legacyQuizService.getQuestionsForSession(categoryId, 1, userId);

      // Assert: Should return questions using legacy algorithm
      expect(questions.length, equals(1));
      expect(questions.first.text, equals('Legacy Question 1'));
    });

    test('can be disabled via feature flag', () async {
      // Create a QuizService with pool architecture disabled
      final legacyQuizService = QuizService(
        firestore: firestore,
        questionPoolService: poolService,
        usePoolArchitecture: false, // Disabled
      );

      const userId = 'test_user';
      const categoryId = 'test_category';

      // Create questions
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Legacy Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Act: Should use legacy algorithm even with pool service available
      final questions = await legacyQuizService.getQuestionsForSession(categoryId, 1, userId);

      // Assert: Should return questions using legacy algorithm
      expect(questions.length, equals(1));
      expect(questions.first.text, equals('Legacy Question 1'));
    });
  });

  group('QuizService - Category Question Counter', () {
    late FakeFirebaseFirestore firestore;
    late QuizService quizService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      quizService = QuizService(firestore: firestore);
    });

    test('getQuestionCountForCategory returns questionCounter when field exists', () async {
      // Arrange: Create a category with questionCounter field
      const categoryId = 'test_category';
      await firestore.collection('categories').doc(categoryId).set({
        'title': 'Test Category',
        'description': 'Test Description',
        'order': 1,
        'iconName': 'health',
        'isPremium': false,
        'questionCounter': 25,
      });

      // Act: Get question count
      final count = await quizService.getQuestionCountForCategory(categoryId);

      // Assert: Should return the questionCounter value
      expect(count, equals(25));
    });

    test('getQuestionCountForCategory falls back to query when field is missing', () async {
      // Arrange: Create a category without questionCounter field
      const categoryId = 'test_category';
      await firestore.collection('categories').doc(categoryId).set({
        'title': 'Test Category',
        'description': 'Test Description',
        'order': 1,
        'iconName': 'health',
        'isPremium': false,
        // No questionCounter field
      });

      // Add some active questions
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      await firestore.collection('questions').add({
        'categoryId': categoryId,
        'text': 'Question 3',
        'options': ['A', 'B', 'C'],
        'correctIndices': [2],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': false, // Inactive question should not be counted
      });

      // Act: Get question count
      final count = await quizService.getQuestionCountForCategory(categoryId);

      // Assert: Should count only active questions
      expect(count, equals(2));
    });

    test('getQuestionCountForCategory returns 0 for non-existent category', () async {
      // Act: Get question count for non-existent category
      final count = await quizService.getQuestionCountForCategory('non_existent');

      // Assert: Should return 0
      expect(count, equals(0));
    });

    test('Category.fromMap reads questionCounter field', () {
      // Arrange: Create a map with questionCounter
      final map = {
        'title': 'Test Category',
        'description': 'Test Description',
        'order': 1,
        'iconName': 'health',
        'isPremium': false,
        'questionCounter': 30,
      };

      // Act: Create category from map
      final category = Category.fromMap(map, 'test_id');

      // Assert: Should have the questionCounter value
      expect(category.questionCounter, equals(30));
    });

    test('Category.fromMap defaults questionCounter to 0 when missing', () {
      // Arrange: Create a map without questionCounter
      final map = {
        'title': 'Test Category',
        'description': 'Test Description',
        'order': 1,
        'iconName': 'health',
        'isPremium': false,
      };

      // Act: Create category from map
      final category = Category.fromMap(map, 'test_id');

      // Assert: Should default to 0
      expect(category.questionCounter, equals(0));
    });

    test('Category.toMap includes questionCounter field', () {
      // Arrange: Create a category
      final category = Category(
        id: 'test_id',
        title: 'Test Category',
        description: 'Test Description',
        order: 1,
        iconName: 'health',
        isPremium: false,
        questionCounter: 42,
      );

      // Act: Convert to map
      final map = category.toMap();

      // Assert: Should include questionCounter
      expect(map['questionCounter'], equals(42));
    });
  });

  group('QuizService - Cross-Category Question Selection', () {
    late FakeFirebaseFirestore firestore;
    late QuizService quizService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      quizService = QuizService(firestore: firestore, random: Random(42)); // Fixed seed for predictable tests
    });

    test('getQuestionsFromAllCategories prioritizes unseen questions', () async {
      const userId = 'test_user';

      // Create questions from multiple categories
      await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Unseen Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      await firestore.collection('questions').add({
        'categoryId': 'category2',
        'text': 'Unseen Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Create a seen but unmastered question
      final seenQuestionRef = await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Seen Question',
        'options': ['A', 'B', 'C'],
        'correctIndices': [2],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Add question state for the seen question
      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(seenQuestionRef.id)
          .set({
        'questionId': seenQuestionRef.id,
        'seenCount': 2,
        'correctCount': 1,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 1)),
        'mastered': false,
      });

      // Act: Get questions from all categories
      final questions = await quizService.getQuestionsFromAllCategories(2, userId);

      // Assert: Should return unseen questions first
      expect(questions.length, equals(2));
      expect(questions.any((q) => q.text == 'Unseen Question 1'), isTrue);
      expect(questions.any((q) => q.text == 'Unseen Question 2'), isTrue);
      expect(questions.any((q) => q.text == 'Seen Question'), isFalse);
    });

    test('getQuestionsFromAllCategories falls back to unmastered when no unseen', () async {
      const userId = 'test_user';

      // Create questions and mark them all as seen but unmastered
      final question1Ref = await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Unmastered Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      final question2Ref = await firestore.collection('questions').add({
        'categoryId': 'category2',
        'text': 'Unmastered Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Create a mastered question
      final masteredQuestionRef = await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Mastered Question',
        'options': ['A', 'B', 'C'],
        'correctIndices': [2],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Add question states
      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(question1Ref.id)
          .set({
        'questionId': question1Ref.id,
        'seenCount': 2,
        'correctCount': 1,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 2)),
        'mastered': false,
      });

      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(question2Ref.id)
          .set({
        'questionId': question2Ref.id,
        'seenCount': 1,
        'correctCount': 0,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 1)),
        'mastered': false,
      });

      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(masteredQuestionRef.id)
          .set({
        'questionId': masteredQuestionRef.id,
        'seenCount': 5,
        'correctCount': 3,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 3)),
        'mastered': true,
      });

      // Act: Get questions from all categories
      final questions = await quizService.getQuestionsFromAllCategories(2, userId);

      // Assert: Should return unmastered questions
      expect(questions.length, equals(2));
      expect(questions.any((q) => q.text == 'Unmastered Question 1'), isTrue);
      expect(questions.any((q) => q.text == 'Unmastered Question 2'), isTrue);
      expect(questions.any((q) => q.text == 'Mastered Question'), isFalse);
    });

    test('getQuestionsFromAllCategories returns all questions when everything is mastered', () async {
      const userId = 'test_user';

      // Create questions and mark them all as mastered
      final question1Ref = await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Mastered Question 1',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      final question2Ref = await firestore.collection('questions').add({
        'categoryId': 'category2',
        'text': 'Mastered Question 2',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });

      // Add question states - all mastered
      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(question1Ref.id)
          .set({
        'questionId': question1Ref.id,
        'seenCount': 5,
        'correctCount': 3,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 2)),
        'mastered': true,
      });

      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(question2Ref.id)
          .set({
        'questionId': question2Ref.id,
        'seenCount': 4,
        'correctCount': 3,
        'lastSeenAt': DateTime.now().subtract(const Duration(days: 1)),
        'mastered': true,
      });

      // Act: Get questions from all categories
      final questions = await quizService.getQuestionsFromAllCategories(2, userId);

      // Assert: Should return all questions (random selection from mastered)
      expect(questions.length, equals(2));
      expect(questions.any((q) => q.text == 'Mastered Question 1'), isTrue);
      expect(questions.any((q) => q.text == 'Mastered Question 2'), isTrue);
    });

    test('getQuestionsFromAllCategories returns empty list when no questions exist', () async {
      const userId = 'test_user';

      // Act: Get questions when no questions exist
      final questions = await quizService.getQuestionsFromAllCategories(5, userId);

      // Assert: Should return empty list
      expect(questions, isEmpty);
    });

    test('getQuestionsFromAllCategories only includes active questions', () async {
      const userId = 'test_user';

      // Create active and inactive questions
      await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Active Question',
        'options': ['A', 'B', 'C'],
        'correctIndices': [0],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': true,
      });
      await firestore.collection('questions').add({
        'categoryId': 'category1',
        'text': 'Inactive Question',
        'options': ['A', 'B', 'C'],
        'correctIndices': [1],
        'explanation': 'Explanation',
        'difficulty': 1,
        'isActive': false,
      });

      // Act: Get questions from all categories
      final questions = await quizService.getQuestionsFromAllCategories(5, userId);

      // Assert: Should only include active questions
      expect(questions.length, equals(1));
      expect(questions.first.text, equals('Active Question'));
    });
  });
}
