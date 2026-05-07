import 'package:flutter/material.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.accessDenied)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            localizer.accessDeniedMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
