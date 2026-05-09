import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/realtime/signalr_service.dart';
import 'package:qadaya_lawyersys/features/about/screens/about_screen.dart';
import 'package:qadaya_lawyersys/features/administration/screens/administration_screen.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/screens/ai_assistant_screen.dart';
import 'package:qadaya_lawyersys/features/auditlogs/screens/audit_logs_screen.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_event.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/billing/screens/billing_list_screen.dart';
import 'package:qadaya_lawyersys/features/calendar/screens/calendar_screen.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_event.dart';
import 'package:qadaya_lawyersys/features/cases/screens/case_form_screen.dart';
import 'package:qadaya_lawyersys/features/cases/screens/cases_list_screen.dart';
import 'package:qadaya_lawyersys/features/client-portal/screens/portal_overview_screen.dart';
import 'package:qadaya_lawyersys/features/consultations/screens/consultations_list_screen.dart';
import 'package:qadaya_lawyersys/features/contact/screens/contact_screen.dart';
import 'package:qadaya_lawyersys/features/contenders/screens/contenders_list_screen.dart';
import 'package:qadaya_lawyersys/features/court-automation/screens/court_automation_screen.dart';
import 'package:qadaya_lawyersys/features/courts/screens/courts_list_screen.dart';
import 'package:qadaya_lawyersys/features/customers/screens/customers_list_screen.dart';
import 'package:qadaya_lawyersys/features/dashboard/screens/dashboard_screen.dart';
import 'package:qadaya_lawyersys/features/document-generation/screens/doc_generation_screen.dart';
import 'package:qadaya_lawyersys/features/documents/screens/documents_list_screen.dart';
import 'package:qadaya_lawyersys/features/employees/screens/employees_list_screen.dart';
import 'package:qadaya_lawyersys/features/esign/screens/esign_list_screen.dart';
import 'package:qadaya_lawyersys/features/files/screens/files_list_screen.dart';
import 'package:qadaya_lawyersys/features/governments/screens/governments_list_screen.dart';
import 'package:qadaya_lawyersys/features/hearings/screens/hearings_list_screen.dart';
import 'package:qadaya_lawyersys/features/intake/screens/intake_leads_list_screen.dart';
import 'package:qadaya_lawyersys/features/judicial/screens/judicial_documents_list_screen.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_bloc.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_event.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_state.dart';
import 'package:qadaya_lawyersys/features/notifications/models/notification.dart' as model;
import 'package:qadaya_lawyersys/features/notifications/screens/notifications_inbox_screen.dart';
import 'package:qadaya_lawyersys/features/reports/screens/reports_screen.dart';
import 'package:qadaya_lawyersys/features/settings/screens/settings_screen.dart';
import 'package:qadaya_lawyersys/features/sitings/screens/sitings_list_screen.dart';
import 'package:qadaya_lawyersys/features/subscription/screens/subscription_screen.dart';
import 'package:qadaya_lawyersys/features/tasks/screens/tasks_list_screen.dart';
import 'package:qadaya_lawyersys/features/tenants/screens/tenants_list_screen.dart';
import 'package:qadaya_lawyersys/features/timetracking/screens/timetracking_list_screen.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/screens/trust_list_screen.dart';
import 'package:qadaya_lawyersys/features/trust-reports/screens/trust_reports_screen.dart';
import 'package:qadaya_lawyersys/features/users/screens/users_list_screen.dart';
import 'package:qadaya_lawyersys/features/workqueue/screens/workqueue_screen.dart';

// Theme constants matching ClientApp
const _kPrimary = Color(0xFF14345A);
const _kGold = Color(0xFFB98746);
const _kBg = Color(0xFFEEF4FA);
const _kText = Color(0xFF0F172A);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription<Map<String, dynamic>>? _signalRSub;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationsBloc>()
      ..add(LoadNotifications());
    _signalRSub = SignalRService().events.listen((event) {
      if ((event['event']?.toString() ?? '') == 'NotificationsChanged') {
        if (mounted) bloc.add(LoadNotifications());
        return;
      }

      final title = event['title']?.toString() ?? 'Update';
      final message = event['message']?.toString() ?? 'You have a new update';
      final id = event['notificationId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final notification = model.AppNotification(
          notificationId: id, title: title, message: message,);
      if (mounted) bloc.add(NewNotificationReceived(notification));
    });
  }

  @override
  void dispose() {
    _signalRSub?.cancel();
    super.dispose();
  }

  Widget? _buildFab(BuildContext context, _NavItem currentItem, UserSession? session) {
    // Show a create-case FAB only on the Cases screen and only when the user
    // has the createCases permission (Admin/Employee).
    if (currentItem.page is! CasesListScreen) return null;
    if (!(session?.hasPermission(Permissions.createCases) ?? false)) return null;

    return FloatingActionButton.extended(
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(AppLocalizations.of(context)!.createCase),
      onPressed: () async {
        final bloc = context.read<CasesBloc>();
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CaseFormScreen()),
        );
        if (mounted) bloc.add(RefreshCases());
      },
    );
  }

  List<_NavItem> _buildNavItems(AppLocalizations l, UserSession? session) {
    if (session == null) return [];

    // Customer-only menu — limited to their own portal view.
    if (session.isCustomer()) {
      return [
        _NavItem(Icons.dashboard, l.dashboard, const DashboardScreen()),
        _NavItem(Icons.folder, l.cases, const CasesListScreen()),
        _NavItem(Icons.hub, l.clientPortal, const PortalOverviewScreen()),
        _NavItem(Icons.notifications, l.notifications, const NotificationsInboxScreen()),
        _NavItem(Icons.settings, l.settings, const SettingsScreen()),
      ];
    }

    // Full menu — every item gated by its required permission.
    // Admins receive all permissions via hasPermission(), so their list is
    // always complete. Employees and custom roles see only what their
    // permission set allows.
    final all = <_NavItem>[
      _NavItem(Icons.dashboard, l.dashboard, const DashboardScreen()),
      _NavItem(Icons.gavel, l.cases, const CasesListScreen(),
          permission: Permissions.viewCases,),
      _NavItem(Icons.people, l.customers, const CustomersListScreen(),
          permission: Permissions.viewCustomers,),
      _NavItem(Icons.location_city, l.governments, const GovernmentsListScreen(),
          permission: Permissions.viewGovernments,),
      _NavItem(Icons.person_search, l.contenders, const ContendersListScreen(),
          permission: Permissions.viewContenders,),
      _NavItem(Icons.badge, l.employees, const EmployeesListScreen(),
          permission: Permissions.viewEmployees,),
      _NavItem(Icons.account_balance, l.courts, const CourtsListScreen(),
          permission: Permissions.viewCourts,),
      _NavItem(Icons.event, l.hearings, const HearingsListScreen(),
          permission: Permissions.viewHearings,),
      _NavItem(Icons.description, l.judicialDocuments,
          const JudicialDocumentsListScreen(),
          permission: Permissions.viewJudicial,),
      _NavItem(Icons.calendar_today, l.calendar, const CalendarScreen(),
          permission: Permissions.viewCalendar,),
      _NavItem(Icons.task_alt, l.tasks, const TasksListScreen(),
          permission: Permissions.viewTasks,),
      _NavItem(Icons.receipt, l.billing, const BillingListScreen(),
          permission: Permissions.viewBilling,),
      _NavItem(Icons.savings, l.trustAccounting, const TrustListScreen(),
          permission: Permissions.viewTrustAccounting,),
      _NavItem(Icons.timer, l.timeTracking, const TimeTrackingListScreen(),
          permission: Permissions.viewTimeTracking,),
      _NavItem(Icons.chat_bubble_outline, l.consultations,
          const ConsultationsListScreen(),
          permission: Permissions.viewConsultations,),
      _NavItem(Icons.description, l.documents, const DocumentsListScreen(),
          permission: Permissions.viewDocuments,),
      _NavItem(Icons.hub, l.clientPortal, const PortalOverviewScreen(),
          permission: Permissions.viewClientPortal,),
      _NavItem(Icons.bar_chart, l.reports, const ReportsScreen(),
          permission: Permissions.viewReports,),
      _NavItem(Icons.supervisor_account, l.users, const UsersListScreen(),
          permission: Permissions.manageUsers,),
      _NavItem(Icons.apartment, l.tenants, const TenantsListScreen(),
          permission: Permissions.manageTenants,),
      _NavItem(Icons.assignment_ind, l.intake, const IntakeLeadsListScreen(),
          permission: Permissions.viewIntake,),
      _NavItem(Icons.folder_open, l.files, const FilesListScreen(),
          permission: Permissions.viewFiles,),
      _NavItem(Icons.draw, l.eSignatures, const ESignListScreen(),
          permission: Permissions.viewESign,),
      _NavItem(Icons.smart_toy, l.aiAssistant, const AiAssistantScreen(),
          permission: Permissions.viewAiAssistant,),
      _NavItem(Icons.create_new_folder, l.documentGeneration,
          const DocGenerationScreen(),
          permission: Permissions.viewDocumentGeneration,),
      _NavItem(Icons.gavel, l.courtAutomation, const CourtAutomationScreen(),
          permission: Permissions.viewCourtAutomation,),
      _NavItem(Icons.event_seat, l.sitings, const SitingsListScreen(),
          permission: Permissions.viewSitings,),
      _NavItem(Icons.queue, l.myQueue, const WorkqueueScreen(),
          permission: Permissions.viewWorkqueue,),
      _NavItem(Icons.admin_panel_settings, l.administration,
          const AdministrationScreen(),
          permission: Permissions.manageAdministration,),
      _NavItem(Icons.subscriptions, l.subscription, const SubscriptionScreen(),
          permission: Permissions.manageSubscription,),
      _NavItem(Icons.bar_chart, l.trustReports, const TrustReportsScreen(),
          permission: Permissions.viewTrustReports,),
      _NavItem(Icons.history, l.auditLogs, const AuditLogsScreen(),
          permission: Permissions.viewAuditLogs,),
      // Always visible to authenticated non-customer users.
      _NavItem(Icons.notifications, l.notifications,
          const NotificationsInboxScreen(),),
      _NavItem(Icons.info_outline, l.aboutUs, const AboutScreen()),
      _NavItem(Icons.contact_mail, l.contactUs, const ContactScreen()),
      _NavItem(Icons.settings, l.settings, const SettingsScreen()),
    ];

    return all.where((item) {
      if (item.permission == null) return true;
      return session.hasPermission(item.permission!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;
    final items = _buildNavItems(localizer, session);

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Text(localizer.accessDenied,
              style: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w700,),),
        ),
      );
    }

    if (_selectedIndex >= items.length) _selectedIndex = 0;

    final currentItem = items[_selectedIndex];
    final unreadCount = context.select<NotificationsBloc, int>((bloc) {
      final s = bloc.state;
      if (s is NotificationsLoaded) return s.unreadCount;
      return 0;
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          currentItem.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Notifications bell
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white),),
              backgroundColor: Colors.red,
              child: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
            ),
            onPressed: () {
              setState(() {
                _selectedIndex =
                    items.indexWhere((i) => i.page is NotificationsInboxScreen);
                if (_selectedIndex < 0) _selectedIndex = 0;
              });
            },
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _kGold,
                child: Text(
                  (session?.fullName.isNotEmpty ?? false
                          ? session!.fullName[0]
                          : session?.email[0] ?? 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _kPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      drawer: _AppDrawer(
        items: items,
        selectedIndex: _selectedIndex,
        session: session,
        onItemTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
        onLogout: () {
          Navigator.pop(context);
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      floatingActionButton: _buildFab(context, currentItem, session),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: currentItem.page,
        ),
      ),
    );
  }
}

// Sidebar Drawer
class _AppDrawer extends StatelessWidget {

  const _AppDrawer({
    required this.items,
    required this.selectedIndex,
    required this.session,
    required this.onItemTap,
    required this.onLogout,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final UserSession? session;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initials = (session?.fullName.isNotEmpty ?? false
            ? session!.fullName[0]
            : session?.email[0] ?? 'U')
        .toUpperCase();
    final displayName = (session?.fullName.isNotEmpty ?? false)
        ? session!.fullName
        : session?.email ?? '';

    return Drawer(
      backgroundColor: _kBg,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Column(
        children: [
          // ── Compact profile card ─────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _kGold,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (session != null)
                          _RoleBadge(session: session!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav items ────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onItemTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11,),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kPrimary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: _kPrimary.withValues(alpha: 0.25),)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _kPrimary
                                    : _kPrimary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : _kPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? _kPrimary : _kText,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: _kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Logout ──────────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {

  _NavItem(this.icon, this.label, this.page, {this.permission});
  final IconData icon;
  final String label;
  final Widget page;
  final String? permission;
}

/// Role badge shown in the compact profile card.
/// SuperAdmin gets a gold badge; others get a white-tinted badge.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.session});
  final UserSession session;

  @override
  Widget build(BuildContext context) {
    final roleLabel = session.isSuperAdmin()
        ? 'Super Admin'
        : session.isAdmin()
            ? 'Admin'
            : session.isEmployee()
                ? 'Employee'
                : 'Customer';
    final badgeColor = session.isSuperAdmin()
        ? _kGold
        : Colors.white.withValues(alpha: 0.22);
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        roleLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
