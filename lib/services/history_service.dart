import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_points.dart';

class HistoryService {
  final FirebaseFirestore _firestore;

  HistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save weekly points to history subcollection
  /// Property 36: Weekly points persistence
  /// Property 37: History date format
  Future<void> saveWeeklyPoints(
    String userId,
    DateTime weekStart,
    int points, {
    int sessionsCompleted = 0,
    int questionsAnswered = 0,
    int correctAnswers = 0,
  }) async {
    try {
      // Format date as yyyy-MM-dd for the Monday of the week
      final dateKey = _formatDate(weekStart);

      // Calculate week end (Sunday)
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weeklyPoints = WeeklyPoints(
        date: dateKey,
        weekStart: weekStart,
        weekEnd: weekEnd,
        points: points,
        sessionsCompleted: sessionsCompleted,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .doc(dateKey)
          .set(weeklyPoints.toMap());
    } on FirebaseException catch (e) {
      print('Firebase error saving weekly points: ${e.code} - ${e.message}');
      // Don't throw - this is a background operation that shouldn't block the main flow
    } catch (e) {
      print('Error saving weekly points: $e');
      // Don't throw - this is a background operation that shouldn't block the main flow
    }
  }

  /// Get points history for a user
  /// Returns list of WeeklyPoints ordered by date descending (most recent first)
  Future<List<WeeklyPoints>> getPointsHistory(
    String userId, {
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('weekStart', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => WeeklyPoints.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      print('Firebase error getting points history: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load points history. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting points history: $e');
      throw Exception('Failed to load points history. Please try again.');
    }
  }

  // Helper method to format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
