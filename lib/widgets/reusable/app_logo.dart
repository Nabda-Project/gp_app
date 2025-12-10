import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 150.0});

  @override
  Widget build(BuildContext context) {
    // Using an Icon as a placeholder if asset is not available,
    // wrapped in a Container to verify size.
    // In production, use Image.asset(AppAssets.logo, width: size, height: size);

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
      child: Center(
        child: Icon(
          Icons.local_hospital_rounded, // Medical cross icon
          size: size * 0.6,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
