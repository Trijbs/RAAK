# RAAK v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build RAAK — a production-ready Flutter party app with multi-touch finger selection, 6 game modes, Thumbnail Chaos design system, and explicitly disclosed Chaos Control mode.

**Architecture:** Flutter + Riverpod StateNotifier. All game state flows through `GameSessionNotifier`. Touch events are captured via raw `Listener` pointer events. All randomness is isolated in `core/randomness.dart`. Screens are stateless consumers of providers.

**Tech Stack:** Flutter 3.x, Dart, flutter_riverpod ^2.6.1, uuid ^4.3.3, audioplayers ^6.0.0, flutter_test

---

## File Map

| File | Responsibility |
|---|---|
| `lib/main.dart` | App entry point, ProviderScope |
| `lib/app.dart` | MaterialApp, named routes, theme injection |
| `lib/core/theme.dart` | Design tokens: colors, text styles, button styles |
| `lib/core/randomness.dart` | ALL selection logic — fair and chaos modes |
| `lib/core/haptics.dart` | Vibration + audio wrapper |
| `lib/models/player.dart` | Player data class |
| `lib/models/game_session.dart` | GameSession, GamePhase, GameMode, EliminationPhase, ChaosConfig, ChaosTargetType |
| `lib/models/game_result.dart` | GameResult data class |
| `lib/providers/game_session_provider.dart` | GameSessionNotifier — central game state |
| `lib/providers/settings_provider.dart` | Sound, vibration, countdown duration prefs |
| `lib/providers/history_provider.dart` | Last 5 round results (in-memory) |
| `lib/widgets/finger_bubble.dart` | Animated touch point — idle/locked/winner/loser |
| `lib/widgets/sticker_label.dart` | Rotated result label (WINNAAR / PECH / TEAM A) |
| `lib/widgets/chaos_banner.dart` | Hazard-stripe Chaos Control disclosure banner |
| `lib/widgets/result_card.dart` | Round result display widget |
| `lib/screens/home/home_screen.dart` | Home screen with SPEEL NU CTA and history strip |
| `lib/screens/mode_select/mode_select_screen.dart` | Mode picker + N/team count config + Chaos sheet |
| `lib/screens/arena/arena_screen.dart` | Touch arena — Listener widget, bubble management |
| `lib/screens/reveal/reveal_screen.dart` | Result reveal + rematch/new round |
| `lib/screens/settings/settings_screen.dart` | Sound, vibration, countdown toggles |
| `test/randomness_test.dart` | Unit tests for all selection paths |
| `test/game_session_test.dart` | Unit tests for state transitions and edge cases |
| `pubspec.yaml` | Dependencies and asset declarations |

---

## Task 1: Flutter Project Scaffold

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`
- Create: `assets/sounds/.gitkeep`

- [ ] **Step 1: Create Flutter project**

```bash
cd /Users/trijbs/RAAK
flutter create . --org com.raak --project-name raak --platforms ios,android
```

Expected: Flutter creates `lib/main.dart`, `pubspec.yaml`, `test/widget_test.dart`, `android/`, `ios/` etc.

- [ ] **Step 2: Delete generated boilerplate**

```bash
rm -f lib/main.dart test/widget_test.dart
```

- [ ] **Step 3: Replace pubspec.yaml**

Replace the entire contents of `pubspec.yaml` with:

```yaml
name: raak
description: RAAK — party finger chooser app
version: 1.0.0+1
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  uuid: ^4.3.3
  audioplayers: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
```

- [ ] **Step 4: Create asset directories**

```bash
mkdir -p assets/sounds assets/fonts
touch assets/sounds/.gitkeep assets/fonts/.gitkeep
```

- [ ] **Step 5: Get dependencies**

```bash
flutter pub get
```

Expected: `Resolving dependencies... Got dependencies.` No errors.

- [ ] **Step 6: Write lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: RaakApp()));
}
```

- [ ] **Step 7: Write lib/app.dart**

```dart
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/mode_select/mode_select_screen.dart';
import 'screens/arena/arena_screen.dart';
import 'screens/reveal/reveal_screen.dart';
import 'screens/settings/settings_screen.dart';

class RaakApp extends StatelessWidget {
  const RaakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAAK',
      debugShowCheckedModeBanner: false,
      theme: RaakTheme.themeData,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/mode-select': (_) => const ModeSelectScreen(),
        '/arena': (_) => const ArenaScreen(),
        '/reveal': (_) => const RevealScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
```

- [ ] **Step 8: Create stub screen files so app compiles**

Create each file with just a scaffold so routing works. We'll implement them fully in later tasks.

`lib/screens/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('HOME')));
}
```

Repeat the same stub pattern for:
- `lib/screens/mode_select/mode_select_screen.dart` — class `ModeSelectScreen`
- `lib/screens/arena/arena_screen.dart` — class `ArenaScreen`
- `lib/screens/reveal/reveal_screen.dart` — class `RevealScreen`
- `lib/screens/settings/settings_screen.dart` — class `SettingsScreen`

- [ ] **Step 9: Verify app compiles and runs**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: scaffold Flutter project with routing and dependencies"
```

---

## Task 2: Design System Tokens

**Files:**
- Create: `lib/core/theme.dart`

- [ ] **Step 1: Write lib/core/theme.dart**

```dart
import 'package:flutter/material.dart';

// RAAK Design System — Thumbnail Chaos aesthetic
// All colors, text styles, and component styles live here.
// Never reference raw hex values outside this file.

abstract class RaakColors {
  static const voidBlack = Color(0xFF0D0D0D);   // background
  static const surface = Color(0xFF1A1A1A);      // cards, panels
  static const volt = Color(0xFFFFE500);         // primary CTA, winner — use with textDark
  static const shock = Color(0xFFFF00AA);        // loser — use with white text ONLY (3.9:1 on dark)
  static const mint = Color(0xFF00FFAA);         // success, teams — use with textDark
  static const blast = Color(0xFFFF3C00);        // chaos control, danger — use with white
  static const current = Color(0xFF0A84FF);      // info, team color — use with white
  static const staticPurple = Color(0xFFBF5AF2); // team color — use with white

  static const textDark = Color(0xFF111111);
  static const textWhite = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFF888888);
  static const borderDark = Color(0xFF333333);

  // Player bubble color cycle (6 slots, wraps)
  static const List<Color> playerColors = [
    volt, shock, mint, blast, current, staticPurple,
  ];

  // Text color to use on each player color background
  static const List<Color> playerTextColors = [
    textDark,  // on volt
    textWhite, // on shock
    textDark,  // on mint
    textWhite, // on blast
    textWhite, // on current
    textWhite, // on staticPurple
  ];

  static Color playerColor(int index) => playerColors[index % playerColors.length];
  static Color playerTextColor(int index) => playerTextColors[index % playerTextColors.length];
}

abstract class RaakTextStyles {
  // Display: logo / big impact text
  static const display = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 48,
    letterSpacing: -2,
    height: 1,
    color: RaakColors.volt,
  );

  // Sticker label text (used inside StickerLabel widget)
  static const sticker = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 14,
    letterSpacing: 0.5,
    color: RaakColors.textDark,
  );

  // Body text
  static const body = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: RaakColors.textWhite,
  );

  // Caption / meta
  static const caption = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 2,
    color: RaakColors.textGrey,
  );

  // Mode title on mode select
  static const modeTitle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 18,
    color: RaakColors.textWhite,
    letterSpacing: 0.5,
  );
}

abstract class RaakTheme {
  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RaakColors.voidBlack,
    colorScheme: const ColorScheme.dark(
      surface: RaakColors.surface,
      primary: RaakColors.volt,
      error: RaakColors.blast,
    ),
    textTheme: const TextTheme(
      displayLarge: RaakTextStyles.display,
      bodyMedium: RaakTextStyles.body,
      labelSmall: RaakTextStyles.caption,
    ),
    useMaterial3: true,
  );
}

// Reusable button styles
abstract class RaakButtonStyle {
  // Hard drop shadow — 4px offset, no blur
  static List<BoxShadow> hardShadow(Color color) => [
    BoxShadow(offset: const Offset(4, 4), blurRadius: 0, color: color),
  ];

  static BoxDecoration primary({double radius = 12}) => BoxDecoration(
    color: RaakColors.volt,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: RaakColors.textDark, width: 3),
    boxShadow: hardShadow(RaakColors.textDark),
  );

  static BoxDecoration secondary({double radius = 12}) => BoxDecoration(
    color: RaakColors.shock,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: RaakColors.textDark, width: 3),
    boxShadow: hardShadow(RaakColors.textDark),
  );

  static BoxDecoration ghost({double radius = 12}) => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: RaakColors.borderDark, width: 2),
  );
}
```

- [ ] **Step 2: Verify the app still compiles**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/...`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme.dart
git commit -m "feat: add RAAK design system tokens"
```

---

## Task 3: Data Models

**Files:**
- Create: `lib/models/player.dart`
- Create: `lib/models/game_session.dart`
- Create: `lib/models/game_result.dart`

- [ ] **Step 1: Write lib/models/player.dart**

```dart
import 'package:flutter/material.dart';

class Player {
  final String id;           // UUID, generated at touch-down
  final int pointerId;       // Flutter PointerEvent.pointer — OS touch identifier
  final Color color;         // assigned from RaakColors.playerColor(arrivalIndex)
  final String nickname;     // "P1", "P2", etc. — editable post-round
  final int arrivalIndex;    // 0-based order finger landed — used by Chaos Control
  final Offset position;     // last known screen position

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
}
```

- [ ] **Step 2: Write lib/models/game_session.dart**

```dart
import 'player.dart';
import 'game_result.dart';

enum GameMode { winner, loser, multiWinner, teams, elimination, chaos }
enum GamePhase { waiting, collecting, locked, revealing, done }
enum EliminationPhase { roundActive, roundResult, complete }
enum ChaosTargetType { forceWinner, forceLoser, weightedOdds }

// CHAOS CONTROL: This config is only non-null when the host has explicitly
// activated Chaos Control. The presence of this object means results are NOT random.
// The UI must display the hazard-stripe disclosure banner whenever this is non-null.
class ChaosConfig {
  final ChaosTargetType targetType;

  // For forceWinner / forceLoser:
  // 0-based arrival index of the target finger. null = not yet configured.
  final int? arrivalIndex;

  // For weightedOdds:
  // Map of arrivalIndex → weight (0.0–1.0). Must sum to ≤ 1.0.
  // Fingers not in map share the remaining weight equally.
  final Map<int, double>? weights;

  const ChaosConfig({
    required this.targetType,
    this.arrivalIndex,
    this.weights,
  });

  ChaosConfig copyWith({
    ChaosTargetType? targetType,
    int? arrivalIndex,
    Map<int, double>? weights,
  }) => ChaosConfig(
    targetType: targetType ?? this.targetType,
    arrivalIndex: arrivalIndex ?? this.arrivalIndex,
    weights: weights ?? this.weights,
  );
}

class GameSession {
  final GameMode mode;
  final GamePhase phase;
  final List<Player> activePlayers;
  final List<Player> eliminatedPlayers;
  final int? multiWinnerCount;    // set in Mode Select; clamped to count-1 at reveal
  final int? teamCount;           // 2–4, set in Mode Select for teams mode
  final ChaosConfig? chaosConfig; // null = fair mode
  final GameResult? result;       // non-null when phase == done

  // Elimination sub-state
  final EliminationPhase eliminationPhase;
  final int eliminationRound; // 1-based

  const GameSession({
    required this.mode,
    required this.phase,
    required this.activePlayers,
    required this.eliminatedPlayers,
    required this.eliminationPhase,
    required this.eliminationRound,
    this.multiWinnerCount,
    this.teamCount,
    this.chaosConfig,
    this.result,
  });

  static GameSession initial(GameMode mode, {
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
  }) => GameSession(
    mode: mode,
    phase: GamePhase.waiting,
    activePlayers: const [],
    eliminatedPlayers: const [],
    eliminationPhase: EliminationPhase.roundActive,
    eliminationRound: 1,
    multiWinnerCount: multiWinnerCount,
    teamCount: teamCount,
    chaosConfig: chaosConfig,
  );

  GameSession copyWith({
    GameMode? mode,
    GamePhase? phase,
    List<Player>? activePlayers,
    List<Player>? eliminatedPlayers,
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
    GameResult? result,
    EliminationPhase? eliminationPhase,
    int? eliminationRound,
  }) => GameSession(
    mode: mode ?? this.mode,
    phase: phase ?? this.phase,
    activePlayers: activePlayers ?? this.activePlayers,
    eliminatedPlayers: eliminatedPlayers ?? this.eliminatedPlayers,
    multiWinnerCount: multiWinnerCount ?? this.multiWinnerCount,
    teamCount: teamCount ?? this.teamCount,
    chaosConfig: chaosConfig ?? this.chaosConfig,
    result: result ?? this.result,
    eliminationPhase: eliminationPhase ?? this.eliminationPhase,
    eliminationRound: eliminationRound ?? this.eliminationRound,
  );

  bool get isChaosActive => chaosConfig != null;
}
```

- [ ] **Step 3: Write lib/models/game_result.dart**

```dart
import 'player.dart';

class GameResult {
  final List<Player> winners;
  final List<Player> losers;
  final List<List<Player>>? teams; // non-null only for teams mode
  final bool wasChaosControlActive;
  final DateTime timestamp;

  const GameResult({
    required this.winners,
    required this.losers,
    required this.wasChaosControlActive,
    required this.timestamp,
    this.teams,
  });
}
```

- [ ] **Step 4: Verify no compile errors**

```bash
flutter analyze lib/models/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/models/
git commit -m "feat: add Player, GameSession, GameResult, ChaosConfig models"
```

---

## Task 4: Randomness Engine (TDD)

**Files:**
- Create: `lib/core/randomness.dart`
- Create: `test/randomness_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/randomness_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raak/core/randomness.dart';
import 'package:raak/models/player.dart';
import 'package:raak/models/game_session.dart';
import 'package:flutter/material.dart';

Player makePlayer(int index) => Player(
  id: 'p$index',
  pointerId: index,
  color: Colors.red,
  nickname: 'P${index + 1}',
  arrivalIndex: index,
  position: Offset.zero,
);

void main() {
  final players = List.generate(5, makePlayer);

  group('selectWinner (fair)', () {
    test('returns exactly 1 winner from the player list', () {
      final result = selectWinner(players, null);
      expect(result.winners.length, 1);
      expect(result.losers.isEmpty, true);
      expect(players.contains(result.winners.first), true);
      expect(result.wasChaosControlActive, false);
    });
  });

  group('selectLoser (fair)', () {
    test('returns exactly 1 loser from the player list', () {
      final result = selectLoser(players, null);
      expect(result.losers.length, 1);
      expect(result.winners.isEmpty, true);
      expect(players.contains(result.losers.first), true);
    });
  });

  group('selectMultiWinner (fair)', () {
    test('returns exactly N winners', () {
      final result = selectMultiWinner(players, 2, null);
      expect(result.winners.length, 2);
    });

    test('clamps N if N >= player count', () {
      final result = selectMultiWinner(players, 5, null); // 5 == count, should clamp to 4
      expect(result.winners.length, 4);
    });
  });

  group('splitTeams (fair)', () {
    test('assigns every player to exactly one team', () {
      final result = splitTeams(players, 2, null);
      final allAssigned = result.teams!.expand((t) => t).toList();
      expect(allAssigned.length, players.length);
      for (final p in players) {
        expect(allAssigned.contains(p), true);
      }
    });

    test('creates the requested number of teams', () {
      final result = splitTeams(players, 2, null);
      expect(result.teams!.length, 2);
    });
  });

  group('Chaos Control — forceWinner', () {
    test('returns the player at arrivalIndex 0 as winner', () {
      const chaos = ChaosConfig(
        targetType: ChaosTargetType.forceWinner,
        arrivalIndex: 0,
      );
      final result = selectWinner(players, chaos);
      expect(result.winners.first.arrivalIndex, 0);
      expect(result.wasChaosControlActive, true);
    });
  });

  group('Chaos Control — weightedOdds', () {
    test('returns a winner (smoke test — weighted selection runs without error)', () {
      const chaos = ChaosConfig(
        targetType: ChaosTargetType.weightedOdds,
        weights: {0: 0.9, 1: 0.1},
      );
      final result = selectWinner(players, chaos);
      expect(result.winners.length, 1);
      expect(result.wasChaosControlActive, true);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
flutter test test/randomness_test.dart 2>&1 | tail -10
```

Expected: compilation errors because `randomness.dart` doesn't exist yet.

- [ ] **Step 3: Write lib/core/randomness.dart**

```dart
// CHAOS CONTROL: When chaosConfig is non-null, results are NOT random.
// Weighting or forcing is applied explicitly per the host's configuration.
// This is never called without the UI disclosing it to all players.

import 'dart:math';
import '../models/player.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';

// Fisher-Yates shuffle — fair, O(n)
List<T> _shuffle<T>(List<T> list) {
  final rng = Random();
  final result = List<T>.from(list);
  for (int i = result.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}

// Pick one index using a weight map. Fingers not in the map share remaining weight equally.
int _weightedPick(List<Player> players, Map<int, double> weights) {
  final rng = Random();
  final total = weights.values.fold(0.0, (a, b) => a + b);
  final remaining = (1.0 - total).clamp(0.0, 1.0);
  final unmappedCount = players.where((p) => !weights.containsKey(p.arrivalIndex)).length;
  final defaultWeight = unmappedCount > 0 ? remaining / unmappedCount : 0.0;

  final cumulativeWeights = <double>[];
  double cumulative = 0.0;
  for (final p in players) {
    cumulative += weights[p.arrivalIndex] ?? defaultWeight;
    cumulativeWeights.add(cumulative);
  }

  final roll = rng.nextDouble() * cumulative;
  for (int i = 0; i < cumulativeWeights.length; i++) {
    if (roll <= cumulativeWeights[i]) return i;
  }
  return players.length - 1;
}

GameResult selectWinner(List<Player> players, ChaosConfig? chaosConfig) {
  assert(players.length >= 2, 'Need at least 2 players to select a winner');

  if (chaosConfig != null) {
    // CHAOS CONTROL path — explicit, traceable
    if (chaosConfig.targetType == ChaosTargetType.forceWinner &&
        chaosConfig.arrivalIndex != null) {
      final winner = players.firstWhere(
        (p) => p.arrivalIndex == chaosConfig.arrivalIndex,
        orElse: () => players.first,
      );
      return GameResult(
        winners: [winner],
        losers: const [],
        wasChaosControlActive: true,
        timestamp: DateTime.now(),
      );
    }

    if (chaosConfig.targetType == ChaosTargetType.weightedOdds &&
        chaosConfig.weights != null) {
      final idx = _weightedPick(players, chaosConfig.weights!);
      return GameResult(
        winners: [players[idx]],
        losers: const [],
        wasChaosControlActive: true,
        timestamp: DateTime.now(),
      );
    }
  }

  // Fair path — no hidden weighting
  final rng = Random();
  final winner = players[rng.nextInt(players.length)];
  return GameResult(
    winners: [winner],
    losers: const [],
    wasChaosControlActive: false,
    timestamp: DateTime.now(),
  );
}

GameResult selectLoser(List<Player> players, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);

  if (chaosConfig != null &&
      chaosConfig.targetType == ChaosTargetType.forceLoser &&
      chaosConfig.arrivalIndex != null) {
    final loser = players.firstWhere(
      (p) => p.arrivalIndex == chaosConfig.arrivalIndex,
      orElse: () => players.first,
    );
    return GameResult(
      winners: const [],
      losers: [loser],
      wasChaosControlActive: true,
      timestamp: DateTime.now(),
    );
  }

  final rng = Random();
  final loser = players[rng.nextInt(players.length)];
  return GameResult(
    winners: const [],
    losers: [loser],
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

GameResult selectMultiWinner(List<Player> players, int n, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);
  final clampedN = n.clamp(1, players.length - 1);
  final shuffled = _shuffle(players);
  return GameResult(
    winners: shuffled.take(clampedN).toList(),
    losers: const [],
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

GameResult splitTeams(List<Player> players, int teamCount, ChaosConfig? chaosConfig) {
  assert(players.length >= 2);
  final clampedTeams = teamCount.clamp(2, players.length);
  final shuffled = _shuffle(players);
  final teams = List.generate(clampedTeams, (_) => <Player>[]);
  for (int i = 0; i < shuffled.length; i++) {
    teams[i % clampedTeams].add(shuffled[i]);
  }
  return GameResult(
    winners: const [],
    losers: const [],
    teams: teams,
    wasChaosControlActive: chaosConfig != null,
    timestamp: DateTime.now(),
  );
}

// Elimination: pick one loser from the current round's players
GameResult eliminationRound(List<Player> players, ChaosConfig? chaosConfig) {
  return selectLoser(players, chaosConfig);
}
```

- [ ] **Step 4: Run tests — verify they PASS**

```bash
flutter test test/randomness_test.dart --reporter=expanded 2>&1
```

Expected: All tests pass. If any fail, fix `randomness.dart` before proceeding.

- [ ] **Step 5: Commit**

```bash
git add lib/core/randomness.dart test/randomness_test.dart
git commit -m "feat: add randomness engine with fair and chaos modes (TDD)"
```

---

## Task 5: Providers

**Files:**
- Create: `lib/providers/game_session_provider.dart`
- Create: `lib/providers/settings_provider.dart`
- Create: `lib/providers/history_provider.dart`
- Create: `test/game_session_test.dart`

- [ ] **Step 1: Write failing tests for GameSessionNotifier**

Create `test/game_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raak/providers/game_session_provider.dart';
import 'package:raak/models/game_session.dart';
import 'package:raak/models/player.dart';
import 'package:flutter/material.dart';

Player makeTestPlayer(int index) => Player(
  id: 'test-$index',
  pointerId: index,
  color: Colors.red,
  nickname: 'P${index + 1}',
  arrivalIndex: index,
  position: const Offset(100, 100),
);

ProviderContainer makeContainer() => ProviderContainer();

void main() {
  group('GameSessionNotifier', () {
    test('initial state is waiting phase', () {
      final container = makeContainer();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.waiting);
      expect(session.activePlayers.isEmpty, true);
    });

    test('addPlayer transitions to collecting phase', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 1);
    });

    test('removePlayer removes by pointerId', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.addPlayer(makeTestPlayer(1));
      notifier.removePlayer(0); // remove by pointerId
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 1);
      expect(session.activePlayers.first.pointerId, 1);
    });

    test('max 10 players enforced', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      for (int i = 0; i < 12; i++) {
        notifier.addPlayer(makeTestPlayer(i));
      }
      final session = container.read(gameSessionProvider);
      expect(session.activePlayers.length, 10);
    });

    test('resetForRematch preserves mode and players, resets phase to collecting', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.addPlayer(makeTestPlayer(1));
      notifier.resetForRematch();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.collecting);
      expect(session.mode, GameMode.winner);
      expect(session.activePlayers.length, 2);
      expect(session.result, isNull);
    });

    test('resetFull returns to waiting with empty players', () {
      final container = makeContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(GameMode.winner);
      notifier.addPlayer(makeTestPlayer(0));
      notifier.resetFull();
      final session = container.read(gameSessionProvider);
      expect(session.phase, GamePhase.waiting);
      expect(session.activePlayers.isEmpty, true);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
flutter test test/game_session_test.dart 2>&1 | tail -5
```

Expected: compilation error — provider doesn't exist yet.

- [ ] **Step 3: Write lib/providers/game_session_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../core/randomness.dart';
import '../core/theme.dart';

const _uuid = Uuid();
const _maxPlayers = 10;

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSession>(
  (ref) => GameSessionNotifier(),
);

class GameSessionNotifier extends StateNotifier<GameSession> {
  GameSessionNotifier()
      : super(GameSession.initial(GameMode.winner));

  void startSession(
    GameMode mode, {
    int? multiWinnerCount,
    int? teamCount,
    ChaosConfig? chaosConfig,
  }) {
    state = GameSession.initial(
      mode,
      multiWinnerCount: multiWinnerCount,
      teamCount: teamCount,
      chaosConfig: chaosConfig,
    );
  }

  void addPlayer(Player player) {
    if (state.activePlayers.length >= _maxPlayers) return;
    if (state.activePlayers.any((p) => p.pointerId == player.pointerId)) return;
    state = state.copyWith(
      phase: GamePhase.collecting,
      activePlayers: [...state.activePlayers, player],
    );
  }

  // Convenience: create a player from a pointer event and add them
  void addPlayerFromPointer(int pointerId, Offset position) {
    final index = state.activePlayers.length +
        state.eliminatedPlayers.length; // total ever seen = arrival order
    final arrivalIndex = state.activePlayers.length; // 0-based among current active
    final player = Player(
      id: _uuid.v4(),
      pointerId: pointerId,
      color: RaakColors.playerColor(index),
      nickname: 'P${index + 1}',
      arrivalIndex: arrivalIndex,
      position: position,
    );
    addPlayer(player);
  }

  void updatePlayerPosition(int pointerId, Offset position) {
    state = state.copyWith(
      activePlayers: state.activePlayers.map((p) {
        return p.pointerId == pointerId ? p.copyWith(position: position) : p;
      }).toList(),
    );
  }

  void removePlayer(int pointerId) {
    state = state.copyWith(
      activePlayers: state.activePlayers
          .where((p) => p.pointerId != pointerId)
          .toList(),
      // If we drop below 2 players during countdown, reset to collecting
      phase: state.activePlayers.length - 1 < 2
          ? GamePhase.collecting
          : state.phase,
    );
  }

  void setPhase(GamePhase phase) {
    state = state.copyWith(phase: phase);
  }

  void updateNickname(String playerId, String nickname) {
    state = state.copyWith(
      activePlayers: state.activePlayers.map((p) {
        return p.id == playerId ? p.copyWith(nickname: nickname) : p;
      }).toList(),
    );
  }

  void reveal() {
    if (state.activePlayers.length < 2) return;
    state = state.copyWith(phase: GamePhase.revealing);

    final result = _computeResult();
    state = state.copyWith(
      phase: GamePhase.done,
      result: result,
    );
  }

  GameResult _computeResult() {
    final players = state.activePlayers;
    final chaos = state.chaosConfig;

    switch (state.mode) {
      case GameMode.winner:
      case GameMode.chaos:
        return selectWinner(players, chaos);
      case GameMode.loser:
        return selectLoser(players, chaos);
      case GameMode.multiWinner:
        final n = state.multiWinnerCount ?? 2;
        return selectMultiWinner(players, n, chaos);
      case GameMode.teams:
        final t = state.teamCount ?? 2;
        return splitTeams(players, t, chaos);
      case GameMode.elimination:
        return eliminationRound(players, chaos);
    }
  }

  void advanceElimination() {
    // Called after an elimination round is done and survivor count > 1
    final loser = state.result?.losers.firstOrNull;
    if (loser == null) return;

    final remaining = state.activePlayers
        .where((p) => p.id != loser.id)
        .toList();
    final eliminated = [...state.eliminatedPlayers, loser];

    if (remaining.length <= 1) {
      // Final survivor — game over
      state = state.copyWith(
        activePlayers: remaining,
        eliminatedPlayers: eliminated,
        eliminationPhase: EliminationPhase.complete,
        result: GameResult(
          winners: remaining,
          losers: eliminated,
          wasChaosControlActive: state.isChaosActive,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      // Next elimination round
      state = state.copyWith(
        activePlayers: remaining,
        eliminatedPlayers: eliminated,
        phase: GamePhase.collecting,
        eliminationPhase: EliminationPhase.roundActive,
        eliminationRound: state.eliminationRound + 1,
        result: null,
      );
    }
  }

  // REMATCH: reset phase to collecting, keep players and config, clear result
  void resetForRematch() {
    state = state.copyWith(
      phase: GamePhase.collecting,
      result: null,
    );
  }

  // NEW ROUND: full reset to waiting
  void resetFull() {
    state = GameSession.initial(state.mode);
  }
}
```

- [ ] **Step 4: Write lib/providers/settings_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int countdownSeconds; // 1, 2, or 3

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
```

- [ ] **Step 5: Write lib/providers/history_provider.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';

const _maxHistory = 5;

class HistoryState {
  final List<({GameMode mode, GameResult result})> rounds;
  const HistoryState({this.rounds = const []});
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState());

  void addRound(GameMode mode, GameResult result) {
    final updated = [(mode: mode, result: result), ...state.rounds];
    state = HistoryState(
      rounds: updated.take(_maxHistory).toList(),
    );
  }
}
```

- [ ] **Step 6: Run game session tests — verify they PASS**

```bash
flutter test test/game_session_test.dart --reporter=expanded 2>&1
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/providers/ test/game_session_test.dart
git commit -m "feat: add game session, settings, and history providers (TDD)"
```

---

## Task 6: Core Widgets

**Files:**
- Create: `lib/widgets/sticker_label.dart`
- Create: `lib/widgets/chaos_banner.dart`
- Create: `lib/widgets/finger_bubble.dart`
- Create: `lib/widgets/result_card.dart`

- [ ] **Step 1: Write lib/widgets/sticker_label.dart**

```dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

class StickerLabel extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double rotation; // radians

  const StickerLabel({
    super.key,
    required this.text,
    this.backgroundColor = RaakColors.volt,
    this.textColor = RaakColors.textDark,
    this.rotation = -0.035, // ~-2 degrees default
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RaakColors.textDark, width: 1.5),
          boxShadow: RaakButtonStyle.hardShadow(RaakColors.textDark),
        ),
        child: Text(
          text.toUpperCase(),
          style: RaakTextStyles.sticker.copyWith(color: textColor),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write lib/widgets/chaos_banner.dart**

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme.dart';

// Hazard-stripe Chaos Control disclosure banner.
// MUST be shown whenever Chaos Control is active — never hidden.
class ChaosBanner extends StatelessWidget {
  const ChaosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: _HazardGradient(),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A00),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHAOS CONTROL ACTIEF',
                        style: RaakTextStyles.sticker.copyWith(
                          color: RaakColors.blast,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Resultaten worden handmatig beïnvloed',
                        style: RaakTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Diagonal hazard stripe using CustomPainter
class _HazardGradient extends Gradient {
  const _HazardGradient();

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    return LinearGradient(
      colors: const [
        RaakColors.blast, RaakColors.blast,
        RaakColors.volt, RaakColors.volt,
      ],
      stops: const [0.0, 0.5, 0.5, 1.0],
      transform: const GradientRotation(math.pi / 4),
      tileMode: TileMode.repeated,
    ).createShader(rect);
  }
}
```

- [ ] **Step 3: Write lib/widgets/finger_bubble.dart**

```dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/player.dart';

enum BubbleState { idle, locked, winner, loser }

class FingerBubble extends StatefulWidget {
  final Player player;
  final BubbleState bubbleState;

  const FingerBubble({
    super.key,
    required this.player,
    this.bubbleState = BubbleState.idle,
  });

  @override
  State<FingerBubble> createState() => _FingerBubbleState();
}

class _FingerBubbleState extends State<FingerBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.bubbleState;
    final color = widget.player.color;
    final textColor = s == BubbleState.loser
        ? RaakColors.textGrey
        : (widget.player.arrivalIndex % 2 == 0
            ? RaakColors.textDark
            : RaakColors.textWhite);

    double scale = 1.0;
    double opacity = 1.0;
    BoxBorder? border;
    List<BoxShadow> shadows = [];

    switch (s) {
      case BubbleState.idle:
        border = Border.all(color: color, width: 3);
        break;
      case BubbleState.locked:
        border = Border.all(color: color, width: 3);
        shadows = [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 0, spreadRadius: 10),
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 0, spreadRadius: 16),
        ];
        break;
      case BubbleState.winner:
        scale = 1.27;
        border = Border.all(color: color, width: 4);
        shadows = [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 20, spreadRadius: 4),
        ];
        break;
      case BubbleState.loser:
        scale = 0.8;
        opacity = 0.6;
        border = Border.all(color: RaakColors.textGrey, width: 3, style: BorderStyle.none);
        break;
    }

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring for idle state
            if (s == BubbleState.idle)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 60 + (_pulseAnim.value * 16),
                  height: 60 + (_pulseAnim.value * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15 * (1 - _pulseAnim.value)),
                  ),
                ),
              ),
            // Main bubble
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: s == BubbleState.loser ? RaakColors.surface : color,
                shape: BoxShape.circle,
                border: border,
                boxShadow: shadows,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.player.nickname,
                style: RaakTextStyles.sticker.copyWith(
                  color: textColor,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write lib/widgets/result_card.dart**

```dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/game_result.dart';
import '../models/game_session.dart';
import 'sticker_label.dart';
import 'chaos_banner.dart';

class ResultCard extends StatelessWidget {
  final GameResult result;
  final GameMode mode;

  const ResultCard({super.key, required this.result, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RaakColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaakColors.borderDark, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.wasChaosControlActive) ...[
            const ChaosBanner(),
            const SizedBox(height: 16),
          ],
          if (result.winners.isNotEmpty) ...[
            StickerLabel(
              text: mode == GameMode.multiWinner ? 'WINNAARS' : 'WINNAAR',
              backgroundColor: RaakColors.volt,
              textColor: RaakColors.textDark,
            ),
            const SizedBox(height: 8),
            ...result.winners.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(p.nickname, style: RaakTextStyles.body),
            )),
          ],
          if (result.losers.isNotEmpty) ...[
            StickerLabel(
              text: mode == GameMode.elimination ? 'ERUIT' : 'PECH',
              backgroundColor: RaakColors.shock,
              textColor: RaakColors.textWhite,
              rotation: 0.026,
            ),
            const SizedBox(height: 8),
            ...result.losers.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(p.nickname, style: RaakTextStyles.body.copyWith(color: RaakColors.textGrey)),
            )),
          ],
          if (result.teams != null) ...[
            ...result.teams!.asMap().entries.map((e) => Column(
              children: [
                const SizedBox(height: 12),
                StickerLabel(
                  text: 'TEAM ${String.fromCharCode(65 + e.key)}',
                  backgroundColor: RaakColors.playerColor(e.key),
                  textColor: RaakColors.playerTextColor(e.key),
                  rotation: e.key.isEven ? -0.026 : 0.026,
                ),
                const SizedBox(height: 6),
                ...e.value.map((p) => Text(p.nickname, style: RaakTextStyles.body)),
              ],
            )),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Verify no compile errors**

```bash
flutter analyze lib/widgets/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/
git commit -m "feat: add FingerBubble, StickerLabel, ChaosBanner, ResultCard widgets"
```

---

## Task 7: Haptics + Audio

**Files:**
- Create: `lib/core/haptics.dart`

- [ ] **Step 1: Write lib/core/haptics.dart**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/haptics.dart
git commit -m "feat: add haptics and audio wrapper"
```

---

## Task 8: Home Screen

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

- [ ] **Step 1: Implement home_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/history_provider.dart';
import '../../models/game_session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).rounds;

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo
            Text(
              'RAAK',
              style: RaakTextStyles.display.copyWith(fontSize: 72),
            ),
            const SizedBox(height: 8),
            Text(
              'WIE GAAT ERUIT?',
              style: RaakTextStyles.caption,
            ),
            const Spacer(),
            // Main CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/mode-select'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: RaakButtonStyle.primary(radius: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'SPEEL NU',
                    style: RaakTextStyles.body.copyWith(
                      color: RaakColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Settings button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: RaakButtonStyle.ghost(),
                    child: Text('INSTELLINGEN', style: RaakTextStyles.caption),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showHistory(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: RaakButtonStyle.ghost(),
                      child: Text('GESCHIEDENIS', style: RaakTextStyles.caption),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    final history = ref.read(historyProvider).rounds;
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAATSTE RONDES', style: RaakTextStyles.caption),
            const SizedBox(height: 16),
            ...history.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(_modeLabel(entry.mode), style: RaakTextStyles.caption),
                  const SizedBox(width: 12),
                  Text(
                    entry.result.winners.isNotEmpty
                        ? entry.result.winners.map((p) => p.nickname).join(', ')
                        : entry.result.losers.map((p) => p.nickname).join(', '),
                    style: RaakTextStyles.body,
                  ),
                  if (entry.result.wasChaosControlActive) ...[
                    const SizedBox(width: 8),
                    const Text('⚠️', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.winner: return 'WINNAAR';
      case GameMode.loser: return 'PECH';
      case GameMode.multiWinner: return 'MULTI';
      case GameMode.teams: return 'TEAMS';
      case GameMode.elimination: return 'OVERLEVER';
      case GameMode.chaos: return '⚠️ CHAOS';
    }
  }
}
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/screens/home/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/
git commit -m "feat: implement home screen with SPEEL NU CTA and history modal"
```

---

## Task 9: Mode Select Screen

**Files:**
- Modify: `lib/screens/mode_select/mode_select_screen.dart`

- [ ] **Step 1: Implement mode_select_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../widgets/chaos_banner.dart';

class ModeSelectScreen extends ConsumerStatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  ConsumerState<ModeSelectScreen> createState() => _ModeSelectState();
}

class _ModeSelectState extends ConsumerState<ModeSelectScreen> {
  GameMode _selectedMode = GameMode.winner;
  int _multiWinnerCount = 2;
  int _teamCount = 2;
  ChaosConfig? _chaosConfig;

  final _modes = const [
    (mode: GameMode.winner, label: 'WINNAAR', subtitle: '1 willekeurige winnaar', color: RaakColors.volt),
    (mode: GameMode.loser, label: 'PECH', subtitle: '1 verliezer aanwijzen', color: RaakColors.shock),
    (mode: GameMode.multiWinner, label: 'MULTI', subtitle: 'Meerdere winnaars', color: RaakColors.mint),
    (mode: GameMode.teams, label: 'TEAMS', subtitle: 'Splits in groepen', color: RaakColors.current),
    (mode: GameMode.elimination, label: 'OVERLEVER', subtitle: 'Laatste persoon wint', color: RaakColors.blast),
    (mode: GameMode.chaos, label: '⚠️ CHAOS', subtitle: 'Jij bepaalt de uitkomst', color: RaakColors.staticPurple),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      appBar: AppBar(
        backgroundColor: RaakColors.voidBlack,
        foregroundColor: RaakColors.textWhite,
        title: Text('KIES MODUS', style: RaakTextStyles.caption),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _modes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = _modes[i];
                  final selected = _selectedMode == m.mode;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMode = m.mode;
                        if (m.mode == GameMode.chaos) {
                          _showChaosSheet();
                        } else {
                          _chaosConfig = null;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? m.color.withOpacity(0.15) : RaakColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? m.color : RaakColors.borderDark,
                          width: selected ? 3 : 2,
                        ),
                        boxShadow: selected ? RaakButtonStyle.hardShadow(m.color) : [],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label, style: RaakTextStyles.modeTitle.copyWith(color: m.color)),
                                Text(m.subtitle, style: RaakTextStyles.caption),
                              ],
                            ),
                          ),
                          if (selected && _selectedMode == GameMode.multiWinner)
                            _buildCountPicker(
                              value: _multiWinnerCount,
                              min: 2, max: 5,
                              onChanged: (v) => setState(() => _multiWinnerCount = v),
                            ),
                          if (selected && _selectedMode == GameMode.teams)
                            _buildCountPicker(
                              value: _teamCount,
                              min: 2, max: 4,
                              onChanged: (v) => setState(() => _teamCount = v),
                            ),
                          if (selected) Icon(Icons.check_circle, color: m.color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedMode == GameMode.chaos && _chaosConfig != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ChaosBanner(),
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: RaakButtonStyle.primary(),
                  alignment: Alignment.center,
                  child: Text(
                    'START',
                    style: RaakTextStyles.body.copyWith(
                      color: RaakColors.textDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
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

  Widget _buildCountPicker({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: RaakColors.textWhite),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: RaakTextStyles.modeTitle),
        IconButton(
          icon: const Icon(Icons.add, color: RaakColors.textWhite),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  void _showChaosSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChaosConfigSheet(
        onConfigured: (config) {
          setState(() => _chaosConfig = config);
          Navigator.pop(context);
        },
        onCancel: () {
          setState(() {
            _selectedMode = GameMode.winner;
            _chaosConfig = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _startGame() {
    ref.read(gameSessionProvider.notifier).startSession(
      _selectedMode,
      multiWinnerCount: _multiWinnerCount,
      teamCount: _teamCount,
      chaosConfig: _selectedMode == GameMode.chaos ? _chaosConfig : null,
    );
    Navigator.pushNamed(context, '/arena');
  }
}

class _ChaosConfigSheet extends StatefulWidget {
  final ValueChanged<ChaosConfig> onConfigured;
  final VoidCallback onCancel;

  const _ChaosConfigSheet({required this.onConfigured, required this.onCancel});

  @override
  State<_ChaosConfigSheet> createState() => _ChaosConfigSheetState();
}

class _ChaosConfigSheetState extends State<_ChaosConfigSheet> {
  ChaosTargetType _type = ChaosTargetType.forceWinner;
  int _targetArrival = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChaosBanner(),
          const SizedBox(height: 20),
          Text('WAT WIL JE BEPALEN?', style: RaakTextStyles.caption),
          const SizedBox(height: 12),
          ...[
            (type: ChaosTargetType.forceWinner, label: 'Forceer winnaar'),
            (type: ChaosTargetType.forceLoser, label: 'Forceer verliezer'),
            (type: ChaosTargetType.weightedOdds, label: 'Hogere kans'),
          ].map((opt) => RadioListTile<ChaosTargetType>(
            title: Text(opt.label, style: RaakTextStyles.body),
            value: opt.type,
            groupValue: _type,
            activeColor: RaakColors.blast,
            onChanged: (v) => setState(() => _type = v!),
          )),
          const SizedBox(height: 12),
          if (_type != ChaosTargetType.weightedOdds) ...[
            Text('WELKE VINGER (volgorde)?', style: RaakTextStyles.caption),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _targetArrival = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _targetArrival == i ? RaakColors.blast : RaakColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RaakColors.borderDark),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: RaakTextStyles.body),
                ),
              )),
            ],
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: RaakButtonStyle.ghost(),
                    alignment: Alignment.center,
                    child: Text('ANNULEREN', style: RaakTextStyles.caption),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onConfigured(ChaosConfig(
                    targetType: _type,
                    arrivalIndex: _type != ChaosTargetType.weightedOdds ? _targetArrival : null,
                    weights: _type == ChaosTargetType.weightedOdds
                        ? {_targetArrival: 0.8}
                        : null,
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: RaakColors.blast,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RaakColors.textDark, width: 3),
                      boxShadow: RaakButtonStyle.hardShadow(RaakColors.textDark),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'INSTELLEN',
                      style: RaakTextStyles.body.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/screens/mode_select/ 2>&1
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/mode_select/
git commit -m "feat: implement mode select screen with chaos control config sheet"
```

---

## Task 10: Touch Arena Screen

**Files:**
- Modify: `lib/screens/arena/arena_screen.dart`

- [ ] **Step 1: Implement arena_screen.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/finger_bubble.dart';
import '../../widgets/chaos_banner.dart';

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  Timer? _lockTimer;
  int _countdown = 0;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final notifier = ref.read(gameSessionProvider.notifier);
    notifier.addPlayerFromPointer(event.pointer, event.localPosition);
    ref.read(hapticsProvider).fingerDown();
    _resetLockTimer();
  }

  void _onPointerMove(PointerMoveEvent event) {
    ref.read(gameSessionProvider.notifier)
        .updatePlayerPosition(event.pointer, event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    final session = ref.read(gameSessionProvider);
    if (session.phase == GamePhase.locked ||
        session.phase == GamePhase.revealing ||
        session.phase == GamePhase.done) return;

    ref.read(gameSessionProvider.notifier).removePlayer(event.pointer);
    _resetLockTimer();
  }

  void _resetLockTimer() {
    _lockTimer?.cancel();
    final session = ref.read(gameSessionProvider);
    if (session.activePlayers.length < 2) return;

    final countdownSecs = ref.read(settingsProvider).countdownSeconds;
    setState(() => _countdown = countdownSecs);
    ref.read(gameSessionProvider.notifier).setPhase(GamePhase.collecting);

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = ref.read(gameSessionProvider);
      if (current.activePlayers.length < 2) {
        timer.cancel();
        return;
      }

      setState(() => _countdown--);
      ref.read(hapticsProvider).countdownTick();

      if (_countdown <= 0) {
        timer.cancel();
        ref.read(gameSessionProvider.notifier).setPhase(GamePhase.locked);
        _triggerReveal();
      }
    });
  }

  void _triggerReveal() async {
    await Future.delayed(const Duration(milliseconds: 300));
    ref.read(hapticsProvider).reveal();
    ref.read(gameSessionProvider.notifier).reveal();

    final session = ref.read(gameSessionProvider);
    if (session.result != null && mounted) {
      // Save to history
      // (history write handled in RevealScreen on mount)
      Navigator.pushNamed(context, '/reveal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: Stack(
        children: [
          // Touch surface
          Listener(
            onPointerDown: session.phase == GamePhase.locked ||
                    session.phase == GamePhase.revealing ||
                    session.phase == GamePhase.done
                ? null
                : _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: session.phase == GamePhase.locked ||
                    session.phase == GamePhase.revealing ||
                    session.phase == GamePhase.done
                ? null
                : _onPointerUp,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          // Finger bubbles
          ...session.activePlayers.map((player) => Positioned(
            left: player.position.dx - 30,
            top: player.position.dy - 30,
            child: FingerBubble(
              player: player,
              bubbleState: _bubbleStateFor(player, session),
            ),
          )),
          // Instruction overlay when no fingers
          if (session.activePlayers.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: RaakColors.textGrey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'LEG VINGERS OP HET SCHERM',
                    style: RaakTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          // Countdown overlay
          if (session.phase == GamePhase.collecting && _countdown > 0)
            Center(
              child: Text(
                '$_countdown',
                style: RaakTextStyles.display.copyWith(
                  fontSize: 120,
                  color: RaakColors.volt.withOpacity(0.9),
                ),
              ),
            ),
          if (session.phase == GamePhase.locked)
            Center(
              child: Text(
                'BEZIG...',
                style: RaakTextStyles.display.copyWith(fontSize: 32),
              ),
            ),
          // Chaos banner at top
          if (session.isChaosActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: const ChaosBanner(),
            ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: session.isChaosActive
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: RaakColors.textGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
          ),
        ],
      ),
    );
  }

  BubbleState _bubbleStateFor(player, GameSession session) {
    if (session.phase == GamePhase.idle || session.phase == GamePhase.collecting) {
      return BubbleState.idle;
    }
    if (session.phase == GamePhase.locked) return BubbleState.locked;
    return BubbleState.idle; // Revealing/Done state shown in RevealScreen
  }
}
```

- [ ] **Step 2: Fix the idle phase reference** — `GamePhase` has no `idle` value. Replace `GamePhase.idle` in `_bubbleStateFor` with `GamePhase.waiting`:

In `_bubbleStateFor`, change `GamePhase.idle` to `GamePhase.waiting`.

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/screens/arena/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/arena/
git commit -m "feat: implement touch arena with raw pointer events and countdown"
```

---

## Task 11: Reveal Screen

**Files:**
- Modify: `lib/screens/reveal/reveal_screen.dart`

- [ ] **Step 1: Implement reveal_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/finger_bubble.dart';
import '../../widgets/result_card.dart';
import 'finger_bubble.dart' show BubbleState;

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _scaleAnim;
  bool _hasRecordedHistory = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
    _revealController.forward();

    // Record to history once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRecordedHistory) {
        final session = ref.read(gameSessionProvider);
        if (session.result != null) {
          ref.read(historyProvider.notifier).addRound(session.mode, session.result!);
          _hasRecordedHistory = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final result = session.result;

    if (result == null) {
      return const Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Animated result card
            ScaleTransition(
              scale: _scaleAnim,
              child: ResultCard(result: result, mode: session.mode),
            ),
            const SizedBox(height: 24),
            // Bubble row — show winner/loser states
            if (session.activePlayers.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: session.activePlayers.map((player) {
                    final isWinner = result.winners.any((w) => w.id == player.id);
                    final isLoser = result.losers.any((l) => l.id == player.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FingerBubble(
                        player: player,
                        bubbleState: isWinner
                            ? BubbleState.winner
                            : isLoser
                                ? BubbleState.loser
                                : BubbleState.idle,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const Spacer(),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: 'REMATCH',
                      style: RaakButtonStyle.secondary(),
                      onTap: () {
                        ref.read(gameSessionProvider.notifier).resetForRematch();
                        Navigator.pushReplacementNamed(context, '/arena');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildButton(
                      label: 'NIEUWE RONDE',
                      style: RaakButtonStyle.primary(),
                      onTap: () {
                        ref.read(gameSessionProvider.notifier).resetFull();
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/mode-select', (r) => r.settings.name == '/',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Elimination: continue if survivors > 1
            if (session.mode == GameMode.elimination &&
                session.eliminationPhase != EliminationPhase.complete &&
                session.activePlayers.length - result.losers.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildButton(
                  label: 'VOLGENDE RONDE',
                  style: BoxDecoration(
                    color: RaakColors.blast,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RaakColors.textDark, width: 3),
                    boxShadow: RaakButtonStyle.hardShadow(RaakColors.textDark),
                  ),
                  onTap: () {
                    ref.read(gameSessionProvider.notifier).advanceElimination();
                    Navigator.pushReplacementNamed(context, '/arena');
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required BoxDecoration style,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: style,
        alignment: Alignment.center,
        child: Text(
          label,
          style: RaakTextStyles.body.copyWith(
            fontWeight: FontWeight.w900,
            color: RaakColors.textDark,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Fix import** — `reveal_screen.dart` incorrectly imports `finger_bubble.dart` from itself. Remove this line:
```dart
import 'finger_bubble.dart' show BubbleState;
```
Replace with the correct import:
```dart
import '../../widgets/finger_bubble.dart' show BubbleState;
```

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/screens/reveal/ 2>&1
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/reveal/
git commit -m "feat: implement reveal screen with animated result card and rematch flow"
```

---

## Task 12: Settings Screen

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Implement settings_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
          _buildSection('OVER', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('RAAK v1.0', style: RaakTextStyles.body),
              subtitle: Text('Originele party app — geen kopie', style: RaakTextStyles.caption),
              trailing: const Icon(Icons.info_outline, color: RaakColors.textGrey),
            ),
          ]),
        ],
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
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/screens/settings/ 2>&1
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/settings/
git commit -m "feat: implement settings screen with sound, vibration, and countdown config"
```

---

## Task 13: Full Integration + Run Tests

**Files:**
- All files — final wiring and verification

- [ ] **Step 1: Run all tests**

```bash
flutter test --reporter=expanded 2>&1
```

Expected: All tests in `randomness_test.dart` and `game_session_test.dart` pass. Fix any failures before proceeding.

- [ ] **Step 2: Run full static analysis**

```bash
flutter analyze 2>&1
```

Expected: `No issues found!` Fix any errors. Warnings about unused imports or deprecated APIs are acceptable.

- [ ] **Step 3: Build debug APK to verify end-to-end compilation**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Write README.md**

Create `README.md` at project root:

```markdown
# RAAK

Party finger-chooser app. Place fingers on screen, RAAK picks a winner.

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

## Architecture
- Flutter + Riverpod StateNotifier
- All game logic in `lib/providers/game_session_provider.dart`
- All randomness isolated in `lib/core/randomness.dart`
- Raw pointer events via `Listener` widget (not GestureDetector)

## Chaos Control
Chaos Control is an explicitly disclosed, opt-in mode. It is never hidden.
When active, a hazard-stripe banner is shown on both the arena and result screens.
See `lib/core/randomness.dart` for the ethical code comment.

## Known Limitations (v1)
- History is in-memory — lost on restart
- No tablet-optimized layout
- Dark mode only
```

- [ ] **Step 5: Final commit and push**

```bash
git add -A
git commit -m "feat: complete RAAK v1 implementation — all screens, tests, and README"
git push origin main
```

---

## Quick Reference: Run Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device/emulator |
| `flutter test` | Run all unit tests |
| `flutter analyze` | Static analysis |
| `flutter build apk --debug` | Build Android debug APK |
| `flutter build ios --debug` | Build iOS debug (requires Mac + Xcode) |
