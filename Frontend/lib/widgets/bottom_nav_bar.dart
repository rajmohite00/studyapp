import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Kept for backwards compat — home_screen uses its own _PremiumBottomNav.
/// Any screen still importing BottomNavBar directly gets this clean version.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined,          Icons.home_rounded,           'Home'),
    (Icons.calendar_today_outlined,Icons.calendar_today_rounded, 'Planner'),
    (Icons.auto_awesome_outlined,  Icons.auto_awesome_rounded,   'AI'),
    (Icons.quiz_outlined,          Icons.quiz_rounded,           'Tests'),
    (Icons.person_outline_rounded, Icons.person_rounded,         'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                          horizontal: sel ? 14 : 6, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(sel ? _items[i].$2 : _items[i].$1,
                          size: 22,
                          color: sel ? AppColors.primary : AppColors.textLight),
                    ),
                    const SizedBox(height: 2),
                    Text(_items[i].$3,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? AppColors.primary : AppColors.textLight)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
