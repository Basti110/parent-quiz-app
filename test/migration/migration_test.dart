import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the migration from XP-based to streak-based gamification
/// 
/// This test file:
/// - Creates test users with old schema
/// - Runs migration logic
/// - Verifies all fields are correct
/// - Verifies no data loss

void main() {
  group('Simplified Gamification Migration Tests', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('should preserve existing streak data', () async {
      // Arrange: Create user with old schema
      final userId = 'test_user_1';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'friendCode': 'ABC123',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 5,
        'streakLongest': 10,
        'totalXp': 500,
        'currentLevel': 6,
        'weeklyXpCurrent': 150,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 8,
        'duelsWon': 5,
        'duelsLost': 3,
        'duelPoints': 15,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify streak data preserved
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['streakCurrent'], equals(5));
      expect(data['streakLongest'], equals(10));
    });

    test('should remove XP-related fields', () async {
      // Arrange: Create user with old schema
      final userId = 'test_user_2';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 2',
        'email': 'test2@example.com',
        'friendCode': 'XYZ789',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 0,
        'streakLongest': 0,
        'totalXp': 1000,
        'currentLevel': 11,
        'weeklyXpCurrent': 250,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 0,
        'duelsWon': 0,
        'duelsLost': 0,
        'duelPoints': 0,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify XP fields removed
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data.containsKey('totalXp'), isFalse);
      expect(data.containsKey('currentLevel'), isFalse);
      expect(data.containsKey('weeklyXpCurrent'), isFalse);
      expect(data.containsKey('weeklyXpWeekStart'), isFalse);
      expect(data.containsKey('duelPoints'), isFalse);
      expect(data.containsKey('duelsLost'), isFalse);
      expect(data.containsKey('duelsPlayed'), isFalse);
    });

    test('should initialize new fields with defaults', () async {
      // Arrange: Create user with old schema
      final userId = 'test_user_3';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 3',
        'email': 'test3@example.com',
        'friendCode': 'DEF456',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 3,
        'streakLongest': 7,
        'totalXp': 750,
        'currentLevel': 8,
        'weeklyXpCurrent': 200,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 12,
        'duelsWon': 7,
        'duelsLost': 5,
        'duelPoints': 21,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify new fields initialized
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['streakPoints'], equals(0));
      expect(data['dailyGoal'], equals(10));
      expect(data['questionsAnsweredToday'], equals(0));
      expect(data['lastDailyReset'], isA<Timestamp>());
      expect(data['totalQuestionsAnswered'], equals(0));
      expect(data['totalCorrectAnswers'], equals(0));
      expect(data['totalMasteredQuestions'], equals(0));
    });

    test('should update duel statistics correctly', () async {
      // Arrange: Create user with old schema
      final userId = 'test_user_4';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 4',
        'email': 'test4@example.com',
        'friendCode': 'GHI789',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 1,
        'streakLongest': 5,
        'totalXp': 300,
        'currentLevel': 4,
        'weeklyXpCurrent': 100,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 20,
        'duelsWon': 12,
        'duelsLost': 8,
        'duelPoints': 36,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify duel statistics updated
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['duelsCompleted'], equals(20));
      expect(data['duelsWon'], equals(12));
      expect(data.containsKey('duelsLost'), isFalse);
      expect(data.containsKey('duelPoints'), isFalse);
    });

    test('should preserve question states subcollection', () async {
      // Arrange: Create user with question states
      final userId = 'test_user_5';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 5',
        'email': 'test5@example.com',
        'friendCode': 'JKL012',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 2,
        'streakLongest': 4,
        'totalXp': 400,
        'currentLevel': 5,
        'weeklyXpCurrent': 120,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 5,
        'duelsWon': 3,
        'duelsLost': 2,
        'duelPoints': 9,
      });

      // Add question states
      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc('question_1')
          .set({
        'questionId': 'question_1',
        'seenCount': 5,
        'correctCount': 4,
        'lastSeenAt': Timestamp.now(),
        'mastered': true,
      });

      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc('question_2')
          .set({
        'questionId': 'question_2',
        'seenCount': 3,
        'correctCount': 1,
        'lastSeenAt': Timestamp.now(),
        'mastered': false,
      });

      await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc('question_3')
          .set({
        'questionId': 'question_3',
        'seenCount': 4,
        'correctCount': 3,
        'lastSeenAt': Timestamp.now(),
        'mastered': true,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify question states preserved
      final questionStates = await firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      expect(questionStates.docs.length, equals(3));

      final q1 = questionStates.docs
          .firstWhere((doc) => doc.id == 'question_1')
          .data();
      expect(q1['seenCount'], equals(5));
      expect(q1['correctCount'], equals(4));
      expect(q1['mastered'], isTrue);

      final q2 = questionStates.docs
          .firstWhere((doc) => doc.id == 'question_2')
          .data();
      expect(q2['seenCount'], equals(3));
      expect(q2['correctCount'], equals(1));
      expect(q2['mastered'], isFalse);

      final q3 = questionStates.docs
          .firstWhere((doc) => doc.id == 'question_3')
          .data();
      expect(q3['seenCount'], equals(4));
      expect(q3['correctCount'], equals(3));
      expect(q3['mastered'], isTrue);
    });

    test('should calculate totalMasteredQuestions from questionStates', () async {
      // Arrange: Create user with question states
      final userId = 'test_user_6';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 6',
        'email': 'test6@example.com',
        'friendCode': 'MNO345',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 0,
        'streakLongest': 0,
        'totalXp': 100,
        'currentLevel': 2,
        'weeklyXpCurrent': 50,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 0,
        'duelsWon': 0,
        'duelsLost': 0,
        'duelPoints': 0,
      });

      // Add 3 mastered questions and 2 non-mastered
      for (int i = 1; i <= 3; i++) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('questionStates')
            .doc('question_$i')
            .set({
          'questionId': 'question_$i',
          'seenCount': 5,
          'correctCount': 4,
          'lastSeenAt': Timestamp.now(),
          'mastered': true,
        });
      }

      for (int i = 4; i <= 5; i++) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('questionStates')
            .doc('question_$i')
            .set({
          'questionId': 'question_$i',
          'seenCount': 2,
          'correctCount': 1,
          'lastSeenAt': Timestamp.now(),
          'mastered': false,
        });
      }

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify totalMasteredQuestions calculated correctly
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['totalMasteredQuestions'], equals(3));
    });

    test('should handle users with missing optional fields', () async {
      // Arrange: Create user with minimal old schema
      final userId = 'test_user_7';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 7',
        'email': 'test7@example.com',
        'friendCode': 'PQR678',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        // Missing streak fields
        'totalXp': 50,
        'currentLevel': 1,
        // Missing duel fields
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify defaults applied for missing fields
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['streakCurrent'], equals(0));
      expect(data['streakLongest'], equals(0));
      expect(data['streakPoints'], equals(0));
      expect(data['duelsCompleted'], equals(0));
      expect(data['duelsWon'], equals(0));
    });

    test('should handle users with zero values correctly', () async {
      // Arrange: Create user with all zeros
      final userId = 'test_user_8';
      await firestore.collection('users').doc(userId).set({
        'displayName': 'Test User 8',
        'email': 'test8@example.com',
        'friendCode': 'STU901',
        'createdAt': Timestamp.now(),
        'lastActiveAt': Timestamp.now(),
        'streakCurrent': 0,
        'streakLongest': 0,
        'totalXp': 0,
        'currentLevel': 1,
        'weeklyXpCurrent': 0,
        'weeklyXpWeekStart': Timestamp.now(),
        'duelsPlayed': 0,
        'duelsWon': 0,
        'duelsLost': 0,
        'duelPoints': 0,
      });

      // Act: Run migration
      await _migrateUser(firestore, userId);

      // Assert: Verify zeros preserved where appropriate
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data()!;

      expect(data['streakCurrent'], equals(0));
      expect(data['streakLongest'], equals(0));
      expect(data['streakPoints'], equals(0));
      expect(data['duelsCompleted'], equals(0));
      expect(data['duelsWon'], equals(0));
      expect(data['totalQuestionsAnswered'], equals(0));
      expect(data['totalCorrectAnswers'], equals(0));
      expect(data['totalMasteredQuestions'], equals(0));
    });
  });
}

/// Migration logic extracted for testing
/// This mirrors the logic in scripts/migrate_to_simplified_gamification.dart
Future<void> _migrateUser(
  FirebaseFirestore firestore,
  String userId,
) async {
  final doc = await firestore.collection('users').doc(userId).get();
  final data = doc.data()!;

  // Prepare updates for new fields
  final updates = <String, dynamic>{};

  // 1. Preserve existing streak data
  updates['streakCurrent'] = data['streakCurrent'] ?? 0;
  updates['streakLongest'] = data['streakLongest'] ?? 0;

  // 2. Initialize streak points to 0
  updates['streakPoints'] = 0;

  // 3. Initialize daily goal system
  updates['dailyGoal'] = 10;
  updates['questionsAnsweredToday'] = 0;
  updates['lastDailyReset'] = Timestamp.now();

  // 4. Initialize question statistics
  updates['totalQuestionsAnswered'] = 0;
  updates['totalCorrectAnswers'] = 0;
  updates['totalMasteredQuestions'] = 0;

  // 5. Update duel statistics
  updates['duelsCompleted'] = data['duelsPlayed'] ?? 0;
  updates['duelsWon'] = data['duelsWon'] ?? 0;

  // Apply updates
  await doc.reference.update(updates);

  // 6. Remove XP-related fields
  final fieldsToDelete = <String, dynamic>{
    'totalXp': FieldValue.delete(),
    'currentLevel': FieldValue.delete(),
    'weeklyXpCurrent': FieldValue.delete(),
    'weeklyXpWeekStart': FieldValue.delete(),
    'duelPoints': FieldValue.delete(),
    'duelsPlayed': FieldValue.delete(),
    'duelsLost': FieldValue.delete(),
  };

  await doc.reference.update(fieldsToDelete);

  // 7. Calculate totalMasteredQuestions from questionStates
  final questionStatesSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('questionStates')
      .where('mastered', isEqualTo: true)
      .get();

  final masteredCount = questionStatesSnapshot.docs.length;
  await doc.reference.update({'totalMasteredQuestions': masteredCount});
}
