/// Primary action button for assessment screens.
import 'package:flutter/material.dart';
import 'assessment_theme.dart';

class AssessmentNextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AssessmentNextButton({
    super.key,
    this.label = 'التالي',
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: enabled ? AssessmentColors.cardGradient : null,
          color: enabled ? null : AssessmentColors.unselected,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled ? AssessmentShadows.button : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.white : AssessmentColors.textMuted,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (icon == null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_back_ios_rounded,
                        color: enabled ? Colors.white : AssessmentColors.textMuted,
                        size: 16,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
