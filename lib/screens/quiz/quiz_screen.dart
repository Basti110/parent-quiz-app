import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/category.dart';
import '../../models/question.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../l10n/app_localizations.dart';

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
    final category = args['category'] as Category;
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
      final questions = await quizService.getQuestionsForSession(
        category.id,
        questionCount,
        userId,
      );

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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions![_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions!.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.question} ${_currentQuestionIndex + 1}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' / ${_questions!.length}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
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
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: question.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIndices.isEmpty ? null : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF9CA3AF),
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

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF1F2937);

    if (_isAnswered) {
      if (isCorrectOption) {
        backgroundColor = const Color(0xFFDCFCE7); // Green-100
        borderColor = const Color(0xFF22C55E); // Green-500
        textColor = const Color(0xFF166534); // Green-800
      } else if (isSelected && !isCorrectOption) {
        backgroundColor = const Color(0xFFFFE4E6); // Rose-100
        borderColor = const Color(0xFFE11D48); // Rose-600
        textColor = const Color(0xFF9F1239); // Rose-800
      }
    } else if (isSelected) {
      backgroundColor = const Color(0xFFCCFBF1); // Teal-100
      borderColor = const Color(0xFF0D9488); // Teal-600
      textColor = const Color(0xFF0F766E); // Teal-700
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
                  color: isSelected ? borderColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? backgroundColor : Colors.white,
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
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 24,
              ),
            if (_isAnswered && isSelected && !isCorrectOption)
              const Icon(Icons.cancel, color: Color(0xFFE11D48), size: 24),
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
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
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
