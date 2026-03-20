# RAAK

Party finger-chooser app. Place fingers on screen — RAAK picks the winner.

## Features

- 2–10 players simultaneously on one screen
- 6 game modes: Winner, Loser, Multi-Winner, Teams, Elimination, Chaos Control
- High-energy "Thumbnail Chaos" visual identity
- Explicitly disclosed Chaos Control mode (never hidden)
- Haptic feedback + sound toggle
- In-memory round history (last 5 rounds)

## Run

```bash
flutter pub get
flutter run
```

## Requirements

- Flutter 3.x
- Dart SDK >=3.0.0
- iOS 14+ or Android API 21+

## Test

```bash
flutter test
```

All 14 unit tests cover randomness engine and game session state machine.

## Architecture

- **Framework:** Flutter + Riverpod StateNotifier
- **Touch:** Raw pointer events via `Listener` widget (not GestureDetector)
- **State:** `GameSessionNotifier` is the single source of truth for game state
- **Randomness:** Isolated in `lib/core/randomness.dart` — fair Fisher-Yates shuffle
- **Design:** Thumbnail Chaos aesthetic — volt/shock/mint/blast color system

## Chaos Control

Chaos Control is an explicitly disclosed, opt-in mode that allows the host to influence results. It is **never** a hidden mechanic:

- OFF by default
- Must be deliberately activated in Mode Select
- Hazard-stripe banner visible on arena and result screens when active
- See `lib/core/randomness.dart` for the ethical code comment

## Known Limitations (v1)

- History is in-memory — lost on app restart
- No tablet-optimized layout
- Dark mode only
- Screenshot-shareable result card deferred to v1.1
