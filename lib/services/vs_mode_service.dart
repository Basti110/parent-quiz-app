import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vs_mode_session.dart';
import '../models/vs_mode_result.dart';
import '../models/question.dart';
import 'dart:math';

class VSModeService {
  final FirebaseFirestore _firestore;
  final Random _random;

  VSModeService({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random();

  /// Initialize a VS Mode duel session
  /// Requirements: 9.2, 9.3
  Future<VSModeSession> startVSMode({
    required String categoryId,
    required int questionsPerPlayer,
    required String playerAName,
    required String playerBName,
  }) async {
    try {
      // Load all active questions for the category
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      if (questionsSnapshot.docs.isEmpty) {
        throw Exception('No questions available for this category');
      }

      final allQuestions = questionsSnapshot.docs
          .map((doc) => Question.fromMap(doc.data(), doc.id))
          .toList();

      // Shuffle questions for random selection
      allQuestions.shuffle(_random);

      // Need enough questions for both players
      final totalQuestionsNeeded = questionsPerPlayer * 2;
      if (allQuestions.length < totalQuestionsNeeded) {
        throw Exception(
          'Not enough questions available. Need $totalQuestionsNeeded, but only ${allQuestions.length} available',
        );
      }

      // Assign questions to each player
      final playerAQuestionIds = allQuestions
          .take(questionsPerPlayer)
          .map((q) => q.id)
          .toList();
      final playerBQuestionIds = allQuestions
          .skip(questionsPerPlayer)
          .take(questionsPerPlayer)
          .map((q) => q.id)
          .toList();

      return VSModeSession(
        categoryId: categoryId,
        questionsPerPlayer: questionsPerPlayer,
        playerAName: playerAName,
        playerBName: playerBName,
        playerAQuestionIds: playerAQuestionIds,
        playerBQuestionIds: playerBQuestionIds,
      );
    } on FirebaseException catch (e) {
      print('Firebase error starting VS Mode: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to start VS Mode. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error starting VS Mode: $e');
      rethrow;
    }
  }

  /// Record when a player starts viewing a question (timer starts/resumes)
  /// Requirements: 18.1, 18.2, 18.5, 22.2, 22.3
  VSModeSession recordQuestionStart({
    required VSModeSession session,
    required String playerId,
    required DateTime startTime,
  }) {
    // Store the start time in session state for later calculation
    // This method is called when a question is displayed
    // The actual elapsed time is calculated in recordQuestionEnd
    return session;
  }

  /// Record when a player submits an answer (timer pauses)
  /// Accumulates elapsed time for the question
  /// Requirements: 18.1, 18.2, 18.5, 17.4, 22.2, 22.3
  VSModeSession recordQuestionEnd({
    required VSModeSession session,
    required String playerId,
    required DateTime endTime,
    required DateTime startTime,
  }) {
    // Calculate elapsed time for this question
    final elapsedSeconds = endTime.difference(startTime).inSeconds;
    
    // Validate that end time is after start time (handle clock skew)
    if (elapsedSeconds < 0) {
      print('Warning: Negative elapsed time detected. Skipping this question duration.');
      return session;
    }
    
    // Accumulate elapsed time for the player
    if (playerId == 'playerA') {
      final newElapsedSeconds = session.playerAElapsedSeconds + elapsedSeconds;
      return session.copyWith(playerAElapsedSeconds: newElapsedSeconds);
    } else if (playerId == 'playerB') {
      final newElapsedSeconds = session.playerBElapsedSeconds + elapsedSeconds;
      return session.copyWith(playerBElapsedSeconds: newElapsedSeconds);
    } else {
      throw ArgumentError(
        'Invalid playerId: $playerId. Must be "playerA" or "playerB"',
      );
    }
  }

  /// Record that a player viewed an explanation
  /// Requirements: 17.4, 22.2, 22.3
  VSModeSession recordExplanationViewed({
    required VSModeSession session,
    required String playerId,
    required String questionId,
  }) {
    if (playerId == 'playerA') {
      final updatedViewed = Map<String, bool>.from(session.playerAExplanationsViewed);
      updatedViewed[questionId] = true;
      return session.copyWith(playerAExplanationsViewed: updatedViewed);
    } else if (playerId == 'playerB') {
      final updatedViewed = Map<String, bool>.from(session.playerBExplanationsViewed);
      updatedViewed[questionId] = true;
      return session.copyWith(playerBExplanationsViewed: updatedViewed);
    } else {
      throw ArgumentError(
        'Invalid playerId: $playerId. Must be "playerA" or "playerB"',
      );
    }
  }

  /// Submit an answer for a player during VS Mode
  /// Requirements: 9.3
  VSModeSession submitPlayerAnswer({
    required VSModeSession session,
    required String playerId,
    required String questionId,
    required bool isCorrect,
  }) {
    if (playerId == 'playerA') {
      final updatedAnswers = Map<String, bool>.from(session.playerAAnswers);
      updatedAnswers[questionId] = isCorrect;
      return session.copyWith(playerAAnswers: updatedAnswers);
    } else if (playerId == 'playerB') {
      final updatedAnswers = Map<String, bool>.from(session.playerBAnswers);
      updatedAnswers[questionId] = isCorrect;
      return session.copyWith(playerBAnswers: updatedAnswers);
    } else {
      throw ArgumentError(
        'Invalid playerId: $playerId. Must be "playerA" or "playerB"',
      );
    }
  }

  /// Calculate XP for a player based on their answers and explanation views
  /// Requirements: 25.1, 25.2, 25.3, 25.4
  int calculatePlayerXP({
    required Map<String, bool> answers,
    required Map<String, bool> explanationsViewed,
    required int questionsPerPlayer,
  }) {
    int xp = 0;
    
    // Calculate XP per question
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final isCorrect = entry.value;
      
      if (isCorrect) {
        // Correct answer: +10 XP
        xp += 10;
      } else {
        // Incorrect answer
        final viewedExplanation = explanationsViewed[questionId] ?? false;
        if (viewedExplanation) {
          // Incorrect + explanation viewed: +5 XP
          xp += 5;
        } else {
          // Incorrect without explanation: +2 XP
          xp += 2;
        }
      }
    }
    
    // Apply session bonuses
    final questionsAnswered = answers.length;
    if (questionsAnswered == questionsPerPlayer) {
      // Session completion bonus
      if (questionsPerPlayer == 5) {
        xp += 10;
      } else if (questionsPerPlayer == 10) {
        xp += 25;
      }
      
      // Perfect score bonus
      final correctCount = answers.values.where((correct) => correct).length;
      if (correctCount == questionsPerPlayer) {
        xp += 10;
      }
    }
    
    return xp;
  }

  /// Calculate the result of a VS Mode duel
  /// Property 24: Duel winner determination
  /// Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 24.1, 24.2, 24.3
  VSModeResult calculateResult(VSModeSession session) {
    // Use the factory constructor that handles time-based tiebreaker
    return VSModeResult.fromSession(
      playerAName: session.playerAName,
      playerBName: session.playerBName,
      playerAScore: session.playerAScore,
      playerBScore: session.playerBScore,
      playerATimeSeconds: session.playerATimeSeconds,
      playerBTimeSeconds: session.playerBTimeSeconds,
    );
  }

  /// Update duel statistics for the logged-in user
  /// Property 25: Duel win stats update
  /// Property 26: Duel tie stats update
  /// Property 27: Duel loss stats update
  /// Requirements: 9.6, 9.7, 9.8
  Future<void> updateDuelStats({
    required String userId,
    required VSModeResult result,
    required String userPlayerName,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentDuelsPlayed = userData['duelsPlayed'] as int;
      final currentDuelsWon = userData['duelsWon'] as int;
      final currentDuelsLost = userData['duelsLost'] as int;
      final currentDuelPoints = userData['duelPoints'] as int;

      int newDuelsPlayed = currentDuelsPlayed + 1;
      int newDuelsWon = currentDuelsWon;
      int newDuelsLost = currentDuelsLost;
      int newDuelPoints = currentDuelPoints;

      if (result.isPlayerWinner(userPlayerName)) {
        // User won: +3 points, increment duelsWon
        newDuelsWon += 1;
        newDuelPoints += 3;
      } else if (result.isTie()) {
        // Tie: +1 point
        newDuelPoints += 1;
      } else {
        // User lost: increment duelsLost
        newDuelsLost += 1;
      }

      await _firestore.collection('users').doc(userId).update({
        'duelsPlayed': newDuelsPlayed,
        'duelsWon': newDuelsWon,
        'duelsLost': newDuelsLost,
        'duelPoints': newDuelPoints,
      });
    } on FirebaseException catch (e) {
      print('Firebase error updating duel stats: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update duel stats. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating duel stats: $e');
      rethrow;
    }
  }
}
