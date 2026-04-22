import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/energy_charts.dart';
import '../services/firebase_service.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  @override
  void initState() {
    super.initState();
    // Start PZEM stream for real-time energy calculation in stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().sendCommand('start_stream', {});
      // Also do a one-time sync of historical energy data
      context.read<FirebaseService>().forceSync('energy');
    });
  }

  @override
  void deactivate() {
    // Stop stream when leaving stats page
    context.read<FirebaseService>().sendCommand('stop_stream', {});
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FirebaseService>().refresh('energy'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const EnergyCharts(),
            const SizedBox(height: 32),
            _buildManualControls(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy Usage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Real-time Consumption Analytics',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildManualControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONNECTIVITY',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Manual Sync Control',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              _buildControlButton(
                onPressed: () => context.read<FirebaseService>().sendCommand('force_day_roll', {}),
                label: 'ROLL DAY',
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                onPressed: () => context.read<FirebaseService>().sendCommand('force_month_roll', {}),
                label: 'PUSH MONTH',
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required VoidCallback onPressed, required String label, required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }
}
