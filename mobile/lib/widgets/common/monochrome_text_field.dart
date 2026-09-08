import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// Modern modular input field with monochrome styling
class MonochromeTextField extends StatefulWidget {
  const MonochromeTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<MonochromeTextField> createState() => _MonochromeTextFieldState();
}

class _MonochromeTextFieldState extends State<MonochromeTextField> {
  bool _obscured = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.body(
            fontSize: 13,
            weight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? AppColors.errorRed
                    : (_isFocused ? AppColors.borderFocus : AppColors.borderSubtle),
                width: _isFocused || hasError ? 1.5 : 1.0,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword ? _obscured : false,
              keyboardType: widget.keyboardType,
              style: AppTypography.body(fontSize: 15, color: AppColors.textPrimary),
              onChanged: widget.onChanged,
              validator: widget.validator,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hint,
                hintStyle: AppTypography.body(fontSize: 14, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused ? AppColors.textPrimary : AppColors.textSecondary,
                      )
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.errorRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.body(fontSize: 12, color: AppColors.errorRed),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
