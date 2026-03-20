import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/game_session.dart';
import '../../providers/game_session_provider.dart';
import '../../widgets/chaos_banner.dart';

class ModeSelectScreen extends ConsumerStatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  ConsumerState<ModeSelectScreen> createState() => _ModeSelectState();
}

class _ModeSelectState extends ConsumerState<ModeSelectScreen> {
  GameMode _selectedMode = GameMode.winner;
  int _multiWinnerCount = 2;
  int _teamCount = 2;
  ChaosConfig? _chaosConfig;

  static const _modes = [
    (mode: GameMode.winner, label: 'WINNAAR', subtitle: '1 willekeurige winnaar', color: RaakColors.volt),
    (mode: GameMode.loser, label: 'PECH', subtitle: '1 verliezer aanwijzen', color: RaakColors.shock),
    (mode: GameMode.multiWinner, label: 'MULTI', subtitle: 'Meerdere winnaars', color: RaakColors.mint),
    (mode: GameMode.teams, label: 'TEAMS', subtitle: 'Splits in groepen', color: RaakColors.current),
    (mode: GameMode.elimination, label: 'OVERLEVER', subtitle: 'Laatste persoon wint', color: RaakColors.blast),
    (mode: GameMode.chaos, label: '⚠️ CHAOS', subtitle: 'Jij bepaalt de uitkomst', color: RaakColors.staticPurple),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      appBar: AppBar(
        backgroundColor: RaakColors.voidBlack,
        foregroundColor: RaakColors.textWhite,
        title: Text('KIES MODUS', style: RaakTextStyles.caption),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _modes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = _modes[i];
                  final selected = _selectedMode == m.mode;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMode = m.mode;
                        if (m.mode != GameMode.chaos) _chaosConfig = null;
                      });
                      if (m.mode == GameMode.chaos) _showChaosSheet();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? m.color.withValues(alpha: 0.15) : RaakColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? m.color : RaakColors.borderDark,
                          width: selected ? 3 : 2,
                        ),
                        boxShadow: selected ? RaakButtonStyle.hardShadow(m.color) : [],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label, style: RaakTextStyles.modeTitle.copyWith(color: m.color)),
                                Text(m.subtitle, style: RaakTextStyles.caption),
                              ],
                            ),
                          ),
                          if (selected && _selectedMode == GameMode.multiWinner)
                            _buildCountPicker(
                              value: _multiWinnerCount,
                              min: 2, max: 5,
                              onChanged: (v) => setState(() => _multiWinnerCount = v),
                            ),
                          if (selected && _selectedMode == GameMode.teams)
                            _buildCountPicker(
                              value: _teamCount,
                              min: 2, max: 4,
                              onChanged: (v) => setState(() => _teamCount = v),
                            ),
                          if (selected) Icon(Icons.check_circle, color: m.color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedMode == GameMode.chaos && _chaosConfig != null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ChaosBanner(),
              ),
            if (_selectedMode == GameMode.chaos && _chaosConfig != null)
              const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: RaakButtonStyle.primary(),
                  alignment: Alignment.center,
                  child: Text(
                    'START',
                    style: RaakTextStyles.body.copyWith(
                      color: RaakColors.textDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountPicker({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: RaakColors.textWhite),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: RaakTextStyles.modeTitle),
        IconButton(
          icon: const Icon(Icons.add, color: RaakColors.textWhite),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  void _showChaosSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChaosConfigSheet(
        onConfigured: (config) {
          setState(() => _chaosConfig = config);
          Navigator.pop(context);
        },
        onCancel: () {
          setState(() {
            _selectedMode = GameMode.winner;
            _chaosConfig = null;
          });
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      // If the sheet was swiped away without configuration, reset to winner
      if (_selectedMode == GameMode.chaos && _chaosConfig == null) {
        setState(() => _selectedMode = GameMode.winner);
      }
    });
  }

  void _startGame() {
    ref.read(gameSessionProvider.notifier).startSession(
      _selectedMode,
      multiWinnerCount: _multiWinnerCount,
      teamCount: _teamCount,
      chaosConfig: _selectedMode == GameMode.chaos ? _chaosConfig : null,
    );
    Navigator.pushNamed(context, '/arena');
  }
}

class _ChaosConfigSheet extends StatefulWidget {
  final ValueChanged<ChaosConfig> onConfigured;
  final VoidCallback onCancel;

  const _ChaosConfigSheet({required this.onConfigured, required this.onCancel});

  @override
  State<_ChaosConfigSheet> createState() => _ChaosConfigSheetState();
}

class _ChaosConfigSheetState extends State<_ChaosConfigSheet> {
  ChaosTargetType _type = ChaosTargetType.forceWinner;
  int _targetArrival = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChaosBanner(),
          const SizedBox(height: 20),
          Text('WAT WIL JE BEPALEN?', style: RaakTextStyles.caption),
          const SizedBox(height: 12),
          ...[
            (type: ChaosTargetType.forceWinner, label: 'Forceer winnaar'),
            (type: ChaosTargetType.forceLoser, label: 'Forceer verliezer'),
            (type: ChaosTargetType.weightedOdds, label: 'Hogere kans'),
          ].map((opt) => RadioListTile<ChaosTargetType>(
            title: Text(opt.label, style: RaakTextStyles.body),
            value: opt.type,
            groupValue: _type,
            activeColor: RaakColors.blast,
            onChanged: (v) => setState(() => _type = v!),
          )),
          const SizedBox(height: 12),
          if (_type != ChaosTargetType.weightedOdds) ...[
            Text('WELKE VINGER (volgorde)?', style: RaakTextStyles.caption),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _targetArrival = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _targetArrival == i ? RaakColors.blast : RaakColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RaakColors.borderDark),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: RaakTextStyles.body),
                ),
              )),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: RaakButtonStyle.ghost(),
                    alignment: Alignment.center,
                    child: Text('ANNULEREN', style: RaakTextStyles.caption),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onConfigured(ChaosConfig(
                    targetType: _type,
                    arrivalIndex: _type != ChaosTargetType.weightedOdds ? _targetArrival : null,
                    weights: _type == ChaosTargetType.weightedOdds
                        ? {_targetArrival: 0.8}
                        : null,
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: RaakColors.blast,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RaakColors.textDark, width: 3),
                      boxShadow: RaakButtonStyle.hardShadow(RaakColors.textDark),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'INSTELLEN',
                      style: RaakTextStyles.body.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
