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
              child: Text(
                p.nickname,
                style: RaakTextStyles.body.copyWith(color: RaakColors.textGrey),
              ),
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
