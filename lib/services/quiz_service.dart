import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/question.dart';
import '../models/question_state.dart';
import 'question_pool_service.dart';
import 'dart:math';

class QuizService {
  final FirebaseFirestore _firestore;
  final Random _random;
  final QuestionPoolService? _questionPoolService;
  final bool _usePoolArchitecture;

  QuizService({
    FirebaseFirestore? firestore, 
    Random? random,
    QuestionPoolService? questionPoolService,
    bool usePoolArchitecture = true, // Feature flag for gradual rollout
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _random = random ?? Random(),
       _questionPoolService = questionPoolService,
       _usePoolArchitecture = usePoolArchitecture;

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
  /// 
  /// Uses the new pool architecture when available and enabled, otherwise falls back
  /// to the legacy algorithm for backward compatibility.
  /// 
  /// Pool architecture provides:
  /// - Three-tier priority system (unseen -> unmastered -> mastered)
  /// - Automatic pool expansion when needed
  /// - Better performance through pre-populated question states
  /// 
  /// Legacy algorithm provides:
  /// - Two-tier priority system (unseen -> oldest seen)
  /// - Direct query of all questions and states
  /// 
  /// Requirements: 1.1, 1.2, 1.3, 1.4
  Future<List<Question>> getQuestionsForSession(
    String categoryId,
    int count,
    String userId,
  ) async {
    // Use pool architecture if available and enabled
    if (_usePoolArchitecture && _questionPoolService != null) {
      try {
        return await _questionPoolService.getQuestionsForSession(
          userId: userId,
          count: count,
          categoryId: categoryId,
        );
      } catch (e) {
        print('Warning: Pool architecture failed, falling back to legacy: $e');
        // Fall back to legacy algorithm on error
      }
    }

    // Legacy algorithm (original implementation)
    return await _getQuestionsForSessionLegacy(categoryId, count, userId);
  }

  /// Legacy implementation of getQuestionsForSession
  /// 
  /// Maintains the original algorithm for backward compatibility.
  /// Property 5: Unseen question prioritization - prioritize seenCount = 0
  /// Property 6: Oldest question fallback - use oldest lastSeenAt when no unseen
  /// Requirements: 4.1, 4.2
  Future<List<Question>> _getQuestionsForSessionLegacy(
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
        
        // Handle nullable lastSeenAt - null values go to the end
        if (stateA.lastSeenAt == null && stateB.lastSeenAt == null) {
          return 0;
        } else if (stateA.lastSeenAt == null) {
          return 1;
        } else if (stateB.lastSeenAt == null) {
          return -1;
        } else {
          return stateA.lastSeenAt!.compareTo(stateB.lastSeenAt!);
        }
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

  /// Get questions from ALL categories with intelligent cross-category selection
  /// 
  /// Uses the new pool architecture when available and enabled, otherwise falls back
  /// to the legacy algorithm for backward compatibility.
  /// 
  /// Pool architecture provides:
  /// - Three-tier priority system across all categories
  /// - Automatic pool expansion when needed
  /// - Better performance through pre-populated question states
  /// 
  /// Legacy algorithm provides:
  /// - Three-tier priority system (unseen -> unmastered -> mastered)
  /// - Direct query of all questions and states
  /// 
  /// Requirements: 1.1, 1.2, 1.3, 1.4
  Future<List<Question>> getQuestionsFromAllCategories(
    int count,
    String userId,
  ) async {
    // Use pool architecture if available and enabled
    if (_usePoolArchitecture && _questionPoolService != null) {
      try {
        return await _questionPoolService.getQuestionsForSession(
          userId: userId,
          count: count,
          // No categoryId filter = all categories
        );
      } catch (e) {
        print('Warning: Pool architecture failed, falling back to legacy: $e');
        // Fall back to legacy algorithm on error
      }
    }

    // Legacy algorithm (original implementation)
    return await _getQuestionsFromAllCategoriesLegacy(count, userId);
  }

  /// Legacy implementation of getQuestionsFromAllCategories
  /// 
  /// Maintains the original algorithm for backward compatibility.
  /// Priority order:
  /// 1. Unseen questions (seenCount = 0) - random from all categories
  /// 2. Unmastered questions (mastered = false) - random from all categories  
  /// 3. All questions - random from all categories
  /// Requirements: Cross-category question selection for "Jetzt Lernen"
  Future<List<Question>> _getQuestionsFromAllCategoriesLegacy(
    int count,
    String userId,
  ) async {
    try {
      // Load all active questions from all categories
      final questionsSnapshot = await _firestore
          .collection('questions')
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

      // Separate questions by priority
      final unseenQuestions = <Question>[];
      final unmasteredQuestions = <Question>[];
      final masteredQuestions = <Question>[];

      for (final question in allQuestions) {
        final state = questionStates[question.id];
        
        if (state == null || state.seenCount == 0) {
          // Never seen before - highest priority
          unseenQuestions.add(question);
        } else if (!state.mastered) {
          // Seen but not mastered - medium priority
          unmasteredQuestions.add(question);
        } else {
          // Mastered - lowest priority
          masteredQuestions.add(question);
        }
      }

      // Priority 1: Select from unseen questions
      if (unseenQuestions.isNotEmpty) {
        unseenQuestions.shuffle(_random);
        return unseenQuestions.take(count).toList();
      }

      // Priority 2: Select from unmastered questions
      if (unmasteredQuestions.isNotEmpty) {
        unmasteredQuestions.shuffle(_random);
        return unmasteredQuestions.take(count).toList();
      }

      // Priority 3: Select from all questions (everything is mastered)
      final allQuestionsList = [...unseenQuestions, ...unmasteredQuestions, ...masteredQuestions];
      allQuestionsList.shuffle(_random);
      return allQuestionsList.take(count).toList();

    } on FirebaseException catch (e) {
      print('Firebase error loading questions from all categories: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load questions. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading questions from all categories: $e');
      throw Exception('Failed to load questions. Please try again.');
    }
  }

  /// Record an answer for a question and update the question state
  /// 
  /// Uses the new pool architecture when available and enabled, otherwise falls back
  /// to updating question states directly for backward compatibility.
  /// 
  /// Pool architecture provides:
  /// - Automatic pool metadata updates
  /// - Mastery threshold enforcement
  /// - Lazy migration support
  /// 
  /// Legacy behavior:
  /// - Direct question state updates without pool metadata
  /// 
  /// Requirements: 3.1, 3.2, 3.3, 3.4
  Future<void> recordAnswer({
    required String userId,
    required String questionId,
    required bool isCorrect,
  }) async {
    // Use pool architecture if available and enabled
    if (_usePoolArchitecture && _questionPoolService != null) {
      try {
        return await _questionPoolService.recordAnswer(
          userId: userId,
          questionId: questionId,
          isCorrect: isCorrect,
        );
      } catch (e) {
        print('Warning: Pool architecture answer recording failed, falling back to legacy: $e');
        // Fall back to legacy behavior on error
      }
    }

    // Legacy behavior - direct question state update without pool metadata
    await _recordAnswerLegacy(userId: userId, questionId: questionId, isCorrect: isCorrect);
  }

  /// Legacy implementation of answer recording
  /// 
  /// Updates question state directly without pool metadata management.
  /// Maintains backward compatibility for users not yet migrated to pool architecture.
  Future<void> _recordAnswerLegacy({
    required String userId,
    required String questionId,
    required bool isCorrect,
  }) async {
    try {
      final stateRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(questionId);

      await _firestore.runTransaction((transaction) async {
        final stateDoc = await transaction.get(stateRef);
        
        QuestionState currentState;
        if (stateDoc.exists) {
          currentState = QuestionState.fromMap(stateDoc.data()!);
        } else {
          // Create new state for first-time answer
          currentState = QuestionState(
            questionId: questionId,
            seenCount: 0,
            correctCount: 0,
            lastSeenAt: null,
            mastered: false,
          );
        }

        // Update state fields
        final newSeenCount = currentState.seenCount + 1;
        final newCorrectCount = isCorrect ? currentState.correctCount + 1 : currentState.correctCount;
        final newMastered = newCorrectCount >= 3; // Mastery threshold

        final updatedState = QuestionState(
          questionId: currentState.questionId,
          seenCount: newSeenCount,
          correctCount: newCorrectCount,
          lastSeenAt: DateTime.now(),
          mastered: newMastered,
        );

        transaction.set(stateRef, updatedState.toMap());
      });

    } on FirebaseException catch (e) {
      print('Firebase error recording answer: ${e.code} - ${e.message}');
      throw Exception('Failed to record answer. Please check your connection and try again.');
    } catch (e) {
      print('Error recording answer: $e');
      throw Exception('Failed to record answer. Please try again.');
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
  /// Property 3: Fallback to query when counter missing
  /// Requirements: 1.1, 1.4, 1.5
  Future<int> getQuestionCountForCategory(String categoryId) async {
    try {
      final categoryDoc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();

      if (!categoryDoc.exists) {
        return 0;
      }

      final data = categoryDoc.data()!;
      final questionCounter = data['questionCounter'] as int?;

      // Fallback to querying if field is missing
      if (questionCounter == null) {
        return await _countActiveQuestions(categoryId);
      }

      return questionCounter;
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

  /// Helper method for fallback - count active questions by querying
  Future<int> _countActiveQuestions(String categoryId) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
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
