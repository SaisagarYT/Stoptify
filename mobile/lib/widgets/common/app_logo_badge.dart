import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Minimalist modern geometric logo badge for Stoptify
class AppLogoBadge extends StatelessWidget {
  const AppLogoBadge({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Center(
        child: Container(
          width: size * 0.44,
          height: size * 0.44,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(size * 0.12),
          ),
          child: Center(
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
