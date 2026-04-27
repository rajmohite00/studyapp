import 'package:flutter/material.dart';
import '../app_theme.dart';

class HeatmapWidget extends StatelessWidget {
  final List<dynamic> data;
  const HeatmapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Determine the past 30 days of data, pad with empty days if needed
    final past30 = data.length > 30 ? data.sublist(data.length - 30) : data;
    final displayData = List.generate(30, (i) {
      if (i < past30.length) return past30[i];
      return null;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Last 30 Days', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                const Text('Less', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                _ColorBox(AppColors.primary.withValues(alpha: 0.1)),
                _ColorBox(AppColors.primary.withValues(alpha: 0.4)),
                _ColorBox(AppColors.primary.withValues(alpha: 0.7)),
                const _ColorBox(AppColors.primary),
                const SizedBox(width: 4),
                const Text('More', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final entry = displayData[index];
              final intensity = entry != null ? entry.intensity : 0; 
              
              return Container(
                decoration: BoxDecoration(
                  color: intensity == 0 
                      ? AppColors.divider 
                      : AppColors.primary.withValues(alpha: (intensity / 4).clamp(0.2, 1.0)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  const _ColorBox(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}
