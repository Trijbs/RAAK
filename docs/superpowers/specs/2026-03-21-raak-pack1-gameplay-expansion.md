# RAAK Pack 1 — Gameplay Expansion Design Spec

**Date:** 2026-03-21
**Version:** 1.0
**Scope:** Best of 5 / Party Mode, Dares, Persistent History

---

## 1. Summary

Pack 1 adds three gameplay features to RAAK v1 without touching the existing game engine. A new `Match` layer wraps multi-round play above `GameSession`. A dare system draws from a bundled Dutch list and lets players manage custom dares. History is persisted across restarts via SharedPreferences.

---

## 2. Architecture Principle

The existing `game_session_provider.dart`, `arena_screen.dart`, and `randomness.dart` are **not modified**. All new features wrap around or hook into the existing flow at well-defined seams (mode select config, post-reveal navigation, settings screen, history provider).

---

## 3. Feature: Best of 5 / Party Mode

### 3a. Model — `lib/models/match.dart`

```dart
class MatchConfig {
  final int winTarget; // 2 = Best of 3, 3 = Best of 5, 4 = Best of 7
  const MatchConfig({required this.winTarget});
}

class MatchState {
  final MatchConfig config;
  final int roundNumber;          // starts at 1
  final Map<int, int> scores;     // playerSlot -> wins
  final int? matchWinner;         // slot index, null until match decided

  const MatchState({
    required this.config,
    this.roundNumber = 1,
    this.scores = const {},
    this.matchWinner,
  });

  bool get isActive => matchWinner == null;

  MatchState recordWin(int slot) {
    final newScores = Map<int, int>.from(scores);
    newScores[slot] = (newScores[slot] ?? 0) + 1;
    final winner = newScores[slot]! >= config.winTarget ? slot : null;
    return MatchState(
      config: config,
      roundNumber: roundNumber + 1,
      scores: newScores,
      matchWinner: winner,
    );
  }
}
```

### 3b. Provider — `lib/providers/match_provider.dart`

`MatchNotifier extends StateNotifier<MatchState?>`. Null state = no active match (normal single-round play).

Methods:
- `startMatch(MatchConfig config)` — initialises a fresh `MatchState`
- `recordRoundResult(int winnerSlot)` — calls `MatchState.recordWin`, updates state
- `endMatch()` — resets to null

### 3c. Mode Select Changes

When `GameMode.winner` or `GameMode.loser` is selected, a **"PARTY MODE"** toggle row appears below the mode card. When enabled, a row of three chips appears: **Best of 3 / Best of 5 / Best of 7** (default: Best of 5).

The selected `MatchConfig` is passed into `_startGame()` and handed to `MatchNotifier.startMatch()` before navigating to `/arena`.

### 3d. Reveal Screen Changes

When `matchProvider` is non-null and active:
- Below the result card, a compact **score tally** row is shown (e.g. "Speler 1: 2 — Speler 3: 1 — Speler 2: 0")
- The **REMATCH** button continues the current match (calls `gameSessionProvider.notifier.startSession()` with same config, does NOT reset match)
- **NIEUWE RONDE** resets the match entirely (`matchProvider.notifier.endMatch()`)

After `reveal()`, if `matchProvider.recordRoundResult(winnerSlot)` causes `matchWinner != null`, navigation goes to `/match-summary` instead of staying on reveal.

### 3e. Match Summary Screen — `lib/screens/match_summary/match_summary_screen.dart`

Full-screen result showing:
- Champion slot highlighted with volt/winner color and a large sticker label ("KAMPIOEN")
- Full score breakdown table for all slots
- **NIEUW SPEL** button — ends match, returns to home
- **NIEUWE RONDE** button — ends match, goes to mode select

### 3f. Player Identity

Player identity is by arrival order (slot index, 0-based), consistent with v1 color assignment (`RaakColors.playerColor(index)`). No new nickname system in Pack 1.

---

## 4. Feature: Dares

### 4a. Model — `lib/models/dare.dart`

```dart
class Dare {
  final String id;
  final String text;
  final bool isCustom;
  final bool isEnabled;

  const Dare({
    required this.id,
    required this.text,
    this.isCustom = false,
    this.isEnabled = true,
  });

  Dare copyWith({bool? isEnabled}) => Dare(
    id: id, text: text, isCustom: isCustom,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'isCustom': isCustom, 'isEnabled': isEnabled,
  };

  factory Dare.fromJson(Map<String, dynamic> j) => Dare(
    id: j['id'], text: j['text'],
    isCustom: j['isCustom'] ?? false,
    isEnabled: j['isEnabled'] ?? true,
  );
}
```

### 4b. Built-in Dare List — `lib/core/dares_data.dart`

40 Dutch-language dares, IDs `builtin_0` through `builtin_39`. Tone: social and physical, appropriate for a party app. Examples:
- "Doe 10 push-ups"
- "Bel iemand op en zing een liedje"
- "Wissel van plek met iemand anders"
- "Drink je glas in één keer leeg"
- "Vertel een genant geheim"
- "Doe een dans die iedereen moet natansen"
- "Spreek de rest van de ronde met een accent"
- "Geef iemand een compliment dat je normaal nooit zou zeggen"

Full list defined as a `const List<Dare>` in this file.

### 4c. Provider — `lib/providers/dare_provider.dart`

`DareNotifier extends StateNotifier<List<Dare>>`. On construction, loads built-in list merged with persisted custom dares and toggle states from SharedPreferences.

Methods:
- `drawRandom()` — returns a random enabled `Dare` (Fisher-Yates on enabled subset); null if none enabled
- `drawAgain(String excludeId)` — returns a random enabled dare that is not `excludeId`
- `addCustom(String text)` — creates a dare with `isCustom: true`, UUID id, appends and persists
- `toggle(String id)` — flips `isEnabled`, persists
- `deleteCustom(String id)` — removes custom dare, persists (built-in dares cannot be deleted)

Persistence key: `raak_dares_v1` (JSON array of all dares with their current `isEnabled` state).

### 4d. Dare Overlay Screen — `lib/screens/dare_overlay/dare_overlay_screen.dart`

Full-screen push route `/dare`. Receives the loser's player slot index as a route argument.

Layout:
- Background: `RaakColors.voidBlack`
- Top: small caption "OPDRACHT VOOR SPELER X"
- Center: large dare card styled with `RaakColors.blast` border and hard shadow
- Dare text in `RaakTextStyles.modeTitle` (large, bold)
- Bottom row: ghost button **"VOLGENDE"** (one redraw allowed per round, then disabled) + primary button **"GEDAAN"**

Navigation: **"GEDAAN"** pops back to reveal screen.

### 4e. Reveal Screen Changes

After the result is shown, if the result contains a loser (modes: loser, winner with loser slot, elimination), a **"GEEF OPDRACHT"** secondary button appears below the main action buttons. Tapping it pushes `/dare` with the loser's slot index.

### 4f. Settings Screen Changes

New section **"OPDRACHTEN"** added to settings screen:
- List of all dares (built-in and custom) with a toggle switch per dare
- Built-in dares show a lock icon, no delete button
- Custom dares show a delete (trash) icon
- **"OPDRACHT TOEVOEGEN"** button at the bottom opens a bottom sheet with a text field and confirm button

---

## 5. Feature: Persistent History

### 5a. Serialization

`Player` gets `toJson()`/`fromJson()`:
```dart
Map<String, dynamic> toJson() => {'id': id, 'nickname': nickname, 'colorIndex': colorIndex};
factory Player.fromJson(Map<String, dynamic> j) => Player(id: j['id'], nickname: j['nickname'], colorIndex: j['colorIndex']);
```

`GameResult` gets `toJson()`/`fromJson()`. `HistoryEntry` (wrapping mode + result) gets `toJson()`/`fromJson()`.

### 5b. HistoryNotifier Changes

On init: reads `raak_history_v1` from SharedPreferences, deserializes up to 25 entries.

On `addRound(HistoryEntry entry)`:
- Prepends entry to list
- Trims to 25
- Serializes and writes back to SharedPreferences

### 5c. No UI changes

The existing history bottom sheet on the home screen already handles display. The only change is that entries survive app restart.

---

## 6. New Routes

| Route | Screen | Notes |
|---|---|---|
| `/dare` | `DareOverlayScreen` | arg: `int` loser slot index |
| `/match-summary` | `MatchSummaryScreen` | arg: `MatchState` |

---

## 7. Dependencies

Add to `pubspec.yaml`:
- `shared_preferences: ^2.2.0` — used by dare provider, history provider, and (already used by) settings provider

---

## 8. Testing

| Test file | What it covers |
|---|---|
| `test/match_test.dart` | `MatchState.recordWin`, win detection, round increment |
| `test/dare_provider_test.dart` | `drawRandom`, `drawAgain` exclusion, `addCustom`, `toggle`, `deleteCustom` |
| `test/history_persistence_test.dart` | `toJson`/`fromJson` round-trip for `Player`, `GameResult`, `HistoryEntry`; cap at 25 |

Existing tests (`randomness_test.dart`, `game_session_test.dart`) must continue to pass unchanged.

---

## 9. Out of Scope for Pack 1

- Nickname editing during a match
- Per-dare difficulty ratings
- Cloud sync for history
- Visual Overhaul (fonts, themes, juice) — Pack 2
