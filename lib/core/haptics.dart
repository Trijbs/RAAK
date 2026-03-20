import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

// Haptics and sound wrapper.
// All feedback goes through this class — never call HapticFeedback or AudioPlayer directly.
class RaakHaptics {
  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  RaakHaptics(this._ref);

  SettingsState get _settings => _ref.read(settingsProvider);

  void fingerDown() {
    if (_settings.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void countdownTick() {
    if (_settings.vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void reveal() {
    if (_settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> playSound(String assetPath) async {
    if (!_settings.soundEnabled) return;
    try {
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Sound assets may not be present in dev — fail silently
    }
  }
}

final hapticsProvider = Provider((ref) => RaakHaptics(ref));
