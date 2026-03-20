import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int countdownSeconds;

  const SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.countdownSeconds = 2,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? countdownSeconds,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    countdownSeconds: countdownSeconds ?? this.countdownSeconds,
  );
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleSound() =>
      state = state.copyWith(soundEnabled: !state.soundEnabled);

  void toggleVibration() =>
      state = state.copyWith(vibrationEnabled: !state.vibrationEnabled);

  void setCountdown(int seconds) {
    assert(seconds >= 1 && seconds <= 3);
    state = state.copyWith(countdownSeconds: seconds);
  }
}
