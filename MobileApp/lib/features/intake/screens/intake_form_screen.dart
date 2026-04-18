import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/intake_bloc.dart';
import '../bloc/intake_event.dart';
import '../bloc/intake_state.dart';
import '../models/intake_form.dart';

class IntakeFormScreen extends StatefulWidget {
  const IntakeFormScreen({super.key});

  @override
  State<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends State<IntakeFormScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  static const _statuses = ['New', 'Qualified', 'Rejected', 'Converted'];

  @override
  void initState() {
    super.initState();
    context.read<IntakeBloc>().add(LoadIntakeLeads());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => switch (status) {
        'Qualified' => Colors.blue,
        'Converted' => Colors.green,
        'Rejected' => Colors.grey,
        _ => Colors.orange,
      };

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : null,
    ));
  }

  void _showLeadActions(IntakeForm lead, List<IntakeAssignmentOption> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => BlocProvider.value(
        value: context.read<IntakeBloc>(),
        child: _LeadActionsSheet(lead: lead, assignmentOptions: options),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intake Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Submit Public Lead',
            onPressed: () => _showPublicForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + status filter
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search name, email, subject...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<IntakeBloc>()
                                    .add(SearchIntakeLeads(''));
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        context.read<IntakeBloc>().add(SearchIntakeLeads(v)),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedStatus,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._statuses.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    context
                        .read<IntakeBloc>()
                        .add(FilterIntakeByStatus(v));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: BlocConsumer<IntakeBloc, IntakeState>(
              listener: (context, state) {
                if (state is IntakeActionSuccess) {
                  _showSnack(state.message);
                }
                if (state is IntakeError) {
                  _showSnack(state.message, error: true);
                }
              },
              builder: (context, state) {
                if (state is IntakeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is IntakeLoaded) {
                  if (state.leads.isEmpty) {
                    return const Center(child: Text('No leads found'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<IntakeBloc>().add(RefreshIntakeLeads()),
                    child: ListView.separated(
                      itemCount: state.leads.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lead = state.leads[index];
                        return _LeadTile(
                          lead: lead,
                          statusColor: _statusColor(lead.status),
                          onTap: () =>
                              _showLeadActions(lead, state.assignmentOptions),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPublicForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => BlocProvider.value(
        value: context.read<IntakeBloc>(),
        child: const _PublicIntakeForm(),
      ),
    );
  }
}

// Lead tile

class _LeadTile extends StatelessWidget {
  final IntakeForm lead;
  final Color statusColor;
  final VoidCallback onTap;

  const _LeadTile(
      {required this.lead,
      required this.statusColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(Icons.person_outline, color: statusColor, size: 20),
      ),
      title: Text(lead.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lead.subject,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (lead.email != null || lead.phoneNumber != null)
            Text(lead.email ?? lead.phoneNumber ?? '',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Chip(
            label: Text(lead.status,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white)),
            backgroundColor: statusColor,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (lead.conflictChecked)
            Icon(
              lead.hasConflict ? Icons.warning : Icons.check_circle,
              size: 14,
              color: lead.hasConflict ? Colors.red : Colors.green,
            ),
        ],
      ),
      isThreeLine: lead.email != null || lead.phoneNumber != null,
    );
  }
}

// Lead actions bottom sheet

class _LeadActionsSheet extends StatelessWidget {
  final IntakeForm lead;
  final List<IntakeAssignmentOption> assignmentOptions;

  const _LeadActionsSheet(
      {required this.lead, required this.assignmentOptions});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<IntakeBloc>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(lead.subject,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),

            // Details
            if (lead.email != null)
              _DetailRow(icon: Icons.email, text: lead.email!),
            if (lead.phoneNumber != null)
              _DetailRow(icon: Icons.phone, text: lead.phoneNumber!),
            if (lead.desiredCaseType != null)
              _DetailRow(
                  icon: Icons.gavel, text: 'Type: ${lead.desiredCaseType}'),
            if (lead.description != null)
              _DetailRow(
                  icon: Icons.notes, text: lead.description!, maxLines: 3),
            if (lead.conflictDetails != null)
              _DetailRow(
                  icon: lead.hasConflict
                      ? Icons.warning
                      : Icons.check_circle,
                  text: lead.conflictDetails!,
                  color: lead.hasConflict ? Colors.red : Colors.green),
            if (lead.assignedEmployeeName != null)
              _DetailRow(
                  icon: Icons.assignment_ind,
                  text: 'Assigned: ${lead.assignedEmployeeName}'),
            if (lead.nextFollowUpAt != null)
              _DetailRow(
                  icon: Icons.schedule,
                  text:
                      'Follow-up: ${lead.nextFollowUpAt!.toLocal().toString().substring(0, 16)}'),
            if (lead.convertedCaseCode != null)
              _DetailRow(
                  icon: Icons.check_circle,
                  text:
                      'Converted -> Case #${lead.convertedCaseCode}, Customer #${lead.convertedCustomerId}',
                  color: Colors.green),

            const SizedBox(height: 12),

            // Actions
            if (!lead.isConverted) ...[
              // Conflict check
              OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Run Conflict Check'),
                onPressed: () {
                  bloc.add(RunIntakeConflictCheck(lead.id));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),

              // Qualify / Reject
              if (!lead.isQualified && !lead.isRejected)
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        bloc.add(QualifyIntakeLead(lead.id,
                            isQualified: true));
                        Navigator.pop(context);
                      },
                      child: const Text('Qualify'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        bloc.add(QualifyIntakeLead(lead.id,
                            isQualified: false));
                        Navigator.pop(context);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                ]),

              // Assign
              if (assignmentOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _AssignSection(
                    leadId: lead.id, options: assignmentOptions),
              ],

              // Convert (qualified + no conflict)
              if (lead.isQualified && !lead.hasConflict) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.transform),
                  label: const Text('Convert to Customer & Case'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () {
                    bloc.add(ConvertIntakeLead(lead.id,
                        caseType: lead.desiredCaseType));
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final int maxLines;

  const _DetailRow(
      {required this.icon,
      required this.text,
      this.color,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _AssignSection extends StatefulWidget {
  final int leadId;
  final List<IntakeAssignmentOption> options;

  const _AssignSection(
      {required this.leadId, required this.options});

  @override
  State<_AssignSection> createState() => _AssignSectionState();
}

class _AssignSectionState extends State<_AssignSection> {
  int? _selectedEmployeeId;
  DateTime? _followUpAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
              labelText: 'Assign to Employee', isDense: true),
          initialValue: _selectedEmployeeId,
          items: widget.options
              .map((o) => DropdownMenuItem(
                  value: o.employeeId, child: Text(o.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedEmployeeId = v),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _selectedEmployeeId == null
              ? null
              : () {
                  context.read<IntakeBloc>().add(AssignIntakeLead(
                        widget.leadId,
                        assignedEmployeeId: _selectedEmployeeId!,
                        nextFollowUpAt: _followUpAt,
                      ));
                  Navigator.pop(context);
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

// Public intake form

class _PublicIntakeForm extends StatefulWidget {
  const _PublicIntakeForm();

  @override
  State<_PublicIntakeForm> createState() => _PublicIntakeFormState();
}

class _PublicIntakeFormState extends State<_PublicIntakeForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _caseTypeCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    _caseTypeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<IntakeBloc>().add(CreatePublicIntakeLead({
      'fullName': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phoneNumber':
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'nationalId': _nationalIdCtrl.text.trim().isEmpty
          ? null
          : _nationalIdCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      'desiredCaseType': _caseTypeCtrl.text.trim().isEmpty
          ? null
          : _caseTypeCtrl.text.trim(),
    }));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Submit Intake Request',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nationalIdCtrl,
                decoration: const InputDecoration(labelText: 'National ID'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _caseTypeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Desired Case Type'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _submit, child: const Text('Submit')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}


