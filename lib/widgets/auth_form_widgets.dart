import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shared look for the login and register screens.

/// White pill-shaped field with no outline, green outline when focused.
InputDecoration authInputDecoration(String hint, {Widget? suffixIcon}) {
  OutlineInputBorder border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: width),
      );
  final noBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.ink),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    suffixIcon: suffixIcon == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: suffixIcon,
          ),
    border: noBorder,
    enabledBorder: noBorder,
    focusedBorder: border(AppColors.brightGreen),
    errorBorder: border(AppColors.error, width: 1),
    focusedErrorBorder: border(AppColors.error),
  );
}

/// Eye icon that shows or hides a password field.
class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    super.key,
    required this.obscured,
    required this.onPressed,
    required this.showTooltip,
    required this.hideTooltip,
  });

  final bool obscured;
  final VoidCallback onPressed;
  final String showTooltip;
  final String hideTooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? showTooltip : hideTooltip,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Two overlapping soft-mint circles in the top-left corner.
class AuthCornerCircles extends StatelessWidget {
  const AuthCornerCircles({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.softMint.withValues(alpha: 0.6);
    return IgnorePointer(
      child: SizedBox(
        width: 200,
        height: 185,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: -88,
              child: _Circle(diameter: 200, color: color),
            ),
            Positioned(
              left: -100,
              top: -15,
              child: _Circle(diameter: 200, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Full-width bright-green primary button with a loading spinner.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brightGreen,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.brightGreen.withValues(alpha: 0.6),
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// "Question? Action" line at the bottom of the auth screens.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: textTheme.bodyLarge),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brightGreen,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            textStyle: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
