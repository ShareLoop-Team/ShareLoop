import 'package:flutter/material.dart';

import '../core/theme/sl_tokens.dart';
import 'sl/sl_button.dart';
import 'sl/sl_input.dart';

/// Shared look for the Give an Item and Request an Item forms. Fields use
/// [slInputDecoration] and [SLFieldLabel] from `sl/sl_input.dart`.

/// Back button above the form's title and subtitle. The button pops the
/// route unless [onBack] is given (e.g. when shown as a tab).
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
    final sl = context.sl;
    final type = context.slType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: sl.surface,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 22, color: sl.ink),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(height: SLSpace.l),
        Semantics(
          header: true,
          child: Text(title, style: type.title),
        ),
        const SizedBox(height: SLSpace.xs),
        Text(subtitle, style: type.body.copyWith(color: sl.inkMuted)),
      ],
    );
  }
}

/// Dropdown styled like [slInputDecoration] fields, with a muted hint
/// until something is chosen. [labelOf] gives each stored option its shown
/// name (e.g. a translated category); the value stays the stored one.
class PostDropdownField extends StatelessWidget {
  const PostDropdownField({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.labelOf,
    this.validator,
    this.menuMaxHeight,
  });

  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String Function(String option)? labelOf;
  final FormFieldValidator<String>? validator;
  final double? menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    final type = context.slType;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        overflow: TextOverflow.ellipsis,
        style: type.body.copyWith(color: sl.inkMuted),
      ),
      style: type.body,
      decoration: slInputDecoration(context),
      dropdownColor: sl.surface,
      borderRadius: BorderRadius.circular(SLRadius.control),
      menuMaxHeight: menuMaxHeight,
      icon: Icon(Icons.keyboard_arrow_down, color: sl.inkMuted),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              labelOf?.call(option) ?? option,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Bar pinned to the bottom holding the full-width submit button. The
/// surface tone sets it apart from the page, without a line.
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
    return ColoredBox(
      color: context.sl.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SLSpace.screen,
            SLSpace.m,
            SLSpace.screen,
            SLSpace.m,
          ),
          child: SLButton(
            label: label,
            icon: icon,
            expand: true,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
