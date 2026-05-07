import 'package:flutter/material.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizer.login)),
      body: Center(child: Text(localizer.languageSelectionScreen)),
    );
  }
}
