import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/duel_model.dart';
import '../../models/question.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/duel_providers.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingResults(e.toString()))),
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
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenTitleDuelResults)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loadingResults),
            ],
          ),
        ),
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
        title: Text(AppLocalizations.of(context)!.screenTitleDuelResults),
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

                  // Test indicator to verify we're using the updated duel result screen
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      '🎉 DUEL RESULT - EXPANDABLE FRAGEN JETZT AKTIV! 🎉',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

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
                        AppLocalizations.of(context)!.vsText,
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
                                ? AppLocalizations.of(context)!.tie
                                : userWon
                                    ? AppLocalizations.of(context)!.youWon
                                    : AppLocalizations.of(context)!.youLost,
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
                            AppLocalizations.of(context)!.waitingForPlayerToComplete(otherUser.displayName),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.resultsAvailableWhenBothComplete,
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
                      AppLocalizations.of(context)!.questionBreakdown,
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
                      child: Text(
                        AppLocalizations.of(context)!.done,
                        style: const TextStyle(
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
              completed ? AppLocalizations.of(context)!.questionProgress(score, 5) : AppLocalizations.of(context)!.questionProgress(0, 5).replaceFirst('0', '-'),
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



  /// Build expandable question breakdown showing detailed results
  List<Widget> _buildQuestionBreakdown(bool isDarkMode) {
    final userId = ref.read(currentUserIdProvider);
    final isChallenger = _duel!.challengerId == userId;
    final userAnswers =
        isChallenger ? _duel!.challengerAnswers : _duel!.opponentAnswers;
    final opponentAnswers =
        isChallenger ? _duel!.opponentAnswers : _duel!.challengerAnswers;

    return List.generate(_questions!.length, (index) {
      final question = _questions![index];
      final userAnswerData = userAnswers[question.id];
      final opponentAnswerData = opponentAnswers[question.id];
      
      final userCorrect = userAnswerData?['isCorrect'] as bool? ?? false;
      final opponentCorrect = opponentAnswerData?['isCorrect'] as bool? ?? false;

      return Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        elevation: 1,
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF00897B),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            'Frage ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            question.text.replaceAll(RegExp(r'[*_#]'), '').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User result
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: userCorrect 
                      ? Colors.green 
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  userCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: opponentCorrect 
                      ? Colors.green 
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  opponentCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          children: [
            _buildExpandedQuestionDetails(question, userAnswerData, opponentAnswerData, isChallenger),
          ],
        ),
      );
    });
  }

  /// Build the expanded question details showing full question, answers, and explanations
  Widget _buildExpandedQuestionDetails(Question question, Map<String, dynamic>? userAnswerData, Map<String, dynamic>? opponentAnswerData, bool isChallenger) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = isChallenger ? _challenger! : _opponent!;
    final opponent = isChallenger ? _opponent! : _challenger!;
    
    final userCorrect = userAnswerData?['isCorrect'] as bool? ?? false;
    final opponentCorrect = opponentAnswerData?['isCorrect'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full question text
          Text(
            question.text.replaceAll(RegExp(r'[*_#]'), '').trim(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Answer options with A, B, C, D labels
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isCorrectOption = question.correctIndices.contains(optionIndex);
            final optionLabel = String.fromCharCode(65 + optionIndex); // A, B, C, D
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isCorrectOption 
                    ? Colors.green.shade50 
                    : Colors.grey.shade50,
                border: Border.all(
                  color: isCorrectOption 
                      ? Colors.green 
                      : Colors.grey.shade300,
                  width: isCorrectOption ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Option label (A, B, C, D)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCorrectOption 
                          ? Colors.green 
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        optionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Correct answer indicator
                  if (isCorrectOption)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontWeight: isCorrectOption 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        color: isCorrectOption 
                            ? Colors.green.shade800 
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Results comparison with note about data limitation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Antwort-Ergebnisse',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Grün markierte Optionen (A, B, C, D) sind die korrekten Antworten. Die angezeigten Antworten (z.B. "Nele wählte A") zeigen die tatsächlich gewählten Optionen.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: userCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userCorrect ? Icons.check_circle : Icons.cancel,
                        color: userCorrect ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${currentUser.displayName}: ${_getAnswerChoice(question, userAnswerData)}',
                          style: TextStyle(
                            color: userCorrect ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: opponentCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opponentCorrect ? Icons.check_circle : Icons.cancel,
                        color: opponentCorrect ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${opponent.displayName}: ${_getAnswerChoice(question, opponentAnswerData)}',
                          style: TextStyle(
                            color: opponentCorrect ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Explanation
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.explanation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    height: 1.4,
                  ),
                ),
                
                // Tips if available
                if (question.tips != null && question.tips!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              color: Colors.amber.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.tips,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.tips!,
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get the actual answer choice that was selected
  /// Now uses real data from the new answer format
  String _getAnswerChoice(Question question, Map<String, dynamic>? answerData) {
    if (answerData == null) {
      return 'keine Antwort';
    }
    
    final selectedIndex = answerData['selectedIndex'] as int?;
    final isCorrect = answerData['isCorrect'] as bool? ?? false;
    
    if (selectedIndex == null || selectedIndex < 0) {
      return isCorrect ? 'richtig beantwortet ✓' : 'falsch beantwortet ✗';
    }
    
    final selectedLabel = String.fromCharCode(65 + selectedIndex); // A, B, C, D
    return isCorrect 
        ? 'wählte $selectedLabel ✓' 
        : 'wählte $selectedLabel ✗';
  }
}
