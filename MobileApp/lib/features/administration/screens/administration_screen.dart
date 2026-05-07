import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../bloc/administration_bloc.dart';
import '../bloc/administration_event.dart';
import '../bloc/administration_state.dart';
import '../models/admin_overview.dart';

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

  List<_StatCardData> _buildCardData(AdminOverview overview) {
    return [
      _StatCardData(
        label: 'Total Users',
        value: overview.totalUsers,
        icon: Icons.people,
        color: Colors.blue,
      ),
      _StatCardData(
        label: 'Total Cases',
        value: overview.totalCases,
        icon: Icons.folder_copy,
        color: Colors.indigo,
      ),
      _StatCardData(
        label: 'Total Customers',
        value: overview.totalCustomers,
        icon: Icons.person,
        color: Colors.teal,
      ),
      _StatCardData(
        label: 'Total Employees',
        value: overview.totalEmployees,
        icon: Icons.badge,
        color: Colors.orange,
      ),
      _StatCardData(
        label: 'Total Tenants',
        value: overview.totalTenants,
        icon: Icons.apartment,
        color: Colors.purple,
      ),
      _StatCardData(
        label: 'Active Tenants',
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
            final cards = _buildCardData(state.overview);
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdministrationBloc>().add(RefreshAdminOverview());
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
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
            );
          }

          // AdminInitial / AdminError fallback
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdministrationBloc>().add(LoadAdminOverview());
            },
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(child: Text('Pull to refresh')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
