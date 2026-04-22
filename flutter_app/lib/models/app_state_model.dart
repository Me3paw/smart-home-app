class PZEMState {
  final double voltage;
  final double current;
  final double power;
  final double energy;
  final double frequency;
  final double pf;

  PZEMState({
    this.voltage = 0.0,
    this.current = 0.0,
    this.power = 0.0,
    this.energy = 0.0,
    this.frequency = 0.0,
    this.pf = 0.0,
  });

  factory PZEMState.fromJson(Map<String, dynamic> json) {
    return PZEMState(
      voltage: (json['v'] ?? 0.0).toDouble(),
      current: (json['a'] ?? 0.0).toDouble(),
      power: (json['w'] ?? 0.0).toDouble(),
      energy: (json['e'] ?? 0.0).toDouble(),
      frequency: (json['hz'] ?? 0.0).toDouble(),
      pf: (json['pf'] ?? 0.0).toDouble(),
    );
  }
}

class RelayInfo {
  final bool state;
  final String name;
  final int start;
  final int stop;

  RelayInfo({
    this.state = false,
    this.name = '',
    this.start = 0,
    this.stop = 0,
  });

  factory RelayInfo.fromJson(Map<String, dynamic> json) {
    return RelayInfo(
      state: json['state'] ?? false,
      name: json['name'] ?? '',
      start: (json['start'] ?? 0).toInt(),
      stop: (json['stop'] ?? 0).toInt(),
    );
  }
}

class PCInfo {
  final bool online;
  final int start;
  final int stop;

  PCInfo({
    this.online = false,
    this.start = 0,
    this.stop = 0,
  });

  factory PCInfo.fromJson(Map<String, dynamic> json) {
    return PCInfo(
      online: json['online'] ?? json['pc'] ?? false,
      start: (json['start'] ?? 0).toInt(),
      stop: (json['stop'] ?? 0).toInt(),
    );
  }
}

class ACState {
  final bool power;
  final int temp;
  final int mode;
  final dynamic fan; 
  final bool swingV;
  final bool swingH;
  final bool econo;
  final bool powerful;
  final bool quiet;
  final bool comfort;
  final int timer;
  final ACState? preset;

  ACState({
    this.power = false,
    this.temp = 24,
    this.mode = 3, 
    this.fan = 'Auto',
    this.swingV = false,
    this.swingH = false,
    this.econo = false,
    this.powerful = false,
    this.quiet = false,
    this.comfort = false,
    this.timer = 0,
    this.preset,
  });

  factory ACState.fromJson(Map<String, dynamic> json) {
    return ACState(
      power: json['power'] ?? false,
      temp: json['temp'] ?? 24,
      mode: json['mode'] ?? 3,
      fan: json['fan'] ?? 'Auto',
      swingV: json['swingV'] ?? false,
      swingH: json['swingH'] ?? false,
      econo: json['econo'] ?? false,
      powerful: json['powerful'] ?? false,
      quiet: json['quiet'] ?? false,
      comfort: json['comfort'] ?? false,
      timer: json['timer'] ?? 0,
      preset: json['preset'] != null ? ACState.fromJson(Map<String, dynamic>.from(json['preset'])) : null,
    );
  }
}

class MacroConfig {
  final String name;
  final String color;
  final bool active;
  final List<int> relays;
  final bool wakePc;
  final bool acOn;

  MacroConfig({
    this.name = 'Empty',
    this.color = 'white',
    this.active = false,
    this.relays = const [],
    this.wakePc = false,
    this.acOn = false,
  });

  factory MacroConfig.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final trimmedName = rawName.trim();
    return MacroConfig(
      name: trimmedName.isEmpty ? 'Empty' : trimmedName,
      color: json['color'] ?? 'white',
      active: json['active'] ?? false,
      relays: List<int>.from(json['relays'] ?? []),
      wakePc: json['wake_pc'] ?? false,
      acOn: json['ac_on'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'active': active,
      'relays': relays,
      'wake_pc': wakePc,
      'ac_on': acOn,
    };
  }

  MacroConfig copyWith({
    String? name,
    String? color,
    bool? active,
    List<int>? relays,
    bool? wakePc,
    bool? acOn,
  }) {
    return MacroConfig(
      name: name ?? this.name,
      color: color ?? this.color,
      active: active ?? this.active,
      relays: relays ?? this.relays,
      wakePc: wakePc ?? this.wakePc,
      acOn: acOn ?? this.acOn,
    );
  }
}

class HealthState {
  final double temp;
  final double humid;
  final bool autoSleep;
  final bool isHot;
  final bool isHumid;
  final int lastUpdate;
  final double tempHigh;
  final double tempLow;
  final double humidHigh;
  final double humidLow;

  HealthState({
    this.temp = 0.0,
    this.humid = 0.0,
    this.autoSleep = false,
    this.isHot = false,
    this.isHumid = false,
    this.lastUpdate = 0,
    this.tempHigh = 28.5,
    this.tempLow = 26.0,
    this.humidHigh = 60.0,
    this.humidLow = 55.0,
  });

  factory HealthState.fromJson(Map<String, dynamic> json) {
    return HealthState(
      temp: (json['temp'] ?? 0.0).toDouble(),
      humid: (json['humid'] ?? 0.0).toDouble(),
      autoSleep: json['autoSleep'] ?? false,
      isHot: json['isHot'] ?? false,
      isHumid: json['isHumid'] ?? false,
      lastUpdate: (json['lastUpdate'] ?? 0).toInt(),
      tempHigh: (json['th'] ?? 28.5).toDouble(),
      tempLow: (json['tl'] ?? 26.0).toDouble(),
      humidHigh: (json['hh'] ?? 60.0).toDouble(),
      humidLow: (json['hl'] ?? 55.0).toDouble(),
    );
  }
}

class FullAppState {
  final PZEMState pzem;
  final List<RelayInfo> relays;
  final ACState ac;
  final PCInfo pc;
  final HealthState health;
  final List<MacroConfig> macros;
  final double elecPrice;
  final List<double> tierPrices;
  final List<double?> monthly;
  final List<double?> hourly;
  final double dailyUsed;
  final bool phoneOnline;
  final bool notifyCheck;

  FullAppState({
    required this.pzem,
    required this.relays,
    required this.ac,
    required this.pc,
    required this.health,
    required this.macros,
    this.elecPrice = 3000.0,
    this.tierPrices = const [1984, 2380, 2998, 3571, 3967],
    this.monthly = const [],
    this.hourly = const [],
    this.dailyUsed = 0.0,
    this.phoneOnline = false,
    this.notifyCheck = false,
  });

  factory FullAppState.initial() {
    return FullAppState(
      pzem: PZEMState(),
      relays: List.generate(6, (_) => RelayInfo()),
      ac: ACState(),
      pc: PCInfo(),
      health: HealthState(),
      macros: List.generate(6, (_) => MacroConfig()),
      monthly: List.filled(31, 0.0),
      hourly: List.filled(24, 0.0),
      dailyUsed: 0.0,
    );
  }

  FullAppState copyWith({
    PZEMState? pzem,
    List<RelayInfo>? relays,
    ACState? ac,
    PCInfo? pc,
    HealthState? health,
    List<MacroConfig>? macros,
    double? elecPrice,
    List<double>? tierPrices,
    List<double?>? monthly,
    List<double?>? hourly,
    double? dailyUsed,
    bool? phoneOnline,
    bool? notifyCheck,
  }) {
    return FullAppState(
      pzem: pzem ?? this.pzem,
      relays: relays ?? this.relays,
      ac: ac ?? this.ac,
      pc: pc ?? this.pc,
      health: health ?? this.health,
      macros: macros ?? this.macros,
      elecPrice: elecPrice ?? this.elecPrice,
      tierPrices: tierPrices ?? this.tierPrices,
      monthly: monthly ?? this.monthly,
      hourly: hourly ?? this.hourly,
      dailyUsed: dailyUsed ?? this.dailyUsed,
      phoneOnline: phoneOnline ?? this.phoneOnline,
      notifyCheck: notifyCheck ?? this.notifyCheck,
    );
  }
}
