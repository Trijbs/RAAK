import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';

const _maxHistory = 25;
const _kHistoryKey = 'raak_history_v1';

class HistoryEntry {
  final GameMode mode;
  final GameResult result;
  const HistoryEntry({required this.mode, required this.result});

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'result': result.toJson(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    mode: GameMode.values.firstWhere((m) => m.name == j['mode']),
    result: GameResult.fromJson(j['result'] as Map<String, dynamic>),
  );
}

class HistoryState {
  final List<HistoryEntry> rounds;
  const HistoryState({this.rounds = const []});
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  late final Future<void> initFuture;

  HistoryNotifier() : super(const HistoryState()) {
    initFuture = _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null) return;
    try {
      final entries = (jsonDecode(raw) as List)
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .take(_maxHistory)
          .toList();
      state = HistoryState(rounds: entries);
    } catch (_) {
      // Corrupt data — start fresh
    }
  }

  Future<void> addRound(HistoryEntry entry) async {
    await initFuture; // ensure _init() has loaded persisted data before we prepend
    final updated = [entry, ...state.rounds].take(_maxHistory).toList();
    state = HistoryState(rounds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}
