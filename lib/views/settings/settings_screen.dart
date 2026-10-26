import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/language_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';

/// View: language switch between Sinhala, Tamil, and English.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = context.watch<LanguageController>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.language,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          RadioGroup<String>(
            groupValue: languageController.locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                context.read<LanguageController>().setLanguage(value);
              }
            },
            child: Column(
              children: AppConstants.languageNames.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
