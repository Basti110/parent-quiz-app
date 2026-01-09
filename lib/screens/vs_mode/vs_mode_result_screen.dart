import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vs_mode_session.dart';
import '../../models/vs_mode_result.dart';
import '../../models/question.dart';
import '../../services/vs_mode_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
  Map<String, Question> _questionsCache = {};
  bool _questionsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statsUpdated) {
      _updateDuelStats();
    }
    if (!_questionsLoaded) {
      _loadQuestions();
    }
  }

  /// Load all questions for the session to display in expandable details
  Future<void> _loadQuestions() async {
    if (_questionsLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Handle test session case
    if (args == null || args['session'] == null) {
      setState(() {
        _questionsCache = _createTestQuestions();
        _questionsLoaded = true;
      });
      return;
    }

    final session = args['session'] as VSModeSession;

    try {
      final quizService = ref.read(quizServiceProvider);
      final allQuestionIds = <String>{
        ...session.playerAQuestionIds,
        ...session.playerBQuestionIds,
      };

      final questionsMap = <String, Question>{};
      for (final questionId in allQuestionIds) {
        final question = await quizService.getQuestionById(questionId);
        if (question != null) {
          questionsMap[questionId] = question;
        }
      }

      if (mounted) {
        setState(() {
          _questionsCache = questionsMap;
          _questionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          _questionsCache = _createTestQuestions(); // Fallback to test questions
          _questionsLoaded = true;
        });
      }
    }
  }

  /// Create test questions for development/testing purposes
  Map<String, Question> _createTestQuestions() {
    return {
      'q1': Question(
        id: 'q1',
        categoryId: 'test-category',
        text: 'Was ist die Hauptstadt von Deutschland?',
        options: ['Berlin', 'München', 'Hamburg', 'Köln'],
        correctIndices: [0],
        explanation: 'Berlin ist seit der Wiedervereinigung 1990 die Hauptstadt Deutschlands.',
        tips: 'Berlin liegt im Nordosten Deutschlands und ist auch die größte Stadt des Landes.',
        difficulty: 1,
        isActive: true,
        sequence: 1,
      ),
      'q2': Question(
        id: 'q2',
        categoryId: 'test-category',
        text: 'Welche Farben hat die deutsche Flagge?',
        options: ['Schwarz, Rot, Gold', 'Schwarz, Rot, Gelb', 'Rot, Weiß, Blau', 'Grün, Weiß, Rot'],
        correctIndices: [0],
        explanation: 'Die deutsche Flagge besteht aus drei horizontalen Streifen in Schwarz, Rot und Gold.',
        tips: 'Diese Farben haben eine lange Tradition in der deutschen Geschichte.',
        difficulty: 1,
        isActive: true,
        sequence: 2,
      ),
      'q3': Question(
        id: 'q3',
        categoryId: 'test-category',
        text: 'Wie viele Bundesländer hat Deutschland?',
        options: ['14', '15', '16', '17'],
        correctIndices: [2],
        explanation: 'Deutschland besteht aus 16 Bundesländern, darunter drei Stadtstaaten.',
        tips: 'Die drei Stadtstaaten sind Berlin, Hamburg und Bremen.',
        difficulty: 2,
        isActive: true,
        sequence: 3,
      ),
      'q4': Question(
        id: 'q4',
        categoryId: 'test-category',
        text: 'Wann fiel die Berliner Mauer?',
        options: ['1987', '1988', '1989', '1990'],
        correctIndices: [2],
        explanation: 'Die Berliner Mauer fiel am 9. November 1989, was ein historischer Moment für Deutschland war.',
        tips: 'Dieses Ereignis führte zur deutschen Wiedervereinigung im Jahr 1990.',
        difficulty: 2,
        isActive: true,
        sequence: 4,
      ),
      'q5': Question(
        id: 'q5',
        categoryId: 'test-category',
        text: 'Welcher Fluss fließt durch Berlin?',
        options: ['Rhein', 'Elbe', 'Spree', 'Donau'],
        correctIndices: [2],
        explanation: 'Die Spree fließt durch Berlin und ist ein wichtiger Fluss der Stadt.',
        tips: 'Viele Sehenswürdigkeiten Berlins liegen an der Spree.',
        difficulty: 1,
        isActive: true,
        sequence: 5,
      ),
      'q6': Question(
        id: 'q6',
        categoryId: 'test-category',
        text: 'Wie heißt das deutsche Parlament?',
        options: ['Bundestag', 'Bundesrat', 'Landtag', 'Reichstag'],
        correctIndices: [0],
        explanation: 'Der Bundestag ist das deutsche Parlament und tagt im Reichstagsgebäude in Berlin.',
        tips: 'Der Bundestag wird alle vier Jahre gewählt.',
        difficulty: 1,
        isActive: true,
        sequence: 6,
      ),
    };
  }

  /// Create a test session for development/testing purposes
  VSModeSession _createTestSession() {
    return VSModeSession(
      categoryId: 'test-category',
      questionsPerPlayer: 3,
      playerAName: 'Spieler A',
      playerBName: 'Spieler B',
      playerAQuestionIds: ['q1', 'q2', 'q3'],
      playerBQuestionIds: ['q4', 'q5', 'q6'],
      playerAAnswers: {'q1': true, 'q2': false, 'q3': true},
      playerBAnswers: {'q4': false, 'q5': true, 'q6': true},
      playerAElapsedSeconds: 45,
      playerBElapsedSeconds: 52,
      playerAExplanationsViewed: {'q2': true},
      playerBExplanationsViewed: {'q4': true, 'q5': false},
    );
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorUpdatingStats(e.toString()))));
      }
      setState(() {
        _isUpdatingStats = false;
        _statsUpdated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Create test session if no arguments provided (for testing)
    final VSModeSession session;
    if (args == null || args['session'] == null) {
      session = _createTestSession();
    } else {
      session = args['session'] as VSModeSession;
    }

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

                  // Test indicator to verify we're using the new screen
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      '🎉 NEUE EXPANDABLE FRAGEN FUNKTION AKTIV! 🎉',
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
                        l10n.vsText,
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
                  _buildWinnerSection(result, l10n),
                  const SizedBox(height: 32),

                  // XP earned (for logged-in user only)
                  _buildXPSection(session, result, l10n),
                  const SizedBox(height: 32),

                  // Question breakdown section
                  _buildQuestionBreakdown(session, l10n),
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
                          child: Text(AppLocalizations.of(context)!.buttonHome),
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
                          child: Text(AppLocalizations.of(context)!.playAgain),
                        ),
                      ),
                    ],
                  ),

                  // Debug button (only visible in debug mode)
                  if (args == null || args['session'] == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.bug_report, color: Colors.orange),
                          const SizedBox(height: 8),
                          const Text(
                            'DEBUG MODE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dies ist eine Test-Ansicht der neuen expandable Fragen-Funktion.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the expandable question breakdown section
  Widget _buildQuestionBreakdown(VSModeSession session, AppLocalizations l10n) {
    if (!_questionsLoaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.questionBreakdown,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Player A questions
            _buildPlayerQuestions(
              session.playerAName,
              session.playerAQuestionIds,
              session.playerAAnswers,
              session.playerAExplanationsViewed,
              l10n,
            ),
            
            const SizedBox(height: 16),
            
            // Player B questions
            _buildPlayerQuestions(
              session.playerBName,
              session.playerBQuestionIds,
              session.playerBAnswers,
              session.playerBExplanationsViewed,
              l10n,
            ),
          ],
        ),
      ),
    );
  }

  /// Build questions section for a specific player
  Widget _buildPlayerQuestions(
    String playerName,
    List<String> questionIds,
    Map<String, bool> answers,
    Map<String, bool> explanationsViewed,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playerName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        ...questionIds.asMap().entries.map((entry) {
          final index = entry.key;
          final questionId = entry.value;
          final question = _questionsCache[questionId];
          final isCorrect = answers[questionId] ?? false;
          final viewedExplanation = explanationsViewed[questionId] ?? false;
          
          if (question == null) {
            return const SizedBox.shrink();
          }
          
          return _buildExpandableQuestion(
            question,
            index + 1,
            isCorrect,
            viewedExplanation,
            l10n,
          );
        }),
      ],
    );
  }

  /// Build an expandable question card
  Widget _buildExpandableQuestion(
    Question question,
    int questionNumber,
    bool isCorrect,
    bool viewedExplanation,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          child: Icon(
            isCorrect ? Icons.check : Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          '${l10n.question} $questionNumber',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          question.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full question text
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Answer options
                ...question.options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final optionText = entry.value;
                  final isCorrectOption = question.correctIndices.contains(optionIndex);
                  
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
                
                // Result indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? l10n.correct : l10n.incorrect,
                        style: TextStyle(
                          color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                          if (viewedExplanation) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.visibility,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                          ],
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

  Widget _buildWinnerSection(VSModeResult result, AppLocalizations l10n) {
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
              isTie ? (isPerfectTie ? l10n.perfectTie : l10n.tie) : l10n.winnerWins(result.winnerName),
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
                    l10n.wonBySpeed,
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

  Widget _buildXPSection(VSModeSession session, VSModeResult result, AppLocalizations l10n) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const SizedBox.shrink();
    }

    // Calculate XP based on outcome
    int xpEarned = 0;
    String xpMessage = '';

    if (result.isTie()) {
      xpEarned = 1;
      xpMessage = l10n.duelPointsTie;
    } else {
      // Check if logged-in user won
      final userDataAsync = ref.watch(userDataProvider(userId));
      return userDataAsync.when(
        data: (userData) {
          if (result.isPlayerWinner(userData.displayName)) {
            xpEarned = 3;
            xpMessage = l10n.duelPointsWin;
          } else if (result.isPlayerLoser(userData.displayName)) {
            xpEarned = 0;
            xpMessage = l10n.duelPointsLoss;
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
                          l10n.duelPointsEarned,
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
                    l10n.duelPointsEarned,
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
