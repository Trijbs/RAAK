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
