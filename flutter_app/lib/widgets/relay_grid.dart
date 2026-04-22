import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/app_state_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RelayGrid extends StatefulWidget {
  const RelayGrid({super.key});

  @override
  State<RelayGrid> createState() => _RelayGridState();
}

class _RelayGridState extends State<RelayGrid> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every second to update countdowns
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
    final relays = context.select<FirebaseService, List<RelayInfo>>((s) => s.state.relays);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("RELAY CONTROLS", style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                onPressed: () => _showGlobalTimerSettings(context, relays),
                icon: const FaIcon(FontAwesomeIcons.clock, size: 18, color: Color(0xFFF59E0B)),
                tooltip: "Set timers for multiple relays",
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85, 
          ),
          itemCount: relays.length > 6 ? 6 : relays.length,
          itemBuilder: (context, index) {
            final relay = relays[index];
            final isActive = relay.state;
            return GestureDetector(
              onLongPress: () => _showRelayRename(context, index, relay),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF064E3B).withValues(alpha: 0.1) : const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF374151),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showRelayRename(context, index, relay),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    relay.name.isEmpty ? 'RELAY ${index + 1}' : relay.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 10,
                                  color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFF6B7280).withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (relay.start != 0 || relay.stop != 0)
                          const FaIcon(FontAwesomeIcons.clock, size: 12, color: Color(0xFFF59E0B)),
                      ],
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (val) {
                        context.read<FirebaseService>().sendCommand('relay_set', {'index': index, 'state': val});
                      },
                      activeThumbColor: const Color(0xFF10B981),
                      activeTrackColor: const Color(0xFF064E3B),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFF374151),
                    ),
                    Text(
                      isActive ? 'ACTIVE' : 'STANDBY',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFF4B5563),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (relay.start != 0 || relay.stop != 0)
                      Text(
                        _formatTimer(relay),
                        style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTimer(RelayInfo relay) {
    String text = "";
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (relay.start != 0) {
      final diff = relay.start - nowTs;
      if (diff > 0) {
        final h = diff ~/ 3600;
        final m = (diff % 3600) ~/ 60;
        final s = diff % 60;
        text += "ON: ${h}h ${m}m ${s}s";
      }
    }
    if (relay.stop != 0) {
      final diff = relay.stop - nowTs;
      if (diff > 0) {
        if (text.isNotEmpty) text += " | ";
        final h = diff ~/ 3600;
        final m = (diff % 3600) ~/ 60;
        final s = diff % 60;
        text += "OFF: ${h}h ${m}m ${s}s";
      }
    }
    return text;
  }

  void _showRelayRename(BuildContext context, int index, RelayInfo relay) {
    final nameController = TextEditingController(text: relay.name.isEmpty ? 'Relay ${index + 1}' : relay.name);
    
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text('Rename Relay ${index + 1}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: Color(0xFF6B7280)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF374151))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FirebaseService>().sendCommand('relay_rename', {
                'index': index,
                'name': nameController.text,
              });
              Navigator.pop(innerContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGlobalTimerSettings(BuildContext context, List<RelayInfo> relays) {
    showDialog(
      context: context,
      builder: (innerContext) => _GlobalRelayTimerDialog(relays: relays),
    );
  }
}

class _GlobalRelayTimerDialog extends StatefulWidget {
  final List<RelayInfo> relays;
  const _GlobalRelayTimerDialog({required this.relays});

  @override
  State<_GlobalRelayTimerDialog> createState() => _GlobalRelayTimerDialogState();
}

class _GlobalRelayTimerDialogState extends State<_GlobalRelayTimerDialog> {
  final Set<int> _selectedRelays = {};
  bool _enableOn = false;
  bool _enableOff = false;
  double _onHours = 1.0;
  double _offHours = 1.0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.relays.length; i++) {
      if (widget.relays[i].start != 0 || widget.relays[i].stop != 0) {
        _selectedRelays.add(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      title: const Text('Relay Timer Settings', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose relays to affect:", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.relays.length, (i) {
                final isSel = _selectedRelays.contains(i);
                final name = widget.relays[i].name.isEmpty ? "R${i+1}" : widget.relays[i].name;
                return GestureDetector(
                  onTap: () => setState(() => isSel ? _selectedRelays.remove(i) : _selectedRelays.add(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.transparent,
                      border: Border.all(color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF374151)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(name.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF374151)),
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
                min: 0.1, max: 12, divisions: 119,
                label: "${_onHours.toStringAsFixed(1)}h",
                onChanged: (v) => setState(() => _onHours = v),
              ),
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
                min: 0.1, max: 12, divisions: 119,
                label: "${_offHours.toStringAsFixed(1)}h",
                onChanged: (v) => setState(() => _offHours = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            for (int idx in _selectedRelays) {
              context.read<FirebaseService>().sendCommand('relay_timer', {'index': idx, 'start': 0, 'stop': 0});
            }
            Navigator.pop(context);
          },
          child: const Text('Clear All', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: _selectedRelays.isEmpty ? null : () {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            int startTs = 0;
            int stopTs = 0;
            if (_enableOn) startTs = now + (_onHours * 3600).toInt();
            if (_enableOff) stopTs = now + (_offHours * 3600).toInt();

            for (int idx in _selectedRelays) {
              context.read<FirebaseService>().sendCommand('relay_timer', {
                'index': idx,
                'start': startTs,
                'stop': stopTs,
              });
            }
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
