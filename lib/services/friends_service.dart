import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/friend.dart';

/// Service for managing friend relationships and friend-related queries
/// Requirements: 10.3, 10.4, 10.6
class FriendsService {
  final FirebaseFirestore _firestore;

  FriendsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Find a user by their friend code
  /// Property 28: Friend code lookup - returns at most one user
  /// Requirements: 10.3
  Future<UserModel?> findUserByFriendCode(String friendCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('user')
          .where('friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Failed to find user by friend code: $e');
    }
  }

  /// Add a friend by creating a friend document
  /// Property 29: Friend document creation
  /// Requirements: 10.4
  Future<void> addFriend(String userId, String friendUserId) async {
    try {
      // Prevent self-friending
      if (userId == friendUserId) {
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if friendship already exists
      final existingFriend = await _firestore
          .collection('user')
          .doc(userId)
          .collection('friends')
          .doc(friendUserId)
          .get();

      if (existingFriend.exists) {
        throw Exception('Already friends with this user');
      }

      // Create friend document
      final friend = Friend(
        friendUserId: friendUserId,
        status: 'accepted',
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      await _firestore
          .collection('user')
          .doc(userId)
          .collection('friends')
          .doc(friendUserId)
          .set(friend.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of friends as a one-time fetch
  /// Requirements: 10.3
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      // Get friend documents
      final friendsSnapshot = await _firestore
          .collection('user')
          .doc(userId)
          .collection('friends')
          .get();

      if (friendsSnapshot.docs.isEmpty) {
        return [];
      }

      // Extract friend user IDs
      final friendUserIds = friendsSnapshot.docs
          .map((doc) => doc.data()['friendUserId'] as String)
          .toList();

      // Fetch all friend user documents
      final userDocs = await Future.wait(
        friendUserIds.map((id) => _firestore.collection('user').doc(id).get()),
      );

      // Convert to UserModel
      final friends = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      return friends;
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  /// Get list of friends as a stream for real-time updates
  /// Requirements: 10.3
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('user')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return <UserModel>[];
          }

          // Extract friend user IDs
          final friendUserIds = snapshot.docs
              .map((doc) => doc.data()['friendUserId'] as String)
              .toList();

          // Fetch all friend user documents
          final userDocs = await Future.wait(
            friendUserIds.map(
              (id) => _firestore.collection('user').doc(id).get(),
            ),
          );

          // Convert to UserModel
          final friends = userDocs
              .where((doc) => doc.exists)
              .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
              .toList();

          return friends;
        });
  }

  /// Get friends leaderboard sorted by weeklyXpCurrent
  /// Property 30: Friends leaderboard sorting
  /// Requirements: 10.6
  Future<List<UserModel>> getFriendsLeaderboard(String userId) async {
    try {
      // Get list of friends
      final friends = await getFriends(userId);

      // Sort by weeklyXpCurrent in descending order
      friends.sort((a, b) => b.weeklyXpCurrent.compareTo(a.weeklyXpCurrent));

      return friends;
    } catch (e) {
      throw Exception('Failed to get friends leaderboard: $e');
    }
  }
}
