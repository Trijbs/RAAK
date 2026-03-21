import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/dare.dart';
import '../../providers/settings_provider.dart';
import '../../providers/dare_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dares = ref.watch(dareProvider);
    final dareNotifier = ref.read(dareProvider.notifier);

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
          // Dares section
          Text('OPDRACHTEN', style: RaakTextStyles.caption),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: RaakColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RaakColors.borderDark),
            ),
            child: Column(
              children: [
                ...dares.map((dare) => _DareListTile(
                  dare: dare,
                  onToggle: () => dareNotifier.toggle(dare.id),
                  onDelete: dare.isCustom
                      ? () => dareNotifier.deleteCustom(dare.id)
                      : null,
                )),
                const Divider(color: RaakColors.borderDark, height: 1),
                ListTile(
                  onTap: () => _showAddDareSheet(context, dareNotifier),
                  leading: const Icon(Icons.add, color: RaakColors.volt),
                  title: Text(
                    'OPDRACHT TOEVOEGEN',
                    style: RaakTextStyles.body.copyWith(color: RaakColors.volt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('OVER', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('RAAK v1.1', style: RaakTextStyles.body),
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

  void _showAddDareSheet(BuildContext context, DareNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RaakColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddDareSheet(notifier: notifier),
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

class _DareListTile extends StatelessWidget {
  final Dare dare;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _DareListTile({
    required this.dare,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        dare.text,
        style: RaakTextStyles.body.copyWith(
          fontSize: 14,
          color: dare.isEnabled ? RaakColors.textWhite : RaakColors.textGrey,
        ),
      ),
      leading: Switch(
        value: dare.isEnabled,
        activeColor: RaakColors.volt,
        onChanged: (_) => onToggle(),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: RaakColors.textGrey),
              onPressed: onDelete,
            )
          : const Icon(Icons.lock_outline,
              color: RaakColors.borderDark, size: 16),
    );
  }
}

class _AddDareSheet extends StatefulWidget {
  final DareNotifier notifier;

  const _AddDareSheet({required this.notifier});

  @override
  State<_AddDareSheet> createState() => _AddDareSheetState();
}

class _AddDareSheetState extends State<_AddDareSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NIEUWE OPDRACHT', style: RaakTextStyles.caption),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 120,
            autofocus: true,
            style: RaakTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Typ een opdracht...',
              hintStyle:
                  RaakTextStyles.body.copyWith(color: RaakColors.textGrey),
              filled: true,
              fillColor: RaakColors.voidBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: RaakColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: RaakColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: RaakColors.volt, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  widget.notifier.addCustom(text);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: RaakButtonStyle.primary(),
                alignment: Alignment.center,
                child: Text(
                  'TOEVOEGEN',
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
    );
  }
}
