import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/firebase_service.dart';
import '../models/app_state_model.dart';

class MacroConfigModal extends StatefulWidget {
  final int index;
  final MacroConfig config;

  const MacroConfigModal({super.key, required this.index, required this.config});

  @override
  State<MacroConfigModal> createState() => _MacroConfigModalState();
}

class _MacroConfigModalState extends State<MacroConfigModal> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late List<int> _selectedRelays;
  late bool _wakePc;
  late bool _acOn;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config.name);
    _selectedColor = widget.config.color;
    _selectedRelays = List.from(widget.config.relays);
    _wakePc = widget.config.wakePc;
    _acOn = widget.config.acOn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SETUP MACRO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 32),
            _buildLabel('MACRO NAME'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildLabel('DISPLAY COLOR'),
            _buildColorPicker(),
            const SizedBox(height: 24),
            _buildLabel('TARGET RELAYS'),
            _buildRelayPicker(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildCheckToggle('WAKE PC', FontAwesomeIcons.bolt, _wakePc, (v) => setState(() => _wakePc = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildCheckToggle('AC PRESET', FontAwesomeIcons.snowflake, _acOn, (v) => setState(() => _acOn = v!))),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildColorPicker() {
    final colors = ['white', 'red', 'blue', 'green', 'yellow', 'purple'];
    return Wrap(
      spacing: 12,
      children: colors.map((c) {
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getMacroColor(c),
              shape: BoxShape.circle,
              border: Border.all(color: _selectedColor == c ? Colors.white : Colors.transparent, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelayPicker() {
    final relayInfos = context.read<FirebaseService>().state.relays;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(6, (i) {
        final isSelected = _selectedRelays.contains(i);
        final relayName = relayInfos[i].name.isEmpty ? 'R${i + 1}' : relayInfos[i].name;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedRelays.remove(i);
              } else {
                _selectedRelays.add(i);
              }
            });
          },
          child: Container(
            width: 80, // Increased width for names
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : const Color(0xFF111827),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151)),
            ),
            child: Text(
              relayName.toUpperCase(), 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCheckToggle(String label, dynamic icon, bool value, Function(bool?) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : const Color(0xFF374151)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: value ? const Color(0xFF3B82F6) : const Color(0xFF6B7280), size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _save() {
    final config = MacroConfig(
      name: _nameController.text,
      color: _selectedColor,
      relays: _selectedRelays,
      wakePc: _wakePc,
      acOn: _acOn,
      active: true,
    );
    context.read<FirebaseService>().saveMacro(widget.index, config);
    Navigator.pop(context);
  }

  Color _getMacroColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return const Color(0xFFFF4D4D);
      case 'blue': return const Color(0xFF4D94FF);
      case 'green': return const Color(0xFF47D147);
      case 'yellow': return const Color(0xFFFFFF4D);
      case 'purple': return const Color(0xFFB366FF);
      default: return Colors.white;
    }
  }
}
