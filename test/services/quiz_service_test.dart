import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eduparo/services/quiz_service.dart';
import 'package:eduparo/models/category.dart';
import 'dart:math';

void main() {
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
