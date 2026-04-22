import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/models/app_state_model.dart';

void main() {
  group('HealthState Model Tests', () {
    test('HealthState initial defaults', () {
      final state = HealthState();
      expect(state.temp, 0.0);
      expect(state.tempHigh, 28.5);
      expect(state.tempLow, 26.0);
    });

    test('HealthState fromJson parsing', () {
      final json = {
        'temp': 27.5,
        'humid': 65.0,
        'th': 30.0,
        'tl': 25.0,
        'autoSleep': true,
      };
      final state = HealthState.fromJson(json);
      expect(state.temp, 27.5);
      expect(state.tempHigh, 30.0);
      expect(state.tempLow, 25.0);
      expect(state.autoSleep, true);
    });
  });
}
