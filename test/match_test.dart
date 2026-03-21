import 'package:flutter_test/flutter_test.dart';
import 'package:raak/models/match.dart';

void main() {
  group('MatchState.recordSelection', () {
    test('increments tally for the given slot', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      final state = MatchState(config: config);
      final next = state.recordSelection(0);
      expect(next.tally[0], 1);
    });

    test('increments round number', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      final state = MatchState(config: config);
      final next = state.recordSelection(0);
      expect(next.roundNumber, 2);
    });

    test('isActive is true before winTarget reached', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(0);
      state = state.recordSelection(0);
      expect(state.isActive, isTrue);
      expect(state.matchDecidedSlot, isNull);
    });

    test('sets matchDecidedSlot when winTarget reached (winner mode)', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(1);
      state = state.recordSelection(1);
      state = state.recordSelection(1);
      expect(state.matchDecidedSlot, 1);
      expect(state.isActive, isFalse);
    });

    test('sets matchDecidedSlot when winTarget reached (loser mode)', () {
      final config = MatchConfig(winTarget: 2, outcomeType: MatchOutcomeType.loser);
      var state = MatchState(config: config);
      state = state.recordSelection(2);
      state = state.recordSelection(2);
      expect(state.matchDecidedSlot, 2);
    });

    test('different slots accumulate independently', () {
      final config = MatchConfig(winTarget: 3, outcomeType: MatchOutcomeType.winner);
      var state = MatchState(config: config);
      state = state.recordSelection(0);
      state = state.recordSelection(1);
      state = state.recordSelection(0);
      expect(state.tally[0], 2);
      expect(state.tally[1], 1);
      expect(state.matchDecidedSlot, isNull);
    });
  });
}
