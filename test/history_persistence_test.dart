import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raak/models/player.dart';
import 'package:raak/models/game_result.dart';
import 'package:raak/models/game_session.dart';
import 'package:raak/providers/history_provider.dart';

Player _makePlayer(int arrivalIndex) => Player(
  id: 'p$arrivalIndex',
  pointerId: arrivalIndex,
  color: const Color(0xFFFFE500),
  nickname: 'P${arrivalIndex + 1}',
  arrivalIndex: arrivalIndex,
  position: Offset.zero,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Player serialization', () {
    test('toHistoryJson / fromHistoryJson round-trip', () {
      final player = _makePlayer(2);
      final json = player.toHistoryJson();
      final restored = Player.fromHistoryJson(json);
      expect(restored.arrivalIndex, player.arrivalIndex);
      expect(restored.nickname, player.nickname);
    });
  });

  group('GameResult serialization', () {
    test('toJson / fromJson round-trip', () {
      final result = GameResult(
        winners: [_makePlayer(0)],
        losers: [_makePlayer(1)],
        wasChaosControlActive: false,
        timestamp: DateTime(2026, 3, 21),
      );
      final json = result.toJson();
      final restored = GameResult.fromJson(json);
      expect(restored.winners.first.arrivalIndex, 0);
      expect(restored.losers.first.arrivalIndex, 1);
      expect(restored.wasChaosControlActive, isFalse);
    });
  });

  group('HistoryEntry serialization', () {
    test('toJson / fromJson round-trip', () {
      final entry = HistoryEntry(
        mode: GameMode.winner,
        result: GameResult(
          winners: [_makePlayer(0)],
          losers: [],
          wasChaosControlActive: false,
          timestamp: DateTime(2026, 3, 21),
        ),
      );
      final json = entry.toJson();
      final restored = HistoryEntry.fromJson(json);
      expect(restored.mode, GameMode.winner);
      expect(restored.result.winners.first.arrivalIndex, 0);
    });
  });

  group('HistoryNotifier', () {
    test('persists and restores up to 25 entries', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = HistoryNotifier();
      await notifier.initFuture;

      for (int i = 0; i < 30; i++) {
        await notifier.addRound(HistoryEntry(
          mode: GameMode.winner,
          result: GameResult(
            winners: [_makePlayer(i % 5)],
            losers: [],
            wasChaosControlActive: false,
            timestamp: DateTime(2026, 3, 21),
          ),
        ));
      }
      expect(notifier.state.rounds.length, 25);

      // Simulate app restart by reading from SharedPreferences
      final notifier2 = HistoryNotifier();
      await notifier2.initFuture;
      expect(notifier2.state.rounds.length, 25);
    });
  });
}
