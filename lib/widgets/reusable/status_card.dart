import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Animated StatusCard with a pulsing glow effect.
///
/// OLD VERSION (before animation update) was a static card with
/// a colored left border. See git history for original implementation.
class StatusCard extends StatefulWidget {
  final String title;
  final String status;
  final bool isHealthy;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    this.isHealthy = true,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.isHealthy ? const Color(0xFF00C853) : Colors.orange;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowOpacity = 0.10 + 0.08 * sin(_controller.value * 2 * pi);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: glowOpacity),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StatusBgPainter(
                      progress: _controller.value,
                      color: accentColor,
                      isHealthy: widget.isHealthy,
                    ),
                  ),
                ),
                // Colored left border
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: accentColor, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Row(
                    children: [
                      // Animated icon with glow
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1 + 0.05 * sin(_controller.value * 2 * pi)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: glowOpacity * 0.4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isHealthy
                              ? Icons.check_circle
                              : Icons.warning_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.status,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBgPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isHealthy;

  _StatusBgPainter({
    required this.progress,
    required this.color,
    required this.isHealthy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHealthy) {
      // Gentle sweeping pulse from left to right
      final sweepX = size.width * progress;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(sweepX, size.height * 0.5), radius: 60),
        );
      canvas.drawCircle(Offset(sweepX, size.height * 0.5), 60, paint);
    } else {
      // Warning: subtle pulsing rings
      final center = Offset(size.width * 0.85, size.height * 0.5);
      for (int i = 0; i < 3; i++) {
        final adjustedProgress = (progress + i * 0.33) % 1.0;
        final radius = 20.0 + 30.0 * adjustedProgress;
        final opacity = (1.0 - adjustedProgress) * 0.05;
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StatusBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
