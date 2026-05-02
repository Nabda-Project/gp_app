import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';

/// NABDA logo widget — displays a heartbeat pulse line inside a circle
/// instead of the old medical cross icon. The ECG line is drawn via CustomPaint
/// and can optionally animate.
class AppLogo extends StatelessWidget {
  final double size;
  final bool animate;
  final Animation<double>? animation;

  const AppLogo({
    super.key,
    this.size = 150.0,
    this.animate = false,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: animate && animation != null
            ? AnimatedBuilder(
                animation: animation!,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _HeartbeatPainter(
                      progress: animation!.value,
                      color: AppColors.primaryBlue,
                    ),
                  );
                },
              )
            : CustomPaint(
                size: Size(size, size),
                painter: _HeartbeatPainter(
                  progress: 1.0,
                  color: AppColors.primaryBlue,
                ),
              ),
      ),
    );
  }
}

/// Paints a realistic ECG / heartbeat waveform (P-QRS-T) inside the circle.
class _HeartbeatPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0  controls how much of the line is drawn
  final Color color;

  _HeartbeatPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Add a subtle glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.7; // total waveform width
    final startX = cx - w / 2;

    // Build the ECG waveform as a series of key-points (normalised 0-1 on x)
    // Values on y are centred at cy; negative = upward.
    final List<Offset> ecgPoints = _buildEcgPoints(startX, cy, w, size.height);

    // Trim the path to `progress`
    if (ecgPoints.length < 2) return;

    final totalPoints = ecgPoints.length;
    final visibleCount = (totalPoints * progress).round().clamp(2, totalPoints);

    final path = Path()..moveTo(ecgPoints[0].dx, ecgPoints[0].dy);
    for (int i = 1; i < visibleCount; i++) {
      path.lineTo(ecgPoints[i].dx, ecgPoints[i].dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  /// Generates a smooth ECG-like waveform through key waypoints.
  List<Offset> _buildEcgPoints(
      double startX, double cy, double totalW, double h) {
    final amplitude = h * 0.30; // max spike height

    // Key waypoints: (fractionX, fractionY)  where Y=-1 is full up, +1 full down
    final List<_WavePoint> waypoints = [
      _WavePoint(0.00, 0.0),  // flat start
      _WavePoint(0.15, 0.0),  // flat
      _WavePoint(0.20, 0.08), // small P wave up
      _WavePoint(0.25, 0.0),  // back to baseline
      _WavePoint(0.32, 0.0),  // flat before QRS
      _WavePoint(0.36, 0.15), // Q dip
      _WavePoint(0.42, -1.0), // R spike (big up)
      _WavePoint(0.48, 0.40), // S dip (down)
      _WavePoint(0.52, 0.0),  // back to baseline
      _WavePoint(0.58, 0.0),  // flat
      _WavePoint(0.65, -0.15),// T wave bump
      _WavePoint(0.72, 0.0),  // baseline
      _WavePoint(1.00, 0.0),  // flat end
    ];

    // Interpolate between waypoints for smooth drawing
    final List<Offset> points = [];
    const int segments = 120;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      // Find surrounding waypoints
      int idx = 0;
      for (int j = 0; j < waypoints.length - 1; j++) {
        if (t >= waypoints[j].x && t <= waypoints[j + 1].x) {
          idx = j;
          break;
        }
      }
      final wp0 = waypoints[idx];
      final wp1 = waypoints[math.min(idx + 1, waypoints.length - 1)];
      final segLen = wp1.x - wp0.x;
      final localT = segLen > 0 ? (t - wp0.x) / segLen : 0.0;
      // Smooth interpolation (cubic hermite-like)
      final smoothT = localT * localT * (3 - 2 * localT);
      final yFrac = wp0.y + (wp1.y - wp0.y) * smoothT;

      final px = startX + t * totalW;
      final py = cy - yFrac * amplitude;
      points.add(Offset(px, py));
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _WavePoint {
  final double x; // 0..1  horizontal position
  final double y; // -1..1  vertical (negative = up)
  const _WavePoint(this.x, this.y);
}
