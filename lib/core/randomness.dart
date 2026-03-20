// CHAOS CONTROL: When chaosConfig is non-null, results are NOT random.
// Weighting or forcing is applied explicitly per the host's configuration.
// This is never called without the UI disclosing it to all players.

import 'dart:math';
import '../models/player.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';

// Fisher-Yates shuffle — fair, O(n)
List<T> _shuffle<T>(List<T> list) {
  final rng = Random();
  final result = List<T>.from(list);
  for (int i = result.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}

// Pick one index using a weight map.
int _weightedPick(List<Player> players, Map<int, double> weights) {
  final rng = Random();
  final total = weights.values.fold(0.0, (a, b) => a + b);
  final remaining = (1.0 - total).clamp(0.0, 1.0);
  final unmappedCount = players.where((p) => !weights.containsKey(p.arrivalIndex)).length;
  final defaultWeight = unmappedCount > 0 ? remaining / unmappedCount : 0.0;

  final cumulativeWeights = <double>[];
  double cumulative = 0.0;
  for (final p in players) {
    cumulative += weights[p.arrivalIndex] ?? defaultWeight;
    cumulativeWeights.add(cumulative);
  }

  final roll = rng.nextDouble() * cumulative;
  for (int i = 0; i < cumulativeWeights.length; i++) {
    if (roll <= cumulativeWeights[i]) return i;
  }
  return players.length - 1;
}

GameResult selectWinner(List<Player> players, ChaosConfig? chaosConfig) {
  assert(players.length >= 2, 'Need at least 2 players to select a winner');

  if (chaosConfig != null) {
    // CHAOS CONTROL path — explicit, traceable
    if (chaosConfig.targetType == ChaosTargetType.forceWinner &&
        chaosConfig.arrivalIndex != null) {
      final winner = players.firstWhere(
        (p) => p.arrivalIndex == chaosConfig.arrivalIndex,
        orElse: () => players.first,
      );
      return GameResult(
        winners: [winner],
        losers: const [],
        wasChaosControlActive: true,
        timestamp: DateTime.now(),
      );
    }

    if (chaosConfig.targetType == ChaosTargetType.weightedOdds &&
        chaosConfig.weights != null) {
      final idx = _weightedPick(players, chaosConfig.weights!);
      return GameResult(
        winners: [players[idx]],
        losers: const [],
        wasChaosControlActive: true,
        timestamp: DateTime.now(),
      );
    }
  }

  // Fair path — no hidden weighting
  final rng = Random();
  final winner = players[rng.nextInt(players.length)];
  return GameResult(
    winners: [winner],
    losers: const [],
    wasChaosControlActive: false,
    timestamp: DateTime.now(),
  );
}

GameResult selectLoser(List<Player> players, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);

  if (chaosConfig != null &&
      chaosConfig.targetType == ChaosTargetType.forceLoser &&
      chaosConfig.arrivalIndex != null) {
    final loser = players.firstWhere(
      (p) => p.arrivalIndex == chaosConfig.arrivalIndex,
      orElse: () => players.first,
    );
    return GameResult(
      winners: const [],
      losers: [loser],
      wasChaosControlActive: true,
      timestamp: DateTime.now(),
    );
  }

  final rng = Random();
  final loser = players[rng.nextInt(players.length)];
  return GameResult(
    winners: const [],
    losers: [loser],
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

GameResult selectMultiWinner(List<Player> players, int n, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);
  final clampedN = n.clamp(1, players.length - 1);
  final shuffled = _shuffle(players);
  return GameResult(
    winners: shuffled.take(clampedN).toList(),
    losers: const [],
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

GameResult splitTeams(List<Player> players, int teamCount, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);
  final clampedTeams = teamCount.clamp(2, players.length);
  final shuffled = _shuffle(players);
  final teams = List.generate(clampedTeams, (_) => <Player>[]);
  for (int i = 0; i < shuffled.length; i++) {
    teams[i % clampedTeams].add(shuffled[i]);
  }
  return GameResult(
    winners: const [],
    losers: const [],
    teams: teams,
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

GameResult eliminationRound(List<Player> players, ChaosConfig? chaosConfig) {
  return selectLoser(players, chaosConfig);
}
