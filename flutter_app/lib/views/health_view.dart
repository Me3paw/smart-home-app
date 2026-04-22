import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class HealthView extends StatefulWidget {
  const HealthView({super.key});

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseService>().forceSync('all');
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<FirebaseService>().state.health;

    return Scaffold(
      appBar: AppBar(title: const Text('Health & Automation')),
      body: RefreshIndicator(
        onRefresh: () => context.read<FirebaseService>().refresh('health'),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                Expanded(
                  child: _buildRadialCard(
                    context,
                    'Temperature',
                    health.temp,
                    50.0,
                    '°C',
                    Icons.thermostat,
                    health.isHot ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRadialCard(
                    context,
                    'Humidity',
                    health.humid,
                    100.0,
                    '%',
                    Icons.water_drop,
                    Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto-Sleep Automation'),
                    subtitle: const Text('Auto control AC/Fans based on temperature'),
                    secondary: const Icon(Icons.auto_awesome),
                    value: health.autoSleep,
                    onChanged: (val) {
                      context.read<FirebaseService>().sendCommand('health_cmd', {'autoSleep': val});
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Edit Thresholds'),
                    subtitle: const Text('Customize trigger temperatures and humidity'),
                    leading: const Icon(Icons.settings_input_component),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThresholdDialog(context, health),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoBox(
              context,
              'Automation Logic',
              '• Temp ≥ ${health.tempHigh}°C: AC 25°C, Relay 6 ON\n'
              '• Temp ≤ ${health.tempLow}°C: AC 27°C, Relay 6 OFF\n'
              '• Humid < ${health.humidLow}%: Relay 5 ON; > ${health.humidHigh}%: Relay 5 OFF',
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showThresholdDialog(BuildContext context, dynamic health) {
    final thController = TextEditingController(text: health.tempHigh.toString());
    final tlController = TextEditingController(text: health.tempLow.toString());
    final hhController = TextEditingController(text: health.humidHigh.toString());
    final hlController = TextEditingController(text: health.humidLow.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Automation Thresholds'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField('Temp High (Cooling ON)', thController, '°C'),
              _buildField('Temp Low (Cooling OFF)', tlController, '°C'),
              const Divider(),
              _buildField('Humid High (Stop)', hhController, '%'),
              _buildField('Humid Low (Start)', hlController, '%'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<FirebaseService>().sendCommand('health_thresholds', {
                'th': double.tryParse(thController.text) ?? 28.5,
                'tl': double.tryParse(tlController.text) ?? 26.0,
                'hh': double.tryParse(hhController.text) ?? 60.0,
                'hl': double.tryParse(hlController.text) ?? 55.0,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRadialCard(BuildContext context, String title, double value, double max, String unit, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: RadialPainter(
                      progress: value / max,
                      color: color,
                      backgroundColor: color.withAlpha(30),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: color.withAlpha(180)),
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class RadialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  RadialPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 * 1.25, // Start from bottom-left
      3.14159 * 1.5,   // 270 degrees
      false,
      bgPaint,
    );

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 * 1.25,
      3.14159 * 1.5 * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
