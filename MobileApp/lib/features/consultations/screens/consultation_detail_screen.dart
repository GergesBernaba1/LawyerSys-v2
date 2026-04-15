import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/consultation.dart';

class ConsultationDetailScreen extends StatelessWidget {
  final ConsultationModel consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.consultationDetail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consultation.subject,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DetailRow(label: l.status, value: consultation.status),
            if (consultation.type.isNotEmpty)
              _DetailRow(
                  label: l.translate('consultationType'),
                  value: consultation.type),
            _DetailRow(
              label: l.dateLabel,
              value:
                  '${consultation.consultationDate.day}/${consultation.consultationDate.month}/${consultation.consultationDate.year}',
            ),
            if (consultation.customerFullName != null)
              _DetailRow(label: l.customer, value: consultation.customerFullName!),
            if (consultation.assignedEmployeeName != null)
              _DetailRow(
                  label: l.translate('assignedEmployee'),
                  value: consultation.assignedEmployeeName!),
            const SizedBox(height: 12),
            Text(l.description,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(consultation.details.isNotEmpty ? consultation.details : l.noData),
            if (consultation.feedback != null && consultation.feedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l.translate('consultationFeedback'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(consultation.feedback!),
            ],
            if (consultation.notes != null && consultation.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l.notes, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(consultation.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
