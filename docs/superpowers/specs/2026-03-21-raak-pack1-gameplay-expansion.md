# RAAK Pack 1 — Gameplay Expansion Design Spec

**Date:** 2026-03-21
**Version:** 1.1
**Scope:** Best of 5 / Party Mode, Dares, Persistent History

---

## 1. Summary

Pack 1 adds three gameplay features to RAAK v1 without touching the existing game engine. A new `Match` layer wraps multi-round play above `GameSession`. A dare system draws from a bundled Dutch list and lets players manage custom dares. History is persisted across restarts via SharedPreferences.

---

## 2. Architecture Principle

The core game engine files (`game_session_provider.dart`, `arena_screen.dart`, `randomness.dart`) are **not modified**. All new features wrap around or hook into the existing flow at well-defined seams: mode select config, post-reveal navigation, settings screen, and history provider.

**Files that WILL be modified:**
- `lib/providers/history_provider.dart` — add persistence + `HistoryEntry` model + cap change (5 → 25)
- `lib/screens/mode_select/mode_select_screen.dart` — add party mode toggle
- `lib/screens/reveal/reveal_screen.dart` — add score tally, dare button, match navigation
- `lib/screens/settings/settings_screen.dart` — add dare management section
- `lib/app.dart` — change routing from static `routes` map to `onGenerateRoute` to support route arguments

---

## 3. Feature: Best of 5 / Party Mode

### 3a. Scope

Party Mode is available for `GameMode.winner` and `GameMode.loser` only. `GameMode.chaos`, `multiWinner`, `teams`, and `elimination` are excluded in Pack 1.

- **Winner mode party:** track wins per slot. First slot to reach `winTarget` wins the match.
- **Loser mode party:** track losses per slot. First slot to reach `winTarget` losses is the match loser (shown on match summary with blast/shock color, not volt).

### 3b. Model — `lib/models/match.dart`

```dart
enum MatchOutcomeType { winner, loser }

class MatchConfig {
  final int winTarget;              // 2 = Best of 3, 3 = Best of 5, 4 = Best of 7
  final MatchOutcomeType outcomeType; // mirrors the game mode
  const MatchConfig({required this.winTarget, required this.outcomeType});
}

class MatchState {
  final MatchConfig config;
  final int roundNumber;            // starts at 1
  final Map<int, int> tally;        // slot -> wins (winner mode) or losses (loser mode)
  final int? matchDecidedSlot;      // slot that won/lost the match; null until decided

  const MatchState({
    required this.config,
    this.roundNumber = 1,
    this.tally = const {},
    this.matchDecidedSlot,
  });

  bool get isActive => matchDecidedSlot == null;

  MatchState recordSelection(int slot) {
    final newTally = Map<int, int>.from(tally);
    newTally[slot] = (newTally[slot] ?? 0) + 1;
    final decided = newTally[slot]! >= config.winTarget ? slot : null;
    return MatchState(
      config: config,
      roundNumber: roundNumber + 1,
      tally: newTally,
      matchDecidedSlot: decided,
    );
  }
}
```

`recordSelection(slot)` is called with:
- **Winner mode:** `result.winners.first.arrivalIndex`
- **Loser mode:** `result.losers.first.arrivalIndex`

Both are guaranteed to be non-null when party mode is active (winner/loser modes always produce exactly one winner or one loser).

### 3c. Provider — `lib/providers/match_provider.dart`

`MatchNotifier extends StateNotifier<MatchState?>`. Null = no active match.

Methods:
- `startMatch(MatchConfig config)` — initialises fresh `MatchState`
- `recordSelection(int slot)` — delegates to `MatchState.recordSelection`, updates state
- `endMatch()` — resets state to null

### 3d. Mode Select Changes

When `GameMode.winner` or `GameMode.loser` is selected, a **"PARTY MODE"** toggle row appears below the mode card. When enabled, a row of three chips appears: **Best of 3 / Best of 5 / Best of 7** (default: Best of 5, i.e. `winTarget: 3`).

In `_startGame()`:
```dart
if (_partyModeEnabled) {
  ref.read(matchProvider.notifier).startMatch(MatchConfig(
    winTarget: _winTarget,
    outcomeType: _selectedMode == GameMode.winner
        ? MatchOutcomeType.winner
        : MatchOutcomeType.loser,
  ));
} else {
  ref.read(matchProvider.notifier).endMatch();
}
```

### 3e. Reveal Screen Changes

When `matchProvider` is non-null and active:

1. Call `matchProvider.notifier.recordSelection(selectedSlot)` immediately after `reveal()` returns. `selectedSlot` is derived as described in Section 3b.
2. Below the result card, show a compact **score tally** row. For winner mode label it "WINS", for loser mode label it "VERLIESPUNTEN".
3. **REMATCH** continues the current match (does not reset match state).
4. **NIEUWE RONDE** calls `matchProvider.notifier.endMatch()` and returns to home.

If `matchState.matchDecidedSlot != null` after recording, navigate to `/match-summary` (passing `matchState` as argument) instead of staying on reveal.

### 3f. Match Summary Screen — `lib/screens/match_summary/match_summary_screen.dart`

Full-screen result:
- **Winner mode:** champion slot highlighted with `RaakColors.volt`, large sticker label "KAMPIOEN"
- **Loser mode:** decided slot highlighted with `RaakColors.blast`, large sticker label "VERLIEZER"
- Full tally table for all slots
- **NIEUW SPEL** — calls `endMatch()`, navigates to home
- **NIEUWE RONDE** — calls `endMatch()`, navigates to mode select

### 3g. Player Identity

Player identity uses `arrivalIndex` (0-based slot), consistent with v1 color assignment via `RaakColors.playerColor(index)`.

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
    id: j['id'] as String,
    text: j['text'] as String,
    isCustom: j['isCustom'] as bool? ?? false,
    isEnabled: j['isEnabled'] as bool? ?? true,
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
- "Laat iemand anders je telefoon één minuut vasthouden"
- "Doe 30 seconden lang niets en zeg niets"

(Full 40 defined as `const List<Dare>` in this file — implementer fills out to 40.)

### 4c. Provider — `lib/providers/dare_provider.dart`

`DareNotifier extends StateNotifier<List<Dare>>`. On construction:
1. Load built-in dares from `dares_data.dart`
2. Load persisted JSON from SharedPreferences key `raak_dares_v1`
3. Merge: for each built-in dare, apply saved `isEnabled` state if present; append any saved custom dares

Methods:
- `drawRandom()` → `Dare?` — random enabled dare; returns null if 0 enabled
- `drawAgain(String excludeId)` → `Dare?` — random enabled dare excluding `excludeId`; returns null if fewer than 2 enabled
- `addCustom(String text)` — UUID id (`custom_${DateTime.now().millisecondsSinceEpoch}`), appends, persists
- `toggle(String id)` — flips `isEnabled`, persists
- `deleteCustom(String id)` — only removes if `isCustom == true`, persists

Persistence: serialize full list to JSON, write to `raak_dares_v1`.

### 4d. Dare Overlay Screen — `lib/screens/dare_overlay/dare_overlay_screen.dart`

Full-screen push route `/dare`. Receives `int loserSlot` as route argument.

On build, calls `dareProvider.notifier.drawRandom()` once and stores in local state.

**Edge cases:**
- If `drawRandom()` returns null (0 enabled dares): show a centered message "GEEN OPDRACHTEN INGESTELD" with a "TERUG" button that pops the route.
- If `drawAgain()` returns null (fewer than 2 enabled dares): the "VOLGENDE" button is disabled from the start.

Layout (normal case):
- Background: `RaakColors.voidBlack`
- Top caption: "OPDRACHT VOOR SPELER ${loserSlot + 1}"
- Center: large dare card with `RaakColors.blast` border and hard shadow
- Dare text in `RaakTextStyles.modeTitle`
- Bottom row: ghost **"VOLGENDE"** button (one redraw; disabled after use or if only 1 dare enabled) + primary **"GEDAAN"** button
- **"GEDAAN"** pops back to reveal screen

### 4e. Reveal Screen Changes

After the result is shown, if result contains a loser (`result.losers.isNotEmpty`), show a **"GEEF OPDRACHT"** secondary button.

**"GEEF OPDRACHT" button visibility:**
- Hidden if `dareProvider` has 0 enabled dares (i.e. `dareProvider.where((d) => d.isEnabled).isEmpty`)
- Otherwise visible, tapping pushes `/dare` with `result.losers.first.arrivalIndex`

### 4f. Settings Screen Changes

New section **"OPDRACHTEN"** added:
- List of all dares with a toggle switch per dare
- Built-in dares: no delete button
- Custom dares: trash icon button to delete
- **"OPDRACHT TOEVOEGEN"** button opens a bottom sheet with a text field (max 120 chars) and confirm button

---

## 5. Feature: Persistent History

### 5a. Models with Serialization

**`Player`** — history only needs `arrivalIndex` and `nickname`. `pointerId` and `position` are session-only and are NOT persisted.

```dart
// Added to Player class:
Map<String, dynamic> toHistoryJson() => {
  'arrivalIndex': arrivalIndex,
  'nickname': nickname,
};

factory Player.fromHistoryJson(Map<String, dynamic> j) => Player(
  pointerId: 0,                                  // dummy — not used in history display
  color: RaakColors.playerColor(j['arrivalIndex'] as int),
  arrivalIndex: j['arrivalIndex'] as int,
  position: Offset.zero,                         // dummy
  nickname: j['nickname'] as String?,
);
```

**`GameResult`** — needs `winners`, `losers`, `teams`, `wasChaosControlActive`:

```dart
Map<String, dynamic> toJson() => {
  'winners': winners.map((p) => p.toHistoryJson()).toList(),
  'losers': losers.map((p) => p.toHistoryJson()).toList(),
  'teams': teams.map((t) => t.map((p) => p.toHistoryJson()).toList()).toList(),
  'wasChaosControlActive': wasChaosControlActive,
};

factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
  winners: (j['winners'] as List).map((e) => Player.fromHistoryJson(e as Map<String, dynamic>)).toList(),
  losers: (j['losers'] as List).map((e) => Player.fromHistoryJson(e as Map<String, dynamic>)).toList(),
  teams: (j['teams'] as List).map((t) => (t as List).map((e) => Player.fromHistoryJson(e as Map<String, dynamic>)).toList()).toList(),
  wasChaosControlActive: j['wasChaosControlActive'] as bool? ?? false,
);
```

**`HistoryEntry`** — new class defined inside `history_provider.dart`:

```dart
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
```

### 5b. HistoryNotifier Changes

The existing anonymous record type `({GameMode mode, GameResult result})` is replaced by `HistoryEntry`. The existing `addRound(GameMode mode, GameResult result)` signature is updated to `addRound(HistoryEntry entry)` — **the one call site in `reveal_screen.dart` must also be updated** (line ~40: change to `ref.read(historyProvider.notifier).addRound(HistoryEntry(mode: session.mode, result: session.result!))`).

History cap changes from 5 to 25. The constant `_maxHistory` in `HistoryNotifier` changes from `5` to `25`.

On init: reads `raak_history_v1` from SharedPreferences, deserializes up to 25 entries.

On `addRound(HistoryEntry entry)`:
1. Prepend to list
2. Trim to 25
3. Serialize and write to SharedPreferences key `raak_history_v1`

### 5c. Home Screen

The existing history bottom sheet already handles display. No UI changes needed — it will now show up to 25 entries across app restarts.

---

## 6. Routing Changes — `lib/app.dart`

The existing `routes:` map does not support passing arguments to named routes. Change to `onGenerateRoute`:

```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/': return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/mode-select': return MaterialPageRoute(builder: (_) => const ModeSelectScreen());
    case '/arena': return MaterialPageRoute(builder: (_) => const ArenaScreen());
    case '/reveal': return MaterialPageRoute(builder: (_) => const RevealScreen());
    case '/settings': return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case '/dare':
      final loserSlot = settings.arguments as int;
      return MaterialPageRoute(builder: (_) => DareOverlayScreen(loserSlot: loserSlot));
    case '/match-summary':
      final matchState = settings.arguments as MatchState;
      return MaterialPageRoute(builder: (_) => MatchSummaryScreen(matchState: matchState));
    default: return MaterialPageRoute(builder: (_) => const HomeScreen());
  }
},
```

---

## 7. Dependencies

Add to `pubspec.yaml`:
- `shared_preferences: ^2.2.0` — used by `DareNotifier` and `HistoryNotifier`

Note: `settings_provider.dart` is currently in-memory only. It does NOT currently use SharedPreferences. SharedPreferences is a new dependency for Pack 1.

---

## 8. Testing

| Test file | What it covers |
|---|---|
| `test/match_test.dart` | `MatchState.recordSelection`, win/loss detection, round increment, both outcome types |
| `test/dare_provider_test.dart` | `drawRandom` (returns null when 0 enabled), `drawAgain` exclusion (returns null when <2 enabled), `addCustom`, `toggle`, `deleteCustom` |
| `test/history_persistence_test.dart` | `toJson`/`fromJson` round-trip for `Player.toHistoryJson`, `GameResult`, `HistoryEntry`; cap at 25 |

Existing tests (`randomness_test.dart`, `game_session_test.dart`) must continue to pass unchanged.

---

## 9. Out of Scope for Pack 1

- Party Mode for chaos, multiWinner, teams, elimination modes
- Nickname editing during a match
- Per-dare difficulty ratings
- Settings persistence (sound/vibration toggles across restarts)
- Cloud sync for history
- Visual Overhaul (fonts, themes, juice) — Pack 2
