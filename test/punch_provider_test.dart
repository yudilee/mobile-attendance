import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/punch_provider.dart';

void main() {
  group('PunchState', () {
    test('initial state is idle', () {
      final state = PunchState.initial();
      expect(state.status, PunchStatus.idle);
      expect(state.errorMessage, isNull);
    });

    test('error state stores message', () {
      final state = PunchState(status: PunchStatus.error, errorMessage: 'Test error');
      expect(state.status, PunchStatus.error);
      expect(state.errorMessage, 'Test error');
    });

    test('success state stores result', () {
      final state = PunchState(
        status: PunchStatus.success,
        result: {'message': 'Punch recorded'},
      );
      expect(state.status, PunchStatus.success);
      expect(state.result, {'message': 'Punch recorded'});
    });

    test('offline state indicates saved offline', () {
      final state = PunchState(
        status: PunchStatus.offline,
        savedOffline: true,
      );
      expect(state.status, PunchStatus.offline);
      expect(state.savedOffline, isTrue);
    });

    test('copyWith preserves unset fields', () {
      final state = PunchState.initial();
      final updated = state.copyWith(status: PunchStatus.loading);
      expect(updated.status, PunchStatus.loading);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith overrides specified fields', () {
      final state = PunchState(status: PunchStatus.error, errorMessage: 'Old error');
      final updated = state.copyWith(errorMessage: 'New error');
      expect(updated.status, PunchStatus.error);
      expect(updated.errorMessage, 'New error');
    });
  });
}
