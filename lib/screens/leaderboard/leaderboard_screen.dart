import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/leaderboard_providers.dart';
import '../../services/leaderboard_service.dart';

/// LeaderboardScreen with Global and Friends tabs
/// Requirements: 8.5
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global', icon: Icon(Icons.public)),
            Tab(text: 'Friends', icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view leaderboard'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalLeaderboard(userId),
                _buildFriendsLeaderboard(userId),
              ],
            ),
    );
  }

  Widget _buildGlobalLeaderboard(String userId) {
    final globalLeaderboardAsync = ref.watch(globalLeaderboardProvider);
    final userRankAsync = ref.watch(userRankProvider(userId));

    return globalLeaderboardAsync.when(
      data: (entries) {
        return Column(
          children: [
            // Current user's rank card
            userRankAsync.when(
              data: (rank) => rank != null
                  ? _buildUserRankCard(rank, entries, userId)
                  : const SizedBox.shrink(),
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            const Divider(),
            // Leaderboard list
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('No players on the leaderboard yet'),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isCurrentUser = entry.userId == userId;
                        return _buildLeaderboardTile(
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
            Text('Error loading leaderboard: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(globalLeaderboardProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsLeaderboard(String userId) {
    final friendsLeaderboardAsync = ref.watch(
      friendsLeaderboardProvider(userId),
    );

    return friendsLeaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Add friends to see their rankings'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/friends');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Friends'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isCurrentUser = entry.userId == userId;
            return _buildLeaderboardTile(entry, isCurrentUser: isCurrentUser);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading friends leaderboard: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(friendsLeaderboardProvider(userId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(
    int rank,
    List<LeaderboardEntry> entries,
    String userId,
  ) {
    // Find current user's entry
    final userEntry = entries.firstWhere(
      (e) => e.userId == userId,
      orElse: () => LeaderboardEntry(
        userId: userId,
        displayName: 'You',
        weeklyXpCurrent: 0,
        rank: rank,
      ),
    );

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildRankBadge(userEntry.rank, isCurrentUser: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    userEntry.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Weekly XP', style: TextStyle(fontSize: 12)),
                Text(
                  '${userEntry.weeklyXpCurrent}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    LeaderboardEntry entry, {
    required bool isCurrentUser,
  }) {
    return ListTile(
      leading: _buildRankBadge(entry.rank, isCurrentUser: isCurrentUser),
      title: Text(
        entry.displayName,
        style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${entry.weeklyXpCurrent} XP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      tileColor: isCurrentUser
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
    );
  }

  Widget _buildRankBadge(int rank, {required bool isCurrentUser}) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade400;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown.shade300;
      icon = Icons.emoji_events;
    } else {
      badgeColor = isCurrentUser
          ? Theme.of(context).primaryColor
          : Colors.grey.shade300;
    }

    return CircleAvatar(
      backgroundColor: badgeColor,
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 20)
          : Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
