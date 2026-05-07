import 'package:flutter/material.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/courts/models/court.dart';

class CourtDetailScreen extends StatelessWidget {

  const CourtDetailScreen({super.key, required this.court});
  final CourtModel court;

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.court)), 
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(court.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${localizer.address}: ${court.address}'),
            Text('${localizer.governorate}: ${court.governorate}'),
            Text('${localizer.phone}: ${court.phone}'),
            const SizedBox(height: 16),
            Text('${localizer.notes}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(court.notes.isNotEmpty ? court.notes : localizer.noData),
          ],
        ),
      ),
    );
  }
}
