import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state_model.dart';

class FirebaseService extends ChangeNotifier with WidgetsBindingObserver {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  FullAppState state = FullAppState.initial();
  bool isConnected = false;
  StreamSubscription? _stateSub;
  SharedPreferences? _prefs;
  final List<Timer> _commandTimers = [];

  final Map<int, bool> _runningMacros = {};
  List<Map<String, dynamic>> dailyRealtimeBuffer = [];
  String? lastBufferDate;
  bool _sessionSynced = false;

  bool isMacroRunning(int index) => _runningMacros[index] ?? false;

  FirebaseService() {
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadRealtimeBuffer();
    _loadLocalMacros();
    _listenToState();
    _listenToConnection();
    // One-time session sync
    await forceSync('all');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App Lifecycle State changed to: $state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, forcing Firebase online...');
      FirebaseDatabase.instance.goOnline();
      // Optional: forceSync() here might be too much if we want strictly once per session
    }
  }

  void _loadRealtimeBuffer() {
    try {
      final String? date = _prefs?.getString('buffer_date');
      final String? data = _prefs?.getString('realtime_buffer');

      final String today = DateTime.now().toIso8601String().split('T')[0];

      if (date == today && data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        dailyRealtimeBuffer = decoded.cast<Map<String, dynamic>>();
        lastBufferDate = date;
        debugPrint('Loaded ${dailyRealtimeBuffer.length} points for today');
      } else {
        lastBufferDate = today;
        dailyRealtimeBuffer = [];
      }
    } catch (e) {
      debugPrint('Error loading realtime buffer: $e');
      dailyRealtimeBuffer = [];
    }
  }

  void _saveRealtimeBuffer() {
    if (_prefs == null) return;
    final String data = jsonEncode(dailyRealtimeBuffer);
    _prefs?.setString('realtime_buffer', data);
    _prefs?.setString('buffer_date', lastBufferDate ?? '');
  }

  void _loadLocalMacros() {
    final String? macrosJson = _prefs?.getString('local_macros');
    if (macrosJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(macrosJson);
        state = state.copyWith(
          macros: decoded.map((m) => MacroConfig.fromJson(Map<String, dynamic>.from(m))).toList(),
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading local macros: $e');
      }
    }
  }

  Future<void> saveAcPreset(ACState ac) async {
    debugPrint('Saving AC preset locally and to ESP32');
    final Map<String, dynamic> data = {
      'power': ac.power,
      'temp': ac.temp,
      'mode': ac.mode,
      'fan': ac.fan,
      'swingV': ac.swingV,
      'swingH': ac.swingH,
      'econo': ac.econo,
      'powerful': ac.powerful,
      'quiet': ac.quiet,
      'comfort': ac.comfort,
    };
    final String encoded = jsonEncode(data);
    await _prefs?.setString('ac_preset', encoded);
    await sendCommand('ac_save_preset', data);
  }

  Future<void> saveMacro(int index, MacroConfig config) async {
    debugPrint('Saving Macro at index $index: ${config.name}');
    List<MacroConfig> currentMacros = List.from(state.macros);
    if (index >= 0 && index < currentMacros.length) {
      currentMacros[index] = config;
      state = state.copyWith(macros: currentMacros);
      
      final String encoded = jsonEncode(currentMacros.map((m) => m.toJson()).toList());
      await _prefs?.setString('local_macros', encoded);
      
      await sendCommand('macro_update', {
        'index': index,
        'config': config.toJson(),
      });
      
      notifyListeners();
    }
  }

  void _listenToState() {
    _stateSub = _dbRef.child('device/state').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        if (data is String) {
          _updateState(jsonDecode(data));
        } else if (data is Map) {
          _updateState(Map<String, dynamic>.from(data));
        }
      }
    });
  }

  void _listenToConnection() {
    FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
      isConnected = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
  }

  void _updateState(Map<String, dynamic> data) {
    try {
      PZEMState? pzem;
      if (data['pzem'] != null) {
        pzem = PZEMState.fromJson(Map<String, dynamic>.from(data['pzem']));
        dailyRealtimeBuffer.add({
          't': DateTime.now().toIso8601String(),
          'e': pzem.energy,
        });
        if (dailyRealtimeBuffer.length > 5000) dailyRealtimeBuffer.removeAt(0);
        _saveRealtimeBuffer();
      }
      
      state = state.copyWith(
        pzem: pzem,
        relays: data['relays'] != null 
          ? List<RelayInfo>.from(data['relays'].map((m) => RelayInfo.fromJson(Map<String, dynamic>.from(m)))) 
          : null,
        ac: data['ac'] != null ? ACState.fromJson(Map<String, dynamic>.from(data['ac'])) : null,
        pc: data['pc'] != null ? PCInfo.fromJson(Map<String, dynamic>.from(data['pc'])) : null,
        health: data['health'] != null ? HealthState.fromJson(Map<String, dynamic>.from(data['health'])) : null,
        macros: data['macros'] != null ? List<MacroConfig>.from(data['macros'].map((m) => MacroConfig.fromJson(Map<String, dynamic>.from(m)))) : null,
        tierPrices: data['tierPrices'] != null ? List<double>.from(data['tierPrices'].map((e) => (e as num).toDouble())) : null,
        monthly: data['monthly'] != null ? List<double?>.from(data['monthly'].map((e) => (e as num?)?.toDouble())) : null,
        hourly: data['hourly'] != null ? List<double?>.from(data['hourly'].map((e) => (e as num?)?.toDouble())) : null,
        phoneOnline: data['phoneOnline'] ?? state.phoneOnline,
        notifyCheck: data['notifyCheck'] is Map 
          ? (data['notifyCheck']['active'] ?? state.notifyCheck)
          : (data['notifyCheck'] ?? state.notifyCheck),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing Firebase state: $e');
    }
  }

  Future<void> sendCommand(String type, Map<String, dynamic> params) async {
    final cmd = {
      'type': type,
      ...params,
      'timestamp': ServerValue.timestamp,
    };
    try {
      final cmdRef = _dbRef.child('device/cmd').push();
      final cmdKey = cmdRef.key;

      // Start the 5s "expiration" countdown immediately
      final timer = Timer(const Duration(seconds: 5), () async {
        if (cmdKey != null) {
          debugPrint('Firebase: Expiring command $type ($cmdKey) - 5s elapsed');
          try {
            await _dbRef.child('device/cmd').child(cmdKey).remove();
          } catch (e) {
            // Already gone or permission error, safe to ignore
          }
        }
      });
      _commandTimers.add(timer);

      // With persistence enabled, .set() completes when written to local disk.
      // We add a timeout to handle potential SDK-level stalls.
      await cmdRef.set(cmd).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Firebase: Command push timed out (local disk/cache stall)');
          throw TimeoutException('Firebase local write timed out');
        },
      );
      debugPrint('Firebase: Command sent successfully: $type');
    } catch (e) {
      debugPrint('Firebase Error sending command $type: $e');
    }
  }

  Future<void> forceSync([String target = 'all', bool manual = false]) async {
    if (target == 'all' && !manual) {
      if (_sessionSynced) {
        debugPrint('Global sync already performed this session. Skipping.');
        return;
      }
      _sessionSynced = true;
    }
    
    debugPrint('Requesting remote sync for target: $target (manual: $manual)');
    await sendCommand('sync', {'target': target});
  }

  Future<void> refresh(String target) async {
    debugPrint('Refreshing $target: Clearing command buffer and requesting sync');
    try {
      // 1. Force clear the command node
      await _dbRef.child('device/cmd').remove();
      
      // 2. Request fresh state for this view
      await forceSync(target, true);
    } catch (e) {
      debugPrint('Error during refresh: $e');
    }
  }

  Future<void> executeMacro(int index, MacroConfig _) async {
    if (index < 0 || index >= state.macros.length) return;
    
    MacroConfig macro = state.macros[index];
    final updatedMacro = macro.copyWith(active: !macro.active);
    List<MacroConfig> currentMacros = List.from(state.macros);
    currentMacros[index] = updatedMacro;
    state = state.copyWith(macros: currentMacros);
    notifyListeners();
    
    if (updatedMacro.active) {
      for (int relayIdx in updatedMacro.relays) {
        await sendCommand('relay_set', {'index': relayIdx, 'state': true});
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (updatedMacro.wakePc) {
        await sendCommand('pc_cmd', {'action': 'wake'});
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (updatedMacro.acOn) {
        await sendCommand('ac_cmd', {'cmd': 'power_on'});
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } else {
      for (int relayIdx in updatedMacro.relays) {
        await sendCommand('relay_set', {'index': relayIdx, 'state': false});
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (updatedMacro.wakePc) {
        await sendCommand('pc_cmd', {'action': 'shutdown'});
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (updatedMacro.acOn) {
        await sendCommand('ac_cmd', {'cmd': 'power_off'});
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  List<Map<String, dynamic>> getRealtimeDataForHour(int hour) {
    final dateString = DateTime.now().toIso8601String().split('T')[0];
    return dailyRealtimeBuffer.where((point) {
      final dt = DateTime.parse(point['t']);
      return dt.hour == hour && dt.toIso8601String().split('T')[0] == dateString;
    }).toList();
  }

  List<double> getHourlyBaseline() {
    return state.hourly.map((e) => e ?? 0.0).toList();
  }

  @override
  void dispose() {
    for (var t in _commandTimers) {
      t.cancel();
    }
    _commandTimers.clear();
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    super.dispose();
  }
}
