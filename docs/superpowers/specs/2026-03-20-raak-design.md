# RAAK — Design Specification
**Date:** 2026-03-20
**Version:** 1.0
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
- Session history (last 5 rounds)
- Sound toggle
- Vibration toggle
- Settings panel
- Dark mode (default)
- Chaos Control mode with mandatory disclosure (see Section 7)

### Out of scope for v1 (roadmap)
- Dares / punishment list
- Streamer mode
- Unlockable themes
- Best of 5 party mode
- Voice countdown packs
- House rules presets
- Screenshot-shareable result card (deferred to v1.1)

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
│   │   ├── player.dart                 # id, color, nickname, touchPointerId
│   │   ├── game_session.dart           # mode, players, phase, chaosConfig
│   │   └── game_result.dart            # winners, losers, teams
│   ├── providers/
│   │   ├── game_session_provider.dart  # GameSessionNotifier (central state)
│   │   ├── settings_provider.dart      # sound, vibration, theme prefs
│   │   └── history_provider.dart       # last 5 round results
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
│   ├── fonts/
│   └── sounds/
└── pubspec.yaml
```

---

## 5. Screen Flow

```
HOME → MODE SELECT → TOUCH ARENA → REVEAL
                                     ├── REMATCH → TOUCH ARENA (same mode)
                                     └── NEW ROUND → MODE SELECT

HOME ──► SETTINGS (modal)
MODE SELECT ──► CHAOS CONTROL CONFIG (sheet, when mode = Chaos)
HOME / REVEAL ──► HISTORY (modal)
```

---

## 6. Game Modes

| ID | Name | Dutch Label | Logic |
|---|---|---|---|
| `winner` | Pick Winner | WINNAAR | 1 random finger selected from active set |
| `loser` | Pick Loser | PECH | 1 random finger selected as loser |
| `multi_winner` | Pick N Winners | WINNAARS | N fingers selected (N: 2 to count-1, set in mode select) |
| `teams` | Split Teams | TEAMS | Fingers shuffled into 2–4 equal color groups |
| `elimination` | Elimination | OVERLEVER | Repeated rounds removing 1 loser each until 1 survivor |
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

### Host options
- **Force winner:** Select which position (1st finger down, 2nd, etc.) wins
- **Force loser:** Select which position loses
- **Weighted odds:** Assign a higher probability % to a specific finger

### Code requirement
`randomness.dart` must contain a top-level comment:
```dart
// CHAOS CONTROL: When chaosConfig is non-null, results are NOT random.
// Weighting or forcing is applied explicitly per the host's configuration.
// This is never called without the UI disclosing it to all players.
```

---

## 8. Touch Engine

### Widget
Uses Flutter's `Listener` widget with raw pointer events — not GestureDetector (single-touch only).

### Session Phases
```
WAITING → COLLECTING → LOCKED → REVEALING → DONE
```

- **WAITING:** Arena blank, instruction shown
- **COLLECTING:** Fingers land; each gets bubble + color + nickname prompt
- **LOCKED:** 2s after last new finger, countdown begins (3…2…1). New finger resets countdown.
- **REVEALING:** `randomness.dart` runs selection; bubbles animate to result states
- **DONE:** Result frozen; Rematch / New Round CTAs appear

### Edge Cases
- Minimum 2 fingers required to trigger countdown
- Finger lifted during countdown → countdown resets, bubble removed
- Max 10 simultaneous touches enforced in state
- Stale pointer IDs cleaned on every `onPointerUp`
- No race conditions: all touch mutations go through `GameSessionNotifier`

---

## 9. Design System

### Colors
| Token | Hex | Usage |
|---|---|---|
| `void` | `#0D0D0D` | Background |
| `surface` | `#1A1A1A` | Cards, panels |
| `volt` | `#FFE500` | Primary CTA, winner, logo |
| `shock` | `#FF00AA` | Loser, accents |
| `mint` | `#00FFAA` | Teams, success |
| `blast` | `#FF3C00` | Chaos Control, danger |
| `current` | `#0A84FF` | Info, team color |
| `static` | `#BF5AF2` | Team color, accent |

Player bubble colors cycle: volt → shock → mint → blast → current → static

### Typography
- **Display/Logo:** Impact or `Arial Black`, weight 900, tracking -2px
- **Sticker labels:** System sans-serif, weight 800, slight rotation (±1–3°), uppercase
- **Body:** System sans-serif, weight 600, white/grey on dark
- **Caption/Meta:** weight 500, uppercase, letter-spacing 2px

### Buttons
- Hard 4px drop shadow (offset, not blur)
- 3px solid border, `#111`
- No soft border-radius (12px max)
- Uppercase always
- Primary: `volt` background, `#111` text
- Secondary: `shock` background, white text
- Ghost: transparent, `#333` border, `#888` text

### Finger Bubble States
- **Idle:** 60px circle, player color, 3px border, single pulse ring (opacity 0.15)
- **Locked:** double ring (opacity 0.2 + 0.08), no scale change
- **Winner:** scale 1.27, glow shadow (color * 0.6 opacity), sticker label above
- **Loser:** scale 0.8, opacity 0.6, grey border dashed, PECH sticker

### Chaos Control Banner
Hazard diagonal stripe (blast + volt alternating) as border, dark inner container, ⚠️ icon, red uppercase heading, grey subtext. Must be visually unmistakable.

---

## 10. Randomness Requirements

- `randomness.dart` is the **only** file that performs selection logic
- Fair mode: uses `Random().nextInt(n)` with a Fisher-Yates shuffle for team splits — no hidden weighting
- Chaos mode: uses explicit `ChaosConfig` object with documented weight table
- Both paths are unit-tested in `test/randomness_test.dart`
- No global random state — a fresh `Random()` instance per selection call

---

## 11. Accessibility

- All interactive elements minimum 44×44pt touch target
- Finger bubbles scale to at least 60px diameter
- Labels have sufficient contrast (4.5:1 minimum on dark backgrounds)
- Haptics and sound are opt-out, not opt-in
- Arena works in both portrait and landscape

---

## 12. Known Limitations (v1)

- No cloud save or cross-device session sync
- Screenshot-shareable result card deferred to v1.1
- Dares/punishment list deferred
- Streamer mode deferred
- Voice countdown deferred
- Unlockable themes deferred
- No tablet-optimized layout (works, but not optimized)
