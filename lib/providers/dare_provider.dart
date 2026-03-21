import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dare.dart';
import '../core/dares_data.dart';

const _kDaresKey = 'raak_dares_v1';

final dareProvider = StateNotifierProvider<DareNotifier, List<Dare>>(
  (ref) => DareNotifier(),
);

class DareNotifier extends StateNotifier<List<Dare>> {
  late final Future<void> initFuture;

  DareNotifier() : super([]) {
    initFuture = _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDaresKey);
    if (raw == null) {
      state = List.from(kBuiltinDares);
      return;
    }
    final saved = (jsonDecode(raw) as List)
        .map((e) => Dare.fromJson(e as Map<String, dynamic>))
        .toList();
    final savedMap = {for (final d in saved) d.id: d};
    // Merge: apply saved toggles to built-ins, then append custom dares
    final merged = kBuiltinDares
        .map((d) => savedMap.containsKey(d.id)
            ? d.copyWith(isEnabled: savedMap[d.id]!.isEnabled)
            : d)
        .toList();
    final custom = saved.where((d) => d.isCustom).toList();
    state = [...merged, ...custom];
  }

  Dare? drawRandom() {
    final enabled = state.where((d) => d.isEnabled).toList();
    if (enabled.isEmpty) return null;
    enabled.shuffle();
    return enabled.first;
  }

  Dare? drawAgain(String excludeId) {
    final enabled = state.where((d) => d.isEnabled && d.id != excludeId).toList();
    if (enabled.isEmpty) return null;
    enabled.shuffle();
    return enabled.first;
  }

  void addCustom(String text) {
    final dare = Dare(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isCustom: true,
    );
    state = [...state, dare];
    _persist();
  }

  void toggle(String id) {
    state = state
        .map((d) => d.id == id ? d.copyWith(isEnabled: !d.isEnabled) : d)
        .toList();
    _persist();
  }

  void deleteCustom(String id) {
    state = state.where((d) => !(d.id == id && d.isCustom)).toList();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDaresKey, jsonEncode(state.map((d) => d.toJson()).toList()));
  }
}
