import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/court.dart';

class CourtDetailScreen extends StatelessWidget {
  final CourtModel court;

  const CourtDetailScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.court ?? 'Court')), 
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(court.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${localizer.address}: ${court.address}'),
            Text('${localizer.governorate ?? 'Governorate'}: ${court.governorate}'),
            Text('${localizer.phone ?? 'Phone'}: ${court.phone}'),
            const SizedBox(height: 16),
            Text('${localizer.notes ?? 'Notes'}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(court.notes.isNotEmpty ? court.notes : localizer.noData ?? 'No notes'),
          ],
        ),
      ),
    );
  }
}
