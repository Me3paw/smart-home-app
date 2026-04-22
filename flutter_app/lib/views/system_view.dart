import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/pc_control_card.dart';
import '../services/firebase_service.dart';

class SystemView extends StatefulWidget {
  const SystemView({super.key});

  @override
  State<SystemView> createState() => _SystemViewState();
}

class _SystemViewState extends State<SystemView> {
  @override
  void initState() {
    super.initState();
    // Start stream for constant PC status updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().sendCommand('start_stream', {});
      // Also do a one-time sync for initial state
      context.read<FirebaseService>().forceSync('pc');
    });
  }

  @override
  void deactivate() {
    // Stop stream when leaving PC view
    context.read<FirebaseService>().sendCommand('stop_stream', {});
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FirebaseService>().refresh('pc'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const PcControlCard(),
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
          'PC Control',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Remote Workstation Management',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
