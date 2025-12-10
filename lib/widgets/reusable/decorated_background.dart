import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DecoratedBackground extends StatelessWidget {
  final Widget child;
  final bool showTopCircle;
  final bool showBottomCircle;
  final Color? circleColor;

  const DecoratedBackground({
    super.key,
    required this.child,
    this.showTopCircle = true,
    this.showBottomCircle = true,
    this.circleColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color decorColor =
        circleColor ?? AppColors.primaryBlue.withValues(alpha: 0.04);

    return Stack(
      children: [
        // Background color - white with subtle decorations
        Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.white,
        ),

        // Top-right decorative circle
        if (showTopCircle)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: decorColor,
              ),
            ),
          ),

        // Bottom-left decorative circle
        if (showBottomCircle)
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: decorColor,
              ),
            ),
          ),

        // Additional small accent circle
        if (showTopCircle)
          Positioned(
            top: 150,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentTeal.withValues(alpha: 0.03),
              ),
            ),
          ),

        // Main content
        child,
      ],
    );
  }
}
