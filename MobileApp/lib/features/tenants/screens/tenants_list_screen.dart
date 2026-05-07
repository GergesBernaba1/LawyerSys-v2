import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_bloc.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_event.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_state.dart';
import 'package:qadaya_lawyersys/features/tenants/models/tenant_model.dart';
import 'package:qadaya_lawyersys/features/tenants/screens/tenant_detail_screen.dart';

class TenantsListScreen extends StatefulWidget {
  const TenantsListScreen({super.key});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantsBloc>().add(LoadTenants());
  }

  void _showTenantForm(BuildContext context, TenantModel? tenant) {
    final isEdit = tenant != null;
    final nameController = TextEditingController(text: isEdit ? tenant.name : '');
    final countryController =
        TextEditingController(text: isEdit ? tenant.countryName : '');
    bool isActive = !isEdit || tenant.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit
                ? AppLocalizations.of(context)!.editTenant
                : AppLocalizations.of(context)!.createTenant,),
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
                          onChanged: (v) =>
                              setDialogState(() => isActive = v),
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
                  final data = {
                    'name': nameController.text.trim(),
                    'countryName': countryController.text.trim(),
                    'isActive': isActive,
                  };
                  if (isEdit) {
                    context
                        .read<TenantsBloc>()
                        .add(UpdateTenant(tenant.id, data));
                  } else {
                    context.read<TenantsBloc>().add(CreateTenant(data));
                  }
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

  void _confirmDelete(BuildContext context, TenantModel tenant) {
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
        context.read<TenantsBloc>().add(DeleteTenant(tenant.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.tenants)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.createTenant,
        onPressed: () => _showTenantForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<TenantsBloc, TenantsState>(
        listener: (context, state) {
          if (state is TenantStatusUpdated) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.tenantStatusUpdated)));
          }
          if (state is TenantOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is TenantsError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('${l.error}: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is TenantsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TenantsError) {
            return ListView(children: [
              const SizedBox(height: 80),
              Center(child: Text('${l.error}: ${state.message}')),
            ],);
          }

          if (state is TenantsLoaded) {
            final selection = state.selection;

            if (selection.tenants.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text(l.noTenantsFound)),
              ],);
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<TenantsBloc>().add(RefreshTenants()),
              child: ListView.separated(
                itemCount: selection.tenants.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tenant = selection.tenants[index];
                  return ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<TenantsBloc>(),
                          child: TenantDetailScreen(tenant: tenant),
                        ),
                      ),
                    ),
                    leading: CircleAvatar(
                      child: Text(tenant.name.isNotEmpty
                          ? tenant.name[0].toUpperCase()
                          : 'T',),
                    ),
                    title: Text(
                      '${tenant.name}${tenant.isCurrent ? ' (${l.currentTenant})' : ''}',
                    ),
                    subtitle: Text([
                      if (tenant.countryName.isNotEmpty) tenant.countryName,
                      'Users: ${tenant.userCount}',
                      if (tenant.packageName.isNotEmpty)
                        'Package: ${tenant.packageName}',
                    ].join(' • '),),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selection.isSuperAdmin)
                          Switch(
                            value: tenant.isActive,
                            onChanged: (v) => context
                                .read<TenantsBloc>()
                                .add(UpdateTenantStatus(tenant.id, v)),
                          )
                        else
                          Icon(
                            tenant.isActive
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                tenant.isActive ? Colors.green : Colors.red,
                          ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              _showTenantForm(context, tenant);
                            } else if (v == 'delete') {
                              _confirmDelete(context, tenant);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 8),
                                Text(l.edit),
                              ],),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                const Icon(Icons.delete,
                                    size: 18, color: Colors.red,),
                                const SizedBox(width: 8),
                                Text(
                                  l.delete,
                                  style:
                                      const TextStyle(color: Colors.red),
                                ),
                              ],),
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

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
