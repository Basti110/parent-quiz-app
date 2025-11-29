enum VSModeOutcome { playerAWins, playerBWins, tie }

class VSModeResult {
  final String playerAName;
  final String playerBName;
  final int playerAScore;
  final int playerBScore;
  final VSModeOutcome outcome;

  VSModeResult({
    required this.playerAName,
    required this.playerBName,
    required this.playerAScore,
    required this.playerBScore,
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
}
