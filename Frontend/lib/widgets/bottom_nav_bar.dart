import 'package:flutter/material.dart';
import '../app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 22),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, size: 22),
            selectedIcon: Icon(Icons.timer_rounded, color: AppColors.primary, size: 22),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 22),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 22),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, size: 22),
            selectedIcon: Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 22),
            label: 'AI Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, size: 22),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
