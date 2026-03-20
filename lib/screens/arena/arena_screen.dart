import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/finger_bubble.dart';
import '../../widgets/chaos_banner.dart';

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  Timer? _lockTimer;
  int _countdown = 0;

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  bool get _isLocked {
    final phase = ref.read(gameSessionProvider).phase;
    return phase == GamePhase.locked ||
        phase == GamePhase.revealing ||
        phase == GamePhase.done;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isLocked) return;
    ref.read(gameSessionProvider.notifier)
        .addPlayerFromPointer(event.pointer, event.localPosition);
    ref.read(hapticsProvider).fingerDown();
    _resetLockTimer();
  }

  void _onPointerMove(PointerMoveEvent event) {
    ref.read(gameSessionProvider.notifier)
        .updatePlayerPosition(event.pointer, event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isLocked) return;
    ref.read(gameSessionProvider.notifier).removePlayer(event.pointer);
    _resetLockTimer();
  }

  void _resetLockTimer() {
    _lockTimer?.cancel();
    final session = ref.read(gameSessionProvider);
    if (session.activePlayers.length < 2) {
      setState(() => _countdown = 0);
      return;
    }

    final countdownSecs = ref.read(settingsProvider).countdownSeconds;
    setState(() => _countdown = countdownSecs);
    ref.read(gameSessionProvider.notifier).setPhase(GamePhase.collecting);

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = ref.read(gameSessionProvider);
      if (current.activePlayers.length < 2) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }

      setState(() => _countdown--);
      ref.read(hapticsProvider).countdownTick();

      if (_countdown <= 0) {
        timer.cancel();
        _triggerReveal();
      }
    });
  }

  void _triggerReveal() async {
    ref.read(gameSessionProvider.notifier).setPhase(GamePhase.locked);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    ref.read(hapticsProvider).reveal();
    ref.read(gameSessionProvider.notifier).reveal();
    if (mounted) Navigator.pushNamed(context, '/reveal');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          ...session.activePlayers.map((player) => Positioned(
            left: player.position.dx - 30,
            top: player.position.dy - 30,
            child: FingerBubble(
              player: player,
              bubbleState: _bubbleStateFor(session.phase),
            ),
          )),
          if (session.activePlayers.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: RaakColors.textGrey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'LEG VINGERS OP HET SCHERM',
                    style: RaakTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (session.phase == GamePhase.collecting && _countdown > 0)
            Center(
              child: IgnorePointer(
                child: Text(
                  '$_countdown',
                  style: RaakTextStyles.display.copyWith(
                    fontSize: 120,
                    color: RaakColors.volt.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          if (session.phase == GamePhase.locked || session.phase == GamePhase.revealing)
            const Center(
              child: IgnorePointer(
                child: Text(
                  'BEZIG...',
                  style: RaakTextStyles.display,
                ),
              ),
            ),
          if (session.isChaosActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: const ChaosBanner(),
            ),
          if (!session.isChaosActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: RaakColors.textGrey),
                onPressed: () {
                  _lockTimer?.cancel();
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }

  BubbleState _bubbleStateFor(GamePhase phase) {
    switch (phase) {
      case GamePhase.waiting:
      case GamePhase.collecting:
        return BubbleState.idle;
      case GamePhase.locked:
      case GamePhase.revealing:
      case GamePhase.done:
        return BubbleState.locked;
    }
  }
}
