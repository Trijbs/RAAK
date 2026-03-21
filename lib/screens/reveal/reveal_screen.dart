import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/finger_bubble.dart';
import '../../widgets/result_card.dart';
import '../../models/match.dart';
import '../../providers/match_provider.dart';
import '../../providers/dare_provider.dart';

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
            final isWinnerMode =
                matchState.config.outcomeType == MatchOutcomeType.winner;
            final selectedSlot = isWinnerMode
                ? (result.winners.isEmpty ? null : result.winners.first.arrivalIndex)
                : (result.losers.isEmpty ? null : result.losers.first.arrivalIndex);
            if (selectedSlot != null) {
              ref.read(matchProvider.notifier).recordSelection(selectedSlot);

              // Navigate to match summary if match is decided
              final updated = ref.read(matchProvider);
              if (updated != null && !updated.isActive && mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/match-summary',
                  arguments: updated,
                );
              }
            }
          }
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

    final survivorCount = session.activePlayers.length - result.losers.length;
    final canContinueElimination = session.mode == GameMode.elimination &&
        session.eliminationPhase != EliminationPhase.complete &&
        survivorCount > 1;

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            ScaleTransition(
              scale: _scaleAnim,
              child: ResultCard(result: result, mode: session.mode),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                final matchState = ref.watch(matchProvider);
                if (matchState == null || !matchState.isActive) {
                  return const SizedBox.shrink();
                }
                final isWinnerMode =
                    matchState.config.outcomeType == MatchOutcomeType.winner;
                final label = isWinnerMode ? 'WINS' : 'VERLIESPUNTEN';
                final slots = matchState.tally.keys.toList()..sort();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                                style: RaakTextStyles.body
                                    .copyWith(fontSize: 14),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: 'REMATCH',
                      decoration: RaakButtonStyle.secondary(),
                      textColor: RaakColors.textWhite,
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
                      decoration: RaakButtonStyle.primary(),
                      textColor: RaakColors.textDark,
                      onTap: () {
                        ref.read(matchProvider.notifier).endMatch();
                        ref.read(gameSessionProvider.notifier).resetFull();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/mode-select',
                          (r) => r.settings.name == '/',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (canContinueElimination) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildButton(
                  label: 'VOLGENDE RONDE',
                  decoration: BoxDecoration(
                    color: RaakColors.blast,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RaakColors.textDark, width: 3),
                    boxShadow: RaakButtonStyle.hardShadow(RaakColors.textDark),
                  ),
                  textColor: RaakColors.textWhite,
                  onTap: () {
                    ref.read(gameSessionProvider.notifier).advanceElimination();
                    Navigator.pushReplacementNamed(context, '/arena');
                  },
                ),
              ),
            ],
            Consumer(
              builder: (context, ref, _) {
                final result = ref.watch(gameSessionProvider).result;
                if (result == null || result.losers.isEmpty) {
                  return const SizedBox.shrink();
                }
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color:
                                RaakColors.blast.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: RaakColors.blast, width: 2),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required BoxDecoration decoration,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: decoration,
        alignment: Alignment.center,
        child: Text(
          label,
          style: RaakTextStyles.body.copyWith(
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
