import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/firebase_service.dart';

class AcControlPanel extends StatefulWidget {
  const AcControlPanel({super.key});

  @override
  State<AcControlPanel> createState() => _AcControlPanelState();
}

class _AcControlPanelState extends State<AcControlPanel> {
  double _timerValue = 30;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.select<FirebaseService, dynamic>((s) => s.state.ac);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          _buildStatusHeader(ac),
          const SizedBox(height: 24),
          _buildPowerSync(context, ac),
          const SizedBox(height: 16),
          _buildSavePresetButton(context, ac),
          const SizedBox(height: 32),
          _buildTempControl(context, ac),
          const SizedBox(height: 32),
          _buildModeSelection(context, ac),
          const SizedBox(height: 24),
          _buildFanSelection(context, ac),
          const SizedBox(height: 24),
          _buildSwingSpecial(context, ac),
          const SizedBox(height: 24),
          _buildSleepTimer(context, ac),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(dynamic ac) {
    final modeMap = {0: 'Auto', 2: 'Dry', 3: 'Cool', 4: 'Heat', 6: 'Fan'};
    final fanMap = {0xA: 'Auto', 0xB: 'Silent', 1: '1', 2: '2', 3: '3', 4: '4', 5: '5'};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem('MODE', modeMap[ac.mode] ?? 'UNKNOWN', const Color(0xFF3B82F6)),
          _buildStatusItem('TEMP', '${ac.temp}°C', Colors.white, large: true),
          _buildStatusItem('FAN', fanMap[ac.fan]?.toString() ?? ac.fan.toString(), const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color, {bool large = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: large ? 32 : 18,
            fontWeight: FontWeight.w900,
            fontFamily: large ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPowerSync(BuildContext context, dynamic ac) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': 'power_toggle'}),
            label: 'POWER',
            icon: FontAwesomeIcons.powerOff,
            color: ac.power ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': 'sync'}),
            label: 'SYNC',
            icon: FontAwesomeIcons.rotate,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildSavePresetButton(BuildContext context, dynamic ac) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.read<FirebaseService>().saveAcPreset(ac),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                SizedBox(width: 8),
                Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': 'ac_load_preset'}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.upload, size: 16),
                SizedBox(width: 8),
                Text('LOAD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required String label, required dynamic icon, required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTempControl(BuildContext context, dynamic ac) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRoundButton(
          onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': 'temp_down'}),
          icon: FontAwesomeIcons.minus,
        ),
        const SizedBox(width: 40),
        const Column(
          children: [
            Text('ADJUST', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
            Text('TEMP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(width: 40),
        _buildRoundButton(
          onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': 'temp_up'}),
          icon: FontAwesomeIcons.plus,
        ),
      ],
    );
  }

  Widget _buildRoundButton({required VoidCallback onPressed, required dynamic icon}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          shape: BoxShape.circle,
          border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 4)),
        ),
        child: Center(child: FaIcon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _buildModeSelection(BuildContext context, dynamic ac) {
    final modes = [
      {'label': 'AUTO', 'cmd': 'mode_auto', 'id': 0},
      {'label': 'COOL', 'cmd': 'mode_cool', 'id': 3},
      {'label': 'HEAT', 'cmd': 'mode_heat', 'id': 4},
      {'label': 'DRY', 'cmd': 'mode_dry', 'id': 2},
      {'label': 'FAN', 'cmd': 'mode_fan', 'id': 6},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OPERATION MODE', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modes.map((m) {
            final isActive = ac.mode == m['id'];
            return _buildGridButton(
              onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': m['cmd']}),
              label: m['label'] as String,
              isActive: isActive,
              activeColor: const Color(0xFF3B82F6),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFanSelection(BuildContext context, dynamic ac) {
    final fans = [
      {'label': 'AUTO', 'cmd': 'fan_auto', 'id': 0xA},
      {'label': 'SILENT', 'cmd': 'fan_silent', 'id': 0xB},
      {'label': '1', 'cmd': 'fan_1', 'id': 1},
      {'label': '2', 'cmd': 'fan_2', 'id': 2},
      {'label': '3', 'cmd': 'fan_3', 'id': 3},
      {'label': '4', 'cmd': 'fan_4', 'id': 4},
      {'label': '5', 'cmd': 'fan_5', 'id': 5},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FAN SPEED', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fans.map((f) {
            final isActive = ac.fan == f['id'];
            return _buildGridButton(
              onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': f['cmd']}),
              label: f['label'] as String,
              isActive: isActive,
              activeColor: const Color(0xFFF59E0B),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGridButton({required VoidCallback onPressed, required String label, required bool isActive, required Color activeColor}) {
    return SizedBox(
      width: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? activeColor : const Color(0xFF374151),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSwingSpecial(BuildContext context, dynamic ac) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SWING', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildToggleButton(context, 'swingv_toggle', 'VERT', ac.swingV)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToggleButton(context, 'swingh_toggle', 'HORIZ', ac.swingH)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SPECIAL', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: [
                  _buildToggleButton(context, 'powerful_toggle', 'POWERFUL', ac.powerful, small: true),
                  _buildToggleButton(context, 'econo_toggle', 'ECONO', ac.econo, small: true),
                  _buildToggleButton(context, 'quiet_toggle', 'QUIET', ac.quiet, small: true),
                  _buildToggleButton(context, 'comfort_toggle', 'COMFORT', ac.comfort, small: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context, String cmd, String label, bool isActive, {bool small = false}) {
    return ElevatedButton(
      onPressed: () => context.read<FirebaseService>().sendCommand('ac_cmd', {'cmd': cmd}),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF6366F1) : const Color(0xFF374151),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: small ? 4 : 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: TextStyle(fontSize: small ? 8 : 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSleepTimer(BuildContext context, dynamic ac) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hasTimer = ac.timer > now;
    String timerText = 'NO ACTIVE TIMER';
    
    if (hasTimer) {
      final diff = ac.timer - now;
      final h = (diff / 3600).floor();
      final m = ((diff % 3600) / 60).floor();
      final s = diff % 60;
      timerText = 'OFF IN ${h > 0 ? "$h:" : ""}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SLEEP TIMER', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.clock, color: Color(0xFF6B7280), size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      timerText,
                      style: TextStyle(
                        color: hasTimer ? const Color(0xFF10B981) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<FirebaseService>().sendCommand('ac_timer', {'target': 0}),
                    child: const Text('STOP', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _timerValue,
                      min: 1,
                      max: 120,
                      divisions: 119,
                      activeColor: const Color(0xFF3B82F6),
                      inactiveColor: const Color(0xFF374151),
                      onChanged: (val) => setState(() => _timerValue = val),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${_timerValue.round()}m',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final targetTs = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (_timerValue.round() * 60);
                      context.read<FirebaseService>().sendCommand('ac_timer', {'target': targetTs});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('START', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
