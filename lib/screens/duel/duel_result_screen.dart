import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/duel_model.dart';
import '../../models/question.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/duel_providers.dart';
import '../../theme/app_colors.dart';

/// DuelResultScreen shows the results of a completed duel
/// Requirements: 13.1, 13.2, 13.3, 13.4, 14.5
class DuelResultScreen extends ConsumerStatefulWidget {
  const DuelResultScreen({super.key});

  @override
  ConsumerState<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends ConsumerState<DuelResultScreen> {
  DuelModel? _duel;
  UserModel? _challenger;
  UserModel? _opponent;
  List<Question>? _questions;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_duel == null) {
      _loadDuelResults();
    }
  }

  Future<void> _loadDuelResults() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final duelId = args['duelId'] as String;

    try {
      // Load duel data
      final duelService = ref.read(duelServiceProvider);
      final duel = await duelService.getDuel(duelId);

      // Load user data
      final userService = ref.read(userServiceProvider);
      final challenger = await userService.getUserData(duel.challengerId);
      final opponent = await userService.getUserData(duel.opponentId);

      // Load questions
      final firestore = FirebaseFirestore.instance;
      final questions = <Question>[];
      for (final questionId in duel.questionIds) {
        final doc =
            await firestore.collection('questions').doc(questionId).get();
        if (doc.exists) {
          questions.add(Question.fromMap(doc.data()!, doc.id));
        }
      }

      setState(() {
        _duel = duel;
        _challenger = challenger;
        _opponent = opponent;
        _questions = questions;
        _isLoading = false;
      });

      // Clear the openChallenge field now that user is viewing results
      // This allows them to create new challenges
      await duelService.clearOpenChallenge(duel.challengerId, duel.opponentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading results: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading ||
        _duel == null ||
        _challenger == null ||
        _opponent == null ||
        _questions == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Duel Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userId = ref.read(currentUserIdProvider);
    final winnerId = _duel!.getWinnerId();
    final isTie = winnerId == null;
    final userWon = winnerId == userId;

    // Determine if both players have completed
    final bothCompleted = _duel!.challengerCompletedAt != null &&
        _duel!.opponentCompletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Results'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result header
            if (bothCompleted) ...[
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTie
                        ? [
                            AppColors.info.withValues(alpha: 0.2),
                            AppColors.info.withValues(alpha: 0.1),
                          ]
                        : userWon
                            ? [
                                AppColors.success.withValues(alpha: 0.2),
                                AppColors.success.withValues(alpha: 0.1),
                              ]
                            : [
                                AppColors.error.withValues(alpha: 0.2),
                                AppColors.error.withValues(alpha: 0.1),
                              ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTie
                        ? AppColors.info
                        : userWon
                            ? AppColors.success
                            : AppColors.error,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isTie
                          ? Icons.handshake
                          : userWon
                              ? Icons.emoji_events
                              : Icons.sentiment_neutral,
                      size: 48,
                      color: isTie
                          ? AppColors.info
                          : userWon
                              ? AppColors.success
                              : AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTie
                          ? 'It\'s a Tie!'
                          : userWon
                              ? 'You Won!'
                              : 'You Lost',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isTie
                            ? AppColors.info
                            : userWon
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.info,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for opponent...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Results will be available when both players complete the duel',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Player scores
            Row(
              children: [
                Expanded(
                  child: _buildPlayerCard(
                    context,
                    _challenger!,
                    _duel!.challengerScore,
                    _duel!.challengerCompletedAt != null,
                    winnerId == _duel!.challengerId && !isTie,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlayerCard(
                    context,
                    _opponent!,
                    _duel!.opponentScore,
                    _duel!.opponentCompletedAt != null,
                    winnerId == _duel!.opponentId && !isTie,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question breakdown (only if both completed)
            if (bothCompleted) ...[
              Text(
                'Question Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildQuestionBreakdown(isDarkMode),
            ],

            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    UserModel player,
    int score,
    bool completed,
    bool isWinner,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner
              ? AppColors.success
              : isDarkMode
                  ? AppColors.textSecondary.withValues(alpha: 0.2)
                  : AppColors.borderLight,
          width: isWinner ? 3 : 1,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isWinner
                    ? AppColors.success
                    : isDarkMode
                        ? AppColors.textSecondary.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: player.avatarUrl != null
                  ? Image.asset(
                      player.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(isDarkMode);
                      },
                    )
                  : _buildDefaultAvatar(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),

          // Winner badge
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Winner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (isWinner) const SizedBox(height: 8),

          // Name
          Text(
            player.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Score
          if (completed)
            Text(
              '$score / 5',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isWinner
                    ? AppColors.success
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            )
          else
            Text(
              '- / 5',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? AppColors.textSecondary.withValues(alpha: 0.2)
          : AppColors.borderLight,
      child: Icon(
        Icons.person,
        size: 30,
        color: isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
      ),
    );
  }

  List<Widget> _buildQuestionBreakdown(bool isDarkMode) {
    final userId = ref.read(currentUserIdProvider);
    final isChallenger = _duel!.challengerId == userId;
    final userAnswers =
        isChallenger ? _duel!.challengerAnswers : _duel!.opponentAnswers;
    final opponentAnswers =
        isChallenger ? _duel!.opponentAnswers : _duel!.challengerAnswers;

    return List.generate(_questions!.length, (index) {
      final question = _questions![index];
      final userCorrect = userAnswers[question.id] ?? false;
      final opponentCorrect = opponentAnswers[question.id] ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? AppColors.textSecondary.withValues(alpha: 0.2)
                : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Question number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isDarkMode
                        ? AppColors.primaryLight
                        : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Question text (truncated)
            Expanded(
              child: Text(
                question.text.replaceAll(RegExp(r'[*_#]'), '').trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),

            // User result
            Icon(
              userCorrect ? Icons.check_circle : Icons.cancel,
              color: userCorrect ? AppColors.success : AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),

            // VS text
            Text(
              'vs',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),

            // Opponent result
            Icon(
              opponentCorrect ? Icons.check_circle : Icons.cancel,
              color: opponentCorrect ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ],
        ),
      );
    });
  }
}
