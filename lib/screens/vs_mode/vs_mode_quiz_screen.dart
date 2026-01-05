import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/question.dart';
import '../../models/vs_mode_session.dart';
import '../../services/vs_mode_service.dart';
import '../../providers/quiz_providers.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// VSModeQuizScreen displays questions for pass-and-play VS Mode
/// Requirements: 9.3
class VSModeQuizScreen extends ConsumerStatefulWidget {
  const VSModeQuizScreen({super.key});

  @override
  ConsumerState<VSModeQuizScreen> createState() => _VSModeQuizScreenState();
}

class _VSModeQuizScreenState extends ConsumerState<VSModeQuizScreen> {
  VSModeSession? _session;
  Map<String, Question>? _questionsMap;
  bool _isLoading = true;
  String _currentPlayer = 'playerA';
  int _currentQuestionIndex = 0;
  Set<int> _selectedIndices = {};
  bool _isAnswered = false;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    // Start timer when first question is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuestionTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null) {
      _initializeSession();
    }
  }

  void _startQuestionTimer() {
    setState(() {
      _questionStartTime = DateTime.now();
    });
    
    // Record question start in session
    if (_session != null) {
      final vsModeService = VSModeService();
      _session = vsModeService.recordQuestionStart(
        session: _session!,
        playerId: _currentPlayer,
        startTime: _questionStartTime!,
      );
    }
  }

  Future<void> _initializeSession() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Check if we're resuming from handoff (Player B)
    if (args.containsKey('session') && args.containsKey('questionsMap')) {
      final session = args['session'] as VSModeSession;
      final questionsMap = args['questionsMap'] as Map<String, Question>;
      final currentPlayer = args['currentPlayer'] as String? ?? 'playerA';

      setState(() {
        _session = session;
        _questionsMap = questionsMap;
        _currentPlayer = currentPlayer;
        _isLoading = false;
      });
      return;
    }

    // Starting new session (Player A)
    final category = args['category'] as Category;
    final questionsPerPlayer = args['questionsPerPlayer'] as int;
    final playerAName = args['playerAName'] as String;
    final playerBName = args['playerBName'] as String;

    try {
      final vsModeService = VSModeService();
      final session = await vsModeService.startVSMode(
        categoryId: category.id,
        questionsPerPlayer: questionsPerPlayer,
        playerAName: playerAName,
        playerBName: playerBName,
      );

      // Load all questions for the session
      final quizService = ref.read(quizServiceProvider);
      final allQuestionIds = [
        ...session.playerAQuestionIds,
        ...session.playerBQuestionIds,
      ];

      final questionsMap = <String, Question>{};
      for (final questionId in allQuestionIds) {
        final question = await quizService.getQuestionById(questionId);
        if (question != null) {
          questionsMap[questionId] = question;
        }
      }

      setState(() {
        _session = session;
        _questionsMap = questionsMap;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorStartingVsMode(e.toString()))));
        Navigator.of(context).pop();
      }
    }
  }

  List<String> get _currentPlayerQuestionIds {
    if (_currentPlayer == 'playerA') {
      return _session!.playerAQuestionIds;
    } else {
      return _session!.playerBQuestionIds;
    }
  }

  String get _currentPlayerName {
    return _currentPlayer == 'playerA'
        ? _session!.playerAName
        : _session!.playerBName;
  }

  Future<void> _submitAnswer() async {
    if (_selectedIndices.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectAnswer)));
      return;
    }

    final questionId = _currentPlayerQuestionIds[_currentQuestionIndex];
    final question = _questionsMap![questionId]!;
    final isCorrect = question.isCorrectAnswer(_selectedIndices.toList());

    // Record end time before navigating to explanation (timer pauses)
    final endTime = DateTime.now();
    final vsModeService = VSModeService();
    
    if (_questionStartTime != null) {
      _session = vsModeService.recordQuestionEnd(
        session: _session!,
        playerId: _currentPlayer,
        endTime: endTime,
        startTime: _questionStartTime!,
      );
    }

    // Update session with answer
    _session = vsModeService.submitPlayerAnswer(
      session: _session!,
      playerId: _currentPlayer,
      questionId: questionId,
      isCorrect: isCorrect,
    );

    // Navigate to explanation screen
    final isLastQuestion = _currentQuestionIndex >= _currentPlayerQuestionIds.length - 1;
    
    await Navigator.of(context).pushNamed(
      '/quiz-explanation',
      arguments: {
        'question': question,
        'isCorrect': isCorrect,
        'isLastQuestion': isLastQuestion,
        'selectedIndices': _selectedIndices.toList(),
        'isVSMode': true,
        'categoryName': 'VS Mode',
      },
    );

    // Track explanation view
    _session = vsModeService.recordExplanationViewed(
      session: _session!,
      playerId: _currentPlayer,
      questionId: questionId,
    );

    // After returning from explanation, handle next step
    if (!mounted) return;
    
    _handleAfterExplanation();
  }

  void _handleAfterExplanation() {
    if (_currentQuestionIndex < _currentPlayerQuestionIds.length - 1) {
      // More questions for current player - restart timer for next question
      setState(() {
        _currentQuestionIndex++;
        _selectedIndices.clear();
        _isAnswered = false;
      });
      _startQuestionTimer();
    } else if (_currentPlayer == 'playerA') {
      // Player A finished, show handoff screen
      Navigator.of(context).pushReplacementNamed(
        '/vs-mode-handoff',
        arguments: {'session': _session!, 'questionsMap': _questionsMap!},
      );
    } else {
      // Player B finished, show results
      Navigator.of(context).pushReplacementNamed(
        '/vs-mode-result',
        arguments: {'session': _session!},
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading || _session == null || _questionsMap == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.screenTitleVsMode)),
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

    final questionId = _currentPlayerQuestionIds[_currentQuestionIndex];
    final question = _questionsMap![questionId]!;
    final progress =
        (_currentQuestionIndex + 1) / _currentPlayerQuestionIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.questionProgress(_currentQuestionIndex + 1, _currentPlayerQuestionIds.length),
        ),
      ),
      body: Column(
        children: [
          // Player indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: _currentPlayer == 'playerA'
                ? AppColors.info.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: _currentPlayer == 'playerA'
                      ? AppColors.info
                      : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentPlayerName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _currentPlayer == 'playerA'
                        ? AppColors.info
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ),

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
                          ? AppLocalizations.of(context)!.selectAllThatApply
                          : AppLocalizations.of(context)!.selectOneAnswer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),

                  // Answer options
                  ...List.generate(question.options.length, (index) {
                    return _buildAnswerOption(question, index);
                  }),

                  const SizedBox(height: 16),
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
                child: Text(
                  AppLocalizations.of(context)!.submitAnswer,
                  style: const TextStyle(fontSize: 18),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? backgroundColor;
    Color? borderColor;

    if (_isAnswered) {
      if (isCorrectOption) {
        backgroundColor = AppColors.successLight;
        borderColor = AppColors.success;
      } else if (isSelected && !isCorrectOption) {
        backgroundColor = AppColors.errorLight;
        borderColor = AppColors.error;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              borderColor ??
              (isDark ? AppColors.border.withOpacity(0.3) : AppColors.border),
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
                const Icon(Icons.check, color: AppColors.success),
              if (_isAnswered && isSelected && !isCorrectOption)
                const Icon(Icons.close, color: AppColors.error),
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

}
