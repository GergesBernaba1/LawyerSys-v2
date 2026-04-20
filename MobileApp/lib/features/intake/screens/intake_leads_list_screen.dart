import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../bloc/intake_bloc.dart';
import '../bloc/intake_event.dart';
import '../bloc/intake_state.dart';
import '../repositories/intake_repository.dart';
import 'intake_lead_detail_screen.dart';
import 'intake_form_screen.dart';

class IntakeLeadsListScreen extends StatefulWidget {
  const IntakeLeadsListScreen({super.key});

  @override
  State<IntakeLeadsListScreen> createState() => _IntakeLeadsListScreenState();
}

class _IntakeLeadsListScreenState extends State<IntakeLeadsListScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  static const _statuses = ['New', 'Qualified', 'Rejected', 'Converted'];

  static const _statusColors = {
    'New': Colors.blue,
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
    super.dispose();
  }

  Future<void> _onPublicLinkTapped() async {
    final link = await IntakeRepository(ApiClient()).getPublicIntakeLink();
    if (!mounted) return;
    if (link == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Public intake link not available')), // TODO: localize
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Public Intake Link', // TODO: localize
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: SelectableText(link)),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy', // TODO: localize
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link copied')), // TODO: localize
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilter() {
    context.read<IntakeBloc>().add(LoadIntakeLeads(
          status: _statusFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.leads),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Public Intake Link', // TODO: localize
            onPressed: _onPublicLinkTapped,
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _statusFilter = v);
              _applyFilter();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: null, child: Text(l.noDataAvailable.replaceAll('No data available', 'All'))),
              ..._statuses.map((s) => PopupMenuItem(value: s, child: Text(s))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.create,
        onPressed: () async {
          final bloc = context.read<IntakeBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IntakeFormScreen()),
          );
          if (mounted) bloc.add(RefreshIntakeLeads());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l.search,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _applyFilter,
                      ),
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                if (_statusFilter != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_statusFilter!),
                    onDeleted: () {
                      setState(() => _statusFilter = null);
                      _applyFilter();
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<IntakeBloc, IntakeState>(
              listener: (context, state) {
                if (state is IntakeActionSuccess) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }
                if (state is IntakeError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l.error}: ${state.message}')));
                }
              },
              builder: (context, state) {
                if (state is IntakeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is IntakeError) {
                  return Center(
                      child: Text('${l.error}: ${state.message}'));
                }
                if (state is IntakeLoaded) {
                  final leads = state.leads;
                  if (leads.isEmpty) {
                    return Center(child: Text(l.noLeadsFound));
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<IntakeBloc>().add(RefreshIntakeLeads()),
                    child: ListView.builder(
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        final color =
                            _statusColors[lead.status] ?? Colors.grey;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child:
                                Icon(Icons.person_outline, color: color),
                          ),
                          title: Text(lead.fullName),
                          subtitle: Text(
                            '${lead.subject} • ${lead.status}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Chip(
                            label: Text(lead.status,
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor: color.withValues(alpha: 0.12),
                            side: BorderSide.none,
                          ),
                          onTap: () {
                            final bloc = context.read<IntakeBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    IntakeLeadDetailScreen(lead: lead),
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
