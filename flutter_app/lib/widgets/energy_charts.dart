import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class EnergyCharts extends StatelessWidget {
  const EnergyCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseService>();
    final monthlyData = firebase.state.monthly;
    final hourlyData = firebase.state.hourly;

    return Column(
      children: [
        _buildChartCard(
          title: "TODAY'S USAGE (HOURLY)",
          chart: _buildHourlyChart(firebase, hourlyData),
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: "MONTHLY USAGE (DAILY)",
          chart: _buildMonthlyChart(monthlyData),
          scrollable: true,
        ),
        const SizedBox(height: 24),
        _buildSummaryStats(firebase.state),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget chart, bool scrollable = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: scrollable 
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 600, child: chart),
                )
              : chart,
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(FirebaseService firebase, List<double?> data) {
    // Filter and prepare spots once, not inside the LineChart builder
    final List<FlSpot> spots = [];
    final int currentHour = DateTime.now().hour;
    final buffer = firebase.dailyRealtimeBuffer;

    for (int i = 0; i <= currentHour; i++) {
      // Manual filtering is faster than getRealtimeDataForHour call in loop
      final hourPoints = buffer.where((p) {
        final dt = DateTime.parse(p['t']);
        return dt.hour == i;
      }).toList();

      if (hourPoints.isNotEmpty) {
        for (int j = 0; j < hourPoints.length; j++) {
          double x = i + (j / hourPoints.length);
          double y = (hourPoints[j]['e'] as double) * 1000;
          spots.add(FlSpot(x, y));
        }
      } else if (i < currentHour && i < data.length && data[i] != null) {
        // Only use baseline for PAST hours, skip currentHour dip
        spots.add(FlSpot(i.toDouble(), data[i]! * 1000));
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.isEmpty ? 23 : spots.last.x,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 6,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                );
              },
              reservedSize: 45,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: const Color(0xFF3B82F6),
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<double?> data) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  (value.toInt() + 1).toString(),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i] ?? 0.0,
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                width: 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummaryStats(dynamic state) {
    // Calculate total monthly energy on-the-fly:
    // Sum all previous daily totals from 'monthly' array + current day's real-time PZEM data.
    // Note: ESP32 only writes to 'monthly' upon day rollover, so today's index is 0.0 in the array.
    final double currentDayEnergy = state.pzem.energy;
    final double previousDaysTotal = state.monthly.whereType<double>().fold(0.0, (a, b) => a + b);
    
    // Safety check: if today's entry in monthly is already populated (shouldn't happen), 
    // we use the larger of the two to avoid double-summing while staying accurate.
    final int todayIdx = DateTime.now().day - 1;
    double totalKwh = previousDaysTotal;
    if (todayIdx < state.monthly.length && (state.monthly[todayIdx] ?? 0.0) > 0) {
      // If today is already recorded, only add difference if current is higher
      if (currentDayEnergy > state.monthly[todayIdx]!) {
        totalKwh += (currentDayEnergy - state.monthly[todayIdx]!);
      }
    } else {
      totalKwh += currentDayEnergy;
    }

    double cost = _calculateTieredCost(totalKwh, state.tierPrices);

    final formatter = NumberFormat.decimalPattern('vi-VN');

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: "TOTAL MONTH (kWh)",
            value: totalKwh.toStringAsFixed(2),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: "EST. COST (VND)",
            value: formatter.format(cost.round()),
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  double _calculateTieredCost(double kwh, List<double> prices) {
    const List<int> limits = [100, 200, 400, 700];
    double total = 0;
    double remaining = kwh;
    int prevLimit = 0;

    for (int i = 0; i < limits.length; i++) {
      double tierUsage = (remaining > (limits[i] - prevLimit)) ? (limits[i] - prevLimit).toDouble() : remaining;
      if (tierUsage <= 0) break;
      total += tierUsage * prices[i];
      remaining -= tierUsage;
      prevLimit = limits[i];
    }
    if (remaining > 0) total += remaining * prices[4];
    return total * 1.10; // 10% VAT
  }
}
