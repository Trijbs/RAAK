import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/finger_bubble.dart';
import '../../widgets/result_card.dart';

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
