import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/dare.dart';
import '../../providers/dare_provider.dart';

class DareOverlayScreen extends ConsumerStatefulWidget {
  final int loserSlot;
  const DareOverlayScreen({super.key, required this.loserSlot});

  @override
  ConsumerState<DareOverlayScreen> createState() => _DareOverlayScreenState();
}

class _DareOverlayScreenState extends ConsumerState<DareOverlayScreen> {
  Dare? _currentDare;
  bool _hasRedrawn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Wait for DareNotifier async init (SharedPreferences load) before drawing.
    // initFuture resolves immediately on subsequent launches; only delays on first.
    ref.read(dareProvider.notifier).initFuture.then((_) {
      if (mounted) {
        setState(() {
          _currentDare = ref.read(dareProvider.notifier).drawRandom();
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: Center(child: CircularProgressIndicator(color: RaakColors.volt)),
      );
    }
    if (_currentDare == null) {
      return Scaffold(
        backgroundColor: RaakColors.voidBlack,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GEEN OPDRACHTEN INGESTELD', style: RaakTextStyles.caption),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: RaakButtonStyle.ghost(),
                    child: Text('TERUG', style: RaakTextStyles.caption),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final enabledCount = ref.read(dareProvider).where((d) => d.isEnabled).length;
    final canRedraw = !_hasRedrawn && enabledCount >= 2;

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'OPDRACHT VOOR SPELER ${widget.loserSlot + 1}',
                style: RaakTextStyles.caption,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: RaakColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RaakColors.blast, width: 3),
                  boxShadow: RaakButtonStyle.hardShadow(RaakColors.blast),
                ),
                child: Text(
                  _currentDare!.text,
                  style: RaakTextStyles.modeTitle.copyWith(
                    fontSize: 22,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: canRedraw
                          ? () {
                              final next = ref
                                  .read(dareProvider.notifier)
                                  .drawAgain(_currentDare!.id);
                              if (next != null) {
                                setState(() {
                                  _currentDare = next;
                                  _hasRedrawn = true;
                                });
                              }
                            }
                          : null,
                      child: Opacity(
                        opacity: canRedraw ? 1.0 : 0.4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: RaakButtonStyle.ghost(),
                          alignment: Alignment.center,
                          child: Text('VOLGENDE', style: RaakTextStyles.caption),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: RaakButtonStyle.primary(),
                        alignment: Alignment.center,
                        child: Text(
                          'GEDAAN',
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
            ],
          ),
        ),
      ),
    );
  }
}
