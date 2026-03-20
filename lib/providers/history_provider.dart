import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';

const _maxHistory = 5;

class HistoryState {
  final List<({GameMode mode, GameResult result})> rounds;
  const HistoryState({this.rounds = const []});
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState());

  void addRound(GameMode mode, GameResult result) {
    final updated = [(mode: mode, result: result), ...state.rounds];
    state = HistoryState(rounds: updated.take(_maxHistory).toList());
  }
}
