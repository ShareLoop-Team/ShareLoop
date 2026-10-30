import 'package:flutter/material.dart';

import '../../core/theme/sl_tokens.dart';

/// The app's text field look: a surface field with a hairline edge, a green
/// edge when focused and a red one on error. Follows the light and dark
/// themes. Pair it with an [SLFieldLabel] above the field.
InputDecoration slInputDecoration(
  BuildContext context, {
  String? hint,
  String? helper,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  final sl = context.sl;
  final type = context.slType;
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(SLRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: type.body.copyWith(color: sl.inkMuted),
    helperText: helper,
    helperStyle: type.small,
    helperMaxLines: 2,
    errorStyle: type.small.copyWith(color: sl.danger),
    errorMaxLines: 2,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 22, color: sl.inkMuted),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: sl.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: SLSpace.l,
      vertical: SLSpace.l,
    ),
    border: border(sl.divider),
    enabledBorder: border(sl.divider),
    disabledBorder: border(sl.divider),
    focusedBorder: border(sl.accentText, width: 2),
    errorBorder: border(sl.danger),
    focusedErrorBorder: border(sl.danger, width: 2),
  );
}

/// Field label, with an optional muted [suffix] (e.g. "(optional)") and a
/// right-aligned [trailing] note (e.g. a "1/3" counter).
class SLFieldLabel extends StatelessWidget {
  const SLFieldLabel(this.text, {super.key, this.suffix, this.trailing});

  final String text;
  final String? suffix;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  if (suffix != null)
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: sl.inkMuted,
                      ),
                    ),
                ],
              ),
              style: type.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) Text(trailing!, style: type.small),
        ],
      ),
    );
  }
}
