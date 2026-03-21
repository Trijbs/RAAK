import 'player.dart';

class GameResult {
  final List<Player> winners;
  final List<Player> losers;
  final List<List<Player>>? teams;
  final bool wasChaosControlActive;
  final DateTime timestamp;

  const GameResult({
    required this.winners,
    required this.losers,
    required this.wasChaosControlActive,
    required this.timestamp,
    this.teams,
  });

  Map<String, dynamic> toJson() => {
    'winners': winners.map((p) => p.toHistoryJson()).toList(),
    'losers': losers.map((p) => p.toHistoryJson()).toList(),
    'teams': teams?.map((t) => t.map((p) => p.toHistoryJson()).toList()).toList() ?? [],
    'wasChaosControlActive': wasChaosControlActive,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
    winners: (j['winners'] as List)
        .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
        .toList(),
    losers: (j['losers'] as List)
        .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
        .toList(),
    teams: (j['teams'] as List).isEmpty
        ? null
        : (j['teams'] as List)
            .map((t) => (t as List)
                .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
                .toList())
            .toList(),
    wasChaosControlActive: j['wasChaosControlActive'] as bool? ?? false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
  );
}
