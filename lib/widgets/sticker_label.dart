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
    this.rotation = -0.035,
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
