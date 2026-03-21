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
