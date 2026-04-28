import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Animated StatCard with contextual micro-animations.
///
/// OLD VERSION (before animation update) was a plain white card with icon,
/// value and label, plus a faint background icon. See git history.
class StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated background pattern
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _StatCardBgPainter(
                      progress: _controller.value,
                      color: widget.color,
                    ),
                  );
                },
              ),
            ),
            // Decorative Background Icon (kept from old design, now animated)
            Positioned(
              right: -10,
              bottom: -10,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final opacity =
                      0.03 + 0.02 * sin(_controller.value * 2 * pi);
                  return Opacity(opacity: opacity.clamp(0.01, 0.06), child: child);
                },
                child: Icon(
                  widget.icon,
                  size: 70,
                  color: widget.color,
                ),
              ),
            ),
            Row(
              children: [
                // Icon container with glow effect
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final glowOpacity =
                        0.1 + 0.06 * sin(_controller.value * 2 * pi);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: glowOpacity),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: glowOpacity * 0.5),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: widget.color,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardBgPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StatCardBgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle animated gradient circles in background
    for (int i = 0; i < 3; i++) {
      final adjustedProgress = (progress + i * 0.33) % 1.0;
      final centerX = size.width * (0.2 + 0.6 * ((i + 1) / 3));
      final centerY = size.height * (0.3 + 0.4 * sin(adjustedProgress * 2 * pi));
      final radius = 20.0 + 15.0 * sin(adjustedProgress * pi);
      final opacity = (0.02 + 0.02 * sin(adjustedProgress * pi)).clamp(0.0, 0.05);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StatCardBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
