// ignore_for_file: argument_type_not_assignable, avoid_dynamic_calls, inference_failure_on_instance_creation
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/cases/screens/cases_list_screen.dart';
import 'package:qadaya_lawyersys/features/consultations/screens/consultations_list_screen.dart';
import 'package:qadaya_lawyersys/features/customers/screens/customers_list_screen.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_event.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_state.dart';
import 'package:qadaya_lawyersys/features/employees/screens/employees_list_screen.dart';
import 'package:qadaya_lawyersys/features/intake/screens/intake_form_screen.dart';
import 'package:qadaya_lawyersys/features/tasks/screens/tasks_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastUpdatedAt;
  bool _isRefreshing = false;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    context.read<DashboardBloc>().add(RefreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final userSession = context.read<UserSession?>();
    final userRoles = userSession?.roles ?? [];
    final isEmployeeOnly = userRoles.contains('Employee') &&
        !userRoles.contains('Admin') &&
        !userRoles.contains('SuperAdmin');

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: _handleRefresh,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),);
          }
          if (state is DashboardError) {
            return Center(
              child: Text('Error: ${state.message}',
                  style: TextStyle(color: colorScheme.error),),
            );
          }
          if (state is DashboardLoaded) {
            _lastUpdatedAt = DateTime.now();
            final s = state.summary;

            final overdueCount = isEmployeeOnly
                ? s.employeeMetrics?.overdueTasks ?? 0
                : s.overdueTasks;
            final activityHealthScore = s.activityHealthScore;
            final completionScore = s.completionScore;

            final attentionLevel = overdueCount == 0
                ? {'label': 'On Track', 'color': colorScheme.primary}
                : overdueCount <= 3
                    ? {'label': 'Needs Attention', 'color': Colors.orange}
                    : {'label': 'Critical', 'color': colorScheme.error};

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WelcomeHeader(
                  summary: s,
                  attentionLevel: attentionLevel,
                  overdueCount: overdueCount,
                  activityHealthScore: activityHealthScore,
                  lastUpdatedAt: _lastUpdatedAt,
                  isRefreshing: _isRefreshing,
                  onRefresh: _handleRefresh,
                  isEmployeeOnly: isEmployeeOnly,
                  isRTL: isRTL,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard(
                      label: isEmployeeOnly ? 'My Cases' : 'Total Cases',
                      value:
                          '${isEmployeeOnly ? (s.employeeMetrics?.openCases ?? 0) : s.totalCasesCount}',
                      icon: Icons.gavel,
                      gradient: [
                        _getThemeColor(context, 'primary'),
                        _getThemeColor(context, 'primaryLight'),
                      ],
                      trend: isEmployeeOnly ? null : s.casesTrend,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CasesListScreen(),),),
                    ),
                    _StatCard(
                      label: isEmployeeOnly ? 'My Tasks' : 'Customers',
                      value:
                          '${isEmployeeOnly ? (s.employeeMetrics?.assignedTasks ?? 0) : s.customersCount}',
                      icon: isEmployeeOnly ? Icons.check_circle : Icons.people,
                      gradient: isEmployeeOnly
                          ? [
                              _getThemeColor(context, 'warning'),
                              Colors.orange.shade200,
                            ]
                          : [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => isEmployeeOnly
                                  ? const TasksListScreen()
                                  : const CustomersListScreen(),),),
                    ),
                    _StatCard(
                      label: isEmployeeOnly ? 'My Leads' : 'Employees',
                      value:
                          '${isEmployeeOnly ? (s.employeeMetrics?.assignedLeads ?? 0) : s.employeesCount}',
                      icon: isEmployeeOnly ? Icons.person_search : Icons.badge,
                      gradient: [
                        _getThemeColor(context, 'secondary'),
                        const Color(0xFFD4A15A),
                      ],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => isEmployeeOnly
                                  ? const IntakeFormScreen()
                                  : const EmployeesListScreen(),),),
                    ),
                    _StatCard(
                      label: isEmployeeOnly ? 'My Consultations' : 'Files',
                      value:
                          '${isEmployeeOnly ? (s.employeeMetrics?.assignedConsultations ?? 0) : s.filesCount}',
                      icon: isEmployeeOnly ? Icons.description : Icons.folder,
                      gradient: [
                        _getThemeColor(context, 'success'),
                        const Color(0xFF34D399),
                      ],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConsultationsListScreen(),),),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _SmallStatCard(
                      label: isEmployeeOnly ? 'Open Cases' : 'Revenue',
                      value: isEmployeeOnly
                          ? '${s.employeeMetrics?.openCases ?? 0}'
                          : '\$${s.revenueThisMonth.toStringAsFixed(0)}',
                      icon: isEmployeeOnly
                          ? Icons.folder_open
                          : Icons.attach_money,
                      color: isEmployeeOnly
                          ? _getThemeColor(context, 'primary')
                          : _getThemeColor(context, 'success'),
                      trend: isEmployeeOnly ? null : s.revenueTrend,
                    ),
                    _SmallStatCard(
                      label: isEmployeeOnly
                          ? 'Qualified Leads'
                          : 'Upcoming Hearings',
                      value:
                          '${isEmployeeOnly ? (s.employeeMetrics?.qualifiedLeads ?? 0) : s.upcomingHearingsCount}',
                      icon: isEmployeeOnly ? Icons.star : Icons.event,
                      color: _getThemeColor(context, 'warning'),
                    ),
                    _SmallStatCard(
                      label: 'Overdue Tasks',
                      value: '$overdueCount',
                      icon: Icons.warning,
                      color: _getThemeColor(context, 'error'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _OperationalFocusSection(
                  activityHealthScore: activityHealthScore,
                  completionScore: completionScore,
                  attentionLevel: attentionLevel,
                  isRTL: isRTL,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _QuickActionsSection(
                        isEmployeeOnly: isEmployeeOnly,
                        isRTL: isRTL,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _RecentCasesSection(
                        recentCases: s.recentCases,
                        isRTL: isRTL,
                      ),
                    ),
                  ],
                ),
                if (isEmployeeOnly) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _OverdueTasksSection(
                          tasks: s.employeeMetrics?.overdueTaskList ?? [],
                          isRTL: isRTL,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FollowUpsSection(
                          leads: s.employeeMetrics?.followUps ?? [],
                          isRTL: isRTL,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {

  const _WelcomeHeader({
    required this.summary,
    required this.attentionLevel,
    required this.overdueCount,
    required this.activityHealthScore,
    required this.lastUpdatedAt,
    required this.isRefreshing,
    required this.onRefresh,
    required this.isEmployeeOnly,
    required this.isRTL,
  });
  final dynamic summary;
  final Map<String, dynamic> attentionLevel;
  final int overdueCount;
  final double activityHealthScore;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final bool isEmployeeOnly;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getThemeColor(context, 'primary'),
            _getThemeColor(context, 'primaryLight'),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'primary').withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmployeeOnly
                          ? 'Here is the work currently assigned to you.'
                          : 'Here is what is happening with your legal practice today.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: attentionLevel['label'],
                icon: Icons.info,
                color: attentionLevel['color'],
              ),
              _StatusChip(
                label: 'Overdue: $overdueCount',
                icon: Icons.warning,
              ),
              _StatusChip(
                label: 'Health: ${activityHealthScore.toInt()}%',
                icon: Icons.favorite,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusChip(
                label: lastUpdatedAt != null
                    ? 'Updated: ${lastUpdatedAt!.hour}:${lastUpdatedAt!.minute.toString().padLeft(2, '0')}'
                    : 'Updated: Now',
                icon: Icons.access_time,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(isRefreshing ? 'Refreshing...' : 'Refresh'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {

  const _StatusChip({
    required this.label,
    required this.icon,
    this.color,
  });
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.trend,
  });
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final double? trend;

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend! >= 0 ? '+' : ''}${trend!.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
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

class _SmallStatCard extends StatelessWidget {

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (trend != null)
                Row(
                  children: [
                    Icon(
                      trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend! >= 0
                          ? _getThemeColor(context, 'success')
                          : _getThemeColor(context, 'error'),
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend! >= 0 ? '+' : ''}${trend!.toInt()}%',
                      style: TextStyle(
                        color: trend! >= 0
                            ? _getThemeColor(context, 'success')
                            : _getThemeColor(context, 'error'),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: _getThemeColor(context, 'text'),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _getThemeColor(context, 'textSecondary'),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalFocusSection extends StatelessWidget {

  const _OperationalFocusSection({
    required this.activityHealthScore,
    required this.completionScore,
    required this.attentionLevel,
    required this.isRTL,
  });
  final double activityHealthScore;
  final double completionScore;
  final Map<String, dynamic> attentionLevel;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (attentionLevel['color'] as Color).withValues(alpha: 0.15),),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: attentionLevel['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Operational Focus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (attentionLevel['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (attentionLevel['color'] as Color)
                          .withValues(alpha: 0.2),),
                ),
                child: Text(
                  attentionLevel['label'],
                  style: TextStyle(
                    color: attentionLevel['color'] as Color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressBar(
            label: 'Activity Health',
            value: activityHealthScore,
            color: _getThemeColor(context, 'primary'),
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            label: 'Completion Readiness',
            value: completionScore,
            color: completionScore >= 70
                ? _getThemeColor(context, 'success')
                : completionScore >= 50
                    ? _getThemeColor(context, 'warning')
                    : _getThemeColor(context, 'error'),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _getThemeColor(context, 'textSecondary'),
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _getThemeColor(context, 'text'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withValues(alpha: 0.08),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {

  const _QuickActionsSection({
    required this.isEmployeeOnly,
    required this.isRTL,
  });
  final bool isEmployeeOnly;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  List<Map<String, dynamic>> _getActions(BuildContext context) => isEmployeeOnly
      ? [
          {
            'label': 'Work Queue',
            'path': '/employee-workqueue',
            'icon': Icons.assignment_turned_in,
            'color': _getThemeColor(context, 'error'),
          },
          {
            'label': 'My Cases',
            'path': '/cases',
            'icon': Icons.gavel,
            'color': _getThemeColor(context, 'primary'),
          },
          {
            'label': 'My Tasks',
            'path': '/tasks',
            'icon': Icons.event,
            'color': _getThemeColor(context, 'success'),
          },
          {
            'label': 'My Leads',
            'path': '/intake',
            'icon': Icons.person_search,
            'color': _getThemeColor(context, 'primaryLight'),
          },
          {
            'label': 'My Consultations',
            'path': '/consultations',
            'icon': Icons.description,
            'color': const Color(0xFF8B5CF6),
          },
        ]
      : [
          {
            'label': 'New Case',
            'path': '/cases',
            'icon': Icons.gavel,
            'color': _getThemeColor(context, 'primary'),
          },
          {
            'label': 'New Customer',
            'path': '/customers',
            'icon': Icons.people,
            'color': _getThemeColor(context, 'primaryLight'),
          },
          {
            'label': 'View Billing',
            'path': '/billing',
            'icon': Icons.receipt_long,
            'color': _getThemeColor(context, 'secondary'),
          },
          {
            'label': 'Admin Tasks',
            'path': '/tasks',
            'icon': Icons.event,
            'color': _getThemeColor(context, 'success'),
          },
        ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _getThemeColor(context, 'primary').withValues(alpha: 0.08),),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_new,
                  color: _getThemeColor(context, 'primary'), size: 20,),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._getActions(context).map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionButton(
                  label: action['label'],
                  icon: action['icon'],
                  color: action['color'],
                  isRTL: isRTL,
                  onTap: () => Navigator.pushNamed(context, action['path']),
                ),
              ),),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isRTL,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isRTL;
  final VoidCallback onTap;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCasesSection extends StatelessWidget {

  const _RecentCasesSection({
    required this.recentCases,
    required this.isRTL,
  });
  final List<dynamic> recentCases;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _getThemeColor(context, 'primary').withValues(alpha: 0.08),),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel,
                  color: _getThemeColor(context, 'primary'), size: 20,),
              const SizedBox(width: 8),
              Text(
                'Recent Cases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CasesListScreen()),),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentCases.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 48,
                    color: _getThemeColor(context, 'textSecondary')
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent cases',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _getThemeColor(context, 'textSecondary'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start by creating your first case',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getThemeColor(context, 'textSecondary')
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentCases.take(5).map((c) => _RecentCaseTile(
                  caseName: c.caseName ?? 'Case ${c.caseId}',
                  caseNumber: c.caseNumber ?? '',
                  caseType: c.caseType ?? '',
                  status: c.status ?? 'Active',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CasesListScreen(),),),
                ),),
        ],
      ),
    );
  }
}

class _RecentCaseTile extends StatelessWidget {

  const _RecentCaseTile({
    required this.caseName,
    required this.caseNumber,
    required this.caseType,
    required this.status,
    required this.onTap,
  });
  final String caseName;
  final String caseNumber;
  final String caseType;
  final String status;
  final VoidCallback onTap;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        status.toLowerCase() == 'won' || status.toLowerCase() == 'closed'
            ? _getThemeColor(context, 'success')
            : status.toLowerCase() == 'lost'
                ? _getThemeColor(context, 'error')
                : status.toLowerCase() == 'pending' ||
                        status.toLowerCase() == 'review'
                    ? _getThemeColor(context, 'warning')
                    : _getThemeColor(context, 'primary');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  _getThemeColor(context, 'primary').withValues(alpha: 0.06),),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    _getThemeColor(context, 'primary').withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gavel,
                  color: _getThemeColor(context, 'primary'), size: 18,),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caseName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _getThemeColor(context, 'text'),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caseNumber.isNotEmpty ? caseNumber : 'No Case Number',
                    style: TextStyle(
                      color: _getThemeColor(context, 'textSecondary'),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (caseType.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getThemeColor(context, 'primary')
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  caseType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getThemeColor(context, 'primary'),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueTasksSection extends StatelessWidget {

  const _OverdueTasksSection({
    required this.tasks,
    required this.isRTL,
  });
  final List<dynamic> tasks;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _getThemeColor(context, 'primary').withValues(alpha: 0.08),),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy,
                  color: _getThemeColor(context, 'error'), size: 20,),
              const SizedBox(width: 8),
              Text(
                'My Overdue Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TasksListScreen()),),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Text(
              'No overdue tasks',
              style: TextStyle(
                fontSize: 13,
                color: _getThemeColor(context, 'textSecondary'),
              ),
            )
          else
            ...tasks.take(5).map((task) => _TaskTile(
                  taskName: task.taskName ?? task.task_Name ?? 'Task',
                  reminderDate: task.taskReminderDate,
                  color: _getThemeColor(context, 'error'),
                ),),
        ],
      ),
    );
  }
}

class _FollowUpsSection extends StatelessWidget {

  const _FollowUpsSection({
    required this.leads,
    required this.isRTL,
  });
  final List<dynamic> leads;
  final bool isRTL;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _getThemeColor(context, 'primary').withValues(alpha: 0.08),),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: _getThemeColor(context, 'warning'), size: 20,),
              const SizedBox(width: 8),
              Text(
                'My Follow-ups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getThemeColor(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IntakeFormScreen(),),),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (leads.isEmpty)
            Text(
              'No follow-ups scheduled',
              style: TextStyle(
                fontSize: 13,
                color: _getThemeColor(context, 'textSecondary'),
              ),
            )
          else
            ...leads.take(5).map((lead) => _LeadTile(
                  fullName: lead.fullName ?? 'Lead',
                  followUpAt: lead.nextFollowUpAt,
                  status: lead.status ?? 'Pending',
                  color: _getThemeColor(context, 'warning'),
                ),),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {

  const _TaskTile({
    required this.taskName,
    required this.reminderDate,
    required this.color,
  });
  final String taskName;
  final String? reminderDate;
  final Color color;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try {
      date = reminderDate != null ? DateTime.parse(reminderDate!) : null;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _getThemeColor(context, 'text'),
                    fontSize: 13,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: _getThemeColor(context, 'textSecondary'),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {

  const _LeadTile({
    required this.fullName,
    required this.followUpAt,
    required this.status,
    required this.color,
  });
  final String fullName;
  final String? followUpAt;
  final String status;
  final Color color;

  Color _getThemeColor(BuildContext context, String colorType) {
    final theme = Theme.of(context);
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'error':
        return theme.colorScheme.error;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'primaryLight':
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case 'text':
        return const Color(0xFF0F172A);
      case 'textSecondary':
        return const Color(0xFF5F7085);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try {
      date = followUpAt != null ? DateTime.parse(followUpAt!) : null;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _getThemeColor(context, 'text'),
                    fontSize: 13,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: _getThemeColor(context, 'textSecondary'),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
