class VSModeSession {
  final String categoryId;
  final int questionsPerPlayer;
  final String playerAName;
  final String playerBName;
  final List<String> playerAQuestionIds;
  final List<String> playerBQuestionIds;
  final Map<String, bool> playerAAnswers; // questionId -> isCorrect
  final Map<String, bool> playerBAnswers; // questionId -> isCorrect

  VSModeSession({
    required this.categoryId,
    required this.questionsPerPlayer,
    required this.playerAName,
    required this.playerBName,
    required this.playerAQuestionIds,
    required this.playerBQuestionIds,
    this.playerAAnswers = const {},
    this.playerBAnswers = const {},
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
    );
  }

  int get playerAScore {
    return playerAAnswers.values.where((correct) => correct).length;
  }

  int get playerBScore {
    return playerBAnswers.values.where((correct) => correct).length;
  }
}
