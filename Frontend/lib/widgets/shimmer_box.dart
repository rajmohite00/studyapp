import 'package:flutter/material.dart';

/// Animated shimmer skeleton — use instead of CircularProgressIndicator
/// for content placeholders so the UI feels alive while data loads.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(1.0 + 2.0 * _ctrl.value, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A full-card shimmer skeleton matching the app card style.
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(width: 100, height: 11, borderRadius: BorderRadius.circular(5)),
          const SizedBox(height: 8),
          ShimmerBox(height: 13, borderRadius: BorderRadius.circular(5)),
          const SizedBox(height: 6),
          ShimmerBox(width: 160, height: 10, borderRadius: BorderRadius.circular(5)),
        ],
      ),
    );
  }
}

/// Row of stat shimmer chips
class ShimmerStatRow extends StatelessWidget {
  const ShimmerStatRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          height: 72,
          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 18, height: 18, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 6),
              ShimmerBox(width: 40, height: 14, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 4),
              ShimmerBox(width: 30, height: 10, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ),
      )),
    );
  }
}
