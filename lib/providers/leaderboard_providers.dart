import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/leaderboard_service.dart';

/// Provider for LeaderboardService singleton
/// Requirements: 8.4
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

/// Provider for global leaderboard (top 50 players)
/// Requirements: 8.4
final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard(50);
});

/// Provider for user's rank in global leaderboard
/// Requirements: 8.5
final userRankProvider = FutureProvider.family<int?, String>((ref, userId) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getUserRank(userId);
});

/// Provider for friends leaderboard
/// Requirements: 10.6
final friendsLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, userId) {
      final service = ref.watch(leaderboardServiceProvider);
      return service.getFriendsLeaderboard(userId);
    });
