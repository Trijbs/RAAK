import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/game_result.dart';
import '../core/randomness.dart';
import '../core/theme.dart';

const _uuid = Uuid();
const _maxPlayers = 10;

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSession>(
  (ref) => GameSessionNotifier(),
);

class GameSessionNotifier extends StateNotifier<GameSession> {
  GameSessionNotifier()
      : super(GameSession.initial(GameMode.winner));

  void startSession(
    GameMode mode, {
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
  }) {
    state = GameSession.initial(
      mode,
      multiWinnerCount: multiWinnerCount,
      teamCount: teamCount,
      chaosConfig: chaosConfig,
    );
  }

  void addPlayer(Player player) {
    if (state.activePlayers.length >= _maxPlayers) return;
    if (state.activePlayers.any((p) => p.pointerId == player.pointerId)) return;
    state = state.copyWith(
      phase: GamePhase.collecting,
      activePlayers: [...state.activePlayers, player],
    );
  }

  void addPlayerFromPointer(int pointerId, Offset position) {
    final index = state.activePlayers.length + state.eliminatedPlayers.length;
    final arrivalIndex = state.activePlayers.length;
    final player = Player(
      id: _uuid.v4(),
      pointerId: pointerId,
      color: RaakColors.playerColor(index),
      nickname: 'P${index + 1}',
      arrivalIndex: arrivalIndex,
      position: position,
    );
    addPlayer(player);
  }

  void updatePlayerPosition(int pointerId, Offset position) {
    state = state.copyWith(
      activePlayers: state.activePlayers.map((p) {
        return p.pointerId == pointerId ? p.copyWith(position: position) : p;
      }).toList(),
    );
  }

  void removePlayer(int pointerId) {
    final updated = state.activePlayers
        .where((p) => p.pointerId != pointerId)
        .toList();
    state = state.copyWith(
      activePlayers: updated,
      phase: updated.length < 2 ? GamePhase.collecting : state.phase,
    );
  }

  void setPhase(GamePhase phase) {
    state = state.copyWith(phase: phase);
  }

  void updateNickname(String playerId, String nickname) {
    state = state.copyWith(
      activePlayers: state.activePlayers.map((p) {
        return p.id == playerId ? p.copyWith(nickname: nickname) : p;
      }).toList(),
    );
  }

  void reveal() {
    if (state.activePlayers.length < 2) return;
    state = state.copyWith(phase: GamePhase.revealing);
    final result = _computeResult();
    state = state.copyWith(phase: GamePhase.done, result: result);
  }

  GameResult _computeResult() {
    final players = state.activePlayers;
    final chaos = state.chaosConfig;

    switch (state.mode) {
      case GameMode.winner:
      case GameMode.chaos:
        return selectWinner(players, chaos);
      case GameMode.loser:
        return selectLoser(players, chaos);
      case GameMode.multiWinner:
        final n = state.multiWinnerCount ?? 2;
        return selectMultiWinner(players, n, chaos);
      case GameMode.teams:
        final t = state.teamCount ?? 2;
        return splitTeams(players, t, chaos);
      case GameMode.elimination:
        return eliminationRound(players, chaos);
    }
  }

  void advanceElimination() {
    final loser = state.result?.losers.firstOrNull;
    if (loser == null) return;

    final remaining = state.activePlayers
        .where((p) => p.id != loser.id)
        .toList();
    final eliminated = [...state.eliminatedPlayers, loser];

    if (remaining.length <= 1) {
      state = state.copyWith(
        activePlayers: remaining,
        eliminatedPlayers: eliminated,
        eliminationPhase: EliminationPhase.complete,
        result: GameResult(
          winners: remaining,
          losers: eliminated,
          wasChaosControlActive: state.isChaosActive,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      state = state.copyWith(
        activePlayers: remaining,
        eliminatedPlayers: eliminated,
        phase: GamePhase.collecting,
        eliminationPhase: EliminationPhase.roundActive,
        eliminationRound: state.eliminationRound + 1,
        result: null,
      );
    }
  }

  void resetForRematch() {
    state = state.copyWith(phase: GamePhase.collecting, result: null);
  }

  void resetFull() {
    state = GameSession.initial(state.mode);
  }
}
