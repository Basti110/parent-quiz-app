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
          .collection('question')
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

  /// Calculate the result of a VS Mode duel
  /// Property 24: Duel winner determination
  /// Requirements: 9.5
  VSModeResult calculateResult(VSModeSession session) {
    final playerAScore = session.playerAScore;
    final playerBScore = session.playerBScore;

    VSModeOutcome outcome;
    if (playerAScore > playerBScore) {
      outcome = VSModeOutcome.playerAWins;
    } else if (playerBScore > playerAScore) {
      outcome = VSModeOutcome.playerBWins;
    } else {
      outcome = VSModeOutcome.tie;
    }

    return VSModeResult(
      playerAName: session.playerAName,
      playerBName: session.playerBName,
      playerAScore: playerAScore,
      playerBScore: playerBScore,
      outcome: outcome,
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
      final userDoc = await _firestore.collection('user').doc(userId).get();

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

      await _firestore.collection('user').doc(userId).update({
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
