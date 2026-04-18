import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/contender.dart';

class ContenderDetailScreen extends StatelessWidget {
  final ContenderModel contender;

  const ContenderDetailScreen({super.key, required this.contender});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(contender.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                contender.contenderType,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _infoRow(l.fullName, contender.fullName),
            _infoRow(l.ssn, contender.ssn.isNotEmpty ? contender.ssn : '—'),
            _infoRow(l.phone, contender.phone.isNotEmpty ? contender.phone : '—'),
            _infoRow(l.email, contender.email.isNotEmpty ? contender.email : '—'),
            _infoRow(l.address, contender.address.isNotEmpty ? contender.address : '—'),
            _infoRow(l.caseType, contender.contenderType),
            if (contender.birthDate != null)
              _infoRow(
                l.dateOfBirth,
                contender.birthDate!.toLocal().toIso8601String().split('T').first,
              ),
            if (contender.notes.isNotEmpty) ...[
              const Divider(height: 32),
              Text(l.notes,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text(contender.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
