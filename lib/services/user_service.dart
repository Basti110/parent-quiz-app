import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/question_state.dart';
import '../models/weekly_points.dart';

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
      final currentMonday = _getMondayOfWeek(now);

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
        totalXp: 0,
        currentLevel: 1,
        weeklyXpCurrent: 0,
        weeklyXpWeekStart: currentMonday,
        streakCurrent: 0,
        streakLongest: 0,
        duelsPlayed: 0,
        duelsWon: 0,
        duelsLost: 0,
        duelPoints: 0,
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

  /// Update user's streak based on last active date
  /// Property 15: Streak continuation - if lastActiveAt is yesterday, increment streak
  /// Property 16: Streak reset - if lastActiveAt is more than 1 day ago, reset to 1
  Future<void> updateStreak(String userId) async {
    try {
      final user = await getUserData(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = DateTime(
        user.lastActiveAt.year,
        user.lastActiveAt.month,
        user.lastActiveAt.day,
      );

      // If already active today, no change needed
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
      } else {
        // Streak broken - reset to 1
        newStreakCurrent = 1;
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

  /// Calculate user level based on total XP (100 XP per level)
  /// Property 18: Level calculation - currentLevel = floor(totalXp / 100) + 1
  int calculateLevel(int totalXp) {
    return (totalXp ~/ 100) + 1;
  }

  /// Update weekly XP with week rollover logic
  /// Property 21: Weekly XP accumulation - add to weeklyXpCurrent if in current week
  /// Property 22: Weekly XP reset - reset if new week started
  Future<void> updateWeeklyXP(String userId, int xpGained) async {
    try {
      final user = await getUserData(userId);
      final now = DateTime.now();
      final currentMonday = _getMondayOfWeek(now);

      // Check if we're in a new week
      if (user.weeklyXpWeekStart.isBefore(currentMonday)) {
        // New week started - save previous week to history and reset
        await _saveWeeklyPointsToHistory(userId, user);

        // Reset weekly XP
        await _firestore.collection('users').doc(userId).update({
          'weeklyXpCurrent': xpGained,
          'weeklyXpWeekStart': Timestamp.fromDate(currentMonday),
        });
      } else {
        // Same week - accumulate XP
        await _firestore.collection('users').doc(userId).update({
          'weeklyXpCurrent': user.weeklyXpCurrent + xpGained,
        });
      }
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

  /// Save completed week to history subcollection
  Future<void> _saveWeeklyPointsToHistory(String userId, UserModel user) async {
    try {
      // Format date as yyyy-MM-dd for the Monday of the week
      final weekStart = user.weeklyXpWeekStart;
      final dateKey = _formatDate(weekStart);

      // Calculate week end (Sunday)
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weeklyPoints = WeeklyPoints(
        date: dateKey,
        weekStart: weekStart,
        weekEnd: weekEnd,
        points: user.weeklyXpCurrent,
        sessionsCompleted: 0, // Will be tracked in future enhancements
        questionsAnswered: 0,
        correctAnswers: 0,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .doc(dateKey)
          .set(weeklyPoints.toMap());
    } on FirebaseException catch (e) {
      print(
        'Firebase error saving weekly points to history: ${e.code} - ${e.message}',
      );
      // Don't throw here - this is a background operation that shouldn't block the main flow
    } catch (e) {
      print('Error saving weekly points to history: $e');
      // Don't throw here - this is a background operation that shouldn't block the main flow
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

  DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
