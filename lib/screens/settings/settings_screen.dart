import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: RaakColors.voidBlack,
      appBar: AppBar(
        backgroundColor: RaakColors.voidBlack,
        foregroundColor: RaakColors.textWhite,
        title: Text('INSTELLINGEN', style: RaakTextStyles.caption),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('GELUID & TRILLEN', [
            _buildToggle(
              label: 'Geluidseffecten',
              value: settings.soundEnabled,
              onChanged: (_) => notifier.toggleSound(),
            ),
            _buildToggle(
              label: 'Trillen (haptics)',
              value: settings.vibrationEnabled,
              onChanged: (_) => notifier.toggleVibration(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('AFTELLEN', [
            Row(
              children: [
                Text('Duur', style: RaakTextStyles.body),
                const Spacer(),
                ...[1, 2, 3].map((s) => GestureDetector(
                  onTap: () => notifier.setCountdown(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(left: 8),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: settings.countdownSeconds == s
                          ? RaakColors.volt
                          : RaakColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RaakColors.borderDark),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s}s',
                      style: RaakTextStyles.body.copyWith(
                        color: settings.countdownSeconds == s
                            ? RaakColors.textDark
                            : RaakColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('OVER', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('RAAK v1.0', style: RaakTextStyles.body),
              subtitle: Text(
                'Originele party app — geen kopie',
                style: RaakTextStyles.caption,
              ),
              trailing: const Icon(Icons.info_outline, color: RaakColors.textGrey),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RaakTextStyles.caption),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RaakColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RaakColors.borderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: RaakTextStyles.body),
      value: value,
      activeColor: RaakColors.volt,
      onChanged: onChanged,
    );
  }
}
