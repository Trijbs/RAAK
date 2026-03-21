import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raak/providers/dare_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DareNotifier.drawRandom', () {
    test('returns null when 0 dares are enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      // disable all
      for (final d in notifier.state) {
        notifier.toggle(d.id);
      }
      expect(notifier.drawRandom(), isNull);
    });

    test('returns a dare when at least 1 is enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      expect(notifier.drawRandom(), isNotNull);
    });
  });

  group('DareNotifier.drawAgain', () {
    test('returns null when fewer than 2 dares are enabled', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      // disable all but the first
      final ids = notifier.state.map((d) => d.id).toList();
      for (final id in ids.skip(1)) {
        notifier.toggle(id);
      }
      expect(notifier.drawAgain(ids.first), isNull);
    });

    test('never returns the excluded dare', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final firstId = notifier.state.first.id;
      for (int i = 0; i < 20; i++) {
        final drawn = notifier.drawAgain(firstId);
        expect(drawn?.id, isNot(firstId));
      }
    });
  });

  group('DareNotifier.addCustom', () {
    test('adds a dare with isCustom=true', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final before = notifier.state.length;
      notifier.addCustom('Test opdracht');
      expect(notifier.state.length, before + 1);
      expect(notifier.state.last.isCustom, isTrue);
      expect(notifier.state.last.text, 'Test opdracht');
    });
  });

  group('DareNotifier.toggle', () {
    test('flips isEnabled for a dare', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final id = notifier.state.first.id;
      final before = notifier.state.first.isEnabled;
      notifier.toggle(id);
      expect(notifier.state.first.isEnabled, !before);
    });
  });

  group('DareNotifier.deleteCustom', () {
    test('removes custom dares', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      notifier.addCustom('Te verwijderen');
      final customId = notifier.state.last.id;
      final before = notifier.state.length;
      notifier.deleteCustom(customId);
      expect(notifier.state.length, before - 1);
      expect(notifier.state.any((d) => d.id == customId), isFalse);
    });

    test('does not remove built-in dares', () async {
      final notifier = DareNotifier();
      await notifier.initFuture;
      final builtinId = notifier.state.first.id;
      final before = notifier.state.length;
      notifier.deleteCustom(builtinId);
      expect(notifier.state.length, before); // unchanged
    });
  });
}
