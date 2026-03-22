import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/hearings_bloc.dart';
import '../bloc/hearings_event.dart';
import '../screens/hearing_form_screen.dart';
import '../models/hearing.dart';

class HearingDetailScreen extends StatelessWidget {
  final Hearing hearing;

  const HearingDetailScreen({super.key, required this.hearing});

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.hearingDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: localizer.edit,
            onPressed: () async {
              final updated = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (_) => HearingFormScreen(hearing: hearing)),
              );
              if (updated == true && context.mounted) {
                context.read<HearingsBloc>().add(LoadHearings());
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: localizer.delete,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(localizer.deleteHearing),
                  content: Text(localizer.deleteHearingConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(localizer.cancel)),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(localizer.delete)),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<HearingsBloc>().add(DeleteHearing(hearing.hearingId));
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizer.hearingId}: ${hearing.hearingId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('${localizer.caseNumber}: ${hearing.caseNumber}'),
            const SizedBox(height: 8),
            Text('${localizer.dateLabel}: ${_formatDateTime(hearing.hearingDate)}'),
            const SizedBox(height: 8),
            Text('${localizer.timeEntries}: ${hearing.hearingDate.toLocal().hour.toString().padLeft(2, '0')}:${hearing.hearingDate.toLocal().minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 8),
            Text('${localizer.judgeLabel}: ${hearing.judgeName}'),
            const SizedBox(height: 8),
            Text('${localizer.court}: ${hearing.courtLocation}'),
            if (hearing.notes != null && hearing.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${localizer.notes}: ${hearing.notes}'),
            ]
          ],
        ),
      ),
    );
  }
}
