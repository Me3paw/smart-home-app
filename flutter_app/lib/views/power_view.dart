import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/relay_grid.dart';
import '../services/firebase_service.dart';

class PowerView extends StatefulWidget {
  const PowerView({super.key});

  @override
  State<PowerView> createState() => _PowerViewState();
}

class _PowerViewState extends State<PowerView> {
  @override
  void initState() {
    super.initState();
    // Request initial relay state sync when view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().forceSync('relays');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FirebaseService>().refresh('relays'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            const RelayGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relay Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Hardware GPIO Management',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildActionChip(
              onPressed: () => context.read<FirebaseService>().sendCommand('relay_all', {'state': true}),
              label: 'ALL ON',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              onPressed: () => context.read<FirebaseService>().sendCommand('relay_all', {'state': false}),
              label: 'ALL OFF',
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({required VoidCallback onPressed, required String label, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
