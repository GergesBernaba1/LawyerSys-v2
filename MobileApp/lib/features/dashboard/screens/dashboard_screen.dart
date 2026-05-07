import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../cases/screens/cases_list_screen.dart';
import '../../tasks/screens/tasks_list_screen.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../employees/screens/employees_list_screen.dart';
import '../../intake/screens/intake_form_screen.dart';
import '../../consultations/screens/consultations_list_screen.dart';
import '../../../features/authentication/models/user_session.dart';

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
                child: CircularProgressIndicator(color: colorScheme.primary));
          }
          if (state is DashboardError) {
            return Center(
              child: Text('Error: ${state.message}',
                  style: TextStyle(color: colorScheme.error)),
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
                  getThemeColor: _getThemeColor,
                ),
                const SizedBox(height: 20),
                _BaseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              _getThemeColor(context, 'primaryLight')
                            ],
                            trend: isEmployeeOnly ? null : s.casesTrend,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CasesListScreen())),
                          ),
                          _StatCard(
                            label: isEmployeeOnly ? 'My Tasks' : 'Customers',
                            value:
                                '${isEmployeeOnly ? (s.employeeMetrics?.assignedTasks ?? 0) : s.customersCount}',
                            icon: isEmployeeOnly
                                ? Icons.check_circle
                                : Icons.people,
                            gradient: isEmployeeOnly
                                ? [
                                    _getThemeColor(context, 'warning'),
                                    Colors.orange.shade200
                                  ]
                                : [
                                    const Color(0xFF0EA5E9),
                                    const Color(0xFF38BDF8)
                                  ],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => isEmployeeOnly
                                        ? const TasksListScreen()
                                        : const CustomersListScreen())),
                          ),
                          _StatCard(
                            label: isEmployeeOnly ? 'My Leads' : 'Employees',
                            value:
                                '${isEmployeeOnly ? (s.employeeMetrics?.assignedLeads ?? 0) : s.employeesCount}',
                            icon: isEmployeeOnly
                                ? Icons.person_search
                                : Icons.badge,
                            gradient: [
                              _getThemeColor(context, 'secondary'),
                              const Color(0xFFD4A15A)
                            ],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => isEmployeeOnly
                                        ? const IntakeFormScreen()
                                        : const EmployeesListScreen())),
                          ),
                          _StatCard(
                            label:
                                isEmployeeOnly ? 'My Consultations' : 'Files',
                            value:
                                '${isEmployeeOnly ? (s.employeeMetrics?.assignedConsultations ?? 0) : s.filesCount}',
                            icon: isEmployeeOnly
                                ? Icons.description
                                : Icons.folder,
                            gradient: [
                              _getThemeColor(context, 'success'),
                              const Color(0xFF34D399)
                            ],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ConsultationsListScreen())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _BaseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            getThemeColor: _getThemeColor,
                          ),
                          _SmallStatCard(
                            label: isEmployeeOnly
                                ? 'Qualified Leads'
                                : 'Upcoming Hearings',
                            value:
                                '${isEmployeeOnly ? (s.employeeMetrics?.qualifiedLeads ?? 0) : s.upcomingHearingsCount}',
                            icon: isEmployeeOnly ? Icons.star : Icons.event,
                            color: _getThemeColor(context, 'warning'),
                            getThemeColor: _getThemeColor,
                          ),
                          _SmallStatCard(
                            label: 'Overdue Tasks',
                            value: '$overdueCount',
                            icon: Icons.warning,
                            color: _getThemeColor(context, 'error'),
                            getThemeColor: _getThemeColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _OperationalFocusSection(
                  activityHealthScore: activityHealthScore,
                  completionScore: completionScore,
                  attentionLevel: attentionLevel,
                  isRTL: isRTL,
                  getThemeColor: _getThemeColor,
                ),
                const SizedBox(height: 20),
                _QuickActionsSection(
                  isEmployeeOnly: isEmployeeOnly,
                  isRTL: isRTL,
                  getThemeColor: _getThemeColor,
                ),
                const SizedBox(height: 20),
                _RecentCasesSection(
                  recentCases: s.recentCases,
                  isRTL: isRTL,
                  getThemeColor: _getThemeColor,
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
                          getThemeColor: _getThemeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FollowUpsSection(
                          leads: s.employeeMetrics?.followUps ?? [],
                          isRTL: isRTL,
                          getThemeColor: _getThemeColor,
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

class _BaseCard extends StatelessWidget {
  final Widget child;

  const _BaseCard({
    required this.child,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _getDefaultThemeColor(context, 'primary').withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _getDefaultThemeColor(context, 'text').withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final dynamic summary;
  final Map<String, dynamic> attentionLevel;
  final int overdueCount;
  final double activityHealthScore;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final bool isEmployeeOnly;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType) getThemeColor;

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
    required this.getThemeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            getThemeColor(context, 'primary'),
            getThemeColor(context, 'primaryLight')
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: getThemeColor(context, 'primary').withValues(alpha: 0.3),
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
  final String label;
  final IconData icon;
  final Color? color;

  const _StatusChip({
    required this.label,
    required this.icon,
    this.color,
  });

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
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final double? trend;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
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
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorFunc(context, 'text').withValues(alpha: 0.04),
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
                          ? colorFunc(context, 'success')
                          : colorFunc(context, 'error'),
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend! >= 0 ? '+' : ''}${trend!.toInt()}%',
                      style: TextStyle(
                        color: trend! >= 0
                            ? colorFunc(context, 'success')
                            : colorFunc(context, 'error'),
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
              color: colorFunc(context, 'text'),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorFunc(context, 'textSecondary'),
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
  final double activityHealthScore;
  final double completionScore;
  final Map<String, dynamic> attentionLevel;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _OperationalFocusSection({
    required this.activityHealthScore,
    required this.completionScore,
    required this.attentionLevel,
    required this.isRTL,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return _BaseCard(
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
                  color: colorFunc(context, 'text'),
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
                          .withValues(alpha: 0.2)),
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
            color: colorFunc(context, 'primary'),
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            label: 'Completion Readiness',
            value: completionScore,
            color: completionScore >= 70
                ? colorFunc(context, 'success')
                : completionScore >= 50
                    ? colorFunc(context, 'warning')
                    : colorFunc(context, 'error'),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F7085),
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
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
  final bool isEmployeeOnly;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _QuickActionsSection({
    required this.isEmployeeOnly,
    required this.isRTL,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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

  List<Map<String, dynamic>> _getActions(BuildContext context) {
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return isEmployeeOnly
        ? [
            {
              'label': 'Work Queue',
              'path': '/employee-workqueue',
              'icon': Icons.assignment_turned_in,
              'color': colorFunc(context, 'error')
            },
            {
              'label': 'My Cases',
              'path': '/cases',
              'icon': Icons.gavel,
              'color': colorFunc(context, 'primary')
            },
            {
              'label': 'My Tasks',
              'path': '/tasks',
              'icon': Icons.event,
              'color': colorFunc(context, 'success')
            },
            {
              'label': 'My Leads',
              'path': '/intake',
              'icon': Icons.person_search,
              'color': colorFunc(context, 'primaryLight')
            },
            {
              'label': 'My Consultations',
              'path': '/consultations',
              'icon': Icons.description,
              'color': const Color(0xFF8B5CF6)
            },
          ]
        : [
            {
              'label': 'New Case',
              'path': '/cases',
              'icon': Icons.gavel,
              'color': colorFunc(context, 'primary')
            },
            {
              'label': 'New Customer',
              'path': '/customers',
              'icon': Icons.people,
              'color': colorFunc(context, 'primaryLight')
            },
            {
              'label': 'View Billing',
              'path': '/billing',
              'icon': Icons.receipt_long,
              'color': colorFunc(context, 'secondary')
            },
            {
              'label': 'Admin Tasks',
              'path': '/tasks',
              'icon': Icons.event,
              'color': colorFunc(context, 'success')
            },
          ];
  }

  @override
  Widget build(BuildContext context) {
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_new,
                  color: colorFunc(context, 'primary'), size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorFunc(context, 'text'),
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
              )),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isRTL;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isRTL,
    required this.onTap,
  });

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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Icon(
              isRTL ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
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
  final List<dynamic> recentCases;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _RecentCasesSection({
    required this.recentCases,
    required this.isRTL,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: colorFunc(context, 'primary'), size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Cases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorFunc(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CasesListScreen())),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 48,
                    color: colorFunc(context, 'textSecondary')
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent cases',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorFunc(context, 'textSecondary'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start by creating your first case',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorFunc(context, 'textSecondary')
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CasesListScreen())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Case'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          builder: (_) => const CasesListScreen())),
                  getThemeColor: colorFunc,
                )),
        ],
      ),
    );
  }
}

class _RecentCaseTile extends StatelessWidget {
  final String caseName;
  final String caseNumber;
  final String caseType;
  final String status;
  final VoidCallback onTap;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _RecentCaseTile({
    required this.caseName,
    required this.caseNumber,
    required this.caseType,
    required this.status,
    required this.onTap,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    final statusColor =
        status.toLowerCase() == 'won' || status.toLowerCase() == 'closed'
            ? colorFunc(context, 'success')
            : status.toLowerCase() == 'lost'
                ? colorFunc(context, 'error')
                : status.toLowerCase() == 'pending' ||
                        status.toLowerCase() == 'review'
                    ? colorFunc(context, 'warning')
                    : colorFunc(context, 'primary');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: colorFunc(context, 'primary').withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorFunc(context, 'primary').withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gavel,
                  color: colorFunc(context, 'primary'), size: 18),
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
                      color: colorFunc(context, 'text'),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caseNumber.isNotEmpty ? caseNumber : 'No Case Number',
                    style: TextStyle(
                      color: colorFunc(context, 'textSecondary'),
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
                  color: colorFunc(context, 'primary').withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  caseType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorFunc(context, 'primary'),
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
  final List<dynamic> tasks;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _OverdueTasksSection({
    required this.tasks,
    required this.isRTL,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy,
                  color: colorFunc(context, 'error'), size: 20),
              const SizedBox(width: 8),
              Text(
                'My Overdue Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorFunc(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TasksListScreen())),
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
                color: colorFunc(context, 'textSecondary'),
              ),
            )
          else
            ...tasks.take(5).map((task) => _TaskTile(
                  taskName: task.taskName ?? task.task_Name ?? 'Task',
                  reminderDate: task.taskReminderDate,
                  color: colorFunc(context, 'error'),
                  getThemeColor: colorFunc,
                )),
        ],
      ),
    );
  }
}

class _FollowUpsSection extends StatelessWidget {
  final List<dynamic> leads;
  final bool isRTL;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _FollowUpsSection({
    required this.leads,
    required this.isRTL,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline,
                  color: colorFunc(context, 'warning'), size: 20),
              const SizedBox(width: 8),
              Text(
                'My Follow-ups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorFunc(context, 'text'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IntakeFormScreen())),
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
                color: colorFunc(context, 'textSecondary'),
              ),
            )
          else
            ...leads.take(5).map((lead) => _LeadTile(
                  fullName: lead.fullName ?? 'Lead',
                  followUpAt: lead.nextFollowUpAt,
                  status: lead.status ?? 'Pending',
                  color: colorFunc(context, 'warning'),
                  getThemeColor: colorFunc,
                )),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String taskName;
  final String? reminderDate;
  final Color color;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _TaskTile({
    required this.taskName,
    required this.reminderDate,
    required this.color,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
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
                    color: colorFunc(context, 'text'),
                    fontSize: 13,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: colorFunc(context, 'textSecondary'),
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
  final String fullName;
  final String? followUpAt;
  final String status;
  final Color color;
  final Color Function(BuildContext context, String colorType)? getThemeColor;

  const _LeadTile({
    required this.fullName,
    required this.followUpAt,
    required this.status,
    required this.color,
    this.getThemeColor,
  });

  Color _getDefaultThemeColor(BuildContext context, String colorType) {
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
    final colorFunc = getThemeColor ?? _getDefaultThemeColor;
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
                    color: colorFunc(context, 'text'),
                    fontSize: 13,
                  ),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: colorFunc(context, 'textSecondary'),
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
