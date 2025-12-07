import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';

// Temporary hardcoded data model for duel stats
class DuelStats {
  final String userId;
  final String displayName;
  final String avatarInitials;
  final int wins;
  final int losses;
  final int ties;
  final bool isCurrentUser;

  DuelStats({
    required this.userId,
    required this.displayName,
    required this.avatarInitials,
    required this.wins,
    required this.losses,
    required this.ties,
    this.isCurrentUser = false,
  });

  int get totalGames => wins + losses + ties;
}

/// LeaderboardScreen showing friends' duel statistics
/// Requirements: 8.5
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  // Hardcoded example data
  List<DuelStats> _getHardcodedStats(String currentUserId) {
    return [
      DuelStats(
        userId: 'user1',
        displayName: 'Maria A.',
        avatarInitials: 'MA',
        wins: 15,
        losses: 3,
        ties: 2,
      ),
      DuelStats(
        userId: currentUserId,
        displayName: 'You',
        avatarInitials: 'ME',
        wins: 8,
        losses: 5,
        ties: 1,
        isCurrentUser: true,
      ),
      DuelStats(
        userId: 'user3',
        displayName: 'Thomas K.',
        avatarInitials: 'TK',
        wins: 7,
        losses: 6,
        ties: 3,
      ),
      DuelStats(
        userId: 'user4',
        displayName: 'Sarah M.',
        avatarInitials: 'SM',
        wins: 5,
        losses: 8,
        ties: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.leaderboard)),
        body: Center(child: Text(l10n.pleaseLoginToViewLeaderboard)),
      );
    }

    final stats = _getHardcodedStats(userId);
    // Sort by wins (descending)
    stats.sort((a, b) => b.wins.compareTo(a.wins));

    return Scaffold(
      appBar: AppBar(
        title: const Text('THIS WEEK\'S LEADERBOARD'),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildLeaderboardTile(context, stat, rank: index + 1);
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    DuelStats stat, {
    required int rank,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Assign avatar colors based on rank
    final avatarColor = _getAvatarColorForRank(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stat.isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.1)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stat.isCurrentUser
              ? AppColors.primary
              : (isDark ? AppColors.border : AppColors.borderLight),
          width: stat.isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stat.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          CircleAvatar(
            backgroundColor: avatarColor,
            radius: 24,
            child: Text(
              stat.avatarInitials,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            child: Text(
              stat.displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: stat.isCurrentUser
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: stat.isCurrentUser
                    ? AppColors.primary
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          // Stats
          Text(
            '${stat.wins}W / ${stat.losses}L / ${stat.ties}T',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: stat.isCurrentUser
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColorForRank(int rank) {
    switch (rank) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
