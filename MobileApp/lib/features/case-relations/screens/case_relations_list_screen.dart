import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/case_relations_bloc.dart';
import '../bloc/case_relations_event.dart';
import '../bloc/case_relations_state.dart';
import '../models/case_relation.dart';

class CaseRelationsListScreen extends StatefulWidget {
  final int caseCode;
  final String caseStatement;

  const CaseRelationsListScreen({
    super.key,
    required this.caseCode,
    required this.caseStatement,
  });

  @override
  State<CaseRelationsListScreen> createState() => _CaseRelationsListScreenState();
}

class _CaseRelationsListScreenState extends State<CaseRelationsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'Customers', icon: Icons.person),
    (label: 'Contenders', icon: Icons.gavel),
    (label: 'Courts', icon: Icons.account_balance),
    (label: 'Employees', icon: Icons.work),
    (label: 'Hearings', icon: Icons.calendar_month),
    (label: 'Files', icon: Icons.folder),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<CaseRelationsBloc>().add(LoadCaseRelations(widget.caseCode));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case ${widget.caseCode}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(icon: Icon(t.icon, size: 18), text: t.label))
              .toList(),
        ),
      ),
      body: BlocBuilder<CaseRelationsBloc, CaseRelationsState>(
        builder: (context, state) {
          if (state is CaseRelationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CaseRelationsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<CaseRelationsBloc>()
                        .add(LoadCaseRelations(widget.caseCode)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is CaseRelationsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<CaseRelationsBloc>()
                  .add(RefreshCaseRelations(widget.caseCode)),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RelationTab(
                    items: state.relations.customers
                        .map((c) => _RelationItem(id: c.id, title: c.customerName, subtitle: 'Customer #${c.customerId}'))
                        .toList(),
                  ),
                  _RelationTab(
                    items: state.relations.contenders
                        .map((c) => _RelationItem(id: c.id, title: c.contenderName, subtitle: 'Contender #${c.contenderId}'))
                        .toList(),
                  ),
                  _RelationTab(
                    items: state.relations.courts
                        .map((c) => _RelationItem(id: c.id, title: c.courtName, subtitle: 'Court #${c.courtId}'))
                        .toList(),
                  ),
                  _RelationTab(
                    items: state.relations.employees
                        .map((e) => _RelationItem(id: e.id, title: e.employeeName, subtitle: 'Employee #${e.employeeId}'))
                        .toList(),
                  ),
                  _RelationTab(
                    items: state.relations.sitings
                        .map((s) => _RelationItem(
                              id: s.id,
                              title: s.sitingDate ?? 'Hearing #${s.sitingId}',
                              subtitle: s.judgeName != null ? 'Judge: ${s.judgeName}' : null,
                            ))
                        .toList(),
                  ),
                  _RelationTab(
                    items: state.relations.files
                        .map((f) => _RelationItem(id: f.id, title: f.displayName, subtitle: 'File #${f.fileId}'))
                        .toList(),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RelationItem {
  final int id;
  final String title;
  final String? subtitle;
  _RelationItem({required this.id, required this.title, this.subtitle});
}

class _RelationTab extends StatelessWidget {
  final List<_RelationItem> items;
  const _RelationTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items linked'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.title),
          subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
        );
      },
    );
  }
}
