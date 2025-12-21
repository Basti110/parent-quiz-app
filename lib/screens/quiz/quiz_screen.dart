import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/category.dart';
import '../../models/question.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// QuizScreen displays questions and handles user answers
/// Requirements: 4.3, 4.4, 4.5
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Question>? _questions;
  int _currentQuestionIndex = 0;
  Set<int> _selectedIndices = {};
  bool _isAnswered = false;
  bool _isLoading = true;

  // Track session data
  final List<bool> _correctAnswers = [];
  final List<bool> _explanationViewed = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questions == null) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final category = args['category'] as Category?; // Can be null for cross-category
    final questionCount = args['questionCount'] as int;
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.userNotAuthenticated)));
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final quizService = ref.read(quizServiceProvider);
      final List<Question> questions;
      
      if (category == null) {
        // Cross-category mode: select from all categories
        questions = await quizService.getQuestionsFromAllCategories(
          questionCount,
          userId,
        );
      } else {
        // Single category mode
        questions = await quizService.getQuestionsForSession(
          category.id,
          questionCount,
          userId,
        );
      }

      if (questions.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.noQuestionsAvailable)));
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingQuestions(e.toString()))),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _submitAnswer() async {
    if (_selectedIndices.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectAnswer)));
      return;
    }

    final question = _questions![_currentQuestionIndex];
    final isCorrect = question.isCorrectAnswer(_selectedIndices.toList());

    setState(() {
      _isAnswered = true;
    });

    // Update question state in Firestore
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      final userService = ref.read(userServiceProvider);
      await userService.updateQuestionState(userId, question.id, isCorrect);
    }

    // Track for session summary
    _correctAnswers.add(isCorrect);
    _explanationViewed.add(true); // Explanation is shown automatically

    // Wait 1 second before navigating to explanation
    await Future.delayed(const Duration(microseconds: 500));

    // Navigate to explanation screen
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
        },
      );

      // After returning from explanation, move to next question or finish
      if (isLastQuestion) {
        _finishQuiz();
      } else {
        _nextQuestion();
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedIndices.clear();
      _isAnswered = false;
    });
  }

  void _finishQuiz() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final category = args['category'] as Category?; // Can be null for cross-category
    final questionCount = args['questionCount'] as int;
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) return;

    try {
      // Calculate session XP
      final quizService = ref.read(quizServiceProvider);
      final sessionXP = quizService.calculateSessionXP(
        correctAnswers: _correctAnswers,
        explanationViewed: _explanationViewed,
        questionCount: questionCount,
      );

      // Update user XP and weekly XP
      await quizService.updateUserXP(userId, sessionXP);

      final userService = ref.read(userServiceProvider);
      await userService.updateWeeklyXP(userId, sessionXP);
      await userService.updateStreak(userId);

      // Update category progress only for single-category mode
      if (category != null) {
        await userService.updateCategoryProgress(
          userId,
          category.id,
          questionCount,
        );
      }
      // For cross-category mode, category progress is updated per question
      // in the updateQuestionState method, so no additional update needed

      // Navigate to results screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/quiz-result',
          arguments: {
            'correctCount': _correctAnswers.where((c) => c).length,
            'totalCount': _correctAnswers.length,
            'xpEarned': sessionXP,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorFinishingQuiz(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quiz)),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.question} ${_currentQuestionIndex + 1}',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' / ${_questions!.length}',
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
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
                      child: _buildAnswerOption(question, index),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Action button
          if (!_isAnswered)
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
                    onPressed: _selectedIndices.isEmpty ? null : _submitAnswer,
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
                    child: Text(
                      l10n.submitAnswer.toUpperCase(),
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

  Widget _buildAnswerOption(Question question, int index) {
    final isSelected = _selectedIndices.contains(index);
    final isCorrectOption = question.correctIndices.contains(index);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = Theme.of(context).colorScheme.surface;
    Color borderColor = isDarkMode
        ? AppColors.textSecondary.withValues(alpha: 0.3)
        : AppColors.border;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    if (_isAnswered) {
      if (isCorrectOption) {
        backgroundColor = isDarkMode
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.successLightest;
        borderColor = AppColors.successLight;
        textColor = isDarkMode
            ? AppColors.successLight
            : AppColors.successDarkest;
      } else if (isSelected && !isCorrectOption) {
        backgroundColor = isDarkMode
            ? AppColors.error.withValues(alpha: 0.2)
            : AppColors.errorLightest;
        borderColor = AppColors.errorLight;
        textColor = isDarkMode ? AppColors.errorLight : AppColors.errorDarkest;
      }
    } else if (isSelected) {
      backgroundColor = isDarkMode
          ? AppColors.primaryDark.withValues(alpha: 0.3)
          : AppColors.primaryLightest;
      borderColor = isDarkMode ? AppColors.primaryLight : AppColors.primaryDark;
      textColor = isDarkMode ? AppColors.primaryLight : AppColors.primaryDarker;
    }

    return InkWell(
      onTap: _isAnswered ? null : () => _toggleOption(question, index),
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

            // Correct/incorrect indicator
            if (_isAnswered && isCorrectOption)
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
            if (_isAnswered && isSelected && !isCorrectOption)
              Icon(Icons.cancel, color: AppColors.error, size: 24),
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

  Future<void> _showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitQuiz),
        content: Text(l10n.exitQuizConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
