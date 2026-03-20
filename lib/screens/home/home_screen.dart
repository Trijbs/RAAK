import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/history_provider.dart';
import '../../models/game_session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).rounds;

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              'RAAK',
              style: RaakTextStyles.display.copyWith(fontSize: 72),
            ),
            const SizedBox(height: 8),
            Text('WIE GAAT ERUIT?', style: RaakTextStyles.caption),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/mode-select'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: RaakButtonStyle.primary(radius: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'SPEEL NU',
                    style: RaakTextStyles.body.copyWith(
                      color: RaakColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: RaakButtonStyle.ghost(),
                    child: Text('INSTELLINGEN', style: RaakTextStyles.caption),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showHistory(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: RaakButtonStyle.ghost(),
                      child: Text('GESCHIEDENIS', style: RaakTextStyles.caption),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    final history = ref.read(historyProvider).rounds;
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAATSTE RONDES', style: RaakTextStyles.caption),
            const SizedBox(height: 16),
            ...history.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(_modeLabel(entry.mode), style: RaakTextStyles.caption),
                  const SizedBox(width: 12),
                  Text(
                    entry.result.winners.isNotEmpty
                        ? entry.result.winners.map((p) => p.nickname).join(', ')
                        : entry.result.losers.map((p) => p.nickname).join(', '),
                    style: RaakTextStyles.body,
                  ),
                  if (entry.result.wasChaosControlActive) ...[
                    const SizedBox(width: 8),
                    const Text('⚠️', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.winner: return 'WINNAAR';
      case GameMode.loser: return 'PECH';
      case GameMode.multiWinner: return 'MULTI';
      case GameMode.teams: return 'TEAMS';
      case GameMode.elimination: return 'OVERLEVER';
      case GameMode.chaos: return '⚠️ CHAOS';
    }
  }
}
