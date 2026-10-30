import 'package:flutter/material.dart';

import '../core/theme/sl_tokens.dart';

/// Mint box with a small icon, for reassuring notes such as how contact
/// details are kept private.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline,
    this.boldPrefix,
  });

  final String text;
  final IconData icon;

  /// Shown in bold before [text], e.g. "Tip:".
  final String? boldPrefix;

  @override
  Widget build(BuildContext context) {
    final sl = context.sl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sl.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sl.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: sl.accentText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (boldPrefix != null)
                    TextSpan(
                      text: '$boldPrefix ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: text),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: sl.ink, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
