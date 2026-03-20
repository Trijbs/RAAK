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
    final textColor = RaakColors.playerTextColor(widget.player.arrivalIndex);

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
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 0, spreadRadius: 10),
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 0, spreadRadius: 16),
        ];
        break;
      case BubbleState.winner:
        scale = 1.27;
        border = Border.all(color: color, width: 4);
        shadows = [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4),
        ];
        break;
      case BubbleState.loser:
        scale = 0.8;
        opacity = 0.6;
        border = Border.all(color: RaakColors.textGrey, width: 3);
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
            if (s == BubbleState.idle)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 60 + (_pulseAnim.value * 16),
                  height: 60 + (_pulseAnim.value * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15 * (1 - _pulseAnim.value)),
                  ),
                ),
              ),
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
                  color: s == BubbleState.loser ? RaakColors.textGrey : textColor,
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
