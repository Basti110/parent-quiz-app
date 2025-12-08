import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import 'dart:math';

class QuizService {
  final FirebaseFirestore _firestore;
  final Random _random;

  QuizService({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random();

  /// Get all active categories
  /// Requirements: 3.2, 11.4
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      print('Firebase error loading categories: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load categories. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading categories: $e');
      throw Exception('Failed to load categories. Please try again.');
    }
  }

  /// Get questions for a quiz session with intelligent selection
  /// Property 5: Unseen question prioritization - prioritize seenCount = 0
  /// Property 6: Oldest question fallback - use oldest lastSeenAt when no unseen
  /// Requirements: 4.1, 4.2
  Future<List<Question>> getQuestionsForSession(
    String categoryId,
    int count,
    String userId,
  ) async {
    try {
      // Load all active questions for the category
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      if (questionsSnapshot.docs.isEmpty) {
        return [];
      }

      final allQuestions = questionsSnapshot.docs
          .map((doc) => Question.fromMap(doc.data(), doc.id))
          .toList();

      // Load user's question states
      final statesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();

      final questionStates = <String, QuestionState>{};
      for (final doc in statesSnapshot.docs) {
        final state = QuestionState.fromMap(doc.data());
        questionStates[state.questionId] = state;
      }

      // Separate questions into unseen and seen
      final unseenQuestions = <Question>[];
      final seenQuestions = <Question>[];

      for (final question in allQuestions) {
        final state = questionStates[question.id];
        if (state == null || state.seenCount == 0) {
          unseenQuestions.add(question);
        } else {
          seenQuestions.add(question);
        }
      }

      // Priority 1: Select from unseen questions
      if (unseenQuestions.isNotEmpty) {
        unseenQuestions.shuffle(_random);
        return unseenQuestions.take(count).toList();
      }

      // Priority 2: Select from seen questions, oldest first
      seenQuestions.sort((a, b) {
        final stateA = questionStates[a.id]!;
        final stateB = questionStates[b.id]!;
        return stateA.lastSeenAt.compareTo(stateB.lastSeenAt);
      });

      // Take oldest questions and shuffle them for variety
      final oldestQuestions = seenQuestions.take(count * 2).toList();
      oldestQuestions.shuffle(_random);

      return oldestQuestions.take(count).toList();
    } on FirebaseException catch (e) {
      print('Firebase error loading questions: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load questions. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading questions: $e');
      throw Exception('Failed to load questions. Please try again.');
    }
  }

  /// Calculate XP for a quiz session
  /// Property 8: Correct answer XP - +10 XP
  /// Property 9: Incorrect answer with explanation XP - +5 XP
  /// Property 10: Incorrect answer without explanation XP - +2 XP
  /// Property 11: Five-question session bonus - +10 XP
  /// Property 12: Ten-question session bonus - +25 XP
  /// Property 13: Perfect session bonus - +10 XP
  /// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
  int calculateSessionXP({
    required List<bool> correctAnswers,
    required List<bool> explanationViewed,
    required int questionCount,
  }) {
    int totalXP = 0;

    // Calculate XP per question
    for (int i = 0; i < correctAnswers.length; i++) {
      if (correctAnswers[i]) {
        // Correct answer: +10 XP
        totalXP += 10;
      } else {
        // Incorrect answer
        if (explanationViewed[i]) {
          // Viewed explanation: +5 XP
          totalXP += 5;
        } else {
          // Did not view explanation: +2 XP
          totalXP += 2;
        }
      }
    }

    // Session completion bonuses
    if (questionCount == 5) {
      // 5-question session bonus: +10 XP
      totalXP += 10;
    } else if (questionCount == 10) {
      // 10-question session bonus: +25 XP
      totalXP += 25;
    }

    // Perfect session bonus
    final allCorrect = correctAnswers.every((correct) => correct);
    if (allCorrect && correctAnswers.isNotEmpty) {
      // All correct bonus: +10 XP
      totalXP += 10;
    }

    return totalXP;
  }

  /// Update user's XP and level after a session
  /// Property 14: Session XP persistence - update totalXp and weeklyXpCurrent
  /// Requirements: 5.7, 7.1
  Future<void> updateUserXP(String userId, int xpGained) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentTotalXp = userData['totalXp'] as int;
      final newTotalXp = currentTotalXp + xpGained;

      // Calculate new level (100 XP per level)
      final newLevel = (newTotalXp ~/ 100) + 1;

      // Update user document with new XP and level
      await _firestore.collection('users').doc(userId).update({
        'totalXp': newTotalXp,
        'currentLevel': newLevel,
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating user XP: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update XP. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating user XP: $e');
      rethrow;
    }
  }

  /// Count total active questions for a category
  /// Requirements: 3.2
  Future<int> getQuestionCountForCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      print('Firebase error counting questions: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to count questions. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error counting questions: $e');
      throw Exception('Failed to count questions. Please try again.');
    }
  }

  /// Get a single question by ID
  /// Used for VS Mode to load specific questions
  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc = await _firestore
          .collection('questions')
          .doc(questionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Question.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      print('Firebase error loading question: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load question. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading question: $e');
      throw Exception('Failed to load question. Please try again.');
    }
  }
}
