import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

/// QuizResultScreen displays session summary with XP earned and streak status
/// Requirements: 5.7, 6.5
class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final correctCount = args['correctCount'] as int;
    final totalCount = args['totalCount'] as int;
    final xpEarned = args['xpEarned'] as int;

    final userId = ref.watch(currentUserIdProvider);
    final userDataAsync = userId != null
        ? ref.watch(userDataProvider(userId))
        : null;

    final percentage = (correctCount / totalCount * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Complete!'),
        automaticallyImplyLeading: false,
      ),
      body: userDataAsync == null
          ? const Center(child: CircularProgressIndicator())
          : userDataAsync.when(
              data: (userData) => SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Success icon and message
                    Icon(
                      percentage >= 70 ? Icons.celebration : Icons.emoji_events,
                      size: 100,
                      color: percentage >= 70 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getResultMessage(percentage),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Score card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              'Your Score',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$correctCount / $totalCount',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$percentage% Correct',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // XP earned card
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 32,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'XP Earned',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '+$xpEarned XP',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildXPBreakdown(
                              context,
                              correctCount,
                              totalCount,
                              xpEarned,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Streak status card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 32,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Streak',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${userData.streakCurrent} Days',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Longest: ${userData.streakLongest} days',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/category-selection',
                          (route) => route.settings.name == '/home',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(fontSize: 18),
                      ),
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
                  ],
                ),
              ),
            ),
    );
  }

  String _getResultMessage(int percentage) {
    if (percentage == 100) {
      return 'Perfect Score! 🎉';
    } else if (percentage >= 80) {
      return 'Excellent Work! 🌟';
    } else if (percentage >= 60) {
      return 'Good Job! 👍';
    } else {
      return 'Keep Learning! 📚';
    }
  }

  Widget _buildXPBreakdown(
    BuildContext context,
    int correctCount,
    int totalCount,
    int totalXP,
  ) {
    final incorrectCount = totalCount - correctCount;

    // Calculate approximate breakdown
    final correctXP = correctCount * 10;
    final incorrectXP = incorrectCount * 5; // Assuming explanation viewed
    final sessionBonus = totalCount == 5 ? 10 : 25;
    final perfectBonus = correctCount == totalCount ? 10 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'XP Breakdown:',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBreakdownRow(
          context,
          'Correct answers',
          '$correctCount × 10',
          correctXP,
        ),
        if (incorrectCount > 0)
          _buildBreakdownRow(
            context,
            'Incorrect (with explanation)',
            '$incorrectCount × 5',
            incorrectXP,
          ),
        _buildBreakdownRow(
          context,
          'Session bonus',
          '$totalCount questions',
          sessionBonus,
        ),
        if (perfectBonus > 0)
          _buildBreakdownRow(
            context,
            'Perfect bonus',
            'All correct!',
            perfectBonus,
          ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    String detail,
    int xp,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                detail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          Text(
            '+$xp XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
