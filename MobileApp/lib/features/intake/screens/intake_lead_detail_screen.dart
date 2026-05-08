import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_bloc.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_event.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_state.dart';
import 'package:qadaya_lawyersys/features/intake/models/intake_form.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);
const _kBg = Color(0xFFF3F6FA);

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

  Color _statusColor(String status) => switch (status) {
        'Qualified' => Colors.green,
        'Rejected' => Colors.red,
        'Converted' => Colors.purple,
        'Contacted' => Colors.orange,
        _ => _kPrimaryLight,
      };

  String _localizeStatus(String status, AppLocalizations l) => switch (status) {
        'New' => l.statusNew,
        'Contacted' => l.statusContacted,
        'Qualified' => l.statusQualified,
        'Rejected' => l.statusRejected,
        'Converted' => l.statusConverted,
        _ => status,
      };

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
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<IntakeBloc>().add(QualifyIntakeLead(
                    _lead.id,
                    isQualified: qualify,
                    notes: notesCtrl.text.trim(),
                  ),);
            },
            child: Text(
              l.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(
    AppLocalizations l,
    List<IntakeAssignmentOption> options,
  ) {
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
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.employeeId,
                        child: Text(o.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedEmployeeId = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  followUp == null
                      ? l.nextFollowUp
                      : '${l.nextFollowUp}: ${DateFormat('yyyy-MM-dd').format(followUp!)}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => followUp = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
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
              child: Text(
                l.save,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _statusColor(_lead.status);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(_lead.fullName),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<IntakeBloc, IntakeState>(
        listener: (context, state) {
          if (state is IntakeActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is IntakeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l.error}: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is IntakeLoaded) {
            final updated =
                state.leads.where((x) => x.id == _lead.id).toList();
            if (updated.isNotEmpty) setState(() => _lead = updated.first);
          }
        },
        builder: (context, state) {
          final options = state is IntakeLoaded
              ? state.assignmentOptions
              : <IntakeAssignmentOption>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(l, color),
              const SizedBox(height: 16),
              _buildInfoCard(l),
              if (_lead.conflictChecked) ...[
                const SizedBox(height: 16),
                _buildConflictCard(l),
              ],
              const SizedBox(height: 16),
              _buildActions(l, options),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l, Color color) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPrimary, _kPrimaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                _lead.fullName.isNotEmpty
                    ? _lead.fullName[0].toUpperCase()
                    : 'L',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lead.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _localizeStatus(_lead.status, AppLocalizations.of(context)!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoCard(AppLocalizations l) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l.leadSubject),
            const SizedBox(height: 8),
            Text(
              _lead.subject,
              style: const TextStyle(fontSize: 14, color: _kText, height: 1.5),
            ),
            const Divider(height: 24, color: Color(0xFFEEF2F7)),
            if (_lead.email != null) ...[
              _InfoRow(Icons.email_outlined, l.email, _lead.email!),
              const SizedBox(height: 8),
            ],
            if (_lead.phoneNumber != null) ...[
              _InfoRow(
                Icons.phone_outlined,
                l.phoneNumber,
                _lead.phoneNumber!,
              ),
              const SizedBox(height: 8),
            ],
            if (_lead.desiredCaseType != null) ...[
              _InfoRow(
                Icons.gavel_outlined,
                l.caseType,
                _lead.desiredCaseType!,
              ),
              const SizedBox(height: 8),
            ],
            if (_lead.assignedEmployeeName != null) ...[
              _InfoRow(
                Icons.assignment_ind_outlined,
                l.leadAssignedTo,
                _lead.assignedEmployeeName!,
              ),
              const SizedBox(height: 8),
            ],
            if (_lead.nextFollowUpAt != null)
              _InfoRow(
                Icons.schedule_outlined,
                l.nextFollowUp,
                DateFormat('yyyy-MM-dd').format(_lead.nextFollowUpAt!.toLocal()),
              ),
            if (_lead.description != null && _lead.description!.isNotEmpty) ...[
              const Divider(height: 24, color: Color(0xFFEEF2F7)),
              _SectionTitle(l.notes),
              const SizedBox(height: 6),
              Text(
                _lead.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kText,
                  height: 1.5,
                ),
              ),
            ],
            if (_lead.isConverted &&
                _lead.convertedCaseCode != null) ...[
              const Divider(height: 24, color: Color(0xFFEEF2F7)),
              _InfoRow(
                Icons.transform_outlined,
                l.convertedToCaseLabel,
                '#${_lead.convertedCaseCode}',
              ),
            ],
          ],
        ),
      );

  Widget _buildConflictCard(AppLocalizations l) => _Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _lead.hasConflict ? Icons.warning_amber : Icons.check_circle,
              color: _lead.hasConflict ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lead.hasConflict
                        ? l.conflictDetected
                        : l.noConflict,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _lead.hasConflict ? Colors.red : Colors.green,
                    ),
                  ),
                  if (_lead.conflictDetails != null &&
                      _lead.conflictDetails!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _lead.conflictDetails!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildActions(
    AppLocalizations l,
    List<IntakeAssignmentOption> options,
  ) =>
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(l.actions),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!_lead.conflictChecked)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(l.leadConflictCheck),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                    ),
                    onPressed: () => _runConflictCheck(l),
                  ),
                if (_lead.isNew || _lead.isRejected == false && !_lead.isQualified) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: Text(l.leadQualify),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showQualifyDialog(l, true),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.thumb_down_outlined),
                    label: Text(l.leadReject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showQualifyDialog(l, false),
                  ),
                ],
                if (_lead.isQualified && _lead.assignedEmployeeId == null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(l.leadAssign),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: options.isEmpty
                        ? null
                        : () => _showAssignDialog(l, options),
                  ),
                if (_lead.isQualified && !_lead.isConverted)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.transform),
                    label: Text(l.leadConvert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context
                        .read<IntakeBloc>()
                        .add(ConvertIntakeLead(_lead.id)),
                  ),
              ],
            ),
          ],
        ),
      );
}

// ── Reusable widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kText.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: _kPrimaryLight),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
            ),
          ),
        ],
      );
}
