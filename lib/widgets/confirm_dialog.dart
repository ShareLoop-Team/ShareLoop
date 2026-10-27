import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Asks the user to confirm a destructive action (shown in red). Resolves
/// true only when they press [actionLabel].
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Theme(
      data: AppTheme.lightTheme,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}
