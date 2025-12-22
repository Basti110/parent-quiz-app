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
          .collection('users')
          .where('friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    } on FirebaseException catch (e) {
      print(
        'Firebase error finding user by friend code: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to find user. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error finding user by friend code: $e');
      throw Exception('Failed to find user. Please try again.');
    }
  }

  /// Send a friend request by creating a request document in receiver's requests subcollection
  /// Property 29: Friend document creation
  /// Requirements: 10.4
  Future<void> sendFriendRequest(String userId, String friendUserId) async {
    try {
      // Prevent self-friending
      if (userId == friendUserId) {
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if friendship already exists
      final existingFriend = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendUserId)
          .get();

      if (existingFriend.exists) {
        throw Exception('Already friends with this user');
      }

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('requests')
          .doc(userId)
          .get();

      if (existingRequest.exists) {
        throw Exception('Friend request already sent');
      }

      final now = DateTime.now();

      // Create incoming request for receiver in their requests subcollection
      final requestData = {
        'fromUserId': userId,
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('requests')
          .doc(userId)
          .set(requestData);
    } on FirebaseException catch (e) {
      print('Firebase error sending friend request: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to send friend request. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request by creating friendship documents and deleting the request
  /// Requirements: 10.4
  Future<void> acceptFriendRequest(String userId, String requesterUserId) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Create friendship document for user (who is accepting)
      final userFriend = Friend(
        friendUserId: requesterUserId,
        status: 'accepted',
        createdAt: now,
        createdBy: requesterUserId, // Original requester
      );

      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(requesterUserId),
        userFriend.toMap(),
      );

      // Create friendship document for friend (who sent the request)
      final friendFriend = Friend(
        friendUserId: userId,
        status: 'accepted',
        createdAt: now,
        createdBy: requesterUserId, // Original requester
      );

      batch.set(
        _firestore
            .collection('users')
            .doc(requesterUserId)
            .collection('friends')
            .doc(userId),
        friendFriend.toMap(),
      );

      // Delete the request document - the document ID is the requester's ID
      batch.delete(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('requests')
            .doc(requesterUserId),
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      print('Firebase error accepting friend request: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to accept friend request. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request by deleting the request document
  /// Requirements: 10.4
  Future<void> declineFriendRequest(String userId, String requesterUserId) async {
    try {
      // Delete the request document - the document ID is the requester's ID
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc(requesterUserId)
          .delete();
    } on FirebaseException catch (e) {
      print('Firebase error declining friend request: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to decline friend request. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error declining friend request: $e');
      rethrow;
    }
  }

  /// Get list of accepted friends as a one-time fetch
  /// Property 7: Friend list ordering - returns friends sorted alphabetically by display name
  /// Requirements: 10.3
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      // Get all friend documents (all are accepted in this collection)
      final friendsSnapshot = await _firestore
          .collection('users')
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
        friendUserIds.map((id) => _firestore.collection('users').doc(id).get()),
      );

      // Convert to UserModel
      final friends = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      // Sort alphabetically by display name
      friends.sort((a, b) => a.displayName.compareTo(b.displayName));

      return friends;
    } on FirebaseException catch (e) {
      print('Firebase error getting friends: ${e.code} - ${e.message}');
      throw Exception(
        'Failed to load friends. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting friends: $e');
      throw Exception('Failed to load friends. Please try again.');
    }
  }

  /// Get list of accepted friends as a stream for real-time updates
  /// Property 7: Friend list ordering - returns friends sorted alphabetically by display name
  /// Requirements: 10.3
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('users')
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
              (id) => _firestore.collection('users').doc(id).get(),
            ),
          );

          // Convert to UserModel
          final friends = userDocs
              .where((doc) => doc.exists)
              .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
              .toList();

          // Sort alphabetically by display name
          friends.sort((a, b) => a.displayName.compareTo(b.displayName));

          return friends;
        });
  }

  /// Get friends leaderboard sorted by streakPoints
  /// Property 30: Friends leaderboard sorting
  /// Requirements: 10.6
  Future<List<UserModel>> getFriendsLeaderboard(String userId) async {
    try {
      // Get list of friends
      final friends = await getFriends(userId);

      // Sort by streakPoints in descending order
      friends.sort((a, b) => b.streakPoints.compareTo(a.streakPoints));

      return friends;
    } on FirebaseException catch (e) {
      print(
        'Firebase error getting friends leaderboard: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Failed to load friends leaderboard. Please check your connection and try again.',
      );
    } catch (e) {
      print('Error getting friends leaderboard: $e');
      rethrow;
    }
  }

  /// Get accepted friends with their friendship data (including openChallenge) as a stream
  /// Requirements: 10.3, 11.1
  Stream<List<(UserModel, Friend)>> getFriendsWithDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return <(UserModel, Friend)>[];
          }

          // Convert friendship documents to Friend objects
          final friendships = snapshot.docs
              .map((doc) => Friend.fromMap(doc.data()))
              .toList();

          // Extract friend user IDs
          final friendUserIds = friendships
              .map((friendship) => friendship.friendUserId)
              .toList();

          // Fetch all friend user documents
          final userDocs = await Future.wait(
            friendUserIds.map(
              (id) => _firestore.collection('users').doc(id).get(),
            ),
          );

          // Combine user data with friendship data
          final friendsWithData = <(UserModel, Friend)>[];
          for (int i = 0; i < userDocs.length; i++) {
            final userDoc = userDocs[i];
            if (userDoc.exists) {
              final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
              final friendship = friendships[i];
              friendsWithData.add((user, friendship));
            }
          }

          // Sort alphabetically by display name
          friendsWithData
              .sort((a, b) => a.$1.displayName.compareTo(b.$1.displayName));

          return friendsWithData;
        });
  }

  /// Get pending friend requests (incoming) as a stream
  /// Requirements: 10.4
  Stream<List<UserModel>> getPendingRequestsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('requests')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <UserModel>[];
      }

      // Extract requester user IDs
      final requesterIds =
          snapshot.docs.map((doc) => doc.data()['fromUserId'] as String).toList();

      // Fetch all requester user documents
      final userDocs = await Future.wait(
        requesterIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        ),
      );

      // Convert to UserModel
      final requesters = userDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      return requesters;
    });
  }

  /// Get friendship document for head-to-head statistics
  /// Requirements: 15a.3, 15a.4
  Future<Friend?> getFriendshipDocument(String userId, String friendId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Friend.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      print(
        'Firebase error getting friendship document: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      print('Error getting friendship document: $e');
      return null;
    }
  }
}
