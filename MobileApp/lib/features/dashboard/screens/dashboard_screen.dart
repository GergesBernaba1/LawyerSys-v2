import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../cases/screens/cases_list_screen.dart';
import '../../hearings/screens/hearings_list_screen.dart';
import '../../tasks/screens/tasks_list_screen.dart';

const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kGold = Color(0xFFB98746);
const _kBg = Color(0xFFEEF4FA);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

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
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async =>
          context.read<DashboardBloc>().add(RefreshDashboard()),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimary));
          }
          if (state is DashboardError) {
            return Center(
              child: Text('Error: ${state.message}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (state is DashboardLoaded) {
            final s = state.summary;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      label: 'Total Cases',
                      value: '${s.totalCasesCount}',
                      icon: Icons.gavel,
                      gradient: const [_kPrimary, _kPrimaryLight],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CasesListScreen())),
                    ),
                    _StatCard(
                      label: 'Active Cases',
                      value: '${s.activeCasesCount}',
                      icon: Icons.folder_open,
                      gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CasesListScreen())),
                    ),
                    _StatCard(
                      label: 'Upcoming Hearings',
                      value: '${s.upcomingHearingsCount}',
                      icon: Icons.event,
                      gradient: const [_kGold, Color(0xFFD4A15A)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HearingsListScreen())),
                    ),
                    _StatCard(
                      label: 'Pending Tasks',
                      value: '${s.pendingTasksCount}',
                      icon: Icons.task_alt,
                      gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TasksListScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activity
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                ...s.recentActivities.map((activity) => _ActivityTile(
                      title: activity.title,
                      description: activity.description,
                    )),
              ],
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.85), size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String description;

  const _ActivityTile({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _kText.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _kText,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        color: _kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
