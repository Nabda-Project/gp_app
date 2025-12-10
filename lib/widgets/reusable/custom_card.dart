import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CustomCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const CustomCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.white.withValues(alpha: 0.2)
                        : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isSelected ? AppColors.white : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isSelected ? AppColors.white : AppColors.darkBlue,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
