import 'package:flutter/material.dart';

import '../core/localization/generated/app_localizations.dart';
import '../core/theme/sl_tokens.dart';

/// Asks the user to confirm a destructive action (shown in red). Resolves
/// true only when they press [actionLabel]. Takes the theme of the screen
/// that opens it (light or dark).
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: dialogContext.sl.accentText,
          ),
          child: Text(
            MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: dialogContext.sl.danger),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks before leaving a form with unsaved input. Resolves true when the
/// user chooses to discard it.
Future<bool> confirmDiscardChanges(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return confirmDestructiveAction(
    context,
    title: l10n.discardTitle,
    message: l10n.discardMessage,
    actionLabel: l10n.discardAction,
  );
}
