/// Styled card for displaying a question with its content.
import 'package:flutter/material.dart';
import 'assessment_theme.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final Widget child;
  final String? hint;
  final IconData? icon;

  const QuestionCard({
    super.key,
    required this.question,
    required this.child,
    this.hint,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AssessmentColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AssessmentShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AssessmentColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AssessmentColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AssessmentColors.textPrimary,
                      fontFamily: 'Cairo',
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AssessmentColors.textMuted,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
