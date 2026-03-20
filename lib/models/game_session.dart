import 'player.dart';
import 'game_result.dart';

enum GameMode { winner, loser, multiWinner, teams, elimination, chaos }
enum GamePhase { waiting, collecting, locked, revealing, done }
enum EliminationPhase { roundActive, roundResult, complete }
enum ChaosTargetType { forceWinner, forceLoser, weightedOdds }

// CHAOS CONTROL: This config is only non-null when the host has explicitly
// activated Chaos Control. The presence of this object means results are NOT random.
// The UI must display the hazard-stripe disclosure banner whenever this is non-null.
class ChaosConfig {
  final ChaosTargetType targetType;

  // For forceWinner / forceLoser:
  // 0-based arrival index of the target finger. null = not yet configured.
  final int? arrivalIndex;

  // For weightedOdds:
  // Map of arrivalIndex → weight (0.0–1.0). Must sum to ≤ 1.0.
  // Fingers not in map share the remaining weight equally.
  final Map<int, double>? weights;

  const ChaosConfig({
    required this.targetType,
    this.arrivalIndex,
    this.weights,
  });

  ChaosConfig copyWith({
    ChaosTargetType? targetType,
    int? arrivalIndex,
    Map<int, double>? weights,
  }) => ChaosConfig(
    targetType: targetType ?? this.targetType,
    arrivalIndex: arrivalIndex ?? this.arrivalIndex,
    weights: weights ?? this.weights,
  );
}

class GameSession {
  final GameMode mode;
  final GamePhase phase;
  final List<Player> activePlayers;
  final List<Player> eliminatedPlayers;
  final int? multiWinnerCount;
  final int? teamCount;
  final ChaosConfig? chaosConfig;
  final GameResult? result;

  // Elimination sub-state
  final EliminationPhase eliminationPhase;
  final int eliminationRound;

  const GameSession({
    required this.mode,
    required this.phase,
    required this.activePlayers,
    required this.eliminatedPlayers,
    required this.eliminationPhase,
    required this.eliminationRound,
    this.multiWinnerCount,
    this.teamCount,
    this.chaosConfig,
    this.result,
  });

  static GameSession initial(GameMode mode, {
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
  }) => GameSession(
    mode: mode,
    phase: GamePhase.waiting,
    activePlayers: const [],
    eliminatedPlayers: const [],
    eliminationPhase: EliminationPhase.roundActive,
    eliminationRound: 1,
    multiWinnerCount: multiWinnerCount,
    teamCount: teamCount,
    chaosConfig: chaosConfig,
  );

  GameSession copyWith({
    GameMode? mode,
    GamePhase? phase,
    List<Player>? activePlayers,
    List<Player>? eliminatedPlayers,
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
    GameResult? result,
    EliminationPhase? eliminationPhase,
    int? eliminationRound,
  }) => GameSession(
    mode: mode ?? this.mode,
    phase: phase ?? this.phase,
    activePlayers: activePlayers ?? this.activePlayers,
    eliminatedPlayers: eliminatedPlayers ?? this.eliminatedPlayers,
    multiWinnerCount: multiWinnerCount ?? this.multiWinnerCount,
    teamCount: teamCount ?? this.teamCount,
    chaosConfig: chaosConfig ?? this.chaosConfig,
    result: result ?? this.result,
    eliminationPhase: eliminationPhase ?? this.eliminationPhase,
    eliminationRound: eliminationRound ?? this.eliminationRound,
  );

  bool get isChaosActive => chaosConfig != null;
}
