import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ignore: unused_import
import '../../../core/localization/app_localizations.dart';
import '../bloc/audit_logs_bloc.dart';
import '../bloc/audit_logs_event.dart';
import '../bloc/audit_logs_state.dart';
import '../models/audit_log.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchController = TextEditingController();
  String? _selectedEntityName;
  String? _selectedAction;

  static const _actionOptions = ['Create', 'Update', 'Delete', 'Login'];

  @override
  void initState() {
    super.initState();
    context.read<AuditLogsBloc>().add(LoadAuditLogs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AuditLogsBloc>().add(
          LoadAuditLogs(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            entityName: _selectedEntityName,
            action: _selectedAction,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditLogs),
      ),
      body: Column(
        children: [
          _buildFilterRow(context),
          Expanded(
            child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
              builder: (context, state) {
                if (state is AuditLogsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AuditLogsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('${l10n.error}: ${state.message}'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context
                              .read<AuditLogsBloc>()
                              .add(RefreshAuditLogs()),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AuditLogsLoaded) {
                  return _buildLogsList(context, state.logs);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchAuditLogs,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _applyFilters(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedEntityName,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.entity,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                    ...const [
                      'Case',
                      'Customer',
                      'Invoice',
                      'Hearing',
                      'Task',
                      'Document',
                      'User',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedEntityName = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedAction,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.action,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                    ..._actionOptions.map(
                      (a) => DropdownMenuItem(value: a, child: Text(a)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedAction = v);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<AuditLog> logs) {
    final l10n = AppLocalizations.of(context)!;
    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            context.read<AuditLogsBloc>().add(RefreshAuditLogs()),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.noAuditLogsFound,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<AuditLogsBloc>().add(RefreshAuditLogs()),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: logs.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          return _AuditLogTile(log: logs[index]);
        },
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;
  const _AuditLogTile({required this.log});

  Color _chipColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(log.action);
    final formattedDate =
        DateFormat('MMM d, yyyy – HH:mm').format(log.performedAt.toLocal());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          log.action,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        log.entityName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.performedBy != null)
            Row(
              children: [
                const Icon(Icons.person, size: 13, color: Colors.grey),
                const SizedBox(width: 3),
                Text(
                  log.performedBy!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 3),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: log.performedBy != null,
    );
  }
}
