import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Animated VitalCard with contextual background animations:
/// - Heart Rate → realistic ECG heartbeat wave (sharp triangular peaks)
/// - Blood Oxygen → floating bubbles
/// - Battery Level → charging wave (height proportional to battery %)
/// - Calendar/Follow-up → soft ripple
///
/// Set [subtleMode] to true for lower-opacity animations (used in doctor views).
class VitalCard extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  /// When true, background animation opacity is significantly reduced.
  final bool subtleMode;

  const VitalCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.subtleMode = false,
  });

  @override
  State<VitalCard> createState() => _VitalCardState();
}

class _VitalCardState extends State<VitalCard> with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;

  @override
  void initState() {
    super.initState();
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _secondaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  /// Master opacity multiplier — 1.0 for normal, 0.35 for subtle (doctor view).
  double get _opacityFactor => widget.subtleMode ? 0.35 : 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: widget.color.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background animation layer
          Positioned.fill(
            child: _buildBackgroundAnimation(),
          ),
          // Content layer
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingS,
              vertical: AppDimensions.paddingS,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon container
                AnimatedBuilder(
                  animation: _primaryController,
                  builder: (context, child) {
                    final scale = 1.0 + 0.08 * sin(_primaryController.value * 2 * pi);
                    return Transform.scale(
                      scale: _isHeartRate ? scale : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      if (widget.unit.isNotEmpty) const SizedBox(width: 2),
                      if (widget.unit.isNotEmpty)
                        Text(
                          widget.unit,
                          style: TextStyle(fontSize: 11, color: AppColors.grey),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isHeartRate => widget.icon == Icons.favorite;
  bool get _isOxygen => widget.icon == Icons.water_drop;
  bool get _isBattery => widget.icon == Icons.battery_charging_full;

  /// Parse battery percentage from the value string. Returns 0.0-1.0.
  double get _batteryFraction {
    final parsed = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null || parsed <= 0) return 0.15; // minimum visible wave
    return (parsed / 100.0).clamp(0.05, 1.0);
  }

  Widget _buildBackgroundAnimation() {
    if (_isHeartRate) {
      return _HeartbeatWaveAnimation(
        controller: _primaryController,
        color: widget.color,
        opacityFactor: _opacityFactor,
      );
    } else if (_isOxygen) {
      return _BubblesAnimation(
        controller: _secondaryController,
        color: widget.color,
        opacityFactor: _opacityFactor,
      );
    } else if (_isBattery) {
      return _ChargingWaveAnimation(
        controller: _secondaryController,
        color: widget.color,
        fillFraction: _batteryFraction,
        opacityFactor: _opacityFactor,
      );
    } else {
      return _SoftPulseAnimation(
        controller: _secondaryController,
        color: widget.color,
        opacityFactor: _opacityFactor,
      );
    }
  }
}

// ── Realistic ECG Heartbeat Wave ────────────────────────────────────────────
class _HeartbeatWaveAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double opacityFactor;

  const _HeartbeatWaveAnimation({
    required this.controller,
    required this.color,
    required this.opacityFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _HeartbeatPainter(
            progress: controller.value,
            color: color,
            opacityFactor: opacityFactor,
          ),
        );
      },
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacityFactor;

  _HeartbeatPainter({
    required this.progress,
    required this.color,
    required this.opacityFactor,
  });

  /// Builds a realistic PQRST ECG segment using line-to points.
  /// The [t] parameter goes from 0.0 to 1.0 across one full heartbeat cycle.
  /// Returns the Y offset relative to the baseline (negative = up).
  double _ecgY(double t, double amplitude) {
    // Flat baseline
    if (t < 0.10) return 0;
    // P-wave (small upward bump)
    if (t < 0.18) {
      final local = (t - 0.10) / 0.08; // 0→1 within P-wave
      return -amplitude * 0.12 * sin(local * pi);
    }
    // Short flat
    if (t < 0.22) return 0;
    // Q-dip (small dip down)
    if (t < 0.26) {
      final local = (t - 0.22) / 0.04;
      return amplitude * 0.10 * sin(local * pi);
    }
    // R-peak (tall sharp triangle UP) — the main spike
    if (t < 0.34) {
      final local = (t - 0.26) / 0.08;
      if (local < 0.5) {
        // Rising edge
        return -amplitude * 0.85 * (local / 0.5);
      } else {
        // Falling edge
        return -amplitude * 0.85 * (1.0 - (local - 0.5) / 0.5);
      }
    }
    // S-dip (moderate dip down)
    if (t < 0.40) {
      final local = (t - 0.34) / 0.06;
      if (local < 0.5) {
        return amplitude * 0.25 * (local / 0.5);
      } else {
        return amplitude * 0.25 * (1.0 - (local - 0.5) / 0.5);
      }
    }
    // Flat ST segment
    if (t < 0.50) return 0;
    // T-wave (broad gentle upward bump)
    if (t < 0.65) {
      final local = (t - 0.50) / 0.15;
      return -amplitude * 0.20 * sin(local * pi);
    }
    // Flat baseline until next cycle
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOpacity = 0.12 * opacityFactor;
    final paint = Paint()
      ..color = color.withValues(alpha: baseOpacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final midY = size.height * 0.55;
    final amplitude = size.height * 0.45;
    final cycleWidth = size.width * 1.2; // pixels per one full PQRST cycle
    final scrollOffset = -progress * cycleWidth;

    bool started = false;
    for (double x = 0; x < size.width; x += 1.0) {
      // Which position are we within the cycle?
      final posInCycle = ((x + scrollOffset) % cycleWidth + cycleWidth) % cycleWidth;
      final t = posInCycle / cycleWidth; // 0..1

      final y = midY + _ecgY(t, amplitude);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Second fainter trace slightly offset
    final paint2 = Paint()
      ..color = color.withValues(alpha: baseOpacity * 0.35)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path.shift(const Offset(0, 12)), paint2);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Floating Bubbles (Oxygen) ───────────────────────────────────────────────
class _BubblesAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double opacityFactor;

  const _BubblesAnimation({
    required this.controller,
    required this.color,
    required this.opacityFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _BubblesPainter(
            progress: controller.value,
            color: color,
            opacityFactor: opacityFactor,
          ),
        );
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacityFactor;

  _BubblesPainter({
    required this.progress,
    required this.color,
    required this.opacityFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bubbles = [
      _Bubble(0.15, 0.08, 0.0),
      _Bubble(0.35, 0.06, 0.2),
      _Bubble(0.55, 0.10, 0.4),
      _Bubble(0.75, 0.07, 0.6),
      _Bubble(0.90, 0.05, 0.8),
      _Bubble(0.25, 0.04, 0.3),
      _Bubble(0.65, 0.06, 0.7),
    ];

    for (final bubble in bubbles) {
      final adjustedProgress = (progress + bubble.delay) % 1.0;
      final y = size.height * (1.0 - adjustedProgress);
      final x = size.width * bubble.x + sin(adjustedProgress * 4 * pi) * 6;
      final radius = size.width * bubble.radius * (0.5 + 0.5 * sin(adjustedProgress * pi));
      final opacity = (sin(adjustedProgress * pi) * 0.12 * opacityFactor).clamp(0.0, 0.12);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Ring around bubble
      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(x, y), radius * 1.4, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Bubble {
  final double x;
  final double radius;
  final double delay;
  _Bubble(this.x, this.radius, this.delay);
}

// ── Charging Wave (Battery) — height proportional to battery % ──────────────
class _ChargingWaveAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double fillFraction;
  final double opacityFactor;

  const _ChargingWaveAnimation({
    required this.controller,
    required this.color,
    required this.fillFraction,
    required this.opacityFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ChargingWavePainter(
            progress: controller.value,
            color: color,
            fillFraction: fillFraction,
            opacityFactor: opacityFactor,
          ),
        );
      },
    );
  }
}

class _ChargingWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double fillFraction;
  final double opacityFactor;

  _ChargingWavePainter({
    required this.progress,
    required this.color,
    required this.fillFraction,
    required this.opacityFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // fillHeight is proportional to battery percentage
    final fillHeight = size.height * fillFraction;
    final waveHeight = 5.0 + 3.0 * fillFraction; // bigger wave for higher charge

    for (int i = 0; i < 2; i++) {
      final baseAlpha = (0.04 + i * 0.03) * opacityFactor;
      final paint = Paint()
        ..color = color.withValues(alpha: baseAlpha)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, size.height - fillHeight);

      for (double x = 0; x <= size.width; x += 1) {
        final y = size.height -
            fillHeight +
            sin((x / size.width * 2 * pi) + progress * 2 * pi + i * pi * 0.5) *
                waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChargingWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.fillFraction != fillFraction;
}

// ── Soft Pulse (Calendar / Generic) ─────────────────────────────────────────
class _SoftPulseAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double opacityFactor;

  const _SoftPulseAnimation({
    required this.controller,
    required this.color,
    required this.opacityFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SoftPulsePainter(
            progress: controller.value,
            color: color,
            opacityFactor: opacityFactor,
          ),
        );
      },
    );
  }
}

class _SoftPulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacityFactor;

  _SoftPulsePainter({
    required this.progress,
    required this.color,
    required this.opacityFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = size.width * 0.6;

    for (int i = 0; i < 3; i++) {
      final adjustedProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * adjustedProgress;
      final opacity = (1.0 - adjustedProgress) * 0.06 * opacityFactor;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
