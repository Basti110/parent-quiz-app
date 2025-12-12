import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../providers/leaderboard_providers.dart';
import '../../theme/app_colors.dart';

/// LeaderboardScreen showing streak points leaderboard
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

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

    final leaderboardAsync = ref.watch(friendsLeaderboardProvider(userId));
    final userRankAsync = ref.watch(userRankProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
        centerTitle: false,
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No friends yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add friends to see them on the leaderboard',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // User's rank display
              if (userRankAsync.hasValue && userRankAsync.value != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rank: #${userRankAsync.value}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isCurrentUser = entry.userId == userId;
                    return _buildLeaderboardTile(
                      context,
                      ref,
                      userId,
                      entry,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading leaderboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    dynamic entry, {
    required bool isCurrentUser,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Assign avatar colors based on rank
    final avatarColor = _getAvatarColorForRank(entry.rank);

    // Get initials from display name
    final initials = _getInitials(entry.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.1)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary
              : (isDark ? AppColors.border : AppColors.borderLight),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank number
              SizedBox(
                width: 40,
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Avatar
              _buildAvatar(entry.avatarPath ?? entry.avatarUrl, initials, avatarColor),
              const SizedBox(width: 16),
              // Name and streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isCurrentUser
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isCurrentUser
                            ? AppColors.primary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.currentStreak} day streak',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Streak points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.streakPoints}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser
                          ? AppColors.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Head-to-head stats for friends (not for current user)
          if (!isCurrentUser)
            FutureBuilder<Map<String, int>?>(
              future: ref
                  .read(leaderboardServiceProvider)
                  .getHeadToHeadStats(currentUserId, entry.userId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final stats = snapshot.data!;
                  final myWins = stats['myWins'] ?? 0;
                  final theirWins = stats['theirWins'] ?? 0;
                  final ties = stats['ties'] ?? 0;
                  final totalDuels = stats['totalDuels'] ?? 0;

                  // Only show if there are duels
                  if (totalDuels > 0) {
                    // Determine status
                    String statusText;
                    Color statusColor;
                    if (myWins > theirWins) {
                      statusText = 'Leading';
                      statusColor = AppColors.success;
                    } else if (myWins < theirWins) {
                      statusText = 'Trailing';
                      statusColor = AppColors.error;
                    } else {
                      statusText = 'Tied';
                      statusColor = AppColors.warning;
                    }

                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Head-to-Head Record',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatItem(
                                'Wins',
                                myWins,
                                AppColors.success,
                              ),
                              const SizedBox(width: 16),
                              _buildStatItem(
                                'Losses',
                                theirWins,
                                AppColors.error,
                              ),
                              const SizedBox(width: 16),
                              _buildStatItem(
                                'Ties',
                                ties,
                                AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String initials, Color avatarColor) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: avatarColor,
        child: ClipOval(
          child: Image.asset(
            avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to initials if image fails to load
              return Container(
                width: 48,
                height: 48,
                color: avatarColor,
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: 24,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

  String _getInitials(String displayName) {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
