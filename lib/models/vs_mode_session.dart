class VSModeSession {
  final String categoryId;
  final int questionsPerPlayer;
  final String playerAName;
  final String playerBName;
  final List<String> playerAQuestionIds;
  final List<String> playerBQuestionIds;
  final Map<String, bool> playerAAnswers; // questionId -> isCorrect
  final Map<String, bool> playerBAnswers; // questionId -> isCorrect
  
  // Time tracking (accumulated time during question answering only)
  final int playerAElapsedSeconds;
  final int playerBElapsedSeconds;
  
  // Explanation tracking
  final Map<String, bool> playerAExplanationsViewed; // questionId -> viewed
  final Map<String, bool> playerBExplanationsViewed; // questionId -> viewed

  VSModeSession({
    required this.categoryId,
    required this.questionsPerPlayer,
    required this.playerAName,
    required this.playerBName,
    required this.playerAQuestionIds,
    required this.playerBQuestionIds,
    this.playerAAnswers = const {},
    this.playerBAnswers = const {},
    this.playerAElapsedSeconds = 0,
    this.playerBElapsedSeconds = 0,
    this.playerAExplanationsViewed = const {},
    this.playerBExplanationsViewed = const {},
  });

  VSModeSession copyWith({
    String? categoryId,
    int? questionsPerPlayer,
    String? playerAName,
    String? playerBName,
    List<String>? playerAQuestionIds,
    List<String>? playerBQuestionIds,
    Map<String, bool>? playerAAnswers,
    Map<String, bool>? playerBAnswers,
    int? playerAElapsedSeconds,
    int? playerBElapsedSeconds,
    Map<String, bool>? playerAExplanationsViewed,
    Map<String, bool>? playerBExplanationsViewed,
  }) {
    return VSModeSession(
      categoryId: categoryId ?? this.categoryId,
      questionsPerPlayer: questionsPerPlayer ?? this.questionsPerPlayer,
      playerAName: playerAName ?? this.playerAName,
      playerBName: playerBName ?? this.playerBName,
      playerAQuestionIds: playerAQuestionIds ?? this.playerAQuestionIds,
      playerBQuestionIds: playerBQuestionIds ?? this.playerBQuestionIds,
      playerAAnswers: playerAAnswers ?? this.playerAAnswers,
      playerBAnswers: playerBAnswers ?? this.playerBAnswers,
      playerAElapsedSeconds: playerAElapsedSeconds ?? this.playerAElapsedSeconds,
      playerBElapsedSeconds: playerBElapsedSeconds ?? this.playerBElapsedSeconds,
      playerAExplanationsViewed: playerAExplanationsViewed ?? this.playerAExplanationsViewed,
      playerBExplanationsViewed: playerBExplanationsViewed ?? this.playerBExplanationsViewed,
    );
  }

  int get playerAScore {
    return playerAAnswers.values.where((correct) => correct).length;
  }

  int get playerBScore {
    return playerBAnswers.values.where((correct) => correct).length;
  }
  
  // Computed properties for time (return elapsed seconds)
  int get playerATimeSeconds => playerAElapsedSeconds;
  
  int get playerBTimeSeconds => playerBElapsedSeconds;
}
