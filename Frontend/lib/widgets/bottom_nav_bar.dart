import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'animations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.timer_outlined, Icons.timer_rounded, 'Study'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics'),
      (Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI Coach'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider.withOpacity(0.25), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => AnimatedNavItem(
                icon: items[i].$1,
                selectedIcon: items[i].$2,
                label: items[i].$3,
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
