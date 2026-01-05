import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/duel_model.dart';
import '../../models/question.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/duel_providers.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// DuelQuestionScreen displays duel questions and handles answers
/// Requirements: 12.1, 12.2, 16.1, 16.2, 16.3
class DuelQuestionScreen extends ConsumerStatefulWidget {
  const DuelQuestionScreen({super.key});

  @override
  ConsumerState<DuelQuestionScreen> createState() =>
      _DuelQuestionScreenState();
}

class _DuelQuestionScreenState extends ConsumerState<DuelQuestionScreen> {
  DuelModel? _duel;
  List<Question>? _questions;
  UserModel? _opponent;
  int _currentQuestionIndex = 0;
  Set<int> _selectedIndices = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_duel == null) {
      _loadDuelData();
    }
  }

  Future<void> _loadDuelData() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final duelId = args['duelId'] as String;
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userNotAuthenticated)),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      // Load duel data
      final duelService = ref.read(duelServiceProvider);
      final duel = await duelService.getDuel(duelId);

      // Verify user is a participant
      if (duel.challengerId != userId && duel.opponentId != userId) {
        throw Exception('You are not a participant in this duel');
      }

      // Load opponent data
      final opponentId =
          duel.challengerId == userId ? duel.opponentId : duel.challengerId;
      final userService = ref.read(userServiceProvider);
      final opponent = await userService.getUserData(opponentId);

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

      if (questions.length != 5) {
        throw Exception('Failed to load all duel questions');
      }

      setState(() {
        _duel = duel;
        _questions = questions;
        _opponent = opponent;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingDuel(e.toString()))),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading || _duel == null || _questions == null || _opponent == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.screenTitleDuel)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loadingQuestions),
            ],
          ),
        ),
      );
    }

    final question = _questions![_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions!.length;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textSecondaryColor),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.duelWith(_opponent!.displayName),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.questionProgress(_currentQuestionIndex + 1, _questions!.length),
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDarkMode
                ? AppColors.progressTrackDark
                : AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? AppColors.primaryLight : AppColors.primary,
            ),
            minHeight: 4,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: question.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Answer options
                  ...List.generate(question.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildAnswerOption(question, index, isDarkMode),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.2 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIndices.isEmpty || _isSubmitting
                      ? null
                      : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: isDarkMode
                        ? AppColors.textSecondary.withValues(alpha: 0.2)
                        : AppColors.border,
                    disabledForegroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.submitAnswer.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(Question question, int index, bool isDarkMode) {
    final isSelected = _selectedIndices.contains(index);

    Color backgroundColor = Theme.of(context).colorScheme.surface;
    Color borderColor = isDarkMode
        ? AppColors.textSecondary.withValues(alpha: 0.3)
        : AppColors.border;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    if (isSelected) {
      backgroundColor = isDarkMode
          ? AppColors.primaryDark.withValues(alpha: 0.3)
          : AppColors.primaryLightest;
      borderColor = isDarkMode ? AppColors.primaryLight : AppColors.primaryDark;
      textColor = isDarkMode ? AppColors.primaryLight : AppColors.primaryDarker;
    }

    return InkWell(
      onTap: _isSubmitting ? null : () => _toggleOption(question, index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Radio button indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? borderColor
                      : (isDarkMode
                          ? AppColors.textSecondary.withValues(alpha: 0.3)
                          : AppColors.borderLight),
                  width: 2,
                ),
                color: isSelected
                    ? backgroundColor
                    : Theme.of(context).colorScheme.surface,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: borderColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Option text
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOption(Question question, int index) {
    setState(() {
      if (question.isMultipleChoice) {
        // Multiple choice: toggle selection
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      } else {
        // Single choice: replace selection
        _selectedIndices = {index};
      }
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedIndices.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final question = _questions![_currentQuestionIndex];
      final isCorrect = question.isCorrectAnswer(_selectedIndices.toList());

      // Submit answer to duel service
      // Requirements: 12.3, 12.4
      final duelService = ref.read(duelServiceProvider);
      await duelService.submitAnswer(
        duelId: _duel!.id,
        userId: userId,
        questionIndex: _currentQuestionIndex,
        questionId: question.id,
        isCorrect: isCorrect,
      );

      // Navigate to explanation screen
      // Requirements: 17.4
      final isLastQuestion = _currentQuestionIndex >= _questions!.length - 1;
      if (mounted) {
        await Navigator.pushNamed(
          context,
          '/quiz-explanation',
          arguments: {
            'question': question,
            'isCorrect': isCorrect,
            'isLastQuestion': isLastQuestion,
            'selectedIndices': _selectedIndices.toList(),
            'isVSMode': true, // Skip user stat updates for duels
            'categoryName': 'Duel',
          },
        );

        // After returning from explanation, move to next question or complete
        if (isLastQuestion) {
          await _completeDuel();
        } else {
          _nextQuestion();
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSubmittingAnswer(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedIndices.clear();
    });
  }

  Future<void> _completeDuel() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final duelService = ref.read(duelServiceProvider);
      await duelService.completeDuel(_duel!.id, userId);

      if (mounted) {
        // Navigate to duel results screen
        Navigator.of(context).pushReplacementNamed(
          '/duel-result',
          arguments: {'duelId': _duel!.id},
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCompletingDuel(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogTitleExitDuel),
        content: Text(l10n.dialogContentExitDuel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(l10n.buttonExit),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
