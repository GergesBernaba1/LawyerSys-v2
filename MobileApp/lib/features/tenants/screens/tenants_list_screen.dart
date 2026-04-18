import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/tenants_bloc.dart';
import '../bloc/tenants_event.dart';
import '../bloc/tenants_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.tenants)),
      body: BlocConsumer<TenantsBloc, TenantsState>(
        listener: (context, state) {
          if (state is TenantStatusUpdated) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.tenantStatusUpdated)));
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
            ]);
          }

          if (state is TenantsLoaded || state is TenantStatusUpdated) {
            final selection = state is TenantsLoaded ? state.selection : null;
            if (selection == null || selection.tenants.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text(l.noTenantsFound)),
              ]);
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
                    leading: CircleAvatar(
                      child: Text(tenant.name.isNotEmpty
                          ? tenant.name[0].toUpperCase()
                          : 'T'),
                    ),
                    title: Text(
                      '${tenant.name}${tenant.isCurrent ? ' (${l.currentTenant})' : ''}',
                    ),
                    subtitle: Text([
                      if (tenant.countryName.isNotEmpty) tenant.countryName,
                      'Users: ${tenant.userCount}',
                      if (tenant.packageName.isNotEmpty)
                        'Package: ${tenant.packageName}',
                    ].join(' • ')),
                    trailing: selection.isSuperAdmin
                        ? Switch(
                            value: tenant.isActive,
                            onChanged: (v) => context
                                .read<TenantsBloc>()
                                .add(UpdateTenantStatus(tenant.id, v)),
                          )
                        : Icon(
                            tenant.isActive ? Icons.check_circle : Icons.cancel,
                            color:
                                tenant.isActive ? Colors.green : Colors.red,
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
