import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_bloc.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_event.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_state.dart';
import 'package:qadaya_lawyersys/features/intake/models/intake_form.dart';
import 'package:qadaya_lawyersys/features/intake/repositories/intake_repository.dart';
import 'package:qadaya_lawyersys/features/intake/screens/intake_lead_detail_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);
const _kBg = Color(0xFFF3F6FA);

class IntakeLeadsListScreen extends StatefulWidget {
  const IntakeLeadsListScreen({super.key});

  @override
  State<IntakeLeadsListScreen> createState() =>
      _IntakeLeadsListScreenState();
}

class _IntakeLeadsListScreenState extends State<IntakeLeadsListScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  Timer? _debounce;

  // Backend status values (keys) — labels resolved via l10n
  static const _statusKeys = [
    'New',
    'Contacted',
    'Qualified',
    'Rejected',
    'Converted',
  ];

  static const _statusColors = {
    'New': Color(0xFF2D6A87),
    'Contacted': Colors.orange,
    'Qualified': Colors.green,
    'Rejected': Colors.red,
    'Converted': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    context.read<IntakeBloc>().add(LoadIntakeLeads());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _localizeStatus(String status, AppLocalizations l) => switch (status) {
        'New' => l.statusNew,
        'Contacted' => l.statusContacted,
        'Qualified' => l.statusQualified,
        'Rejected' => l.statusRejected,
        'Converted' => l.statusConverted,
        _ => status,
      };

  Color _statusColor(String status) =>
      _statusColors[status] ?? _kPrimaryLight;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _applyFilter();
    });
  }

  void _applyFilter() {
    context.read<IntakeBloc>().add(LoadIntakeLeads(
          status: _statusFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),);
  }

  Future<void> _onPublicLinkTapped(AppLocalizations l) async {
    final link = await IntakeRepository(ApiClient()).getPublicIntakeLink();
    if (!mounted) return;
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.publicIntakeLinkNotAvailable)),
      );
      return;
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.intake,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: SelectableText(
                          link,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kText,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, color: _kPrimary),
                      tooltip: l.copyLink,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.linkCopied)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(l.leads),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: l.intake,
            onPressed: () => _onPublicLinkTapped(l),
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: l.filteredBy,
            onSelected: (v) {
              setState(() => _statusFilter = v);
              _applyFilter();
            },
            itemBuilder: (_) => [
              PopupMenuItem(child: Text(l.all)),
              ..._statusKeys.map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_localizeStatus(s, l)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        tooltip: l.create,
        onPressed: () async {
          final bloc = context.read<IntakeBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const _PublicLeadFormSheet(),
              ),
            ),
          );
          if (mounted) bloc.add(RefreshIntakeLeads());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: _kPrimary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l.search,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                if (_statusFilter != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _statusFilter = null);
                      _applyFilter();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _localizeStatus(_statusFilter!, l),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<IntakeBloc, IntakeState>(
              listener: (context, state) {
                if (state is IntakeActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
                if (state is IntakeError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l.error}: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is IntakeLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }
                if (state is IntakeError) {
                  return Center(
                    child: Text(
                      '${l.error}: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (state is IntakeLoaded) {
                  final leads = state.leads;
                  if (leads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 64,
                            color: _kPrimary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.noLeadsFound,
                            style: const TextStyle(color: _kTextSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () async => context
                        .read<IntakeBloc>()
                        .add(RefreshIntakeLeads()),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return _LeadTile(
                          lead: lead,
                          statusLabel: _localizeStatus(lead.status, l),
                          statusColor: _statusColor(lead.status),
                          onTap: () {
                            final bloc = context.read<IntakeBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: bloc,
                                  child: IntakeLeadDetailScreen(lead: lead),
                                ),
                              ),
                            ).then((_) {
                              if (mounted) bloc.add(RefreshIntakeLeads());
                            });
                          },
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
}

// ── Lead tile ───────────────────────────────────────────────────────────────

class _LeadTile extends StatelessWidget {
  const _LeadTile({
    required this.lead,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final IntakeForm lead;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kText.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.person_outline, color: statusColor, size: 20),
        ),
        title: Text(
          lead.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: _kText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary),
            ),
            if (lead.email != null || lead.phoneNumber != null)
              Text(
                lead.email ?? lead.phoneNumber ?? '',
                style: const TextStyle(fontSize: 11, color: _kTextSecondary),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            if (lead.conflictChecked) ...[
              const SizedBox(height: 4),
              Icon(
                lead.hasConflict ? Icons.warning_amber : Icons.check_circle,
                size: 14,
                color: lead.hasConflict ? Colors.red : Colors.green,
              ),
            ],
          ],
        ),
        isThreeLine: lead.email != null || lead.phoneNumber != null,
      ),
    );
  }
}

// ── Inline public lead form (full-screen page) ──────────────────────────────

class _PublicLeadFormSheet extends StatefulWidget {
  const _PublicLeadFormSheet();

  @override
  State<_PublicLeadFormSheet> createState() => _PublicLeadFormSheetState();
}

class _PublicLeadFormSheetState extends State<_PublicLeadFormSheet> {
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
          'email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'phoneNumber': _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
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
        }),);
    Navigator.pop(context);
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimaryLight, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(l.submitPublicLead),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              decoration: _dec('${l.fullName} *', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              decoration: _dec('${l.subject} *', Icons.subject_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: _dec(l.email, Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: _dec(l.phoneNumber, Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nationalIdCtrl,
              decoration: _dec(l.nationalId, Icons.badge_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caseTypeCtrl,
              decoration: _dec(l.desiredCaseType, Icons.gavel_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: _dec(l.description, Icons.notes_outlined),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _submit,
              child: Text(
                l.submit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
