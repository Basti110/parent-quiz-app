import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vs_mode_session.dart';
import '../../models/vs_mode_result.dart';
import '../../services/vs_mode_service.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';

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

  /// Determines if a player has the faster time
  /// Returns true if the player has a faster time than their opponent
  bool _isFasterTime(int? playerATime, int? playerBTime, {required bool isPlayerA}) {
    // If either time is missing, no one is faster
    if (playerATime == null || playerBTime == null) return false;
    
    // If times are equal, no one is faster
    if (playerATime == playerBTime) return false;
    
    // Check if this player is faster
    if (isPlayerA) {
      return playerATime < playerBTime;
    } else {
      return playerBTime < playerATime;
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
      body: Column(
        children: [
          // Gradient bar at top
          Container(
            height: 8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00897B),
                  Color(0xFF26C6DA),
                  Color(0xFF42A5F5),
                  Color(0xFF5C6BC0),
                  Color(0xFF7E57C2),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // VS Mode display with scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Player A
                      _buildPlayerResult(
                        context: context,
                        playerName: session.playerAName,
                        score: session.playerAScore,
                        totalQuestions: session.questionsPerPlayer,
                        isWinner: result.outcome == VSModeOutcome.playerAWins,
                        timeSeconds: result.playerATimeSeconds,
                        isFasterTime: _isFasterTime(
                          result.playerATimeSeconds,
                          result.playerBTimeSeconds,
                          isPlayerA: true,
                        ),
                      ),

                      // VS text
                      Text(
                        'VS',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade300,
                          letterSpacing: 2,
                        ),
                      ),

                      // Player B
                      _buildPlayerResult(
                        context: context,
                        playerName: session.playerBName,
                        score: session.playerBScore,
                        totalQuestions: session.questionsPerPlayer,
                        isWinner: result.outcome == VSModeOutcome.playerBWins,
                        timeSeconds: result.playerBTimeSeconds,
                        isFasterTime: _isFasterTime(
                          result.playerATimeSeconds,
                          result.playerBTimeSeconds,
                          isPlayerA: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Winner announcement
                  _buildWinnerSection(result),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            backgroundColor: const Color(0xFF5C9EFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Play Again'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResult({
    required BuildContext context,
    required String playerName,
    required int score,
    required int totalQuestions,
    required bool isWinner,
    int? timeSeconds,
    bool isFasterTime = false,
  }) {
    final theme = Theme.of(context);
    final borderColor = isWinner 
        ? const Color(0xFF00897B) 
        : Colors.grey.shade300;

    return Column(
      children: [
        // Avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: isWinner ? 4 : 3,
            ),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Player name
        Text(
          playerName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Score display
        Text(
          '$score/$totalQuestions',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF5C6BC0),
            fontWeight: FontWeight.w600,
          ),
        ),

        // Time display
        if (timeSeconds != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                VSModeResult(
                  playerAName: '',
                  playerBName: '',
                  playerAScore: 0,
                  playerBScore: 0,
                  outcome: VSModeOutcome.tie,
                ).formatTime(timeSeconds) ?? '--:--',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (isFasterTime) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.flash_on,
                  size: 16,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ],

        // Winner crown
        if (isWinner) ...[
          const SizedBox(height: 8),
          const Icon(
            Icons.emoji_events,
            color: AppColors.crown,
            size: 32,
          ),
        ],
      ],
    );
  }

  Widget _buildWinnerSection(VSModeResult result) {
    final isTie = result.outcome == VSModeOutcome.tie;
    final isPerfectTie = isTie && 
        result.playerATimeSeconds != null && 
        result.playerBTimeSeconds != null &&
        result.playerATimeSeconds == result.playerBTimeSeconds;

    return Card(
      color: isTie ? AppColors.warningLight : AppColors.primaryLightest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              isTie ? Icons.handshake : Icons.emoji_events,
              size: 64,
              color: isTie ? AppColors.warning : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isTie ? (isPerfectTie ? "Perfect Tie!" : "It's a Tie!") : '${result.winnerName} Wins!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTie ? AppColors.warning : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.wonByTime && !isTie) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flash_on,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Won by speed!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
            color: AppColors.warningLight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 40, color: AppColors.accent),
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
                        color: AppColors.accent,
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
      color: AppColors.warningLight,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.stars, size: 40, color: AppColors.accent),
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
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
