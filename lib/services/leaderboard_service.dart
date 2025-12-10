import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Model for leaderboard entries
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int streakPoints;
  final int currentStreak;
  final int rank;
  final String? avatarUrl;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.streakPoints,
    required this.currentStreak,
    required this.rank,
    this.avatarUrl,
  });
}

/// Service for managing leaderboard queries and rankings
/// Requirements: 8.4, 8.5
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get global leaderboard sorted by streakPoints DESC
  /// Returns top [limit] players (default 50)
  /// Requirements: 7.1, 7.2, 7.3, 7.4
  Future<List<LeaderboardEntry>> getGlobalLeaderboard([int limit = 50]) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakPoints', descending: true)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        entries.add(
          LeaderboardEntry(
            userId: doc.id,
            displayName: data['displayName'] as String,
            streakPoints: data['streakPoints'] as int? ?? 0,
            currentStreak: data['streakCurrent'] as int? ?? 0,
            rank: rank++,
            avatarUrl: data['avatarUrl'] as String?,
          ),
        );
      }

      return entries;
    } on FirebaseException catch (e) {
      print(
        'Firebase error loading global leaderboard: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to load leaderboard. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading global leaderboard: $e');
      throw Exception('Failed to load leaderboard. Please try again.');
    }
  }

  /// Get current user's rank in the global leaderboard
  /// Returns the user's position (1-based) or null if not found
  /// Requirements: 7.4
  Future<int?> getUserRank(String userId) async {
    try {
      // Get the user's streak points
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data()!;
      final userStreakPoints = userData['streakPoints'] as int? ?? 0;

      // Count how many users have more streak points
      final higherRankedCount = await _firestore
          .collection('users')
          .where('streakPoints', isGreaterThan: userStreakPoints)
          .count()
          .get();

      // Rank is count of higher-ranked users + 1
      return higherRankedCount.count! + 1;
    } on FirebaseException catch (e) {
      print('Firebase error getting user rank: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to get your rank. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting user rank: $e');
      throw Exception('Failed to get your rank. Please try again.');
    }
  }

  /// Get friends leaderboard sorted by streakPoints DESC
  /// Requirements: 7.1, 7.2, 7.3
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId) async {
    try {
      // Get list of friend user IDs
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      if (friendsSnapshot.docs.isEmpty) {
        return [];
      }

      final friendUserIds = friendsSnapshot.docs
          .map((doc) => doc.data()['friendUserId'] as String)
          .toList();

      // Add current user to the list
      friendUserIds.add(userId);

      // Fetch all friend user documents
      final userDocs = await Future.wait(
        friendUserIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      // Convert to UserModel and sort by streakPoints
      final users = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      users.sort((a, b) => b.streakPoints.compareTo(a.streakPoints));

      // Convert to LeaderboardEntry with ranks
      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final user in users) {
        entries.add(
          LeaderboardEntry(
            userId: user.id,
            displayName: user.displayName,
            streakPoints: user.streakPoints,
            currentStreak: user.streakCurrent,
            rank: rank++,
            avatarUrl: user.avatarUrl,
          ),
        );
      }

      return entries;
    } on FirebaseException catch (e) {
      print(
        'Firebase error loading friends leaderboard: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to load friends leaderboard. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error loading friends leaderboard: $e');
      throw Exception('Failed to load friends leaderboard. Please try again.');
    }
  }

  /// Get head-to-head statistics for a specific friend
  /// Returns null if friendship doesn't exist
  /// Requirements: 15a.3, 15a.4
  Future<Map<String, int>?> getHeadToHeadStats(
    String userId,
    String friendUserId,
  ) async {
    try {
      final friendDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendUserId)
          .get();

      if (!friendDoc.exists) {
        return null;
      }

      final data = friendDoc.data()!;
      return {
        'myWins': data['myWins'] as int? ?? 0,
        'theirWins': data['theirWins'] as int? ?? 0,
        'ties': data['ties'] as int? ?? 0,
        'totalDuels': data['totalDuels'] as int? ?? 0,
      };
    } on FirebaseException catch (e) {
      print(
        'Firebase error getting head-to-head stats: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to load head-to-head stats. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting head-to-head stats: $e');
      throw Exception('Failed to load head-to-head stats. Please try again.');
    }
  }
}
