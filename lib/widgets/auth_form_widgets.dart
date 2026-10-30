import 'package:flutter/material.dart';

import '../core/theme/sl_tokens.dart';

/// Shared look for the login and register screens. Fields use
/// `slInputDecoration` and `SLFieldLabel` from `sl/sl_input.dart`.

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
        color: context.sl.inkMuted,
      ),
    );
  }
}

/// The illustration at the top of the login and register screens: a
/// rounded card inset by the page margin. The whole illustration is shown,
/// never cropped, on its own background colour so its edges never show.
/// Its height follows the screen: up to [maxHeight] on tall phones, down to
/// [minHeight] on small ones, so the form starts higher where space is
/// short. [leading] sits in the card's top-start corner (e.g. a back
/// button).
class AuthHeroImage extends StatelessWidget {
  const AuthHeroImage({
    super.key,
    required this.asset,
    required this.background,
    this.maxHeight = 280,
    this.minHeight = 150,
    this.screenFraction = 0.3,
    this.leading,
  });

  final String asset;

  /// The illustration's own background colour.
  final Color background;
  final double maxHeight;
  final double minHeight;

  /// Share of the screen height the card aims for, within the limits.
  final double screenFraction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = (screenHeight * screenFraction).clamp(minHeight, maxHeight);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SLRadius.sheet),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: background),
            ExcludeSemantics(
              child: Image(image: AssetImage(asset), fit: BoxFit.contain),
            ),
            if (leading != null)
              PositionedDirectional(
                start: SLSpace.s,
                top: SLSpace.s,
                child: leading!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Round back button that sits on an [AuthHeroImage]. The illustration is
/// light in both themes, so the button stays white with dark ink.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SLColors.light.surface,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(Icons.arrow_back, size: 22, color: SLColors.light.ink),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      ),
    );
  }
}

/// "or continue with" divider above a row of Google and Facebook buttons.
/// [onPressed] runs for either one; Firebase has no social provider set up
/// yet, so the screens use it to say so.
class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.dividerLabel,
    required this.googleLabel,
    required this.facebookLabel,
    required this.onPressed,
  });

  /// Brand icons from Icons8 (https://icons8.com).
  static const String googleIcon = 'assets/images/icon_google.png';
  static const String facebookIcon = 'assets/images/icon_facebook.png';

  final String dividerLabel;

  /// The full actions ("Sign in with Google") for screen readers.
  final String googleLabel;
  final String facebookLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final line = Expanded(child: Divider(color: sl.divider, thickness: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            line,
            // Long translations wrap rather than push the lines away.
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SLSpace.m),
                child: Text(
                  dividerLabel,
                  textAlign: TextAlign.center,
                  style: context.slType.small,
                ),
              ),
            ),
            line,
          ],
        ),
        const SizedBox(height: SLSpace.l),
        Row(
          children: [
            Expanded(
              child: _SocialTile(
                asset: googleIcon,
                provider: 'Google',
                semanticsLabel: googleLabel,
                onPressed: onPressed,
              ),
            ),
            const SizedBox(width: SLSpace.m),
            Expanded(
              child: _SocialTile(
                asset: facebookIcon,
                provider: 'Facebook',
                semanticsLabel: facebookLabel,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Surface button with a provider's logo and name, in the shape of the
/// secondary [SLButton].
class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.asset,
    required this.provider,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String asset;
  final String provider;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: sl.surface,
          foregroundColor: sl.ink,
          minimumSize: const Size.fromHeight(48),
          shape: StadiumBorder(side: BorderSide(color: sl.divider)),
          padding: const EdgeInsets.symmetric(horizontal: SLSpace.m),
          textStyle: context.slType.body.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              asset,
              width: 22,
              height: 22,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: SLSpace.s),
            Flexible(child: Text(provider, overflow: TextOverflow.ellipsis)),
          ],
        ),
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
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: type.body.copyWith(color: sl.inkMuted)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: sl.accentText,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: SLSpace.s),
            textStyle: type.body.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Error from the auth service (e.g. wrong password), shown above the
/// submit button and announced to screen readers.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: sl.danger),
          const SizedBox(width: SLSpace.s),
          Expanded(
            child: Text(
              message,
              style: context.slType.small.copyWith(color: sl.danger),
            ),
          ),
        ],
      ),
    );
  }
}
