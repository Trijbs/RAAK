enum MatchOutcomeType { winner, loser }

class MatchConfig {
  final int winTarget;
  final MatchOutcomeType outcomeType;
  const MatchConfig({required this.winTarget, required this.outcomeType});
}

class MatchState {
  final MatchConfig config;
  final int roundNumber;
  final Map<int, int> tally;
  final int? matchDecidedSlot;

  const MatchState({
    required this.config,
    this.roundNumber = 1,
    this.tally = const {},
    this.matchDecidedSlot,
  });

  bool get isActive => matchDecidedSlot == null;

  MatchState recordSelection(int slot) {
    final newTally = Map<int, int>.from(tally);
    newTally[slot] = (newTally[slot] ?? 0) + 1;
    final decided = newTally[slot]! >= config.winTarget ? slot : null;
    return MatchState(
      config: config,
      roundNumber: roundNumber + 1,
      tally: newTally,
      matchDecidedSlot: decided,
    );
  }
}
