import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/question_state.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user data as a one-time fetch
  Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      return UserModel.fromMap(doc.data()!, userId);
    } on FirebaseException catch (e) {
      print('Firebase error loading user data: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load user data. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading user data: $e');
      rethrow;
    }
  }

  /// Get user data as a stream for real-time updates
  Stream<UserModel> getUserStream(String userId) async* {
    await for (final doc
        in _firestore.collection('users').doc(userId).snapshots()) {
      if (!doc.exists) {
        // If document doesn't exist, create it with default values
        await _createDefaultUserDocument(userId);
        // Wait for the next snapshot which should have the created document
        continue;
      }
      yield UserModel.fromMap(doc.data()!, userId);
    }
  }

  /// Create a default user document for a user that doesn't have one
  Future<void> _createDefaultUserDocument(String userId) async {
    try {
      // Get user email from Firebase Auth if available
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Cannot create user document: user not authenticated');
      }

      final email = currentUser.email ?? 'user@example.com';
      final displayName = currentUser.displayName ?? email.split('@')[0];

      final now = DateTime.now();

      // Generate a simple friend code (not checking for uniqueness here for simplicity)
      final friendCode = _generateSimpleFriendCode();

      final userModel = UserModel(
        id: userId,
        displayName: displayName,
        email: email,
        avatarUrl: null,
        createdAt: now,
        lastActiveAt: now,
        friendCode: friendCode,
        streakCurrent: 0,
        streakLongest: 0,
        streakPoints: 0,
        dailyGoal: 10,
        questionsAnsweredToday: 0,
        lastDailyReset: now,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalMasteredQuestions: 0,
        duelsCompleted: 0,
        duelsWon: 0,
      );

      await _firestore.collection('users').doc(userId).set(userModel.toMap());
    } catch (e) {
      print('Error creating default user document: $e');
      rethrow;
    }
  }

  /// Generate a simple friend code without uniqueness check
  String _generateSimpleFriendCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final length = 6 + random.nextInt(3);

    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ============================================================================
  // Daily Goal Management Methods (Task 2.1)
  // ============================================================================

  /// Update user's daily goal with validation (1-50)
  /// Requirements: 1.3, 1.4
  Future<void> updateDailyGoal(String userId, int newGoal) async {
    // Validate daily goal is between 1 and 50
    if (newGoal < 1 || newGoal > 50) {
      throw ArgumentError('Daily goal must be between 1 and 50');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'dailyGoal': newGoal,
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating daily goal: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update daily goal. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating daily goal: $e');
      rethrow;
    }
  }

  /// Increment the count of questions answered today
  /// Requirements: 1.5
  Future<void> incrementQuestionsAnsweredToday(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'questionsAnsweredToday': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      print(
        'Firebase error incrementing questions answered today: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to update daily progress. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error incrementing questions answered today: $e');
      rethrow;
    }
  }

  /// Reset daily progress if a new day has started
  /// Requirements: 5.5
  Future<void> resetDailyProgressIfNeeded(String userId) async {
    try {
      final user = await getUserData(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastReset = DateTime(
        user.lastDailyReset.year,
        user.lastDailyReset.month,
        user.lastDailyReset.day,
      );

      // If last reset was not today, reset the counter
      if (!_isSameDay(today, lastReset)) {
        await _firestore.collection('users').doc(userId).update({
          'questionsAnsweredToday': 0,
          'lastDailyReset': Timestamp.fromDate(now),
        });
      }
    } on FirebaseException catch (e) {
      print(
        'Firebase error resetting daily progress: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to reset daily progress. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error resetting daily progress: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Streak Management Methods (Task 2.2)
  // ============================================================================

  /// Check and update streak based on daily goal completion
  /// Property 5: Streak continuation - if met goal yesterday, increment streak
  /// Property 6: Streak reset - if failed to meet goal, reset to 0
  /// Requirements: 2.1, 2.2, 2.3, 2.4
  Future<void> checkAndUpdateStreak(String userId) async {
    try {
      final user = await getUserData(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = DateTime(
        user.lastActiveAt.year,
        user.lastActiveAt.month,
        user.lastActiveAt.day,
      );

      // Check if user met their daily goal today
      final metGoalToday = user.questionsAnsweredToday >= user.dailyGoal;

      if (!metGoalToday) {
        // User hasn't met goal yet, don't update streak
        return;
      }

      // If already updated streak today, no change needed
      if (_isSameDay(today, lastActive)) {
        return;
      }

      int newStreakCurrent;
      int newStreakLongest = user.streakLongest;

      // Check if lastActive was yesterday
      if (_isYesterday(lastActive, today)) {
        // Consecutive day - increment streak
        newStreakCurrent = user.streakCurrent + 1;

        // Update longest streak if current exceeds it
        if (newStreakCurrent > newStreakLongest) {
          newStreakLongest = newStreakCurrent;
        }
      } else if (user.streakCurrent == 0) {
        // First time meeting goal
        newStreakCurrent = 1;
        if (newStreakLongest == 0) {
          newStreakLongest = 1;
        }
      } else {
        // Streak broken - reset to 0
        newStreakCurrent = 0;
      }

      // Calculate and award streak points if applicable
      final streakPoints = calculateStreakPoints(newStreakCurrent);
      if (streakPoints > 0) {
        await awardStreakPoints(userId, streakPoints);
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'lastActiveAt': Timestamp.fromDate(now),
        'streakCurrent': newStreakCurrent,
        'streakLongest': newStreakLongest,
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating streak: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update streak. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating streak: $e');
      rethrow;
    }
  }

  /// Calculate streak points based on current streak
  /// Property 8: No points for days 1-2
  /// Property 9: Three points at day 3
  /// Property 10: Three points per additional day
  /// Requirements: 3.1, 3.2, 3.3
  int calculateStreakPoints(int currentStreak) {
    if (currentStreak <= 2) {
      return 0; // No points for days 1-2
    } else if (currentStreak == 3) {
      return 3; // 3 points at day 3
    } else {
      return 3; // 3 points per additional day
    }
  }

  /// Award streak points to user
  /// Property 11: Streak points accumulation - only increases
  /// Requirements: 3.1, 3.2, 3.3
  Future<void> awardStreakPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'streakPoints': FieldValue.increment(points),
      });
    } on FirebaseException catch (e) {
      print('Firebase error awarding streak points: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to award streak points. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error awarding streak points: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Question Statistics Methods (Task 2.3)
  // ============================================================================

  /// Increment total questions answered and correct answers if applicable
  /// Property 12: Correct answer counting
  /// Property 13: Total questions counting
  /// Requirements: 4.1, 4.3
  Future<void> incrementTotalQuestions(String userId, bool correct) async {
    try {
      final updates = <String, dynamic>{
        'totalQuestionsAnswered': FieldValue.increment(1),
      };

      if (correct) {
        updates['totalCorrectAnswers'] = FieldValue.increment(1);
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } on FirebaseException catch (e) {
      print(
        'Firebase error incrementing total questions: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to update question statistics. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error incrementing total questions: $e');
      rethrow;
    }
  }

  /// Update the count of mastered questions by counting from questionStates
  /// Property 15: Mastered count accuracy
  /// Requirements: 4.5
  Future<void> updateMasteredCount(String userId) async {
    try {
      // Get all question states for the user
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .where('mastered', isEqualTo: true)
          .get();

      final masteredCount = statesSnapshot.docs.length;

      await _firestore.collection('users').doc(userId).update({
        'totalMasteredQuestions': masteredCount,
      });
    } on FirebaseException catch (e) {
      print(
        'Firebase error updating mastered count: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to update mastered count. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating mastered count: $e');
      rethrow;
    }
  }

  /// Update user's avatar path
  /// Property 1: Avatar selection persistence
  Future<void> updateAvatarPath(String userId, String avatarPath) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'avatarPath': avatarPath,
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating avatar path: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update avatar. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating avatar path: $e');
      rethrow;
    }
  }

  /// Update weekly XP (legacy method for compatibility)
  /// This method is kept for backward compatibility with existing quiz screen
  Future<void> updateWeeklyXP(String userId, int xpToAdd) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'weeklyXpCurrent': FieldValue.increment(xpToAdd),
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating weekly XP: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update weekly XP. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating weekly XP: $e');
      rethrow;
    }
  }

  /// Update streak (legacy method for compatibility)
  /// This method is kept for backward compatibility with existing quiz screen
  Future<void> updateStreak(String userId) async {
    try {
      // This calls the existing checkAndUpdateStreak method
      await checkAndUpdateStreak(userId);
    } catch (e) {
      print('Error updating streak: $e');
      rethrow;
    }
  }



  /// Update question state for mastery tracking
  /// Property 7: Question state update on answer
  /// Property 19: Question mastery threshold - mastered when correctCount >= 3
  Future<void> updateQuestionState(
    String userId,
    String questionId,
    bool correct,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(questionId);

      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing question state
        final state = QuestionState.fromMap(doc.data()!);
        final newCorrectCount = correct
            ? state.correctCount + 1
            : state.correctCount;
        final newMastered = newCorrectCount >= 3;

        await docRef.update({
          'seenCount': state.seenCount + 1,
          'correctCount': newCorrectCount,
          'lastSeenAt': Timestamp.fromDate(DateTime.now()),
          'mastered': newMastered,
        });
      } else {
        // Create new question state
        final newState = QuestionState(
          questionId: questionId,
          seenCount: 1,
          correctCount: correct ? 1 : 0,
          lastSeenAt: DateTime.now(),
          mastered: false, // Can't be mastered on first attempt
        );

        await docRef.set(newState.toMap());
      }
    } on FirebaseException catch (e) {
      print('Firebase error updating question state: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update question state. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating question state: $e');
      rethrow;
    }
  }

  /// Update category progress after completing a quiz session
  Future<void> updateCategoryProgress(
    String userId,
    String categoryId,
    int questionsAnswered,
  ) async {
    try {
      final user = await getUserData(userId);

      // Get current progress for this category
      final currentProgress = user.categoryProgress[categoryId];
      final currentQuestionsAnswered = currentProgress?.questionsAnswered ?? 0;

      // Count mastered questions in this category
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      // Get all questions for this category
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      final categoryQuestionIds = questionsSnapshot.docs
          .map((doc) => doc.id)
          .toSet();

      // Count mastered questions
      int masteredCount = 0;
      for (final stateDoc in statesSnapshot.docs) {
        if (categoryQuestionIds.contains(stateDoc.id)) {
          final state = QuestionState.fromMap(stateDoc.data());
          if (state.mastered) {
            masteredCount++;
          }
        }
      }

      // Update category progress in user document
      final updatedProgress = {
        'questionsAnswered': currentQuestionsAnswered + questionsAnswered,
        'questionsMastered': masteredCount,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('users').doc(userId).update({
        'categoryProgress.$categoryId': updatedProgress,
      });
    } on FirebaseException catch (e) {
      print(
        'Firebase error updating category progress: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to update category progress. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating category progress: $e');
      rethrow;
    }
  }

  /// Get category mastery percentage
  /// Property 20: Category mastery calculation
  Future<Map<String, double>> getCategoryMastery(String userId) async {
    try {
      // Get all question states for the user
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      if (statesSnapshot.docs.isEmpty) {
        return {};
      }

      // Get all questions to map them to categories
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('isActive', isEqualTo: true)
          .get();

      // Map questionId to categoryId
      final questionToCategory = <String, String>{};
      for (final doc in questionsSnapshot.docs) {
        questionToCategory[doc.id] = doc.data()['categoryId'] as String;
      }

      // Count mastered and total questions per category
      final categoryMastered = <String, int>{};
      final categoryTotal = <String, int>{};

      for (final stateDoc in statesSnapshot.docs) {
        final state = QuestionState.fromMap(stateDoc.data());
        final categoryId = questionToCategory[state.questionId];

        if (categoryId != null) {
          categoryTotal[categoryId] = (categoryTotal[categoryId] ?? 0) + 1;

          if (state.mastered) {
            categoryMastered[categoryId] =
                (categoryMastered[categoryId] ?? 0) + 1;
          }
        }
      }

      // Calculate percentages
      final mastery = <String, double>{};
      for (final categoryId in categoryTotal.keys) {
        final total = categoryTotal[categoryId]!;
        final mastered = categoryMastered[categoryId] ?? 0;
        mastery[categoryId] = (mastered / total) * 100;
      }

      return mastery;
    } on FirebaseException catch (e) {
      print(
        'Firebase error calculating category mastery: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to calculate category mastery. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error calculating category mastery: $e');
      rethrow;
    }
  }

  // Helper methods

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isYesterday(DateTime lastActive, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return _isSameDay(lastActive, yesterday);
  }
}
