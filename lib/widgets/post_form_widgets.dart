import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shared look for the Give an Item and Request an Item forms.

/// White rounded field with a light outline, green when focused.
InputDecoration postInputDecoration({String? hint, String? helper}) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    helperText: helper,
    helperStyle: const TextStyle(color: AppColors.textSecondary),
    helperMaxLines: 2,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.brightGreen, width: 1.5),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, width: 1.5),
  );
}

/// Round back button beside the form's title and subtitle. The button pops
/// the route unless [onBack] is given (e.g. when shown as a tab).
class PostFormHeader extends StatelessWidget {
  const PostFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.softMint),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.ink,
            ),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bold field label, with an optional muted [suffix] (e.g. "(optional)")
/// and a right-aligned [trailing] note (e.g. a "1/3" counter).
class PostFieldLabel extends StatelessWidget {
  const PostFieldLabel(this.text, {super.key, this.suffix, this.trailing});

  final String text;
  final String? suffix;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Dropdown styled like [postInputDecoration] fields, with a muted hint
/// until something is chosen.
class PostDropdownField extends StatelessWidget {
  const PostDropdownField({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.validator,
    this.menuMaxHeight,
  });

  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;
  final double? menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary)),
      decoration: postInputDecoration(),
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      menuMaxHeight: menuMaxHeight,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textSecondary,
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// White bar pinned to the bottom holding the full-width submit button.
class PostSubmitBar extends StatelessWidget {
  const PostSubmitBar({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              foregroundColor: AppColors.white,
              disabledBackgroundColor:
                  AppColors.deepGreen.withValues(alpha: 0.6),
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
