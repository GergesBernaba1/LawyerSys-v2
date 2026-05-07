import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_bloc.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_event.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_state.dart';
import 'package:qadaya_lawyersys/features/intake/models/intake_form.dart';

class IntakeLeadDetailScreen extends StatefulWidget {

  const IntakeLeadDetailScreen({super.key, required this.lead});
  final IntakeForm lead;

  @override
  State<IntakeLeadDetailScreen> createState() =>
      _IntakeLeadDetailScreenState();
}

class _IntakeLeadDetailScreenState extends State<IntakeLeadDetailScreen> {
  late IntakeForm _lead;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
  }

  void _runConflictCheck(AppLocalizations l) {
    context.read<IntakeBloc>().add(RunIntakeConflictCheck(_lead.id));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.leadConflictCheck)));
  }

  void _showQualifyDialog(AppLocalizations l, bool qualify) {
    final notesCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(qualify ? l.leadQualify : l.leadReject),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l.qualificationNotes,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel),),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<IntakeBloc>().add(QualifyIntakeLead(
                    _lead.id,
                    isQualified: qualify,
                    notes: notesCtrl.text.trim(),
                  ),);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(AppLocalizations l,
      List<IntakeAssignmentOption> options,) {
    int? selectedEmployeeId;
    DateTime? followUp;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.leadAssign),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: l.employee),
                items: options
                    .map((o) => DropdownMenuItem(
                        value: o.employeeId, child: Text(o.name),),)
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedEmployeeId = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => followUp = picked);
                  }
                },
                child: Text(followUp == null
                    ? l.nextFollowUp
                    : '${l.nextFollowUp}: ${followUp!.year}-${followUp!.month.toString().padLeft(2, '0')}-${followUp!.day.toString().padLeft(2, '0')}',),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel),),
            ElevatedButton(
              onPressed: selectedEmployeeId == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      context.read<IntakeBloc>().add(AssignIntakeLead(
                            _lead.id,
                            assignedEmployeeId: selectedEmployeeId!,
                            nextFollowUpAt: followUp,
                          ),);
                    },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_lead.fullName)),
      body: BlocConsumer<IntakeBloc, IntakeState>(
        listener: (context, state) {
          if (state is IntakeActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is IntakeError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.error}: ${state.message}')),);
          }
          if (state is IntakeLoaded) {
            final updated =
                state.leads.where((x) => x.id == _lead.id).toList();
            if (updated.isNotEmpty) setState(() => _lead = updated.first);
          }
        },
        builder: (context, state) {
          final options = state is IntakeLoaded ? state.assignmentOptions : <IntakeAssignmentOption>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(_lead.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_lead.status,
                      style: TextStyle(
                          color: _statusColor(_lead.status),
                          fontWeight: FontWeight.bold,),),
                ),
                const SizedBox(height: 16),
                _infoRow(l.fullName, _lead.fullName),
                _infoRow(l.email, _lead.email ?? '—'),
                _infoRow(l.phoneNumber, _lead.phoneNumber ?? '—'),
                _infoRow(l.leadSubject, _lead.subject),
                if (_lead.description != null)
                  _infoRow(l.notes, _lead.description!),
                if (_lead.desiredCaseType != null)
                  _infoRow(l.caseType, _lead.desiredCaseType!),
                if (_lead.assignedEmployeeName != null)
                  _infoRow(l.leadAssignedTo, _lead.assignedEmployeeName!),
                if (_lead.nextFollowUpAt != null)
                  _infoRow(l.nextFollowUp,
                      _lead.nextFollowUpAt!.toLocal().toIso8601String().split('T').first,),
                // Conflict check result
                if (_lead.conflictChecked) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                          _lead.hasConflict
                              ? Icons.warning
                              : Icons.check_circle,
                          color: _lead.hasConflict ? Colors.red : Colors.green,),
                      const SizedBox(width: 8),
                      Text(_lead.hasConflict
                          ? l.conflictDetected
                          : l.noConflict,),
                    ],
                  ),
                  if (_lead.conflictDetails != null &&
                      _lead.conflictDetails!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_lead.conflictDetails!,
                          style: const TextStyle(color: Colors.red),),
                    ),
                ],
                const Divider(height: 32),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!_lead.conflictChecked)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.search),
                        label: Text(l.leadConflictCheck),
                        onPressed: () => _runConflictCheck(l),
                      ),
                    if (_lead.isNew || _lead.isQualified == false) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.thumb_up),
                        label: Text(l.leadQualify),
                        onPressed: () => _showQualifyDialog(l, true),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.thumb_down),
                        label: Text(l.leadReject),
                        onPressed: () => _showQualifyDialog(l, false),
                      ),
                    ],
                    if (_lead.isQualified && _lead.assignedEmployeeId == null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: Text(l.leadAssign),
                        onPressed: options.isEmpty
                            ? null
                            : () => _showAssignDialog(l, options),
                      ),
                    if (_lead.isQualified && !_lead.isConverted)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.transform),
                        label: Text(l.leadConvert),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,),
                        onPressed: () => context
                            .read<IntakeBloc>()
                            .add(ConvertIntakeLead(_lead.id)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Qualified':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Converted':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w600),),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
