import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> entries;
  const WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final sorted = entries.toList()
      ..sort(
        (a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp),
      );

    return Padding(
      padding: EdgeInsets.all(context.dimensions.values.s16),
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.blueAccent,
              belowBarData: BarAreaData(show: false),
              spots: [
                for (int i = 0; i < sorted.length; i++)
                  FlSpot(i.toDouble(), (sorted[i]['weight'] as num).toDouble()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
