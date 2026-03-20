import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raak/providers/game_session_provider.dart';
import 'package:raak/models/game_session.dart';
import 'package:raak/models/player.dart';
import 'package:flutter/material.dart';

Player makeTestPlayer(int index) => Player(
  id: 'test-$index',
  pointerId: index,
  color: Colors.red,
  nickname: 'P${index + 1}',
  arrivalIndex: index,
  position: const Offset(100, 100),
);

ProviderContainer makeContainer() => ProviderContainer();

void main() {
  group('GameSessionNotifier', () {
    test('initial state is waiting phase', () {
      final container = makeContainer();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.waiting);
      expect(session.activePlayers.isEmpty, true);
    });

    test('addPlayer transitions to collecting phase', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 1);
    });

    test('removePlayer removes by pointerId', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.addPlayer(makeTestPlayer(1));
      notifier.removePlayer(0);
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 1);
      expect(session.activePlayers.first.pointerId, 1);
    });

    test('max 10 players enforced', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      for (int i = 0; i < 12; i++) {
        notifier.addPlayer(makeTestPlayer(i));
      }
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 10);
    });

    test('resetForRematch preserves mode and players, resets phase to collecting', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.addPlayer(makeTestPlayer(1));
      notifier.resetForRematch();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.collecting);
      expect(session.mode, GameMode.winner);
      expect(session.activePlayers.length, 2);
      expect(session.result, isNull);
    });

    test('resetFull returns to waiting with empty players', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.resetFull();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.waiting);
      expect(session.activePlayers.isEmpty, true);
    });
  });
}
