import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme.dart';

// Hazard-stripe Chaos Control disclosure banner.
// MUST be shown whenever Chaos Control is active — never hidden.
class ChaosBanner extends StatelessWidget {
  const ChaosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _HazardBorderPainter(),
        child: Container(
          margin: const EdgeInsets.all(3),
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
    );
  }
}

class _HazardBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          RaakColors.blast, RaakColors.blast,
          RaakColors.volt, RaakColors.volt,
        ],
        stops: [0.0, 0.5, 0.5, 1.0],
        transform: GradientRotation(math.pi / 4),
        tileMode: TileMode.repeated,
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_HazardBorderPainter oldDelegate) => false;
}
