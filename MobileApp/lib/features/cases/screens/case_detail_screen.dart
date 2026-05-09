import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_state.dart';
import 'package:qadaya_lawyersys/features/cases/models/case.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_conversation_screen.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_entity_relations_screen.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_form_screen.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_relations_screen.dart';

const _kPrimary = Color(0xFF14345A);

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseModel});
  final CaseModel caseModel;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _statusHistory = [];
  List<Map<String, dynamic>> _courtHistory = [];
  bool _historyLoaded = false;
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (!_historyLoaded && _tabController.index >= 1) {
      _historyLoaded = true;
      setState(() => _historyLoading = true);
      context.read<CasesBloc>()
        ..add(LoadCaseStatusHistory(widget.caseModel.caseId))
        ..add(LoadCaseCourtHistory(widget.caseModel.caseId));
    }
  }

  Future<void> _showChangeStatusDialog(AppLocalizations l, UserSession? session) async {
    if (!(session?.hasPermission(Permissions.editCases) ?? false)) return;

    final statuses = [
      (0, l.statusOpen),
      (1, l.statusInProgress),
      (2, l.statusAwaitingHearing),
      (3, l.statusClosed),
      (4, l.statusWon),
      (5, l.statusLost),
    ];

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.changeStatus),
        children: statuses.map((s) {
          final (value, label) = s;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, value),
            child: Text(label,
                style: TextStyle(
                  fontWeight: value == widget.caseModel.status ? FontWeight.bold : null,
                ),),
          );
        }).toList(),
      ),
    );

    if (selected != null && mounted) {
      context.read<CasesBloc>().add(
            ChangeCaseStatus(caseCode: widget.caseModel.caseId, status: selected),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final canEdit = session?.hasPermission(Permissions.editCases) ?? false;

    return BlocListener<CasesBloc, CasesState>(
      listener: (context, state) {
        if (state is CaseOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is CasesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is CaseStatusHistoryLoaded) {
          setState(() {
            _statusHistory = state.history;
          });
        }
        if (state is CaseCourtHistoryLoaded) {
          setState(() {
            _courtHistory = state.history;
            _historyLoading = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${l.caseDetail} ${widget.caseModel.caseNumber}'),
          actions: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: l.changeStatus,
                onPressed: () => _showChangeStatusDialog(l, session),
              ),
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final bloc = context.read<CasesBloc>();
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CaseFormScreen(caseModel: widget.caseModel),
                    ),
                  );
                  if (!mounted) return;
                  bloc
                    ..add(RefreshCases())
                    ..add(SelectCase(widget.caseModel.caseId));
                },
              ),
            if (session?.hasPermission(Permissions.deleteCases) ?? false)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final bloc = context.read<CasesBloc>();
                  final nav = Navigator.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.deleteCase),
                      content: Text(l.deleteConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l.delete),
                        ),
                      ],
                    ),
                  );
                  if (!(confirmed ?? false) || !mounted) return;
                  bloc.add(DeleteCase(widget.caseModel.caseId));
                  nav.pop();
                },
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.info_outline), text: l.details),
              Tab(icon: const Icon(Icons.history), text: l.statusHistory),
              Tab(icon: const Icon(Icons.gavel), text: l.courtHistory),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _DetailsTab(caseModel: widget.caseModel, session: session),
            _StatusHistoryTab(history: _statusHistory, isLoading: _historyLoading),
            _CourtHistoryTab(history: _courtHistory, isLoading: _historyLoading),
          ],
        ),
      ),
    );
  }
}

// ── Details tab ─────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.caseModel, required this.session});
  final CaseModel caseModel;
  final UserSession? session;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    String localizedStatus(int status) {
      switch (status) {
        case 0: return l.statusOpen;
        case 1: return l.statusInProgress;
        case 2: return l.statusAwaitingHearing;
        case 3: return l.statusClosed;
        case 4: return l.statusWon;
        case 5: return l.statusLost;
        default: return status.toString();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: l.caseNumber, value: caseModel.caseNumber),
        _InfoRow(
          label: l.status,
          value: localizedStatus(caseModel.status),
          valueColor: _statusColor(caseModel.status),
        ),
        _InfoRow(label: l.caseType, value: caseModel.caseType),
        _InfoRow(label: l.caseCode, value: caseModel.code.toString()),
        _InfoRow(
          label: l.filingDate,
          value: caseModel.filingDate != null
              ? '${caseModel.filingDate!.year}-${caseModel.filingDate!.month.toString().padLeft(2, '0')}-${caseModel.filingDate!.day.toString().padLeft(2, '0')}'
              : '—',
        ),
        _InfoRow(label: l.amount, value: caseModel.totalAmount.toString()),
        if (caseModel.invitionsStatment.isNotEmpty)
          _InfoRow(label: l.statement, value: caseModel.invitionsStatment, multiline: true),
        if (caseModel.notes.isNotEmpty)
          _InfoRow(label: l.notes, value: caseModel.notes, multiline: true),
        const SizedBox(height: 16),
        if (caseModel.assignedEmployees.isNotEmpty) ...[
          Text(l.assignedEmployees,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary),),
          const SizedBox(height: 8),
          ...caseModel.assignedEmployees.map((e) => ListTile(
                dense: true,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: _kPrimary,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                title: Text(e.employeeName),
                subtitle: e.role.isNotEmpty ? Text(e.role) : null,
              ),),
          const SizedBox(height: 8),
        ],
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: Text(l.caseConversation),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CaseConversationScreen(caseCode: caseModel.caseId),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: Text(l.caseLinksManager),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CaseEntityRelationsScreen(caseCode: caseModel.caseId),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        CaseRelationsSection(caseId: int.tryParse(caseModel.caseId) ?? 0),
      ],
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 4: return Colors.amber.shade700;
      case 3:
      case 5: return Colors.grey;
      case 1:
      case 2: return Colors.green;
      default: return _kPrimary;
    }
  }
}

// ── Status history tab ───────────────────────────────────────────────────────

class _StatusHistoryTab extends StatelessWidget {
  const _StatusHistoryTab({required this.history, this.isLoading = false});
  final List<Map<String, dynamic>> history;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    String statusName(dynamic v) {
      final i = v is int ? v : int.tryParse(v?.toString() ?? '') ?? -1;
      switch (i) {
        case 0: return l.statusOpen;
        case 1: return l.statusInProgress;
        case 2: return l.statusAwaitingHearing;
        case 3: return l.statusClosed;
        case 4: return l.statusWon;
        case 5: return l.statusLost;
        default: return v?.toString() ?? '—';
      }
    }

    if (isLoading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: _kPrimary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(l.noStatusHistory, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = history[index];
        final changedAt = entry['changedAt'] ?? entry['ChangedAt'];
        final changedBy = (entry['changedBy'] ?? entry['ChangedBy'])?.toString() ?? '';
        final oldStatus = entry['oldStatus'] ?? entry['OldStatus'];
        final newStatus = entry['newStatus'] ?? entry['NewStatus'];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: _kPrimary,
            radius: 18,
            child: Icon(Icons.swap_horiz, color: Colors.white, size: 16),
          ),
          title: Text(
            '${statusName(oldStatus)} → ${statusName(newStatus)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (changedBy.isNotEmpty) Text('${l.changedBy}: $changedBy'),
              if (changedAt != null)
                Text(_formatDate(changedAt.toString())),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Court history tab ────────────────────────────────────────────────────────

class _CourtHistoryTab extends StatelessWidget {
  const _CourtHistoryTab({required this.history, this.isLoading = false});
  final List<Map<String, dynamic>> history;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (isLoading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel, size: 56, color: _kPrimary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(l.noCourtHistory, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    String changeTypeName(dynamic v) {
      final i = v is int ? v : int.tryParse(v?.toString() ?? '') ?? -1;
      switch (i) {
        case 0: return l.added;
        case 1: return l.removed;
        case 2: return l.changed;
        default: return v?.toString() ?? '—';
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = history[index];
        final changeType = entry['changeType'] ?? entry['ChangeType'];
        final oldCourt = (entry['oldCourtName'] ?? entry['OldCourtName'])?.toString() ?? '';
        final newCourt = (entry['newCourtName'] ?? entry['NewCourtName'])?.toString() ?? '';
        final changedBy = (entry['changedBy'] ?? entry['ChangedBy'])?.toString() ?? '';
        final changedAt = entry['changedAt'] ?? entry['ChangedAt'];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _changeTypeColor(changeType),
            radius: 18,
            child: Icon(_changeTypeIcon(changeType), color: Colors.white, size: 16),
          ),
          title: Text(
            changeTypeName(changeType),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (oldCourt.isNotEmpty) Text('${l.from}: $oldCourt'),
              if (newCourt.isNotEmpty) Text('${l.to}: $newCourt'),
              if (changedBy.isNotEmpty) Text('${l.changedBy}: $changedBy'),
              if (changedAt != null) Text(_formatDate(changedAt.toString())),
            ],
          ),
        );
      },
    );
  }

  Color _changeTypeColor(dynamic v) {
    final i = v is int ? v : int.tryParse(v?.toString() ?? '') ?? -1;
    switch (i) {
      case 0: return Colors.green;
      case 1: return Colors.red;
      default: return _kPrimary;
    }
  }

  IconData _changeTypeIcon(dynamic v) {
    final i = v is int ? v : int.tryParse(v?.toString() ?? '') ?? -1;
    switch (i) {
      case 0: return Icons.add;
      case 1: return Icons.remove;
      default: return Icons.edit;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Shared info row widget ───────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.multiline = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
