import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/duel_model.dart';

class DuelService {
  final FirebaseFirestore _firestore;
  final Random _random;

  DuelService({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  /// Create a new duel challenge
  /// Requirements: 10.2, 11.1
  Future<String> createDuel(String challengerId, String opponentId) async {
    try {
      // Validate that challenger and opponent are different
      if (challengerId == opponentId) {
        throw ArgumentError('Cannot challenge yourself to a duel');
      }

      // Check if there's already an active duel between these users
      final hasActive = await hasActiveDuel(challengerId, opponentId);
      if (hasActive) {
        throw Exception('There is already an active duel between these users. Please wait for it to complete before starting a new challenge.');
      }

      // Generate 5 random questions for the duel
      final questionIds = await _generateDuelQuestions();

      if (questionIds.length < 5) {
        throw Exception('Not enough questions available to create a duel');
      }

      // Create the duel document
      final duelData = DuelModel(
        id: '', // Will be set by Firestore
        challengerId: challengerId,
        opponentId: opponentId,
        status: DuelStatus.pending,
        createdAt: DateTime.now(),
        questionIds: questionIds,
      );

      final docRef = await _firestore
          .collection('duels')
          .add(duelData.toMap());

      final duelId = docRef.id;

      // Update both users' friendship documents with the open challenge
      final challengeData = {
        'duelId': duelId,
        'challengerId': challengerId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      // Update opponent's friendship document (they receive the challenge)
      await _firestore
          .collection('users')
          .doc(opponentId)
          .collection('friends')
          .doc(challengerId)
          .update({
        'openChallenge': challengeData,
      });

      // Update challenger's friendship document (they sent the challenge)
      await _firestore
          .collection('users')
          .doc(challengerId)
          .collection('friends')
          .doc(opponentId)
          .update({
        'openChallenge': challengeData,
      });

      return duelId;
    } on FirebaseException catch (e) {
      print('Firebase error creating duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to create duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error creating duel: $e');
      rethrow;
    }
  }

  /// Accept a duel challenge
  /// Requirements: 11.2
  Future<void> acceptDuel(String duelId, String userId) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      final duel = DuelModel.fromMap(duelDoc.data()!, duelDoc.id);

      // Verify the user is the opponent
      if (duel.opponentId != userId) {
        throw ArgumentError('Only the opponent can accept this duel');
      }

      // Verify the duel is in pending status
      if (duel.status != DuelStatus.pending) {
        throw StateError('Duel is not in pending status');
      }

      // Update duel status to accepted
      await _firestore.collection('duels').doc(duelId).update({
        'status': DuelStatus.accepted.name,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update openChallenge status to 'accepted' in both friendship documents
      // This allows both users to start the duel while preventing new challenges
      await _firestore
          .collection('users')
          .doc(duel.challengerId)
          .collection('friends')
          .doc(duel.opponentId)
          .update({
        'openChallenge.status': 'accepted',
      });

      await _firestore
          .collection('users')
          .doc(duel.opponentId)
          .collection('friends')
          .doc(duel.challengerId)
          .update({
        'openChallenge.status': 'accepted',
      });
    } on FirebaseException catch (e) {
      print('Firebase error accepting duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to accept duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error accepting duel: $e');
      rethrow;
    }
  }

  /// Decline a duel challenge
  /// Requirements: 11.3
  Future<void> declineDuel(String duelId, String userId) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      final duel = DuelModel.fromMap(duelDoc.data()!, duelDoc.id);

      // Verify the user is the opponent
      if (duel.opponentId != userId) {
        throw ArgumentError('Only the opponent can decline this duel');
      }

      // Verify the duel is in pending status
      if (duel.status != DuelStatus.pending) {
        throw StateError('Duel is not in pending status');
      }

      // Update duel status to declined
      await _firestore.collection('duels').doc(duelId).update({
        'status': DuelStatus.declined.name,
      });

      // Clear the openChallenge field (declined duels are immediately cleared)
      await _clearOpenChallenge(duel.challengerId, duel.opponentId);
    } on FirebaseException catch (e) {
      print('Firebase error declining duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to decline duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error declining duel: $e');
      rethrow;
    }
  }

  /// Submit an answer for a duel question
  /// Requirements: 12.2, 12.3, 12.4
  Future<void> submitAnswer({
    required String duelId,
    required String userId,
    required int questionIndex,
    required String questionId,
    required bool isCorrect,
  }) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      final duel = DuelModel.fromMap(duelDoc.data()!, duelDoc.id);

      // Verify the user is a participant
      if (duel.challengerId != userId && duel.opponentId != userId) {
        throw ArgumentError('User is not a participant in this duel');
      }

      // Verify the duel is accepted
      if (duel.status != DuelStatus.accepted) {
        throw StateError('Duel must be accepted before submitting answers');
      }

      // Determine which player is submitting
      final isChallenger = duel.challengerId == userId;
      final answersField = isChallenger ? 'challengerAnswers' : 'opponentAnswers';
      final scoreField = isChallenger ? 'challengerScore' : 'opponentScore';

      // Update the answer map and increment score if correct
      await _firestore.collection('duels').doc(duelId).update({
        '$answersField.$questionId': isCorrect,
        if (isCorrect) scoreField: FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      print('Firebase error submitting answer: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to submit answer. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error submitting answer: $e');
      rethrow;
    }
  }

  /// Mark a player's completion of the duel
  /// Requirements: 12.3, 13.2, 15a.2
  Future<void> completeDuel(String duelId, String userId) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      final duel = DuelModel.fromMap(duelDoc.data()!, duelDoc.id);

      // Verify the user is a participant
      if (duel.challengerId != userId && duel.opponentId != userId) {
        throw ArgumentError('User is not a participant in this duel');
      }

      // Determine which player is completing
      final isChallenger = duel.challengerId == userId;
      final completedAtField = isChallenger 
          ? 'challengerCompletedAt' 
          : 'opponentCompletedAt';

      // Mark completion timestamp
      await _firestore.collection('duels').doc(duelId).update({
        completedAtField: Timestamp.fromDate(DateTime.now()),
      });

      // Check if both players have completed
      final updatedDuelDoc = await _firestore.collection('duels').doc(duelId).get();
      final updatedDuel = DuelModel.fromMap(updatedDuelDoc.data()!, updatedDuelDoc.id);

      if (updatedDuel.challengerCompletedAt != null && 
          updatedDuel.opponentCompletedAt != null) {
        // Both players completed - update duel status and statistics
        await _firestore.collection('duels').doc(duelId).update({
          'status': DuelStatus.completed.name,
          'completedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Determine winner and update statistics
        final winnerId = updatedDuel.getWinnerId();
        final isTie = winnerId == null;

        if (isTie) {
          // Update statistics for tie
          await _updateDuelStatistics(
            updatedDuel.challengerId,
            updatedDuel.opponentId,
            true,
          );
          // Add tie to challenge history
          await _addToChallengeHistory(
            updatedDuel.challengerId,
            updatedDuel.opponentId,
            duelId,
            'tied',
          );
        } else {
          // Update statistics for win/loss
          final loserId = winnerId == updatedDuel.challengerId 
              ? updatedDuel.opponentId 
              : updatedDuel.challengerId;
          await _updateDuelStatistics(winnerId, loserId, false);
          
          // Add win/loss to challenge history
          await _addToChallengeHistory(
            updatedDuel.challengerId,
            updatedDuel.opponentId,
            duelId,
            winnerId == updatedDuel.challengerId ? 'won' : 'lost',
          );
        }

        // Update head-to-head statistics for both users
        await _updateHeadToHeadStats(
          updatedDuel.challengerId,
          updatedDuel.opponentId,
          winnerId == updatedDuel.challengerId,
          isTie,
        );

        // Don't clear openChallenge yet - keep it so users can view results
        // It will be cleared when user navigates to results screen
      }
    } on FirebaseException catch (e) {
      print('Firebase error completing duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to complete duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error completing duel: $e');
      rethrow;
    }
  }

  /// Generate 5 random active questions for a duel
  /// Requirements: 11.5
  Future<List<String>> _generateDuelQuestions() async {
    try {
      // Get all active questions
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('isActive', isEqualTo: true)
          .get();

      if (questionsSnapshot.docs.isEmpty) {
        return [];
      }

      // Get all question IDs
      final allQuestionIds = questionsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      // Shuffle and take 5
      allQuestionIds.shuffle(_random);
      return allQuestionIds.take(5).toList();
    } on FirebaseException catch (e) {
      print('Firebase error generating duel questions: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to generate duel questions. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error generating duel questions: $e');
      throw Exception('Failed to generate duel questions. Please try again.');
    }
  }

  /// Update duel statistics for both users
  /// Requirements: 13.4
  Future<void> _updateDuelStatistics(
    String winnerId,
    String loserId,
    bool isTie,
  ) async {
    try {
      if (isTie) {
        // Both users get duelsCompleted incremented
        await _firestore.collection('users').doc(winnerId).update({
          'duelsCompleted': FieldValue.increment(1),
        });
        await _firestore.collection('users').doc(loserId).update({
          'duelsCompleted': FieldValue.increment(1),
        });
      } else {
        // Winner gets duelsWon and duelsCompleted incremented
        await _firestore.collection('users').doc(winnerId).update({
          'duelsWon': FieldValue.increment(1),
          'duelsCompleted': FieldValue.increment(1),
        });
        // Loser gets only duelsCompleted incremented
        await _firestore.collection('users').doc(loserId).update({
          'duelsCompleted': FieldValue.increment(1),
        });
      }
    } on FirebaseException catch (e) {
      print('Firebase error updating duel statistics: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update duel statistics. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating duel statistics: $e');
      throw Exception('Failed to update duel statistics. Please try again.');
    }
  }

  /// Get stream of pending duel challenges for a user
  /// Requirements: 14.1
  Stream<List<DuelModel>> getPendingDuels(String userId) {
    try {
      return _firestore
          .collection('duels')
          .where('opponentId', isEqualTo: userId)
          .where('status', isEqualTo: DuelStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DuelModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting pending duels: $e');
      throw Exception('Failed to get pending duels. Please try again.');
    }
  }

  /// Get stream of active duels for a user (accepted but not completed)
  /// Requirements: 14.2
  Stream<List<DuelModel>> getActiveDuels(String userId) {
    try {
      // Get duels where user is challenger or opponent and status is accepted
      // We need to combine two queries since Firestore doesn't support OR on different fields
      // For MVP, we'll use a client-side filter
      return _firestore
          .collection('duels')
          .where('status', isEqualTo: DuelStatus.accepted.name)
          .orderBy('acceptedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final duels = snapshot.docs
                .map((doc) => DuelModel.fromMap(doc.data(), doc.id))
                .where((duel) => 
                    duel.challengerId == userId || duel.opponentId == userId)
                .toList();
            return duels;
          });
    } catch (e) {
      print('Error getting active duels: $e');
      throw Exception('Failed to get active duels. Please try again.');
    }
  }

  /// Get stream of completed duels for a user
  /// Requirements: 14.4, 15.4
  Stream<List<DuelModel>> getCompletedDuels(String userId) {
    try {
      // Get completed duels where user is challenger or opponent
      // For MVP, we'll use a client-side filter
      return _firestore
          .collection('duels')
          .where('status', isEqualTo: DuelStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final duels = snapshot.docs
                .map((doc) => DuelModel.fromMap(doc.data(), doc.id))
                .where((duel) => 
                    duel.challengerId == userId || duel.opponentId == userId)
                .toList();
            return duels;
          });
    } catch (e) {
      print('Error getting completed duels: $e');
      throw Exception('Failed to get completed duels. Please try again.');
    }
  }

  /// Get a single duel by ID
  /// Requirements: 15.4
  Future<DuelModel> getDuel(String duelId) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      return DuelModel.fromMap(duelDoc.data()!, duelDoc.id);
    } on FirebaseException catch (e) {
      print('Firebase error getting duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to get duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting duel: $e');
      rethrow;
    }
  }

  /// Get a stream of a single duel by ID for real-time updates
  Stream<DuelModel> getDuelStream(String duelId) {
    try {
      return _firestore
          .collection('duels')
          .doc(duelId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          throw StateError('Duel not found');
        }
        return DuelModel.fromMap(doc.data()!, doc.id);
      });
    } catch (e) {
      print('Error getting duel stream: $e');
      throw Exception('Failed to get duel stream. Please try again.');
    }
  }

  /// Update head-to-head statistics for both users
  /// Requirements: 15a.2
  Future<void> _updateHeadToHeadStats(
    String userId1,
    String userId2,
    bool user1Won,
    bool isTie,
  ) async {
    try {
      // Update user1's friendship document with user2
      final user1FriendRef = _firestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .doc(userId2);

      // Update user2's friendship document with user1
      final user2FriendRef = _firestore
          .collection('users')
          .doc(userId2)
          .collection('friends')
          .doc(userId1);

      if (isTie) {
        // Both users get ties incremented
        await user1FriendRef.update({
          'ties': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
        await user2FriendRef.update({
          'ties': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
      } else if (user1Won) {
        // User1 gets myWins incremented, User2 gets theirWins incremented
        await user1FriendRef.update({
          'myWins': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
        await user2FriendRef.update({
          'theirWins': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
      } else {
        // User2 won: User1 gets theirWins incremented, User2 gets myWins incremented
        await user1FriendRef.update({
          'theirWins': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
        await user2FriendRef.update({
          'myWins': FieldValue.increment(1),
          'totalDuels': FieldValue.increment(1),
        });
      }
    } on FirebaseException catch (e) {
      print('Firebase error updating head-to-head stats: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to update head-to-head statistics. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error updating head-to-head stats: $e');
      throw Exception('Failed to update head-to-head statistics. Please try again.');
    }
  }

  /// Clear the openChallenge field from both friendship documents (public method)
  /// Call this when users view the duel results
  Future<void> clearOpenChallenge(String challengerId, String opponentId) async {
    await _clearOpenChallenge(challengerId, opponentId);
  }

  /// Mark that a user has viewed the duel results
  /// If both users have viewed, clear the openChallenge field
  Future<void> markResultsViewed(String duelId, String userId) async {
    try {
      final duelDoc = await _firestore.collection('duels').doc(duelId).get();

      if (!duelDoc.exists) {
        throw StateError('Duel not found');
      }

      final duel = DuelModel.fromMap(duelDoc.data()!, duelDoc.id);

      // Verify the user is a participant
      if (duel.challengerId != userId && duel.opponentId != userId) {
        throw ArgumentError('User is not a participant in this duel');
      }

      // Determine which field to update
      final isChallenger = duel.challengerId == userId;
      final viewedField = isChallenger 
          ? 'challengerViewedResults' 
          : 'opponentViewedResults';

      // Mark that this user has viewed the results
      await _firestore.collection('duels').doc(duelId).update({
        viewedField: true,
      });

      // Check if both users have now viewed the results
      final updatedDuelDoc = await _firestore.collection('duels').doc(duelId).get();
      final data = updatedDuelDoc.data();
      
      final challengerViewed = data?['challengerViewedResults'] ?? false;
      final opponentViewed = data?['opponentViewedResults'] ?? false;

      debugPrint('Results viewed status: challenger=$challengerViewed, opponent=$opponentViewed');

      // If both have viewed, clear the openChallenge field from BOTH friendship documents
      if (challengerViewed && opponentViewed) {
        debugPrint('Both users have viewed results, clearing openChallenge from both friendship documents');
        await _clearOpenChallenge(duel.challengerId, duel.opponentId);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error marking results viewed: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to mark results viewed. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('Error marking results viewed: $e');
      rethrow;
    }
  }

  /// Clear the openChallenge field from both friendship documents
  Future<void> _clearOpenChallenge(String challengerId, String opponentId) async {
    try {
      debugPrint('Clearing openChallenge from both friendship documents: challenger=$challengerId, opponent=$opponentId');
      
      // Clear from challenger's friendship document
      await _firestore
          .collection('users')
          .doc(challengerId)
          .collection('friends')
          .doc(opponentId)
          .update({
        'openChallenge': FieldValue.delete(),
      });
      debugPrint('Cleared openChallenge from challenger\'s friendship document');

      // Clear from opponent's friendship document
      await _firestore
          .collection('users')
          .doc(opponentId)
          .collection('friends')
          .doc(challengerId)
          .update({
        'openChallenge': FieldValue.delete(),
      });
      debugPrint('Cleared openChallenge from opponent\'s friendship document');
      
      debugPrint('Successfully cleared openChallenge from both friendship documents');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error clearing open challenge: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to clear open challenge. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('Error clearing open challenge: $e');
      throw Exception('Failed to clear open challenge. Please try again.');
    }
  }

  /// Check if there's an active duel between two users by checking friendship document
  /// Returns true if there's an openChallenge in the friendship document
  /// This is the single source of truth for active duels
  Future<bool> hasActiveDuel(String userId1, String userId2) async {
    try {
      // Check userId1's friendship document with userId2
      final friendship1 = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .doc(userId2)
          .get();

      if (friendship1.exists) {
        final data = friendship1.data();
        if (data != null && data['openChallenge'] != null) {
          return true;
        }
      }

      // Also check userId2's friendship document with userId1 (should be symmetric)
      final friendship2 = await _firestore
          .collection('users')
          .doc(userId2)
          .collection('friends')
          .doc(userId1)
          .get();

      if (friendship2.exists) {
        final data = friendship2.data();
        if (data != null && data['openChallenge'] != null) {
          return true;
        }
      }

      return false;
    } on FirebaseException catch (e) {
      print('Firebase error checking active duel: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to check active duel. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error checking active duel: $e');
      throw Exception('Failed to check active duel. Please try again.');
    }
  }

  /// Add duel result to challenge history for both users
  Future<void> _addToChallengeHistory(
    String challengerId,
    String opponentId,
    String duelId,
    String result,
  ) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      // Determine results for each user
      String challengerResult;
      String opponentResult;
      
      switch (result) {
        case 'won':
          challengerResult = 'won';
          opponentResult = 'lost';
          break;
        case 'lost':
          challengerResult = 'lost';
          opponentResult = 'won';
          break;
        case 'tied':
          challengerResult = 'tied';
          opponentResult = 'tied';
          break;
        case 'declined':
          challengerResult = 'declined';
          opponentResult = 'declined';
          break;
        default:
          challengerResult = result;
          opponentResult = result;
      }

      // Add to challenger's challenge history
      await _firestore
          .collection('users')
          .doc(challengerId)
          .collection('friends')
          .doc(opponentId)
          .update({
        'challengeHistory': FieldValue.arrayUnion([
          {
            'duelId': duelId,
            'challengerId': challengerId,
            'result': challengerResult,
            'completedAt': now,
          }
        ]),
      });

      // Add to opponent's challenge history
      await _firestore
          .collection('users')
          .doc(opponentId)
          .collection('friends')
          .doc(challengerId)
          .update({
        'challengeHistory': FieldValue.arrayUnion([
          {
            'duelId': duelId,
            'challengerId': challengerId,
            'result': opponentResult,
            'completedAt': now,
          }
        ]),
      });
    } on FirebaseException catch (e) {
      print('Firebase error adding to challenge history: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to add to challenge history. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error adding to challenge history: $e');
      throw Exception('Failed to add to challenge history. Please try again.');
    }
  }
}
