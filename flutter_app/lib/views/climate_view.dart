import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/ac_control_panel.dart';
import '../services/firebase_service.dart';

class ClimateView extends StatefulWidget {
  const ClimateView({super.key});

  @override
  State<ClimateView> createState() => _ClimateViewState();
}

class _ClimateViewState extends State<ClimateView> {
  @override
  void initState() {
    super.initState();
    // Request initial AC state sync when view is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().forceSync('ac');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FirebaseService>().refresh('ac'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const AcControlPanel(),
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
          'AC Control',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Daikin IR Remote',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
