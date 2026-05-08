import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_bloc.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_event.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_state.dart';
import 'package:qadaya_lawyersys/features/administration/models/admin_overview.dart';
import 'package:qadaya_lawyersys/features/customers/screens/customers_list_screen.dart';
import 'package:qadaya_lawyersys/features/employees/screens/employees_list_screen.dart';
import 'package:qadaya_lawyersys/features/tenants/screens/tenants_list_screen.dart';
import 'package:qadaya_lawyersys/features/users/screens/users_list_screen.dart';

class AdministrationScreen extends StatefulWidget {
  const AdministrationScreen({super.key});

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdministrationBloc>().add(LoadAdminOverview());
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StatCardData> _buildCardData(BuildContext context, AdminOverview overview) {
    final l = AppLocalizations.of(context)!;
    return [
      _StatCardData(
        label: l.totalUsers,
        value: overview.totalUsers,
        icon: Icons.people,
        color: Colors.blue,
      ),
      _StatCardData(
        label: l.totalCases,
        value: overview.totalCases,
        icon: Icons.folder_copy,
        color: Colors.indigo,
      ),
      _StatCardData(
        label: l.totalCustomers,
        value: overview.totalCustomers,
        icon: Icons.person,
        color: Colors.teal,
      ),
      _StatCardData(
        label: l.totalEmployees,
        value: overview.totalEmployees,
        icon: Icons.badge,
        color: Colors.orange,
      ),
      _StatCardData(
        label: l.totalTenants,
        value: overview.totalTenants,
        icon: Icons.apartment,
        color: Colors.purple,
      ),
      _StatCardData(
        label: l.activeTenants,
        value: overview.activeTenants,
        icon: Icons.check_circle,
        color: Colors.green,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.administration),
      ),
      body: BlocConsumer<AdministrationBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminLoaded) {
            final cards = _buildCardData(context, state.overview);
            final l = AppLocalizations.of(context)!;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdministrationBloc>().add(RefreshAdminOverview());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return _buildStatCard(
                          label: card.label,
                          value: card.value,
                          icon: card.icon,
                          color: card.color,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.management,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AdminNavTile(
                      icon: Icons.supervisor_account,
                      label: l.users,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const UsersListScreen(),
                        ),
                      ),
                    ),
                    _AdminNavTile(
                      icon: Icons.badge,
                      label: l.employees,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const EmployeesListScreen(),
                        ),
                      ),
                    ),
                    _AdminNavTile(
                      icon: Icons.people,
                      label: l.customers,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const CustomersListScreen(),
                        ),
                      ),
                    ),
                    _AdminNavTile(
                      icon: Icons.apartment,
                      label: l.tenants,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TenantsListScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // AdminInitial / AdminError fallback
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdministrationBloc>().add(LoadAdminOverview());
            },
            child: ListView(
              children: [
                const SizedBox(height: 200),
                Center(child: Text(AppLocalizations.of(context)!.pullToRefresh)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCardData {

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _AdminNavTile extends StatelessWidget {

  const _AdminNavTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
