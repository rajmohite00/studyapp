import 'package:flutter/material.dart';
import '../app_theme.dart';

class HeatmapWidget extends StatelessWidget {
  final List<dynamic> data;
  const HeatmapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // A simplified heatmap representation since we can't use complex 3rd party heatmaps easily here
    // In a real app you'd use a package like flutter_heatmap_calendar

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
                _ColorBox(AppColors.primary.withOpacity(0.1)),
                _ColorBox(AppColors.primary.withOpacity(0.4)),
                _ColorBox(AppColors.primary.withOpacity(0.7)),
                _ColorBox(AppColors.primary),
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
            itemCount: 30, // Simplified to 30 squares
            itemBuilder: (context, index) {
              // Mocking intensities for display
              final intensity = (index * 7) % 5; 
              return Container(
                decoration: BoxDecoration(
                  color: intensity == 0 
                      ? AppColors.divider 
                      : AppColors.primary.withOpacity((intensity / 4).clamp(0.2, 1.0)),
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
