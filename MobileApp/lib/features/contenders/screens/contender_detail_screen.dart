import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/contender.dart';

class ContenderDetailScreen extends StatelessWidget {
  final ContenderModel contender;

  const ContenderDetailScreen({super.key, required this.contender});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizer.contender ?? 'Contender')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contender.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${localizer.ssn ?? 'SSN'}: ${contender.ssn}'),
            Text('${localizer.phone ?? 'Phone'}: ${contender.phone}'),
            Text('${localizer.email ?? 'Email'}: ${contender.email}'),
            Text('${localizer.address ?? 'Address'}: ${contender.address}'),
            Text('${localizer.contenderType ?? 'Type'}: ${contender.contenderType}'),
            const SizedBox(height: 12),
            Text('${localizer.notes ?? 'Notes'}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(contender.notes.isNotEmpty ? contender.notes : localizer.noData ?? 'No notes'),
          ],
        ),
      ),
    );
  }
}
