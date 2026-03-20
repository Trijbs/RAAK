# RAAK — Design Specification
**Date:** 2026-03-20
**Version:** 1.1
**Scope:** v1 Core + Polish Layer

---

## 1. Product Summary

RAAK is a multiplayer party app where 2–10 players simultaneously place fingers on a shared phone screen and the app randomly selects a winner, loser, teams, or runs an elimination sequence. It is an original spiritual successor to the Chwazi-style interaction model, built with a high-energy "Thumbnail Chaos" aesthetic inspired by Dutch creator and internet entertainment culture.

**Legal position:** RAAK shares no brand assets, source code, package naming, layout details, or protected visual identity with any existing app. All design, naming, copy, and interaction patterns are original.

---

## 2. Stack

| Decision | Choice | Reason |
|---|---|---|
| Framework | Flutter | Native pointer events, Skia renderer, 60/120fps animations, superior multi-touch handling vs JS bridge |
| State management | Riverpod + StateNotifier | Clean game session isolation, testable logic, no prop drilling |
| Language | Dart (typed) | Required by Flutter; full type safety |
| Target platforms | iOS + Android | Flutter ships to both from one codebase |
| Offline | Yes — fully offline-first | No network dependency for core gameplay |

---

## 3. v1 Feature Scope

### Mandatory (ship blockers)
- Home screen with SPEEL NU CTA
- Touch arena with live multi-touch finger detection
- Finger bubble visuals (idle → locked → winner/loser states)
- 6 game modes (see Section 6)
- Selection reveal animation with sticker labels
- Rematch + New Round buttons
- Nickname labels per finger/player
- Session history (last 5 rounds, in-memory only)
- Sound toggle
- Vibration toggle
- Settings panel
- Dark mode (default, no toggle in v1)
- Chaos Control mode with mandatory disclosure (see Section 7)

### Out of scope for v1 (roadmap)
- Dares / punishment list
- Streamer mode
- Unlockable themes
- Best of 5 party mode
- Voice countdown packs
- House rules presets
- Screenshot-shareable result card (deferred to v1.1)
- Persistent history across app restarts

---

## 4. Project Structure

```
RAAK/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp, routing, theme injection
│   ├── core/
│   │   ├── randomness.dart             # ALL random logic isolated here
│   │   ├── theme.dart                  # design tokens (colors, type, spacing)
│   │   └── haptics.dart                # vibration + audio wrapper
│   ├── models/
│   │   ├── player.dart                 # see Section 8a
│   │   ├── game_session.dart           # see Section 8b
│   │   └── game_result.dart            # see Section 8c
│   ├── providers/
│   │   ├── game_session_provider.dart  # GameSessionNotifier (central state)
│   │   ├── settings_provider.dart      # sound, vibration prefs
│   │   └── history_provider.dart       # last 5 round results (in-memory)
│   ├── screens/
│   │   ├── home/home_screen.dart
│   │   ├── mode_select/mode_select_screen.dart
│   │   ├── arena/arena_screen.dart
│   │   ├── reveal/reveal_screen.dart
│   │   └── settings/settings_screen.dart
│   └── widgets/
│       ├── finger_bubble.dart          # animated touch point widget
│       ├── sticker_label.dart          # rotated result label
│       ├── result_card.dart            # round result display
│       └── chaos_banner.dart           # "CHAOS CONTROL ACTIEF" disclosure
├── test/
│   ├── randomness_test.dart
│   └── game_session_test.dart
├── assets/
│   ├── fonts/                          # system fonts only in v1 (see Section 9)
│   └── sounds/
└── pubspec.yaml
```

---

## 5. Screen Flow

```
HOME → MODE SELECT → TOUCH ARENA → REVEAL
                                     ├── REMATCH → TOUCH ARENA (provider reset in place, same mode)
                                     └── NEW ROUND → MODE SELECT (provider fully reset)

HOME ──► SETTINGS (modal)
MODE SELECT ──► CHAOS CONTROL CONFIG (bottom sheet, when mode = chaos)
HOME / REVEAL ──► HISTORY (modal)
```

---

## 6. Game Modes

| ID | Name | Dutch Label | Logic |
|---|---|---|---|
| `winner` | Pick Winner | WINNAAR | 1 random finger selected from active set |
| `loser` | Pick Loser | PECH | 1 random finger selected as loser |
| `multi_winner` | Pick N Winners | WINNAARS | N fingers selected (N chosen in Mode Select from 2 up to a placeholder max of 5; validated against actual player count at reveal time — if N ≥ player count, N clamps to count-1) |
| `teams` | Split Teams | TEAMS | Fingers shuffled into 2–4 equal color groups (team count set in Mode Select) |
| `elimination` | Elimination | OVERLEVER | See Section 8b — sub-phase loop |
| `chaos` | Chaos Control | ⚠️ CHAOS | Host-configured forced or weighted result (see Section 7) |

---

## 7. Chaos Control — Ethical Specification

Chaos Control is an **opt-in, explicitly disclosed** mode that allows a host to influence results. It is never a hidden mechanic.

### Requirements
- OFF by default
- Must be deliberately activated in Mode Select before the round
- Hazard-stripe disclosure banner visible on arena screen AND result screen when active
- Banner text: "Chaos Control Actief — Resultaten worden handmatig beïnvloed"
- Result screen shows a distinct visual treatment (hazard stripe, not the clean fair-mode reveal)
- One-tap to deactivate

### ChaosConfig data structure

```dart
enum ChaosTargetType { forceWinner, forceLoser, weightedOdds }

class ChaosConfig {
  final ChaosTargetType targetType;

  // For forceWinner / forceLoser:
  // arrivalIndex is 0-based order in which the finger landed (0 = first down).
  // null means "not yet set" — UI must validate non-null before starting round.
  final int? arrivalIndex;

  // For weightedOdds:
  // Map of arrivalIndex → weight (0.0–1.0). Weights must sum to 1.0.
  // All fingers not in the map share remaining weight equally.
  final Map<int, double>? weights;

  const ChaosConfig({
    required this.targetType,
    this.arrivalIndex,
    this.weights,
  });
}
```

### Code requirement
`randomness.dart` must contain a top-level comment:
```dart
// CHAOS CONTROL: When chaosConfig is non-null, results are NOT random.
// Weighting or forcing is applied explicitly per the host's configuration.
// This is never called without the UI disclosing it to all players.
```

---

## 8. Data Models

### 8a. Player

```dart
class Player {
  final String id;           // UUID generated at touch-down
  final int pointerId;       // Flutter pointer event ID (int, from PointerEvent.pointer)
  final Color color;         // assigned from player color cycle
  final String nickname;     // user-entered or auto "P1", "P2" etc.
  final int arrivalIndex;    // 0-based order this finger landed (used by Chaos Control)
  final Offset position;     // last known touch position on screen

  const Player({ ... });
}
```

### 8b. GameSession

```dart
enum GamePhase { waiting, collecting, locked, revealing, done }

// Elimination sub-phase (only active when mode == GameMode.elimination)
enum EliminationPhase { roundActive, roundResult, complete }

class GameSession {
  final GameMode mode;
  final GamePhase phase;
  final List<Player> activePlayers;     // fingers currently on screen
  final List<Player> eliminatedPlayers; // removed in previous elimination rounds
  final int? multiWinnerCount;          // set in Mode Select for multi_winner mode
  final int? teamCount;                 // set in Mode Select for teams mode (2–4)
  final ChaosConfig? chaosConfig;       // null = fair mode
  final GameResult? result;             // null until phase == done (or elimination roundResult)

  // Elimination only
  final EliminationPhase eliminationPhase;
  final int eliminationRound;           // 1-based

  const GameSession({ ... });
}
```

### 8c. GameResult

```dart
class GameResult {
  final List<Player> winners;  // empty for loser-only modes
  final List<Player> losers;   // empty for winner-only modes
  final List<List<Player>>? teams; // non-null only for teams mode
  final bool wasChaosControlActive;
  final DateTime timestamp;

  const GameResult({ ... });
}
```

---

## 9. Touch Engine

### Widget
Uses Flutter's `Listener` widget with raw pointer events — not GestureDetector (single-touch only).

### Session Phases & Transitions

```
WAITING
  │  onPointerDown (2nd finger lands)
  ▼
COLLECTING
  │  2s timer elapses with no new finger
  ▼
LOCKED  ◄─── onPointerDown resets timer, returns to COLLECTING
  │  countdown reaches 0
  ▼
REVEALING
  │  animations complete
  ▼
DONE
  │  user taps REMATCH         │  user taps NEW ROUND
  ▼                            ▼
COLLECTING (in-place reset,   WAITING (full provider reset,
same mode, same config)       navigate to Mode Select)
```

**Elimination mode loop:**
```
DONE (elimination round N)
  │  survivor count > 1
  ▼
COLLECTING (eliminated player bubble removed, remaining fingers stay)
  │  ... normal countdown ...
  ▼
REVEALING → DONE (elimination round N+1)
  │  survivor count == 1
  ▼
DONE (final — shows OVERLEVER result, no more rounds)
```

### Edge Cases
- Minimum 2 fingers required to trigger countdown
- Finger lifted during countdown → countdown resets, bubble removed
- Max 10 simultaneous touches enforced in state
- Stale pointer IDs cleaned on every `onPointerUp`
- No race conditions: all touch mutations go through `GameSessionNotifier`

### Nickname UX
Nicknames are **not** prompted during the COLLECTING phase (would block multi-touch). Instead:
- Each bubble auto-labels as "P1", "P2"… by arrival order
- After DONE, a nickname edit sheet is optionally available (tap a bubble on the result screen)
- Edited nicknames persist in the provider for the session lifetime (rematch preserves them)

---

## 10. Design System

### Colors
| Token | Hex | Usage |
|---|---|---|
| `void` | `#0D0D0D` | Background |
| `surface` | `#1A1A1A` | Cards, panels |
| `volt` | `#FFE500` | Primary CTA, winner, logo — **only use with `#111` text** |
| `shock` | `#FF00AA` | Loser — **only use with white text** |
| `mint` | `#00FFAA` | Teams, success — **only use with `#111` text** |
| `blast` | `#FF3C00` | Chaos Control, danger — **only use with white text** |
| `current` | `#0A84FF` | Info, team color — **only use with white text** |
| `static` | `#BF5AF2` | Team color, accent — **only use with white text** |

**Contrast note:** `shock` (#FF00AA) on `void` (#0D0D0D) is ~3.9:1 — below WCAG AA for text. `shock` must only be used as a background color for sticker labels (white text on top), never as text color on dark backgrounds.

Player bubble colors cycle: volt → shock → mint → blast → current → static

### Typography
- **Display/Logo:** System-available heavy weight sans-serif (`BlackHanSans` if bundled, else `Impact` on iOS, `sans-serif-black` on Android via `fontWeight: FontWeight.w900`). No custom font bundle required for v1 — system fallback is acceptable and documented.
- **Sticker labels:** System sans-serif, `FontWeight.w800`, slight rotation (±1–3°), uppercase
- **Body:** System sans-serif, `FontWeight.w600`, white/grey on dark
- **Caption/Meta:** `FontWeight.w500`, uppercase, letter-spacing 2px

### Buttons
- Hard 4px drop shadow (offset, not blur)
- 3px solid `Color(0xFF111111)` border
- `BorderRadius.circular(12)` max
- Uppercase always
- Primary: `volt` background, `#111` text
- Secondary: `shock` background, white text
- Ghost: transparent, `#333` border, `#888` text

### Finger Bubble States
- **Idle:** 60px circle, player color, 3px border, single pulse ring (opacity 0.15)
- **Locked:** double ring (opacity 0.2 + 0.08), no scale change
- **Winner:** scale 1.27, glow shadow (player color at 0.6 opacity), sticker label above
- **Loser:** scale 0.8, opacity 0.6, grey dashed border, PECH sticker

### Chaos Control Banner
Hazard diagonal stripe (`blast` + `volt` alternating) as 3px border, dark inner container (`#1A0A00`), ⚠️ icon, `blast`-colored uppercase heading, `#888` subtext. Must be visually unmistakable — never rendered without the stripe.

---

## 11. Randomness Requirements

- `randomness.dart` is the **only** file that performs selection logic
- Fair mode: uses `Random().nextInt(n)` with a Fisher-Yates shuffle for team splits — no hidden weighting
- Chaos mode: uses explicit `ChaosConfig` object with documented weight table
- Both paths are unit-tested in `test/randomness_test.dart`
- No global random state — a fresh `Random()` instance per selection call

---

## 12. Settings Screen Contents

The settings screen (modal) contains:

| Setting | Type | Default |
|---|---|---|
| Sound effects | Toggle | ON |
| Vibration / haptics | Toggle | ON |
| Countdown duration | Selector (1s / 2s / 3s) | 2s |
| About / credits | Link row | — |

Dark mode is always ON in v1 — no toggle. Chaos Control is configured in Mode Select, not Settings.

---

## 13. Accessibility

- All interactive elements minimum 44×44pt touch target
- Finger bubbles minimum 60px diameter
- Sticker labels: white on colored background — all combinations verified ≥ 4.5:1
- `shock` never used as text color on dark background (see Section 10 contrast note)
- Haptics and sound are opt-out via Settings
- Arena works in portrait and landscape

---

## 14. Known Limitations (v1)

- No cloud save or cross-device session sync
- History is in-memory only — lost on app restart
- Dark mode only — no light mode toggle
- Screenshot-shareable result card deferred to v1.1
- Dares/punishment list deferred
- Streamer mode deferred
- Voice countdown deferred
- Unlockable themes deferred
- No tablet-optimized layout (works, not optimized)
- `multi_winner` N clamps silently if N ≥ player count at reveal time
