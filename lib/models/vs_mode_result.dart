enum VSModeOutcome { playerAWins, playerBWins, tie }

class VSModeResult {
  final String playerAName;
  final String playerBName;
  final int playerAScore;
  final int playerBScore;
  final int? playerATimeSeconds;
  final int? playerBTimeSeconds;
  final bool wonByTime;
  final VSModeOutcome outcome;

  VSModeResult({
    required this.playerAName,
    required this.playerBName,
    required this.playerAScore,
    required this.playerBScore,
    this.playerATimeSeconds,
    this.playerBTimeSeconds,
    this.wonByTime = false,
    required this.outcome,
  });

  String get winnerName {
    switch (outcome) {
      case VSModeOutcome.playerAWins:
        return playerAName;
      case VSModeOutcome.playerBWins:
        return playerBName;
      case VSModeOutcome.tie:
        return 'Tie';
    }
  }

  bool isPlayerWinner(String playerName) {
    if (outcome == VSModeOutcome.tie) {
      return false;
    }
    return winnerName == playerName;
  }

  bool isTie() {
    return outcome == VSModeOutcome.tie;
  }

  bool isPlayerLoser(String playerName) {
    if (outcome == VSModeOutcome.tie) {
      return false;
    }
    return winnerName != playerName;
  }
  
  /// Formats time in MM:SS format
  /// Returns null if seconds is null
  String? formatTime(int? seconds) {
    if (seconds == null) return null;
    
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Factory constructor that determines outcome based on scores and times
  factory VSModeResult.fromSession({
    required String playerAName,
    required String playerBName,
    required int playerAScore,
    required int playerBScore,
    int? playerATimeSeconds,
    int? playerBTimeSeconds,
  }) {
    VSModeOutcome outcome;
    bool wonByTime = false;
    
    // First compare scores
    if (playerAScore > playerBScore) {
      outcome = VSModeOutcome.playerAWins;
    } else if (playerBScore > playerAScore) {
      outcome = VSModeOutcome.playerBWins;
    } else {
      // Scores are equal, check time-based tiebreaker
      if (playerATimeSeconds != null && playerBTimeSeconds != null) {
        if (playerATimeSeconds < playerBTimeSeconds) {
          outcome = VSModeOutcome.playerAWins;
          wonByTime = true;
        } else if (playerBTimeSeconds < playerATimeSeconds) {
          outcome = VSModeOutcome.playerBWins;
          wonByTime = true;
        } else {
          // Perfect tie (same score and same time)
          outcome = VSModeOutcome.tie;
        }
      } else {
        // No time data available, it's a tie
        outcome = VSModeOutcome.tie;
      }
    }
    
    return VSModeResult(
      playerAName: playerAName,
      playerBName: playerBName,
      playerAScore: playerAScore,
      playerBScore: playerBScore,
      playerATimeSeconds: playerATimeSeconds,
      playerBTimeSeconds: playerBTimeSeconds,
      wonByTime: wonByTime,
      outcome: outcome,
    );
  }
}
