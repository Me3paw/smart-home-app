import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../widgets/pzem_dashboard.dart';
import '../widgets/macro_list.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Start PZEM stream when home view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().sendCommand('start_stream', {});
      // Also do a one-time sync for immediate data
      context.read<FirebaseService>().forceSync('pzem');
    });
  }

  @override
  void dispose() {
    // Stop PZEM stream when home view is closed
    // Use a reference to FirebaseService because context might be invalid in dispose
    // But since we are in a Navigator tab, dispose might not be called immediately.
    // However, the user might switch tabs. 
    // For Navigator 2.0 or simple tabs, we might need a different approach.
    // For now, let's stick to simple dispose or deactivate.
    super.dispose();
  }

  @override
  void deactivate() {
    context.read<FirebaseService>().sendCommand('stop_stream', {});
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FirebaseService>().refresh('pzem'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const PzemDashboard(),
            const SizedBox(height: 32),
            const MacroList(),
            const SizedBox(height: 100), // Extra space for Bottom Nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'test dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildConnectionIndicator(),
          ],
        ),
        const Text(
          'Real-time Monitoring',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator() {
    return Consumer<FirebaseService>(
      builder: (context, firebase, _) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: firebase.isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
