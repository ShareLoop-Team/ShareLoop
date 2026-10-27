import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';

/// Shared look for the login and register screens.

/// Underlined field that sits under an [AuthFieldLabel].
InputDecoration authInputDecoration(String hint, {Widget? suffixIcon}) {
  UnderlineInputBorder border(Color color, {double width = 1}) =>
      UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    suffixIcon: suffixIcon,
    border: border(AppColors.ink.withValues(alpha: 0.5)),
    enabledBorder: border(AppColors.ink.withValues(alpha: 0.5)),
    focusedBorder: border(AppColors.deepGreen, width: 2),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, width: 2),
  );
}

/// Small label shown above an auth field.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
    );
  }
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

/// Green header with the hand-over illustration and a curved bottom edge.
/// [leading] sits in the top-start corner (logo or back button).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.leading});

  static const String _illustrationAsset =
      'assets/images/login_illustration.svg';
  static const double _height = 240;
  static const double _curveDepth = 52;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: const _ArcClipper(depth: _curveDepth),
      child: Container(
        height: _height + topInset,
        color: AppColors.deepGreen,
        padding: EdgeInsets.only(top: topInset),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, 0.15),
              child: ExcludeSemantics(
                child: SvgPicture.asset(
                  _illustrationAsset,
                  width: 300,
                  height: 170,
                ),
              ),
            ),
            if (leading != null)
              PositionedDirectional(start: 14, top: 10, child: leading!),
          ],
        ),
      ),
    );
  }
}

/// Cuts a dome out of the bottom edge so the page rises into the header.
class _ArcClipper extends CustomClipper<Path> {
  const _ArcClipper({required this.depth});

  final double depth;

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width / 2,
        size.height - depth * 2,
        0,
        size.height,
      )
      ..close();
  }

  @override
  bool shouldReclip(_ArcClipper oldClipper) => oldClipper.depth != depth;
}

/// Round translucent back button for the [AuthHeader].
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.white.withValues(alpha: 0.2),
        foregroundColor: AppColors.white,
        fixedSize: const Size.square(56),
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
    );
  }
}

/// Screen title with the first word in brand green ("Welcome back!").
class AuthAccentTitle extends StatelessWidget {
  const AuthAccentTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    );
    final split = text.indexOf(' ');
    final accent = split < 0 ? text : text.substring(0, split);
    final rest = split < 0 ? '' : text.substring(split);
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: accent,
              style: const TextStyle(color: AppColors.deepGreen),
            ),
            TextSpan(text: rest),
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      ),
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
    this.color = AppColors.brightGreen,
    this.radius = 8,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.6),
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
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

/// Deep-green [AuthPrimaryButton] with a soft shadow, as on the auth designs.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AuthPrimaryButton(
        label: label,
        isLoading: isLoading,
        onPressed: onPressed,
        color: AppColors.deepGreen,
        radius: 14,
      ),
    );
  }
}

/// Thin line – label – thin line.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Grey full-width button with a provider logo (Google, Facebook).
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
  });

  static const String googleLogo = 'assets/images/google_logo.svg';
  static const String facebookLogo = 'assets/images/facebook_logo.svg';

  final String asset;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.mutedSurface,
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(asset, width: 22, height: 22),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
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
    this.actionColor = AppColors.deepGreen,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;
  final Color actionColor;

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
            foregroundColor: actionColor,
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
