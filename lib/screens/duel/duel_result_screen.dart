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

      // Only mark results as viewed if both players have completed
      // This ensures the "View Results" button stays visible until both have seen the final results
      final bothCompleted = duel.challengerCompletedAt != null && 
                           duel.opponentCompletedAt != null;
      
      if (bothCompleted) {
        final userId = ref.read(currentUserIdProvider);
        await duelService.markResultsViewed(duelId, userId!);
      }
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

    // Determine which player is the current user
    final isChallenger = _duel!.challengerId == userId;
    final currentUser = isChallenger ? _challenger! : _opponent!;
    final otherUser = isChallenger ? _opponent! : _challenger!;
    final currentUserScore = isChallenger ? _duel!.challengerScore : _duel!.opponentScore;
    final otherUserScore = isChallenger ? _duel!.opponentScore : _duel!.challengerScore;
    final currentUserCompleted = isChallenger 
        ? _duel!.challengerCompletedAt != null 
        : _duel!.opponentCompletedAt != null;
    final otherUserCompleted = isChallenger 
        ? _duel!.opponentCompletedAt != null 
        : _duel!.challengerCompletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Results'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // VS Mode display with scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Current user
                      _buildPlayerAvatar(
                        context: context,
                        player: currentUser,
                        score: currentUserScore,
                        completed: currentUserCompleted,
                        isWinner: winnerId == userId && !isTie,
                        isDarkMode: isDarkMode,
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

                      // Other user
                      _buildPlayerAvatar(
                        context: context,
                        player: otherUser,
                        score: otherUserScore,
                        completed: otherUserCompleted,
                        isWinner: winnerId != null && winnerId != userId && !isTie,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Result announcement
                  if (bothCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: isTie
                            ? const Color(0xFF5C9EFF).withValues(alpha: 0.15)
                            : userWon
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTie
                              ? const Color(0xFF5C9EFF)
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
                                ? const Color(0xFF5C9EFF)
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
                                  ? const Color(0xFF5C9EFF)
                                  : userWon
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
                          const Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: AppColors.info,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Waiting for ${otherUser.displayName}...',
                            style: const TextStyle(
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
                    const SizedBox(height: 32),
                  ],

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
                        backgroundColor: const Color(0xFF5C9EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar({
    required BuildContext context,
    required UserModel player,
    required int score,
    required bool completed,
    required bool isWinner,
    required bool isDarkMode,
  }) {
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
            child: ClipOval(
              child: (player.avatarPath ?? player.avatarUrl) != null
                  ? Image.asset(
                      player.avatarPath ?? player.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade600,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Player name
        Text(
          player.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Score display and winner crown on same row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              completed ? '$score / 5' : '- / 5',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF5C6BC0),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isWinner) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.emoji_events,
                color: AppColors.crown,
                size: 28,
              ),
            ],
          ],
        ),
      ],
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
          color: isDarkMode 
              ? const Color(0xFF2A3647) 
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Question number in circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00897B),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),

            // User result
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: userCorrect 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFE57373),
                shape: BoxShape.circle,
              ),
              child: Icon(
                userCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),

            // VS text
            Text(
              'vs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),

            // Opponent result
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: opponentCorrect 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFE57373),
                shape: BoxShape.circle,
              ),
              child: Icon(
                opponentCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      );
    });
  }
}
