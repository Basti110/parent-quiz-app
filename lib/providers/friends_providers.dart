import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/friends_service.dart';
import '../models/user_model.dart';
import '../models/friend.dart';
import 'duel_providers.dart';

/// Provider for FriendsService singleton
/// Requirements: 10.3, 10.6
final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService();
});

/// Provider for friends list as a stream (real-time updates)
/// Requirements: 10.3, 10.6
final friendsListProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriendsStream(userId);
});

/// Provider for friends with their friendship data (including openChallenge)
/// Requirements: 10.3, 10.6, 11.1
final friendsWithDataProvider = StreamProvider.family<List<(UserModel, Friend)>, String>((
  ref,
  userId,
) {
  final service = ref.watch(friendsServiceProvider);
  return service.getFriendsWithDataStream(userId);
});

/// Provider to check if there's an active duel between two users
/// Requirements: 11.1
final hasActiveDuelProvider = FutureProvider.family<bool, (String, String)>((
  ref,
  userIds,
) {
  final duelService = ref.watch(duelServiceProvider);
  return duelService.hasActiveDuel(userIds.$1, userIds.$2);
});

/// Provider for friends leaderboard sorted by weekly XP
/// Requirements: 10.6
final friendsLeaderboardSortedProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) {
      final service = ref.watch(friendsServiceProvider);
      return service.getFriendsLeaderboard(userId);
    });
