import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.accessDenied ?? 'Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizer.accessDeniedMessage ?? 'You do not have permission to access this section.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
