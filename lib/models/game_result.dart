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
}
