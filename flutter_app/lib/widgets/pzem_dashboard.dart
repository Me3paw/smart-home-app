import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class PzemDashboard extends StatelessWidget {
  const PzemDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final pzem = context.select<FirebaseService, dynamic>((s) => s.state.pzem);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF374151)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT POWER',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${pzem.power.toStringAsFixed(1)}W',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 60,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: const Color(0xFF374151)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('VOLTAGE', '${pzem.voltage.toStringAsFixed(1)}V', const Color(0xFF3B82F6)),
              _buildStat('CURRENT', '${pzem.current.toStringAsFixed(2)}A', const Color(0xFFF59E0B)),
              _buildStat('ENERGY', '${pzem.energy.toStringAsFixed(2)}kWh', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('FREQ', '${pzem.frequency.toStringAsFixed(1)}Hz', const Color(0xFF9CA3AF)),
              _buildStat('PF', pzem.pf.toStringAsFixed(2), const Color(0xFF9CA3AF)),
              const SizedBox(width: 60), // Spacer to match 3-col layout
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
