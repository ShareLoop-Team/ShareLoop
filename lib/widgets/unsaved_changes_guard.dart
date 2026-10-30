import 'package:flutter/material.dart';

import 'confirm_dialog.dart';

/// Wraps a pushed form page: while [hasChanges], system back (and
/// `maybePop`) asks before discarding the input instead of leaving at once.
/// An explicit `Navigator.pop` after saving is never blocked.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
  });

  final bool hasChanges;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmDiscardChanges(context)) navigator.pop();
      },
      child: child,
    );
  }
}
