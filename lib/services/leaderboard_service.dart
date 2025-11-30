import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Model for leaderboard entries
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int weeklyXpCurrent;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.weeklyXpCurrent,
    required this.rank,
  });
}

/// Service for managing leaderboard queries and rankings
/// Requirements: 8.4, 8.5
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get global leaderboard sorted by weeklyXpCurrent DESC
  /// Returns top [limit] players (default 50)
  /// Requirements: 8.4
  Future<List<LeaderboardEntry>> getGlobalLeaderboard([int limit = 50]) async {
    try {
      final querySnapshot = await _firestore
          .collection('user')
          .orderBy('weeklyXpCurrent', descending: true)
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
            weeklyXpCurrent: data['weeklyXpCurrent'] as int,
            rank: rank++,
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
  /// Requirements: 8.5
  Future<int?> getUserRank(String userId) async {
    try {
      // Get the user's weekly XP
      final userDoc = await _firestore.collection('user').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data()!;
      final userWeeklyXp = userData['weeklyXpCurrent'] as int;

      // Count how many users have more weekly XP
      final higherRankedCount = await _firestore
          .collection('user')
          .where('weeklyXpCurrent', isGreaterThan: userWeeklyXp)
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

  /// Get friends leaderboard sorted by weeklyXpCurrent DESC
  /// Requirements: 10.6
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId) async {
    try {
      // Get list of friend user IDs
      final friendsSnapshot = await _firestore
          .collection('user')
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
        friendUserIds.map((id) => _firestore.collection('user').doc(id).get()),
      );

      // Convert to UserModel and sort by weeklyXpCurrent
      final users = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      users.sort((a, b) => b.weeklyXpCurrent.compareTo(a.weeklyXpCurrent));

      // Convert to LeaderboardEntry with ranks
      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final user in users) {
        entries.add(
          LeaderboardEntry(
            userId: user.id,
            displayName: user.displayName,
            weeklyXpCurrent: user.weeklyXpCurrent,
            rank: rank++,
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
}
