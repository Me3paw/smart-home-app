# Project Architecture: Platform Transfer

## 1. Overview
- ESP32-S3: Hardware controller/aggregator.
- Firebase: Primary sync/API.
- Flutter: Mobile monitor/control.
- PC (Python): Local server for pricing/shutdown.

## 2. ESP32 Modules
- Core: WiFi, NTP, Scheduler.
- FirebaseHandler: Sync logic.
- PZEMManager: Power polling (Serial1).
- ClimateController: Daikin IR/timers.
- RelayController: 6-ch GPIO/NVS.
- PCController: WOL/Shutdown HTTP.
- MacroEngine: Action sequences.
- EnergyAnalytics: Logging/pricing.

## 3. Flutter UI
- Nav: Home, Climate, Power, System, Stats.
- State: Reactive MQTT/Firebase updates.
- Widgets: `PzemDashboard`, `AcControlPanel`, `RelayGrid`, `PcControlCard`, `EnergyChart`, `MacroList`.

## 4. Protocol
- Pub: `device/state/sync` (JSON snapshot).
- Sub: `device/cmd/#` (Module commands).

## 5. Persistence
- ESP32: Relays, AC presets, macros, energy logs.
- PC: `http://192.168.1.27:5000/` for pricing/shutdown.
- Status: Ping PC at `192.168.1.27`.
