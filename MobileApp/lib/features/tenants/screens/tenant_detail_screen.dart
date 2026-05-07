import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_bloc.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_event.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_state.dart';
import 'package:qadaya_lawyersys/features/tenants/models/tenant_model.dart';

class TenantDetailScreen extends StatefulWidget {

  const TenantDetailScreen({super.key, required this.tenant});
  final TenantModel tenant;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  late TenantModel _tenant;

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
  }

  void _showEditForm(BuildContext context) {
    final nameController = TextEditingController(text: _tenant.name);
    final countryController = TextEditingController(text: _tenant.countryName);
    bool isActive = _tenant.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.editTenant),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.tenantName,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: countryController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.governorate,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.allFieldsAreRequired : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.active),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  context.read<TenantsBloc>().add(UpdateTenant(
                        _tenant.id,
                        {
                          'name': nameController.text.trim(),
                          'countryName': countryController.text.trim(),
                          'isActive': isActive,
                        },
                      ),);
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      nameController.dispose();
      countryController.dispose();
    });
  }

  void _confirmDelete(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTenant),
        content: Text(l.deleteTenantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if ((confirmed ?? false) && context.mounted) {
        context.read<TenantsBloc>().add(DeleteTenant(_tenant.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocListener<TenantsBloc, TenantsState>(
      listener: (context, state) {
        if (state is TenantOperationSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context);
        }
        if (state is TenantsError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${l.error}: ${state.message}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tenant.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l.editTenant,
              onPressed: () => _showEditForm(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: l.delete,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(
                label: l.tenantName,
                value: _tenant.name,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                label: l.governorate,
                value: _tenant.countryName.isNotEmpty
                    ? _tenant.countryName
                    : '—',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                label: l.description,
                value: _tenant.packageName.isNotEmpty
                    ? _tenant.packageName
                    : '—',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                label: l.users,
                value: _tenant.userCount.toString(),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.status,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14,),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4,),
                        decoration: BoxDecoration(
                          color: _tenant.isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tenant.isActive ? l.active : l.status,
                          style: TextStyle(
                            color:
                                _tenant.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_tenant.isCurrent)
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,),
                        const SizedBox(width: 8),
                        Text(
                          l.currentTenant,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8,),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.active,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _tenant.isActive,
                        onChanged: (v) {
                          context
                              .read<TenantsBloc>()
                              .add(UpdateTenantStatus(_tenant.id, isActive: v));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.subscriptions),
                  label: Text(l.trustAccounting),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {

  const _InfoCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14,),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
