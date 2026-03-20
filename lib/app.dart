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
