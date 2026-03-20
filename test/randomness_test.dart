import 'package:flutter_test/flutter_test.dart';
import 'package:raak/core/randomness.dart';
import 'package:raak/models/player.dart';
import 'package:raak/models/game_session.dart';
import 'package:flutter/material.dart';

Player makePlayer(int index) => Player(
  id: 'p$index',
  pointerId: index,
  color: Colors.red,
  nickname: 'P${index + 1}',
  arrivalIndex: index,
  position: Offset.zero,
);

void main() {
  final players = List.generate(5, makePlayer);

  group('selectWinner (fair)', () {
    test('returns exactly 1 winner from the player list', () {
      final result = selectWinner(players, null);
      expect(result.winners.length, 1);
      expect(result.losers.isEmpty, true);
      expect(players.contains(result.winners.first), true);
      expect(result.wasChaosControlActive, false);
    });
  });

  group('selectLoser (fair)', () {
    test('returns exactly 1 loser from the player list', () {
      final result = selectLoser(players, null);
      expect(result.losers.length, 1);
      expect(result.winners.isEmpty, true);
      expect(players.contains(result.losers.first), true);
    });
  });

  group('selectMultiWinner (fair)', () {
    test('returns exactly N winners', () {
      final result = selectMultiWinner(players, 2, null);
      expect(result.winners.length, 2);
    });

    test('clamps N if N >= player count', () {
      final result = selectMultiWinner(players, 5, null);
      expect(result.winners.length, 4);
    });
  });

  group('splitTeams (fair)', () {
    test('assigns every player to exactly one team', () {
      final result = splitTeams(players, 2, null);
      final allAssigned = result.teams!.expand((t) => t).toList();
      expect(allAssigned.length, players.length);
      for (final p in players) {
        expect(allAssigned.contains(p), true);
      }
    });

    test('creates the requested number of teams', () {
      final result = splitTeams(players, 2, null);
      expect(result.teams!.length, 2);
    });
  });

  group('Chaos Control — forceWinner', () {
    test('returns the player at arrivalIndex 0 as winner', () {
      const chaos = ChaosConfig(
        targetType: ChaosTargetType.forceWinner,
        arrivalIndex: 0,
      );
      final result = selectWinner(players, chaos);
      expect(result.winners.first.arrivalIndex, 0);
      expect(result.wasChaosControlActive, true);
    });
  });

  group('Chaos Control — weightedOdds', () {
    test('returns a winner (smoke test)', () {
      const chaos = ChaosConfig(
        targetType: ChaosTargetType.weightedOdds,
        weights: {0: 0.9, 1: 0.1},
      );
      final result = selectWinner(players, chaos);
      expect(result.winners.length, 1);
      expect(result.wasChaosControlActive, true);
    });
  });
}
