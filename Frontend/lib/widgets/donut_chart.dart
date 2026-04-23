import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_theme.dart';

class DonutChart extends StatelessWidget {
  final Map<String, int> data;
  final double size;

  const DonutChart({super.key, required this.data, this.size = 180});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No data yet', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final total = data.values.fold(0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: total == 0 
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: size * 0.32),
                ),
              )
            : PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.28,
              sections: entries.asMap().entries.map((e) {
                final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
                final pct = (e.value.value / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: e.value.value.toDouble(),
                  color: color,
                  title: '$pct%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  radius: size * 0.32,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((e) {
              final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
              final h = e.value.value ~/ 60;
              final m = e.value.value % 60;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                    Text(h > 0 ? '${h}h ${m}m' : '${m}m', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class WeekBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;

  const WeekBarChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  return Text(days[value.toInt() % 7],
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
                },
              ),
            ),
          ),
          barGroups: dailyData.asMap().entries.map((e) {
            final minutes = (e.value['totalMinutes'] ?? 0) as int;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: minutes.toDouble(),
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
