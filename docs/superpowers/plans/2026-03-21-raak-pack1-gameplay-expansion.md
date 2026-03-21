# RAAK Pack 1 — Gameplay Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Best of 5 / Party Mode, Dares, and Persistent History to RAAK without touching the existing game engine.

**Architecture:** A new `Match` model wraps multi-round play above the existing `GameSession`. A `DareNotifier` manages 40 built-in Dutch dares plus custom dares, persisted via SharedPreferences. History serialization is added to `Player`/`GameResult` and `HistoryNotifier` gains SharedPreferences persistence. All existing game engine files (`game_session_provider.dart`, `arena_screen.dart`, `randomness.dart`) are untouched.

**Tech Stack:** Flutter, Riverpod StateNotifier, shared_preferences ^2.2.0, Dart 3

---

## File Map

**New files:**
- `lib/models/match.dart` — `MatchConfig`, `MatchState`, `MatchOutcomeType`
- `lib/models/dare.dart` — `Dare` model with JSON serialization
- `lib/core/dares_data.dart` — 40 built-in Dutch dares as a const list
- `lib/providers/match_provider.dart` — `MatchNotifier extends StateNotifier<MatchState?>`
- `lib/providers/dare_provider.dart` — `DareNotifier extends StateNotifier<List<Dare>>`
- `lib/screens/dare_overlay/dare_overlay_screen.dart` — post-reveal dare display
- `lib/screens/match_summary/match_summary_screen.dart` — champion/loser of a match
- `test/match_test.dart`
- `test/dare_provider_test.dart`
- `test/history_persistence_test.dart`

**Modified files:**
- `pubspec.yaml` — add `shared_preferences: ^2.2.0`
- `lib/models/player.dart` — add `toHistoryJson()` / `fromHistoryJson()`
- `lib/models/game_result.dart` — add `toJson()` / `fromJson()`
- `lib/providers/history_provider.dart` — add `HistoryEntry`, SharedPreferences persistence, cap 5→25
- `lib/app.dart` — migrate `routes:` map to `onGenerateRoute`
- `lib/screens/mode_select/mode_select_screen.dart` — add party mode toggle + chip picker
- `lib/screens/reveal/reveal_screen.dart` — add match tally, dare button, match navigation
- `lib/screens/settings/settings_screen.dart` — add dare management section

---

## Task 1: Add shared_preferences dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add `shared_preferences: ^2.2.0` under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  uuid: ^4.3.3
  audioplayers: ^6.0.0
  shared_preferences: ^2.2.0
```

- [ ] **Step 2: Fetch the package**

```bash
cd /Users/trijbs/RAAK && flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: Verify existing tests still pass**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add shared_preferences dependency"
```

---

## Task 2: Match model

**Files:**
- Create: `lib/models/match.dart`
- Create: `test/match_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/match_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raak/models/match.dart';

void main() {
  group('MatchState.recordSelection', () {
    test('increments tally for the given slot', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      final state = MatchState(config: config);
      final next = state.recordSelection(0);
      expect(next.tally[0], 1);
    });

    test('increments round number', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      final state = MatchState(config: config);
      final next = state.recordSelection(0);
      expect(next.roundNumber, 2);
    });

    test('isActive is true before winTarget reached', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(0);
      state = state.recordSelection(0);
      expect(state.isActive, isTrue);
      expect(state.matchDecidedSlot, isNull);
    });

    test('sets matchDecidedSlot when winTarget reached (winner mode)', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(1);
      state = state.recordSelection(1);
      state = state.recordSelection(1);
      expect(state.matchDecidedSlot, 1);
      expect(state.isActive, isFalse);
    });

    test('sets matchDecidedSlot when winTarget reached (loser mode)', () {
      final config = MatchConfig(winTarget: 2, outcomeType: MatchOutcomeType.loser);
      var state = MatchState(config: config);
      state = state.recordSelection(2);
      state = state.recordSelection(2);
      expect(state.matchDecidedSlot, 2);
    });

    test('different slots accumulate independently', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(0);
      state = state.recordSelection(1);
      state = state.recordSelection(0);
      expect(state.tally[0], 2);
      expect(state.tally[1], 1);
      expect(state.matchDecidedSlot, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/trijbs/RAAK && flutter test test/match_test.dart -v
```

Expected: FAIL — `'package:raak/models/match.dart'` not found.

- [ ] **Step 3: Implement `lib/models/match.dart`**

```dart
enum MatchOutcomeType { winner, loser }

class MatchConfig {
  final int winTarget;
  final MatchOutcomeType outcomeType;
  const MatchConfig({required this.winTarget, required this.outcomeType});
}

class MatchState {
  final MatchConfig config;
  final int roundNumber;
  final Map<int, int> tally;
  final int? matchDecidedSlot;

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

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/match_test.dart -v
```

Expected: 6/6 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/match.dart test/match_test.dart
git commit -m "feat: add Match model with recordSelection logic"
```

---

## Task 3: Match provider

**Files:**
- Create: `lib/providers/match_provider.dart`

No unit tests needed — `MatchNotifier` is a thin wrapper over `MatchState`. Behaviour covered by Task 2 tests.

- [ ] **Step 1: Create `lib/providers/match_provider.dart`**

```dart
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
```

- [ ] **Step 2: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/match_provider.dart
git commit -m "feat: add MatchNotifier provider"
```

---

## Task 4: Dare model + built-in data

**Files:**
- Create: `lib/models/dare.dart`
- Create: `lib/core/dares_data.dart`

- [ ] **Step 1: Create `lib/models/dare.dart`**

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
    id: id,
    text: text,
    isCustom: isCustom,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCustom': isCustom,
    'isEnabled': isEnabled,
  };

  factory Dare.fromJson(Map<String, dynamic> j) => Dare(
    id: j['id'] as String,
    text: j['text'] as String,
    isCustom: j['isCustom'] as bool? ?? false,
    isEnabled: j['isEnabled'] as bool? ?? true,
  );
}
```

- [ ] **Step 2: Create `lib/core/dares_data.dart`**

```dart
import '../models/dare.dart';

const List<Dare> kBuiltinDares = [
  Dare(id: 'builtin_0',  text: 'Doe 10 push-ups'),
  Dare(id: 'builtin_1',  text: 'Bel iemand op en zing een liedje'),
  Dare(id: 'builtin_2',  text: 'Wissel van plek met iemand anders'),
  Dare(id: 'builtin_3',  text: 'Drink je glas in één keer leeg'),
  Dare(id: 'builtin_4',  text: 'Vertel een genant geheim'),
  Dare(id: 'builtin_5',  text: 'Doe een dans die iedereen moet natansen'),
  Dare(id: 'builtin_6',  text: 'Spreek de rest van de ronde met een accent'),
  Dare(id: 'builtin_7',  text: 'Geef iemand een compliment dat je normaal nooit zou zeggen'),
  Dare(id: 'builtin_8',  text: 'Laat iemand anders je telefoon één minuut vasthouden'),
  Dare(id: 'builtin_9',  text: 'Doe 30 seconden lang niets en zeg niets'),
  Dare(id: 'builtin_10', text: 'Doe 20 squats'),
  Dare(id: 'builtin_11', text: 'Zing het refrein van het laatste liedje dat je geluisterd hebt'),
  Dare(id: 'builtin_12', text: 'Spreek drie zinnen achter elkaar uitsluitend in rijm'),
  Dare(id: 'builtin_13', text: 'Doe een plank van 30 seconden'),
  Dare(id: 'builtin_14', text: 'Beschrijf jezelf in drie woorden — de anderen kiezen de woorden'),
  Dare(id: 'builtin_15', text: 'Doe alsof je een reclame maakt voor het eerste object dat je ziet'),
  Dare(id: 'builtin_16', text: 'Stuur een random emoji naar de laatste persoon in je chats'),
  Dare(id: 'builtin_17', text: 'Doe de slechtste robot-dans die je kunt'),
  Dare(id: 'builtin_18', text: 'Vertel iets dat niemand hier van je weet'),
  Dare(id: 'builtin_19', text: 'Houd 30 seconden lang een gekke pose vast'),
  Dare(id: 'builtin_20', text: 'Imiteer iemand in de groep totdat iemand raadt wie je bent'),
  Dare(id: 'builtin_21', text: 'Zeg drie dingen die je leuk vindt aan de persoon links van je'),
  Dare(id: 'builtin_22', text: 'Doe 15 jumping jacks'),
  Dare(id: 'builtin_23', text: 'Zeg "banaan" na elke zin die je zegt voor de volgende ronde'),
  Dare(id: 'builtin_24', text: 'Vertel je meest gênante sportmoment'),
  Dare(id: 'builtin_25', text: 'Maak een geluidsimitatie van een dier — de rest raadt welk'),
  Dare(id: 'builtin_26', text: 'Laat iemand anders een berichtje sturen via jouw telefoon'),
  Dare(id: 'builtin_27', text: 'Doe alsof je een nieuwslezer bent en vertel het laatste nieuws'),
  Dare(id: 'builtin_28', text: 'Noem 10 landen in 10 seconden'),
  Dare(id: 'builtin_29', text: 'Beschrijf een film zonder de titel te noemen — de rest raadt'),
  Dare(id: 'builtin_30', text: 'Ga 30 seconden lang in een denkbeeldige stoel zitten (luchtstoel)'),
  Dare(id: 'builtin_31', text: 'Vertel je slechtste grap'),
  Dare(id: 'builtin_32', text: 'Doe de macarena terwijl je de tekst zingt'),
  Dare(id: 'builtin_33', text: 'Toon de meest pijnlijke autocorrect-fout op je telefoon'),
  Dare(id: 'builtin_34', text: 'Zeg het alfabet achterstevoren zo snel mogelijk'),
  Dare(id: 'builtin_35', text: 'Houd een minuut lang een gesprek zonder te lachen'),
  Dare(id: 'builtin_36', text: 'Maak een selfie met een rare gezichtsuitdrukking en toon die aan de groep'),
  Dare(id: 'builtin_37', text: 'Doe alsof je een kok bent en beschrijf het lekkerste gerecht dat je ooit at'),
  Dare(id: 'builtin_38', text: 'Zing "Happy Birthday" in opera-stijl'),
  Dare(id: 'builtin_39', text: 'Neem de rest van de ronde elke zin op fluistertoon'),
];
```

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/models/dare.dart lib/core/dares_data.dart
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/models/dare.dart lib/core/dares_data.dart
git commit -m "feat: add Dare model and 40 built-in Dutch dares"
```

---

## Task 5: Dare provider

**Files:**
- Create: `lib/providers/dare_provider.dart`
- Create: `test/dare_provider_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/dare_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raak/providers/dare_provider.dart';
import 'package:raak/models/dare.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DareNotifier.drawRandom', () {
    test('returns null when 0 dares are enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      // disable all
      for (final d in notifier.state) {
        notifier.toggle(d.id);
      }
      expect(notifier.drawRandom(), isNull);
    });

    test('returns a dare when at least 1 is enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      expect(notifier.drawRandom(), isNotNull);
    });
  });

  group('DareNotifier.drawAgain', () {
    test('returns null when fewer than 2 dares are enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      // disable all but the first
      final ids = notifier.state.map((d) => d.id).toList();
      for (final id in ids.skip(1)) {
        notifier.toggle(id);
      }
      expect(notifier.drawAgain(ids.first), isNull);
    });

    test('never returns the excluded dare', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final firstId = notifier.state.first.id;
      for (int i = 0; i < 20; i++) {
        final drawn = notifier.drawAgain(firstId);
        expect(drawn?.id, isNot(firstId));
      }
    });
  });

  group('DareNotifier.addCustom', () {
    test('adds a dare with isCustom=true', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final before = notifier.state.length;
      notifier.addCustom('Test opdracht');
      expect(notifier.state.length, before + 1);
      expect(notifier.state.last.isCustom, isTrue);
      expect(notifier.state.last.text, 'Test opdracht');
    });
  });

  group('DareNotifier.toggle', () {
    test('flips isEnabled for a dare', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final id = notifier.state.first.id;
      final before = notifier.state.first.isEnabled;
      notifier.toggle(id);
      expect(notifier.state.first.isEnabled, !before);
    });
  });

  group('DareNotifier.deleteCustom', () {
    test('removes custom dares', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      notifier.addCustom('Te verwijderen');
      final customId = notifier.state.last.id;
      final before = notifier.state.length;
      notifier.deleteCustom(customId);
      expect(notifier.state.length, before - 1);
      expect(notifier.state.any((d) => d.id == customId), isFalse);
    });

    test('does not remove built-in dares', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final builtinId = notifier.state.first.id;
      final before = notifier.state.length;
      notifier.deleteCustom(builtinId);
      expect(notifier.state.length, before); // unchanged
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/dare_provider_test.dart -v
```

Expected: FAIL — `'package:raak/providers/dare_provider.dart'` not found.

- [ ] **Step 3: Implement `lib/providers/dare_provider.dart`**

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/dare_provider_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/dare_provider.dart test/dare_provider_test.dart
git commit -m "feat: add DareNotifier with persistence and draw logic"
```

---

## Task 6: History persistence

**Files:**
- Modify: `lib/models/player.dart`
- Modify: `lib/models/game_result.dart`
- Modify: `lib/providers/history_provider.dart`
- Create: `test/history_persistence_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/history_persistence_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raak/models/player.dart';
import 'package:raak/models/game_result.dart';
import 'package:raak/models/game_session.dart';
import 'package:raak/providers/history_provider.dart';

Player _makePlayer(int arrivalIndex) => Player(
  id: 'p$arrivalIndex',
  pointerId: arrivalIndex,
  color: const Color(0xFFFFE500),
  nickname: 'P${arrivalIndex + 1}',
  arrivalIndex: arrivalIndex,
  position: Offset.zero,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Player serialization', () {
    test('toHistoryJson / fromHistoryJson round-trip', () {
      final player = _makePlayer(2);
      final json = player.toHistoryJson();
      final restored = Player.fromHistoryJson(json);
      expect(restored.arrivalIndex, player.arrivalIndex);
      expect(restored.nickname, player.nickname);
    });
  });

  group('GameResult serialization', () {
    test('toJson / fromJson round-trip', () {
      final result = GameResult(
        winners: [_makePlayer(0)],
        losers: [_makePlayer(1)],
        wasChaosControlActive: false,
        timestamp: DateTime(2026, 3, 21),
      );
      final json = result.toJson();
      final restored = GameResult.fromJson(json);
      expect(restored.winners.first.arrivalIndex, 0);
      expect(restored.losers.first.arrivalIndex, 1);
      expect(restored.wasChaosControlActive, isFalse);
    });
  });

  group('HistoryEntry serialization', () {
    test('toJson / fromJson round-trip', () {
      final entry = HistoryEntry(
        mode: GameMode.winner,
        result: GameResult(
          winners: [_makePlayer(0)],
          losers: [],
          wasChaosControlActive: false,
          timestamp: DateTime(2026, 3, 21),
        ),
      );
      final json = entry.toJson();
      final restored = HistoryEntry.fromJson(json);
      expect(restored.mode, GameMode.winner);
      expect(restored.result.winners.first.arrivalIndex, 0);
    });
  });

  group('HistoryNotifier', () {
    test('persists and restores up to 25 entries', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = HistoryNotifier();
      await notifier.initFuture;

      for (int i = 0; i < 30; i++) {
        await notifier.addRound(HistoryEntry(
          mode: GameMode.winner,
          result: GameResult(
            winners: [_makePlayer(i % 5)],
            losers: [],
            wasChaosControlActive: false,
            timestamp: DateTime(2026, 3, 21),
          ),
        ));
      }
      expect(notifier.state.rounds.length, 25);

      // Simulate app restart by reading from SharedPreferences
      final notifier2 = HistoryNotifier();
      await notifier2.initFuture;
      expect(notifier2.state.rounds.length, 25);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/history_persistence_test.dart -v
```

Expected: FAIL.

- [ ] **Step 3: Add serialization to `lib/models/player.dart`**

Add these methods inside the `Player` class, after the `copyWith` method:

```dart
  Map<String, dynamic> toHistoryJson() => {
    'arrivalIndex': arrivalIndex,
    'nickname': nickname,
  };

  factory Player.fromHistoryJson(Map<String, dynamic> j) => Player(
    id: 'restored_${j['arrivalIndex']}',
    pointerId: 0,
    color: RaakColors.playerColor(j['arrivalIndex'] as int),
    nickname: j['nickname'] as String,
    arrivalIndex: j['arrivalIndex'] as int,
    position: Offset.zero,
  );
```

Also add `import '../core/theme.dart';` at the top of `player.dart` (after the existing `import 'package:flutter/material.dart';`).

**Full updated `lib/models/player.dart`:**

```dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

class Player {
  final String id;
  final int pointerId;
  final Color color;
  final String nickname;
  final int arrivalIndex;
  final Offset position;

  const Player({
    required this.id,
    required this.pointerId,
    required this.color,
    required this.nickname,
    required this.arrivalIndex,
    required this.position,
  });

  Player copyWith({
    String? nickname,
    Offset? position,
  }) => Player(
    id: id,
    pointerId: pointerId,
    color: color,
    nickname: nickname ?? this.nickname,
    arrivalIndex: arrivalIndex,
    position: position ?? this.position,
  );

  Map<String, dynamic> toHistoryJson() => {
    'arrivalIndex': arrivalIndex,
    'nickname': nickname,
  };

  factory Player.fromHistoryJson(Map<String, dynamic> j) => Player(
    id: 'restored_${j['arrivalIndex']}',
    pointerId: 0,
    color: RaakColors.playerColor(j['arrivalIndex'] as int),
    nickname: j['nickname'] as String,
    arrivalIndex: j['arrivalIndex'] as int,
    position: Offset.zero,
  );
}
```

- [ ] **Step 4: Add serialization to `lib/models/game_result.dart`**

**Full updated `lib/models/game_result.dart`:**

```dart
import 'player.dart';

class GameResult {
  final List<Player> winners;
  final List<Player> losers;
  final List<List<Player>>? teams;
  final bool wasChaosControlActive;
  final DateTime timestamp;

  const GameResult({
    required this.winners,
    required this.losers,
    required this.wasChaosControlActive,
    required this.timestamp,
    this.teams,
  });

  Map<String, dynamic> toJson() => {
    'winners': winners.map((p) => p.toHistoryJson()).toList(),
    'losers': losers.map((p) => p.toHistoryJson()).toList(),
    'teams': teams?.map((t) => t.map((p) => p.toHistoryJson()).toList()).toList() ?? [],
    'wasChaosControlActive': wasChaosControlActive,
  };

  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
    winners: (j['winners'] as List)
        .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
        .toList(),
    losers: (j['losers'] as List)
        .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
        .toList(),
    teams: (j['teams'] as List).isEmpty
        ? null
        : (j['teams'] as List)
            .map((t) => (t as List)
                .map((e) => Player.fromHistoryJson(e as Map<String, dynamic>))
                .toList())
            .toList(),
    wasChaosControlActive: j['wasChaosControlActive'] as bool? ?? false,
    timestamp: DateTime.now(), // not persisted; use current time on restore
  );
}
```

- [ ] **Step 5: Rewrite `lib/providers/history_provider.dart`**

```dart
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
```

- [ ] **Step 6: Update the call site in `lib/screens/reveal/reveal_screen.dart`**

Find line 40:
```dart
ref.read(historyProvider.notifier).addRound(session.mode, session.result!);
```

Replace with:
```dart
ref.read(historyProvider.notifier).addRound(
  HistoryEntry(mode: session.mode, result: session.result!),
);
```

Also add the import at the top of `reveal_screen.dart`:
```dart
import '../../providers/history_provider.dart'; // already imported — HistoryEntry is now in history_provider.dart
```

(The import already exists; `HistoryEntry` is now exported from the same file.)

- [ ] **Step 7: Update the home screen to use `HistoryEntry`**

In `lib/screens/home/home_screen.dart`, the history bottom sheet uses anonymous record type `entry.mode` and `entry.result`. Since `HistoryEntry` is now a named class, update the references. The API is unchanged (`entry.mode`, `entry.result`, `entry.result.winners`, `entry.result.losers`, `entry.result.wasChaosControlActive`) — if the code compiled before it will compile now. Verify by running analyze.

- [ ] **Step 8: Run tests**

```bash
flutter test test/history_persistence_test.dart -v
```

Expected: all tests pass.

- [ ] **Step 9: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 10: Commit**

```bash
git add lib/models/player.dart lib/models/game_result.dart lib/providers/history_provider.dart lib/screens/reveal/reveal_screen.dart test/history_persistence_test.dart
git commit -m "feat: add history persistence with SharedPreferences and HistoryEntry model"
```

---

## Task 7: Dare overlay screen

**Files:**
- Create: `lib/screens/dare_overlay/dare_overlay_screen.dart`

- [ ] **Step 1: Create `lib/screens/dare_overlay/dare_overlay_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/dare.dart';
import '../../providers/dare_provider.dart';

class DareOverlayScreen extends ConsumerStatefulWidget {
  final int loserSlot;
  const DareOverlayScreen({super.key, required this.loserSlot});

  @override
  ConsumerState<DareOverlayScreen> createState() => _DareOverlayScreenState();
}

class _DareOverlayScreenState extends ConsumerState<DareOverlayScreen> {
  Dare? _currentDare;
  bool _hasRedrawn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Wait for DareNotifier async init (SharedPreferences load) before drawing.
    // initFuture resolves immediately on subsequent launches; only delays on first.
    ref.read(dareProvider.notifier).initFuture.then((_) {
      if (mounted) {
        setState(() {
          _currentDare = ref.read(dareProvider.notifier).drawRandom();
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: Center(child: CircularProgressIndicator(color: RaakColors.volt)),
      );
    }
    if (_currentDare == null) {
      return Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GEEN OPDRACHTEN INGESTELD', style: RaakTextStyles.caption),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: RaakButtonStyle.ghost(),
                    child: Text('TERUG', style: RaakTextStyles.caption),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final enabledCount = ref.read(dareProvider).where((d) => d.isEnabled).length;
    final canRedraw = !_hasRedrawn && enabledCount >= 2;

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'OPDRACHT VOOR SPELER ${widget.loserSlot + 1}',
                style: RaakTextStyles.caption,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: RaakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RaakColors.blast, width: 3),
                  boxShadow: RaakButtonStyle.hardShadow(RaakColors.blast),
                ),
                child: Text(
                  _currentDare!.text,
                  style: RaakTextStyles.modeTitle.copyWith(
                    fontSize: 22,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: canRedraw
                          ? () {
                              final next = ref
                                  .read(dareProvider.notifier)
                                  .drawAgain(_currentDare!.id);
                              if (next != null) {
                                setState(() {
                                  _currentDare = next;
                                  _hasRedrawn = true;
                                });
                              }
                            }
                          : null,
                      child: Opacity(
                        opacity: canRedraw ? 1.0 : 0.4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: RaakButtonStyle.ghost(),
                          alignment: Alignment.center,
                          child: Text('VOLGENDE', style: RaakTextStyles.caption),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: RaakButtonStyle.primary(),
                        alignment: Alignment.center,
                        child: Text(
                          'GEDAAN',
                          style: RaakTextStyles.body.copyWith(
                            color: RaakColors.textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/screens/dare_overlay/dare_overlay_screen.dart
```

Expected: No issues (info only).

- [ ] **Step 3: Commit**

```bash
git add lib/screens/dare_overlay/dare_overlay_screen.dart
git commit -m "feat: add DareOverlayScreen"
```

---

## Task 8: Match summary screen

**Files:**
- Create: `lib/screens/match_summary/match_summary_screen.dart`

- [ ] **Step 1: Create `lib/screens/match_summary/match_summary_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/match.dart';
import '../../providers/match_provider.dart';

class MatchSummaryScreen extends ConsumerWidget {
  final MatchState matchState;
  const MatchSummaryScreen({super.key, required this.matchState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decided = matchState.matchDecidedSlot!;
    final isWinnerMode = matchState.config.outcomeType == MatchOutcomeType.winner;
    final highlightColor = isWinnerMode ? RaakColors.volt : RaakColors.blast;
    final highlightTextColor = isWinnerMode ? RaakColors.textDark : RaakColors.textWhite;
    final labelText = isWinnerMode ? 'KAMPIOEN' : 'VERLIEZER';

    // Build sorted tally entries
    final slots = matchState.tally.keys.toList()
      ..sort((a, b) => (matchState.tally[b] ?? 0).compareTo(matchState.tally[a] ?? 0));

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(labelText, style: RaakTextStyles.caption),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: highlightColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: highlightColor, width: 3),
                boxShadow: RaakButtonStyle.hardShadow(highlightColor),
              ),
              child: Text(
                'SPELER ${decided + 1}',
                style: RaakTextStyles.display.copyWith(color: highlightColor),
              ),
            ),
            const SizedBox(height: 32),
            // Tally table
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RaakColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RaakColors.borderDark),
              ),
              child: Column(
                children: slots.map((slot) {
                  final count = matchState.tally[slot] ?? 0;
                  final isDecided = slot == decided;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'Speler ${slot + 1}',
                          style: RaakTextStyles.body.copyWith(
                            color: isDecided ? highlightColor : RaakColors.textWhite,
                            fontWeight: isDecided ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$count',
                          style: RaakTextStyles.modeTitle.copyWith(
                            color: isDecided ? highlightColor : RaakColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(matchProvider.notifier).endMatch();
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/mode-select', (r) => r.settings.name == '/');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: RaakButtonStyle.ghost(),
                        alignment: Alignment.center,
                        child: Text('NIEUWE RONDE', style: RaakTextStyles.caption),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(matchProvider.notifier).endMatch();
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/', (r) => false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: RaakButtonStyle.primary(),
                        alignment: Alignment.center,
                        child: Text(
                          'NIEUW SPEL',
                          style: RaakTextStyles.body.copyWith(
                            color: RaakColors.textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/screens/match_summary/match_summary_screen.dart
```

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/match_summary/match_summary_screen.dart
git commit -m "feat: add MatchSummaryScreen"
```

---

## Task 9: Routing migration

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Update `lib/app.dart`**

Replace the entire file:

```dart
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'models/match.dart';
import 'screens/home/home_screen.dart';
import 'screens/mode_select/mode_select_screen.dart';
import 'screens/arena/arena_screen.dart';
import 'screens/reveal/reveal_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/dare_overlay/dare_overlay_screen.dart';
import 'screens/match_summary/match_summary_screen.dart';

class RaakApp extends StatelessWidget {
  const RaakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAAK',
      debugShowCheckedModeBanner: false,
      theme: RaakTheme.themeData,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/mode-select':
            return MaterialPageRoute(builder: (_) => const ModeSelectScreen());
          case '/arena':
            return MaterialPageRoute(builder: (_) => const ArenaScreen());
          case '/reveal':
            return MaterialPageRoute(builder: (_) => const RevealScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/dare':
            final loserSlot = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => DareOverlayScreen(loserSlot: loserSlot),
            );
          case '/match-summary':
            final matchState = settings.arguments as MatchState;
            return MaterialPageRoute(
              builder: (_) => MatchSummaryScreen(matchState: matchState),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
```

- [ ] **Step 2: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/app.dart
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: migrate routing to onGenerateRoute for argument support"
```

---

## Task 10: Mode select — party mode toggle

**Files:**
- Modify: `lib/screens/mode_select/mode_select_screen.dart`

The existing state variables are `_selectedMode`, `_multiWinnerCount`, `_teamCount`, `_chaosConfig`. Add `_partyModeEnabled` (bool, default false) and `_winTarget` (int, default 3).

- [ ] **Step 1: Update `lib/screens/mode_select/mode_select_screen.dart`**

Add new state variables after line 19 (`ChaosConfig? _chaosConfig;`):

```dart
  bool _partyModeEnabled = false;
  int _winTarget = 3; // 2 = Best of 3, 3 = Best of 5, 4 = Best of 7
```

Add import at the top of the file:
```dart
import '../../models/match.dart';
import '../../providers/match_provider.dart';
```

**After the mode list `ListView`, before the ChaosBanner, add the party mode section.** Insert this widget in the `Column` children, right after the `Expanded(child: ListView...)` block:

```dart
if (_selectedMode == GameMode.winner || _selectedMode == GameMode.loser)
  _buildPartyModeSection(),
```

Add the `_buildPartyModeSection` method:

```dart
  Widget _buildPartyModeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: RaakColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RaakColors.borderDark),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('PARTY MODE', style: RaakTextStyles.body),
                  subtitle: Text('Speel meerdere rondes', style: RaakTextStyles.caption),
                  value: _partyModeEnabled,
                  activeColor: RaakColors.volt,
                  onChanged: (v) => setState(() => _partyModeEnabled = v),
                ),
                if (_partyModeEnabled) ...[
                  const Divider(color: RaakColors.borderDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWinTargetChip(label: 'Best of 3', value: 2),
                        _buildWinTargetChip(label: 'Best of 5', value: 3),
                        _buildWinTargetChip(label: 'Best of 7', value: 4),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinTargetChip({required String label, required int value}) {
    final selected = _winTarget == value;
    return GestureDetector(
      onTap: () => setState(() => _winTarget = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? RaakColors.volt.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? RaakColors.volt : RaakColors.borderDark,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: RaakTextStyles.caption.copyWith(
            color: selected ? RaakColors.volt : RaakColors.textGrey,
          ),
        ),
      ),
    );
  }
```

Update `_startGame()` to start/end match:

```dart
  void _startGame() {
    if (_partyModeEnabled &&
        (_selectedMode == GameMode.winner || _selectedMode == GameMode.loser)) {
      ref.read(matchProvider.notifier).startMatch(MatchConfig(
        winTarget: _winTarget,
        outcomeType: _selectedMode == GameMode.winner
            ? MatchOutcomeType.winner
            : MatchOutcomeType.loser,
      ));
    } else {
      ref.read(matchProvider.notifier).endMatch();
    }
    ref.read(gameSessionProvider.notifier).startSession(
      _selectedMode,
      multiWinnerCount: _multiWinnerCount,
      teamCount: _teamCount,
      chaosConfig: _selectedMode == GameMode.chaos ? _chaosConfig : null,
    );
    Navigator.pushNamed(context, '/arena');
  }
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/screens/mode_select/mode_select_screen.dart
```

Expected: No issues.

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/mode_select/mode_select_screen.dart
git commit -m "feat: add party mode toggle to mode select screen"
```

---

## Task 11: Reveal screen updates

**Files:**
- Modify: `lib/screens/reveal/reveal_screen.dart`

Add: match tally display, dare button, match navigation on match decided.

- [ ] **Step 1: Add imports to reveal_screen.dart**

Add at the top, after existing imports:

```dart
import '../../models/match.dart';
import '../../providers/match_provider.dart';
import '../../providers/dare_provider.dart';
import '../../providers/history_provider.dart';
```

(history_provider.dart is already imported; just verify `HistoryEntry` resolves.)

- [ ] **Step 2: Update `initState` to record match selection and handle match-decided navigation**

Replace the `addPostFrameCallback` block:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRecordedHistory && mounted) {
        final session = ref.read(gameSessionProvider);
        if (session.result != null) {
          ref.read(historyProvider.notifier).addRound(
            HistoryEntry(mode: session.mode, result: session.result!),
          );
          _hasRecordedHistory = true;

          // Record match selection if party mode is active
          final matchState = ref.read(matchProvider);
          if (matchState != null && matchState.isActive) {
            final result = session.result!;
            final isWinnerMode = matchState.config.outcomeType == MatchOutcomeType.winner;
            final selectedSlot = isWinnerMode
                ? result.winners.first.arrivalIndex
                : result.losers.first.arrivalIndex;
            ref.read(matchProvider.notifier).recordSelection(selectedSlot);

            // Navigate to match summary if match is decided
            final updated = ref.read(matchProvider);
            if (updated != null && !updated.isActive) {
              Navigator.pushReplacementNamed(
                context, '/match-summary', arguments: updated,
              );
            }
          }
        }
      }
    });
```

- [ ] **Step 3: Add match tally widget to the build method**

In the `Column` of the `build` method, after the `ScaleTransition(child: ResultCard(...))` and `SizedBox(height: 24)`, add:

```dart
            Consumer(
              builder: (context, ref, _) {
                final matchState = ref.watch(matchProvider);
                if (matchState == null || !matchState.isActive) return const SizedBox.shrink();
                final isWinnerMode = matchState.config.outcomeType == MatchOutcomeType.winner;
                final label = isWinnerMode ? 'WINS' : 'VERLIESPUNTEN';
                final slots = matchState.tally.keys.toList()..sort();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: RaakColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RaakColors.borderDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: RaakTextStyles.caption),
                        const SizedBox(width: 12),
                        ...slots.map((s) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'P${s + 1}: ${matchState.tally[s] ?? 0}',
                            style: RaakTextStyles.body.copyWith(fontSize: 14),
                          ),
                        )),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '/ ${matchState.config.winTarget}',
                            style: RaakTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
```

- [ ] **Step 4: Add "GEEF OPDRACHT" button**

After the existing buttons row (after the `if (canContinueElimination)` block, before `SizedBox(height: 24)`), add:

```dart
            Consumer(
              builder: (context, ref, _) {
                final result = ref.watch(gameSessionProvider).result;
                if (result == null || result.losers.isEmpty) return const SizedBox.shrink();
                final dares = ref.watch(dareProvider);
                final hasEnabledDares = dares.any((d) => d.isEnabled);
                if (!hasEnabledDares) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/dare',
                          arguments: result.losers.first.arrivalIndex,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: RaakColors.blast.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: RaakColors.blast, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'GEEF OPDRACHT',
                            style: RaakTextStyles.body.copyWith(
                              color: RaakColors.blast,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
```

- [ ] **Step 5: Update REMATCH button to preserve match state**

The REMATCH button already calls `resetForRematch()` and navigates to `/arena`. This is correct — match state is preserved in `matchProvider` which is separate from `gameSessionProvider`. No change needed.

The NIEUWE RONDE button should end the match. Update its `onTap`:

```dart
onTap: () {
  ref.read(matchProvider.notifier).endMatch();
  ref.read(gameSessionProvider.notifier).resetFull();
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/mode-select',
    (r) => r.settings.name == '/',
  );
},
```

- [ ] **Step 6: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Run analyze**

```bash
flutter analyze lib/screens/reveal/reveal_screen.dart
```

Expected: No issues.

- [ ] **Step 8: Commit**

```bash
git add lib/screens/reveal/reveal_screen.dart
git commit -m "feat: add match tally, dare button, and match navigation to reveal screen"
```

---

## Task 12: Settings — dare management

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

Change `SettingsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` so we can manage the "add dare" bottom sheet state cleanly.

- [ ] **Step 1: Update `lib/screens/settings/settings_screen.dart`**

Replace the entire file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/dare.dart';
import '../../providers/settings_provider.dart';
import '../../providers/dare_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dares = ref.watch(dareProvider);
    final dareNotifier = ref.read(dareProvider.notifier);

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      appBar: AppBar(
        backgroundColor: RaakColors.voidBlack,
        foregroundColor: RaakColors.textWhite,
        title: Text('INSTELLINGEN', style: RaakTextStyles.caption),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('GELUID & TRILLEN', [
            _buildToggle(
              label: 'Geluidseffecten',
              value: settings.soundEnabled,
              onChanged: (_) => notifier.toggleSound(),
            ),
            _buildToggle(
              label: 'Trillen (haptics)',
              value: settings.vibrationEnabled,
              onChanged: (_) => notifier.toggleVibration(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('AFTELLEN', [
            Row(
              children: [
                Text('Duur', style: RaakTextStyles.body),
                const Spacer(),
                ...[1, 2, 3].map((s) => GestureDetector(
                  onTap: () => notifier.setCountdown(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(left: 8),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: settings.countdownSeconds == s
                          ? RaakColors.volt
                          : RaakColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RaakColors.borderDark),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s}s',
                      style: RaakTextStyles.body.copyWith(
                        color: settings.countdownSeconds == s
                            ? RaakColors.textDark
                            : RaakColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          // Dares section
          Text('OPDRACHTEN', style: RaakTextStyles.caption),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: RaakColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RaakColors.borderDark),
            ),
            child: Column(
              children: [
                ...dares.map((dare) => _DareListTile(
                  dare: dare,
                  onToggle: () => dareNotifier.toggle(dare.id),
                  onDelete: dare.isCustom
                      ? () => dareNotifier.deleteCustom(dare.id)
                      : null,
                )),
                const Divider(color: RaakColors.borderDark, height: 1),
                ListTile(
                  onTap: () => _showAddDareSheet(context, dareNotifier),
                  leading: const Icon(Icons.add, color: RaakColors.volt),
                  title: Text('OPDRACHT TOEVOEGEN', style: RaakTextStyles.body.copyWith(color: RaakColors.volt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('OVER', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('RAAK v1.1', style: RaakTextStyles.body),
              subtitle: Text(
                'Originele party app — geen kopie',
                style: RaakTextStyles.caption,
              ),
              trailing: const Icon(Icons.info_outline, color: RaakColors.textGrey),
            ),
          ]),
        ],
      ),
    );
  }

  void _showAddDareSheet(BuildContext context, DareNotifier notifier) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIEUWE OPDRACHT', style: RaakTextStyles.caption),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 120,
              autofocus: true,
              style: RaakTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Typ een opdracht...',
                hintStyle: RaakTextStyles.body.copyWith(color: RaakColors.textGrey),
                filled: true,
                fillColor: RaakColors.voidBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: RaakColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: RaakColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: RaakColors.volt, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    notifier.addCustom(text);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: RaakButtonStyle.primary(),
                  alignment: Alignment.center,
                  child: Text(
                    'TOEVOEGEN',
                    style: RaakTextStyles.body.copyWith(
                      color: RaakColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RaakTextStyles.caption),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RaakColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RaakColors.borderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: RaakTextStyles.body),
      value: value,
      activeColor: RaakColors.volt,
      onChanged: onChanged,
    );
  }
}

class _DareListTile extends StatelessWidget {
  final Dare dare;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _DareListTile({
    required this.dare,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        dare.text,
        style: RaakTextStyles.body.copyWith(
          fontSize: 14,
          color: dare.isEnabled ? RaakColors.textWhite : RaakColors.textGrey,
        ),
      ),
      leading: Switch(
        value: dare.isEnabled,
        activeColor: RaakColors.volt,
        onChanged: (_) => onToggle(),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: RaakColors.textGrey),
              onPressed: onDelete,
            )
          : const Icon(Icons.lock_outline, color: RaakColors.borderDark, size: 16),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/screens/settings/settings_screen.dart
```

Expected: No issues.

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Run flutter analyze on entire project**

```bash
flutter analyze
```

Expected: No errors (info/hints only acceptable).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat: add dare management section to settings screen"
```

---

## Final Verification

- [ ] **Run full test suite one last time**

```bash
flutter test -v
```

Expected: All tests pass including `randomness_test.dart`, `game_session_test.dart`, `match_test.dart`, `dare_provider_test.dart`, `history_persistence_test.dart`.

- [ ] **Build check**

```bash
flutter build ios --no-codesign 2>&1 | tail -5
```

Expected: `Build complete.`
