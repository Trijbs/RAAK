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
    final decided = matchState.matchDecidedSlot;
    if (decided == null) {
      return const Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: Center(child: Text('Geen resultaat', style: RaakTextStyles.caption)),
      );
    }
    final isWinnerMode = matchState.config.outcomeType == MatchOutcomeType.winner;
    final highlightColor = isWinnerMode ? RaakColors.volt : RaakColors.blast;
    final labelText = isWinnerMode ? 'KAMPIOEN' : 'VERLIEZER';

    // Build sorted tally entries (highest tally first)
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
