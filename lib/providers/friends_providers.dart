import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/friends_service.dart';
import '../models/user_model.dart';

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

/// Provider for friends leaderboard sorted by weekly XP
/// Requirements: 10.6
final friendsLeaderboardSortedProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) {
      final service = ref.watch(friendsServiceProvider);
      return service.getFriendsLeaderboard(userId);
    });
