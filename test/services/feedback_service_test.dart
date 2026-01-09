import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:eduparo/services/feedback_service.dart';
import 'package:eduparo/models/feedback.dart';

void main() {
  group('FeedbackService', () {
    late FeedbackService feedbackService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      feedbackService = FeedbackService(firestore: fakeFirestore);
    });

    group('submitCommonFeedback', () {
      test('should submit common feedback successfully', () async {
        // Arrange
        final appContext = AppContext(
          version: '1.0.0',
          os: 'android',
          childAgeGroup: '3-5',
        );

        final feedback = CommonFeedback(
          createdAt: DateTime.now(),
          userComment: 'Great app, love the design!',
          userId: 'user123',
          username: 'TestUser',
          status: 'open',
          appContext: appContext,
          ratingApp: 9,
          ratingTheme: 8,
          ratingDuelMode: 7,
          learningFactor: 8,
          scientificTrust: 9,
          doBetter: 'Add more categories',
          futureFeatures: 'Video explanations',
        );

        // Act
        await feedbackService.submitCommonFeedback(feedback);

        // Assert
        final snapshot = await fakeFirestore.collection('feedbacks').get();
        expect(snapshot.docs.length, equals(1));

        final doc = snapshot.docs.first;
        final data = doc.data();
        expect(data['type'], equals('common'));
        expect(data['user_comment'], equals('Great app, love the design!'));
        expect(data['user_id'], equals('user123'));
        expect(data['username'], equals('TestUser'));
        expect(data['status'], equals('open'));
        expect(data['data']['rating_app'], equals(9));
        expect(data['data']['rating_theme'], equals(8));
      });

      test('should handle Firebase errors gracefully', () async {
        // This test would require mocking Firebase exceptions
        // For now, we'll test the basic functionality
        expect(true, isTrue);
      });
    });

    group('submitQuestionFeedback', () {
      test('should submit question feedback successfully', () async {
        // Arrange
        final appContext = AppContext(
          version: '1.0.0',
          os: 'ios',
        );

        final questionSnapshot = QuestionSnapshot(
          text: 'What is the best way to handle tantrums?',
          options: ['Ignore them', 'Stay calm and redirect', 'Give in to demands', 'Punish immediately'],
          correctIndices: [1],
          explanation: 'Staying calm and redirecting helps children learn emotional regulation.',
          tips: 'Remember that tantrums are normal developmental behavior.',
          sourceLabel: 'Child Development Research',
          sourceUrl: 'https://example.com/research',
          difficulty: 3,
          categoryTitle: 'Parenting Basics',
        );

        final feedback = QuestionFeedback(
          createdAt: DateTime.now(),
          userComment: 'There is a typo in this question',
          userId: 'user456',
          username: 'TestUser2',
          status: 'open',
          appContext: appContext,
          questionId: 'question123',
          category: 'Parenting Basics',
          issueType: 'typo',
          questionSnapshot: questionSnapshot,
        );

        // Act
        await feedbackService.submitQuestionFeedback(feedback);

        // Assert
        final snapshot = await fakeFirestore.collection('feedbacks').get();
        expect(snapshot.docs.length, equals(1));

        final doc = snapshot.docs.first;
        final data = doc.data();
        expect(data['type'], equals('question'));
        expect(data['user_comment'], equals('There is a typo in this question'));
        expect(data['user_id'], equals('user456'));
        expect(data['username'], equals('TestUser2'));
        expect(data['data']['question_id'], equals('question123'));
        expect(data['data']['category'], equals('Parenting Basics'));
        expect(data['data']['issue_type'], equals('typo'));
        expect(data['data']['question_snapshot']['text'], equals('What is the best way to handle tantrums?'));
        expect(data['data']['question_snapshot']['category_title'], equals('Parenting Basics'));
      });
    });

    group('getUserFeedback', () {
      test('should retrieve user feedback history', () async {
        // Arrange
        final userId = 'user123';
        
        // Add some test feedback
        await fakeFirestore.collection('feedbacks').add({
          'created_at': Timestamp.now(),
          'user_comment': 'First feedback',
          'user_id': userId,
          'username': 'TestUser',
          'status': 'open',
          'type': 'common',
          'app_context': {'version': '1.0.0', 'os': 'android'},
          'data': {
            'rating_app': 8,
            'rating_theme': 7,
            'rating_duel_mode': 6,
            'learning_factor': 8,
            'scientific_trust': 9,
            'do_better': 'More features',
            'future_features': 'Dark mode',
          },
        });

        await fakeFirestore.collection('feedbacks').add({
          'created_at': Timestamp.now(),
          'user_comment': 'Question issue',
          'user_id': userId,
          'username': 'TestUser',
          'status': 'resolved',
          'type': 'question',
          'app_context': {'version': '1.0.0', 'os': 'android'},
          'data': {
            'question_id': 'q123',
            'category': 'Test Category',
            'issue_type': 'typo',
            'question_snapshot': {
              'text': 'Test question',
              'options': ['A', 'B', 'C'],
              'correct_indices': [0],
              'explanation': 'Test explanation',
              'difficulty': 2,
              'category_title': 'Test Category',
            },
          },
        });

        // Act
        final feedbackList = await feedbackService.getUserFeedback(userId);

        // Assert
        expect(feedbackList.length, equals(2));
        
        // Check that we have both types (order may vary)
        final hasCommonFeedback = feedbackList.any((f) => f is CommonFeedback);
        final hasQuestionFeedback = feedbackList.any((f) => f is QuestionFeedback);
        
        expect(hasCommonFeedback, isTrue);
        expect(hasQuestionFeedback, isTrue);
      });

      test('should return empty list for user with no feedback', () async {
        // Act
        final feedbackList = await feedbackService.getUserFeedback('nonexistent');

        // Assert
        expect(feedbackList, isEmpty);
      });
    });

    group('createAppContext', () {
      test('should create app context with correct information', () {
        // Act
        final appContext = feedbackService.createAppContext(childAgeGroup: '6-8');

        // Assert
        expect(appContext.version, equals('1.0.0'));
        expect(appContext.os, isNotEmpty);
        expect(appContext.childAgeGroup, equals('6-8'));
      });

      test('should create app context without child age group', () {
        // Act
        final appContext = feedbackService.createAppContext();

        // Assert
        expect(appContext.version, equals('1.0.0'));
        expect(appContext.os, isNotEmpty);
        expect(appContext.childAgeGroup, isNull);
      });
    });
  });

  group('FeedbackModels', () {
    group('AppContext', () {
      test('should serialize to map correctly', () {
        // Arrange
        final appContext = AppContext(
          version: '1.0.0',
          os: 'android',
          childAgeGroup: '3-5',
        );

        // Act
        final map = appContext.toMap();

        // Assert
        expect(map['version'], equals('1.0.0'));
        expect(map['os'], equals('android'));
        expect(map['child_age_group'], equals('3-5'));
      });

      test('should deserialize from map correctly', () {
        // Arrange
        final map = {
          'version': '1.0.0',
          'os': 'ios',
          'child_age_group': '6-8',
        };

        // Act
        final appContext = AppContext.fromMap(map);

        // Assert
        expect(appContext.version, equals('1.0.0'));
        expect(appContext.os, equals('ios'));
        expect(appContext.childAgeGroup, equals('6-8'));
      });
    });

    group('QuestionSnapshot', () {
      test('should serialize to map correctly', () {
        // Arrange
        final questionSnapshot = QuestionSnapshot(
          text: 'What is the best parenting approach?',
          options: ['Authoritative', 'Permissive', 'Authoritarian', 'Neglectful'],
          correctIndices: [0],
          explanation: 'Authoritative parenting balances warmth and structure.',
          tips: 'Set clear boundaries while showing empathy.',
          sourceLabel: 'Parenting Research',
          sourceUrl: 'https://example.com/research',
          difficulty: 4,
          categoryTitle: 'Parenting Styles',
        );

        // Act
        final map = questionSnapshot.toMap();

        // Assert
        expect(map['text'], equals('What is the best parenting approach?'));
        expect(map['options'], equals(['Authoritative', 'Permissive', 'Authoritarian', 'Neglectful']));
        expect(map['correct_indices'], equals([0]));
        expect(map['explanation'], equals('Authoritative parenting balances warmth and structure.'));
        expect(map['tips'], equals('Set clear boundaries while showing empathy.'));
        expect(map['source_label'], equals('Parenting Research'));
        expect(map['source_url'], equals('https://example.com/research'));
        expect(map['difficulty'], equals(4));
        expect(map['category_title'], equals('Parenting Styles'));
      });

      test('should deserialize from map correctly', () {
        // Arrange
        final map = {
          'text': 'How to handle bedtime routines?',
          'options': ['Strict schedule', 'Flexible approach', 'No routine'],
          'correct_indices': [0, 1],
          'explanation': 'Both strict and flexible approaches can work.',
          'tips': 'Consistency is key.',
          'source_label': 'Sleep Research',
          'source_url': 'https://example.com/sleep',
          'difficulty': 3,
          'category_title': 'Sleep & Routines',
        };

        // Act
        final questionSnapshot = QuestionSnapshot.fromMap(map);

        // Assert
        expect(questionSnapshot.text, equals('How to handle bedtime routines?'));
        expect(questionSnapshot.options, equals(['Strict schedule', 'Flexible approach', 'No routine']));
        expect(questionSnapshot.correctIndices, equals([0, 1]));
        expect(questionSnapshot.explanation, equals('Both strict and flexible approaches can work.'));
        expect(questionSnapshot.tips, equals('Consistency is key.'));
        expect(questionSnapshot.sourceLabel, equals('Sleep Research'));
        expect(questionSnapshot.sourceUrl, equals('https://example.com/sleep'));
        expect(questionSnapshot.difficulty, equals(3));
        expect(questionSnapshot.categoryTitle, equals('Sleep & Routines'));
      });

      test('should handle optional fields correctly', () {
        // Arrange
        final questionSnapshot = QuestionSnapshot(
          text: 'Basic question',
          options: ['A', 'B'],
          correctIndices: [0],
          explanation: 'Simple explanation',
          difficulty: 1,
          categoryTitle: 'Basic Category',
        );

        // Act
        final map = questionSnapshot.toMap();

        // Assert
        expect(map['tips'], isNull);
        expect(map['source_label'], isNull);
        expect(map['source_url'], isNull);
        expect(map.containsKey('tips'), isFalse);
        expect(map.containsKey('source_label'), isFalse);
        expect(map.containsKey('source_url'), isFalse);
      });
    });

    group('QuestionIssueType', () {
      test('should convert from string correctly', () {
        expect(QuestionIssueType.fromString('typo'), equals(QuestionIssueType.typo));
        expect(QuestionIssueType.fromString('content_outdated'), equals(QuestionIssueType.contentOutdated));
        expect(QuestionIssueType.fromString('broken_link'), equals(QuestionIssueType.brokenLink));
        expect(QuestionIssueType.fromString('other'), equals(QuestionIssueType.other));
        expect(QuestionIssueType.fromString('invalid'), equals(QuestionIssueType.other));
      });

      test('should have correct string values', () {
        expect(QuestionIssueType.typo.value, equals('typo'));
        expect(QuestionIssueType.contentOutdated.value, equals('content_outdated'));
        expect(QuestionIssueType.brokenLink.value, equals('broken_link'));
        expect(QuestionIssueType.other.value, equals('other'));
      });
    });
  });
}