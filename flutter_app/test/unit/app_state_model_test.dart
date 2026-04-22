import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/models/app_state_model.dart';

void main() {
  group('PZEMState tests', () {
    test('PZEMState.fromJson handles valid data', () {
      final json = {
        'v': 220.5,
        'a': 1.2,
        'w': 264.6,
        'e': 15.0,
        'hz': 50.0,
        'pf': 0.95
      };
      final state = PZEMState.fromJson(json);
      expect(state.voltage, 220.5);
      expect(state.current, 1.2);
      expect(state.power, 264.6);
      expect(state.energy, 15.0);
      expect(state.frequency, 50.0);
      expect(state.pf, 0.95);
    });

    test('PZEMState.fromJson handles missing fields with defaults', () {
      final json = {'v': 220.5};
      final state = PZEMState.fromJson(json);
      expect(state.voltage, 220.5);
      expect(state.current, 0.0);
      expect(state.power, 0.0);
    });
  });

  group('RelayInfo tests', () {
    test('RelayInfo.fromJson handles valid data', () {
      final json = {
        'state': true,
        'name': 'Fan',
        'start': 1713631200,
        'stop': 1713634800
      };
      final relay = RelayInfo.fromJson(json);
      expect(relay.state, true);
      expect(relay.name, 'Fan');
      expect(relay.start, 1713631200);
      expect(relay.stop, 1713634800);
    });
  });

  group('ACState tests', () {
    test('ACState.fromJson handles valid data', () {
      final json = {
        'power': true,
        'temp': 22,
        'mode': 4,
        'fan': 'High',
        'swingV': true,
        'timer': 1713638400
      };
      final ac = ACState.fromJson(json);
      expect(ac.power, true);
      expect(ac.temp, 22);
      expect(ac.mode, 4);
      expect(ac.fan, 'High');
      expect(ac.swingV, true);
      expect(ac.timer, 1713638400);
    });
  });

  group('MacroConfig tests', () {
    test('MacroConfig.fromJson handles valid data and trimming', () {
      final json = {
        'name': ' Night Mode ',
        'color': 'blue',
        'relays': [0, 1, 5],
        'wake_pc': true
      };
      final macro = MacroConfig.fromJson(json);
      expect(macro.name, 'Night Mode');
      expect(macro.color, 'blue');
      expect(macro.relays, [0, 1, 5]);
      expect(macro.wakePc, true);
    });

    test('MacroConfig.fromJson handles empty name', () {
      final json = {'name': '  '};
      final macro = MacroConfig.fromJson(json);
      expect(macro.name, 'Empty');
    });
  });

  group('PCInfo tests', () {
    test('PCInfo.fromJson handles "online" and "pc" keys', () {
      final jsonOnline = {'online': true};
      final pcOnline = PCInfo.fromJson(jsonOnline);
      expect(pcOnline.online, true);

      final jsonPc = {'pc': true};
      final pcWithPcKey = PCInfo.fromJson(jsonPc);
      expect(pcWithPcKey.online, true);
    });
  });
}
