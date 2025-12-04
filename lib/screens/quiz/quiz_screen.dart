import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/question.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';

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
  bool _isCorrect = false;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No questions available for this category'),
            ),
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  void _submitAnswer() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an answer')));
      return;
    }

    final question = _questions![_currentQuestionIndex];
    final isCorrect = question.isCorrectAnswer(_selectedIndices.toList());

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
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
      _isCorrect = false;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finishing quiz: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions![_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions!.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${_currentQuestionIndex + 1}/${_questions!.length}',
        ),
        actions: [
          // Tip button
          if (question.tips != null && !_isAnswered)
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Show tip',
              onPressed: () => _showTipDialog(question.tips!),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(value: progress),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question text
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        question.text,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question type indicator
                  if (!_isAnswered)
                    Text(
                      question.isMultipleChoice
                          ? 'Select all that apply'
                          : 'Select one answer',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),

                  // Answer options
                  ...List.generate(question.options.length, (index) {
                    return _buildAnswerOption(question, index);
                  }),

                  const SizedBox(height: 16),

                  // Show correct answers after submission
                  if (_isAnswered) ...[
                    Card(
                      color: _isCorrect
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isCorrect ? 'Correct!' : 'Incorrect',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: _isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action button
          if (!_isAnswered)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Answer',
                  style: TextStyle(fontSize: 18),
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

    Color? backgroundColor;
    Color? borderColor;

    if (_isAnswered) {
      if (isCorrectOption) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrectOption) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: borderColor ?? Colors.grey.shade300,
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isAnswered ? null : () => _toggleOption(question, index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Checkbox or radio button
              if (question.isMultipleChoice)
                Checkbox(
                  value: isSelected,
                  onChanged: _isAnswered
                      ? null
                      : (_) => _toggleOption(question, index),
                )
              else
                Radio<int>(
                  value: index,
                  groupValue: _selectedIndices.isEmpty
                      ? null
                      : _selectedIndices.first,
                  onChanged: _isAnswered
                      ? null
                      : (_) => _toggleOption(question, index),
                ),
              const SizedBox(width: 8),

              // Option text
              Expanded(
                child: Text(
                  question.options[index],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              // Correct/incorrect indicator
              if (_isAnswered && isCorrectOption)
                const Icon(Icons.check, color: Colors.green),
              if (_isAnswered && isSelected && !isCorrectOption)
                const Icon(Icons.close, color: Colors.red),
            ],
          ),
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

  void _showTipDialog(String tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('Tip'),
          ],
        ),
        content: Text(tip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
