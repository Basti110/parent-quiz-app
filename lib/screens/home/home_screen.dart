import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

/// HomeScreen with navigation buttons and user progress display
/// Requirements: 3.1, 7.2
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final userId = ref.watch(currentUserIdProvider);

    // Watch user data if userId is available
    final userDataAsync = userId != null
        ? ref.watch(userDataProvider(userId))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParentQuiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: userDataAsync == null
          ? const Center(child: CircularProgressIndicator())
          : userDataAsync.when(
              data: (userData) => SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome, ${userData.displayName}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // User progress card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Your Progress',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  context,
                                  'Level',
                                  userData.currentLevel.toString(),
                                  Icons.star,
                                ),
                                _buildStatColumn(
                                  context,
                                  'Total XP',
                                  userData.totalXp.toString(),
                                  Icons.emoji_events,
                                ),
                                _buildStatColumn(
                                  context,
                                  'Streak',
                                  '${userData.streakCurrent} days',
                                  Icons.local_fire_department,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // XP progress to next level
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress to Level ${userData.currentLevel + 1}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (userData.totalXp % 100) / 100,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${userData.totalXp % 100}/100 XP',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Play button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/category-selection');
                      },
                      icon: const Icon(Icons.play_arrow, size: 32),
                      label: const Text('Play', style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // VS Mode button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/vs-mode-setup');
                      },
                      icon: const Icon(Icons.people, size: 32),
                      label: const Text(
                        'VS Mode',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Additional navigation buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/leaderboard');
                            },
                            icon: const Icon(Icons.leaderboard),
                            label: const Text('Leaderboard'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/friends');
                            },
                            icon: const Icon(Icons.group),
                            label: const Text('Friends'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading user data: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh by invalidating the provider
                        if (userId != null) {
                          ref.invalidate(userDataProvider(userId));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
