import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';

final matchProvider = StateNotifierProvider<MatchNotifier, MatchState?>(
  (ref) => MatchNotifier(),
);

class MatchNotifier extends StateNotifier<MatchState?> {
  MatchNotifier() : super(null);

  void startMatch(MatchConfig config) {
    state = MatchState(config: config);
  }

  void recordSelection(int slot) {
    if (state == null) return;
    state = state!.recordSelection(slot);
  }

  void endMatch() {
    state = null;
  }
}
