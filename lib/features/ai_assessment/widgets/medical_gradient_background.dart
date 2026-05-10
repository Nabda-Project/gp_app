/// Reusable gradient background for assessment screens.
import 'package:flutter/material.dart';
import 'assessment_theme.dart';

class MedicalGradientBackground extends StatelessWidget {
  final Widget child;
  final bool showDecorations;

  const MedicalGradientBackground({
    super.key,
    required this.child,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0F5FF),
            Color(0xFFF8FAFF),
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (showDecorations) ...[
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AssessmentColors.primary.withOpacity(0.06),
                      AssessmentColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AssessmentColors.accent.withOpacity(0.04),
                      AssessmentColors.accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}
