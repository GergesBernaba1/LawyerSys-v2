import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/case_relations_repository.dart';

class CaseEntityRelationsScreen extends StatelessWidget {
  const CaseEntityRelationsScreen({
    super.key,
    required this.caseCode,
  });

  final String caseCode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session =
        authState is AuthAuthenticated ? authState.session : null;
    final canEdit =
        session?.hasPermission(Permissions.editCases) ?? false;
    final canManageEmployees =
        session?.hasPermission(Permissions.manageUsers) ?? false;
    final repo = CaseRelationsRepository(ApiClient());

    return Scaffold(
      appBar: AppBar(title: Text(l.caseLinksManager)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EntitySection(
            title: l.linkedCustomers,
            addLabel: l.linkCustomer,
            caseCode: caseCode,
            canEdit: canEdit,
            nameField: 'fullName',
            idField: 'customerId',
            fetchItems: repo.getCaseCustomers,
            addItem: repo.addCustomerToCase,
            removeItem: repo.removeCustomerFromCase,
          ),
          const SizedBox(height: 16),
          _EntitySection(
            title: l.linkedCourts,
            addLabel: l.linkCourt,
            caseCode: caseCode,
            canEdit: canEdit,
            nameField: 'name',
            idField: 'courtId',
            fetchItems: repo.getCaseCourts,
            addItem: repo.addCourtToCase,
            removeItem: repo.removeCourtFromCase,
          ),
          const SizedBox(height: 16),
          _EntitySection(
            title: l.linkedContenders,
            addLabel: l.linkContender,
            caseCode: caseCode,
            canEdit: canEdit,
            nameField: 'fullName',
            idField: 'id',
            fetchItems: repo.getCaseContenders,
            addItem: repo.addContenderToCase,
            removeItem: repo.removeContenderFromCase,
          ),
          if (canManageEmployees) ...[
            const SizedBox(height: 16),
            _EntitySection(
              title: l.linkedEmployees,
              addLabel: l.linkEmployee,
              caseCode: caseCode,
              canEdit: canManageEmployees,
              nameField: 'fullName',
              idField: 'id',
              fetchItems: repo.getCaseEmployees,
              addItem: repo.addEmployeeToCase,
              removeItem: repo.removeEmployeeFromCase,
            ),
          ],
        ],
      ),
    );
  }
}

class _EntitySection extends StatefulWidget {
  const _EntitySection({
    required this.title,
    required this.addLabel,
    required this.caseCode,
    required this.canEdit,
    required this.nameField,
    required this.idField,
    required this.fetchItems,
    required this.addItem,
    required this.removeItem,
  });

  final String title;
  final String addLabel;
  final String caseCode;
  final bool canEdit;
  final String nameField;
  final String idField;
  final Future<List<Map<String, dynamic>>> Function(String caseCode) fetchItems;
  final Future<void> Function(String caseCode, String id) addItem;
  final Future<void> Function(String caseCode, String id) removeItem;

  @override
  State<_EntitySection> createState() => _EntitySectionState();
}

class _EntitySectionState extends State<_EntitySection> {
  List<Map<String, dynamic>>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.fetchItems(widget.caseCode);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.addLabel),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: l.enterIdToLink,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.add),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final id = ctrl.text.trim();
      ctrl.dispose();
      if (id.isEmpty) return;
      try {
        await widget.addItem(widget.caseCode, id);
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l.linkSuccess)));
          await _load();
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${l.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ctrl.dispose();
    }
  }

  Future<void> _confirmRemove(BuildContext context, String id) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.unlink),
        content: Text(l.unlinkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.unlink),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await widget.removeItem(widget.caseCode, id);
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l.unlinkSuccess)));
          await _load();
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${l.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.canEdit)
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.add),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              )
            else if (_items == null || _items!.isEmpty)
              Text(
                l.noData,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              )
            else
              ..._items!.map(
                (item) {
                  final id = item[widget.idField]?.toString() ?? '';
                  final name = item[widget.nameField]?.toString() ??
                      item['name']?.toString() ??
                      item['fullName']?.toString() ??
                      id;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text('ID: $id',
                        style: theme.textTheme.labelSmall,),
                    trailing: widget.canEdit
                        ? IconButton(
                            icon: const Icon(Icons.link_off, color: Colors.red),
                            onPressed: () => _confirmRemove(context, id),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
