import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/contender.dart';

class ContenderDetailScreen extends StatelessWidget {
  final ContenderModel contender;

  const ContenderDetailScreen({super.key, required this.contender});

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizer.contenders)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contender.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${localizer.ssn}: ${contender.ssn}'),
            Text('${localizer.phone}: ${contender.phone}'),
            Text('${localizer.email}: ${contender.email}'),
            Text('${localizer.address}: ${contender.address}'),
            Text('${localizer.caseType}: ${contender.contenderType}'),
            if (contender.birthDate != null)
              Text('${localizer.startDate}: ${contender.birthDate!.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 12),
            Text('${localizer.notes}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(contender.notes.isNotEmpty ? contender.notes : localizer.noData),
          ],
        ),
      ),
    );
  }
}
