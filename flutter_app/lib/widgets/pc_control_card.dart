import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/firebase_service.dart';
import '../models/app_state_model.dart';

class PcControlCard extends StatefulWidget {
  const PcControlCard({super.key});

  @override
  State<PcControlCard> createState() => _PcControlCardState();
}

class _PcControlCardState extends State<PcControlCard> {
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
    final pc = context.select<FirebaseService, PCInfo>((s) => s.state.pc);
    final pcOnline = pc.online;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32), // Spacer to center icon
              _buildStatusIcon(pcOnline),
              IconButton(
                onPressed: () => _showPcTimerSettings(context, pc),
                icon: FaIcon(
                  FontAwesomeIcons.clock,
                  color: (pc.start != 0 || pc.stop != 0) ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Master PC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'PC_MAC_PLACEHOLDER',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
            ),
          ),
          if (pc.start != 0 || pc.stop != 0)
             Padding(
               padding: const EdgeInsets.only(top: 16),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 14),
                     const SizedBox(width: 8),
                     Text(
                        _formatTimer(pc),
                        style: const TextStyle(
                          color: Color(0xFFF59E0B), 
                          fontSize: 11, 
                          fontWeight: FontWeight.w900, 
                          fontFamily: 'monospace'
                        ),
                      ),
                   ],
                 ),
               ),
             ),
          const SizedBox(height: 40),
          _buildControlButton(
            onPressed: () => context.read<FirebaseService>().sendCommand('pc_cmd', {'action': 'wake'}),
            label: 'WAKE ON LAN',
            icon: FontAwesomeIcons.bolt,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            onPressed: () => context.read<FirebaseService>().sendCommand('pc_cmd', {'action': 'shutdown'}),
            label: 'SHUTDOWN',
            icon: FontAwesomeIcons.powerOff,
            color: const Color(0xFF111827).withValues(alpha: 0.5),
            textColor: const Color(0xFFEF4444),
            borderColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  String _formatTimer(PCInfo pc) {
    String text = "TIMER: ";
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (pc.start != 0) {
      final diff = pc.start - nowTs;
      if (diff > 0) {
        final h = diff ~/ 3600;
        final m = (diff % 3600) ~/ 60;
        final s = diff % 60;
        text += "ON: ${h}h ${m}m ${s}s";
      }
    }
    if (pc.stop != 0) {
      final diff = pc.stop - nowTs;
      if (diff > 0) {
        if (pc.start != 0) text += " | ";
        final h = diff ~/ 3600;
        final m = (diff % 3600) ~/ 60;
        final s = diff % 60;
        text += "OFF: ${h}h ${m}m ${s}s";
      }
    }
    return text;
  }

  void _showPcTimerSettings(BuildContext context, PCInfo pc) {
    showDialog(
      context: context,
      builder: (innerContext) => _PcTimerDialog(pc: pc),
    );
  }

  Widget _buildStatusIcon(bool online) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: online ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFF7F1D1D).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: online ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.1),
              width: 4,
            ),
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.desktop,
              size: 50,
              color: online ? const Color(0xFF3B82F6) : const Color(0xFF4B5563),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: online ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              online ? 'ONLINE' : 'OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required String label,
    required dynamic icon,
    required Color color,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderColor != null ? BorderSide(color: borderColor, width: 2) : BorderSide.none,
          ),
          elevation: color == const Color(0xFF3B82F6) ? 8 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _PcTimerDialog extends StatefulWidget {
  final PCInfo pc;
  const _PcTimerDialog({required this.pc});

  @override
  State<_PcTimerDialog> createState() => _PcTimerDialogState();
}

class _PcTimerDialogState extends State<_PcTimerDialog> {
  bool _enableOn = false;
  bool _enableOff = false;
  double _onHours = 1.0;
  double _offHours = 1.0;

  @override
  void initState() {
    super.initState();
    _enableOn = widget.pc.start != 0;
    _enableOff = widget.pc.stop != 0;
    if (_enableOn) {
       final diff = widget.pc.start - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
       _onHours = (diff / 3600).clamp(0.1, 12.0);
    }
    if (_enableOff) {
       final diff = widget.pc.stop - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
       _offHours = (diff / 3600).clamp(0.1, 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      title: const Text('PC Timer Settings', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text("Turn ON after", style: TextStyle(color: Colors.white, fontSize: 14)),
            value: _enableOn,
            onChanged: (v) => setState(() => _enableOn = v ?? false),
            activeColor: const Color(0xFF3B82F6),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableOn)
            Slider(
              value: _onHours,
              min: 0.1,
              max: 12,
              divisions: 119,
              label: "${_onHours.toStringAsFixed(1)}h",
              onChanged: (v) => setState(() => _onHours = v),
            ),
          const Divider(color: Color(0xFF374151)),
          CheckboxListTile(
            title: const Text("Turn OFF after", style: TextStyle(color: Colors.white, fontSize: 14)),
            value: _enableOff,
            onChanged: (v) => setState(() => _enableOff = v ?? false),
            activeColor: const Color(0xFFEF4444),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableOff)
            Slider(
              value: _offHours,
              min: 0.1,
              max: 12,
              divisions: 119,
              label: "${_offHours.toStringAsFixed(1)}h",
              onChanged: (v) => setState(() => _offHours = v),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.pc.start != 0 || widget.pc.stop != 0)
          TextButton(
            onPressed: () {
              context.read<FirebaseService>().sendCommand('pc_timer', {'start': 0, 'stop': 0});
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int startTs = 0;
            int stopTs = 0;
            if (_enableOn) startTs = now + (_onHours * 3600).toInt();
            if (_enableOff) stopTs = now + (_offHours * 3600).toInt();

            context.read<FirebaseService>().sendCommand('pc_timer', {
              'start': startTs,
              'stop': stopTs,
            });
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
