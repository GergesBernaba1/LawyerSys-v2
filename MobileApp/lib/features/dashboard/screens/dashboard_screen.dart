import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../cases/screens/cases_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(RefreshDashboard());
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is DashboardLoaded) {
              final summary = state.summary;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard('Total Cases', summary.totalCasesCount.toString(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CasesListScreen()))),
                  _buildStatCard('Active Cases', summary.activeCasesCount.toString(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CasesListScreen()))),
                  _buildStatCard('Upcoming Hearings', summary.upcomingHearingsCount.toString(), () {}),
                  _buildStatCard('Pending Tasks', summary.pendingTasksCount.toString(), () {}),
                  const SizedBox(height: 16),
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...summary.recentActivities.map((activity) => ListTile(title: Text(activity.title), subtitle: Text(activity.description))).toList(),
                ],
              );
            }
            return const Center(child: Text('No data available'));
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        onTap: onTap,
      ),
    );
  }
}

