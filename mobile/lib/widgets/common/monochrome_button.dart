import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum MonochromeButtonVariant { primary, secondary, outlined }

// Modern modular button with high-contrast monochrome design
class MonochromeButton extends StatelessWidget {
  const MonochromeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = MonochromeButtonVariant.primary,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final MonochromeButtonVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    switch (variant) {
      case MonochromeButtonVariant.primary:
        backgroundColor = AppColors.buttonPrimary;
        foregroundColor = AppColors.buttonText;
        borderSide = BorderSide.none;
        break;
      case MonochromeButtonVariant.secondary:
        backgroundColor = AppColors.surfaceElevated;
        foregroundColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.borderSubtle, width: 1);
        break;
      case MonochromeButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.borderStrong, width: 1);
        break;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.heading(
                      fontSize: 15,
                      weight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: foregroundColor),
                  ],
                ],
              ),
      ),
    );
  }
}
