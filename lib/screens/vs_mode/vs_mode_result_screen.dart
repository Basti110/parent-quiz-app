import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vs_mode_session.dart';
import '../../models/vs_mode_result.dart';
import '../../services/vs_mode_service.dart';
import '../../providers/auth_providers.dart';

/// VSModeResultScreen displays the results of a VS Mode duel
/// Requirements: 9.5
class VSModeResultScreen extends ConsumerStatefulWidget {
  const VSModeResultScreen({super.key});

  @override
  ConsumerState<VSModeResultScreen> createState() => _VSModeResultScreenState();
}

class _VSModeResultScreenState extends ConsumerState<VSModeResultScreen> {
  bool _isUpdatingStats = false;
  bool _statsUpdated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsUpdated) {
      _updateDuelStats();
    }
  }

  Future<void> _updateDuelStats() async {
    if (_isUpdatingStats || _statsUpdated) return;

    setState(() {
      _isUpdatingStats = true;
    });

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final session = args['session'] as VSModeSession;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() {
        _isUpdatingStats = false;
        _statsUpdated = true;
      });
      return;
    }

    try {
      final vsModeService = VSModeService();
      final result = vsModeService.calculateResult(session);

      // Get current user's data to determine which player they are
      final userService = ref.read(userServiceProvider);
      final userData = await userService.getUserData(userId);

      // Update stats only if the logged-in user is one of the players
      if (userData.displayName == session.playerAName ||
          userData.displayName == session.playerBName) {
        await vsModeService.updateDuelStats(
          userId: userId,
          result: result,
          userPlayerName: userData.displayName,
        );
      }

      setState(() {
        _isUpdatingStats = false;
        _statsUpdated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating stats: $e')));
      }
      setState(() {
        _isUpdatingStats = false;
        _statsUpdated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final session = args['session'] as VSModeSession;

    final vsModeService = VSModeService();
    final result = vsModeService.calculateResult(session);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner announcement
            _buildWinnerSection(result),
            const SizedBox(height: 32),

            // Player scores
            _buildPlayerScoreCard(
              playerName: session.playerAName,
              score: session.playerAScore,
              totalQuestions: session.questionsPerPlayer,
              isWinner: result.outcome == VSModeOutcome.playerAWins,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildPlayerScoreCard(
              playerName: session.playerBName,
              score: session.playerBScore,
              totalQuestions: session.questionsPerPlayer,
              isWinner: result.outcome == VSModeOutcome.playerBWins,
              color: Colors.green,
            ),
            const SizedBox(height: 32),

            // XP earned (for logged-in user only)
            _buildXPSection(session, result),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Home'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/vs-mode-setup',
                        (route) => route.settings.name == '/home',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerSection(VSModeResult result) {
    final isTie = result.outcome == VSModeOutcome.tie;

    return Card(
      color: isTie ? Colors.amber.shade50 : Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              isTie ? Icons.handshake : Icons.emoji_events,
              size: 64,
              color: isTie ? Colors.amber.shade700 : Colors.purple.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              isTie ? "It's a Tie!" : '${result.winnerName} Wins!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTie ? Colors.amber.shade700 : Colors.purple.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScoreCard({
    required String playerName,
    required int score,
    required int totalQuestions,
    required bool isWinner,
    required MaterialColor color,
  }) {
    return Card(
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isWinner ? color.shade700 : color.shade200,
          width: isWinner ? 3 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.person, size: 40, color: color.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        playerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isWinner) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct: $score / $totalQuestions',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Text(
              '$score',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPSection(VSModeSession session, VSModeResult result) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const SizedBox.shrink();
    }

    // Calculate XP based on outcome
    int xpEarned = 0;
    String xpMessage = '';

    if (result.isTie()) {
      xpEarned = 1;
      xpMessage = '+1 Duel Point (Tie)';
    } else {
      // Check if logged-in user won
      final userDataAsync = ref.watch(userDataProvider(userId));
      return userDataAsync.when(
        data: (userData) {
          if (result.isPlayerWinner(userData.displayName)) {
            xpEarned = 3;
            xpMessage = '+3 Duel Points (Win)';
          } else if (result.isPlayerLoser(userData.displayName)) {
            xpEarned = 0;
            xpMessage = 'No Duel Points (Loss)';
          } else {
            // User is not one of the players
            return const SizedBox.shrink();
          }

          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.stars, size: 40, color: Colors.orange.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duel Points Earned',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          xpMessage,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  if (xpEarned > 0)
                    Text(
                      '+$xpEarned',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.stars, size: 40, color: Colors.orange.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duel Points Earned',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(xpMessage, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (xpEarned > 0)
              Text(
                '+$xpEarned',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
