import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/permissions.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/authentication/bloc/auth_bloc.dart';
import '../../features/authentication/bloc/auth_event.dart';
import '../../features/authentication/bloc/auth_state.dart';
import '../../features/authentication/models/user_session.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/cases/screens/cases_list_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/contenders/screens/contenders_list_screen.dart';
import '../../features/courts/screens/courts_list_screen.dart';
import '../../features/governments/screens/governments_list_screen.dart';
import '../../features/judicial/screens/judicial_documents_list_screen.dart';
import '../../features/client-portal/screens/portal_messages_screen.dart';
import '../../features/client-portal/screens/portal_documents_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/notifications/screens/notifications_inbox_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/trust-accounting/screens/trust_list_screen.dart';
import '../../features/billing/screens/billing_list_screen.dart';
import '../../features/tasks/screens/tasks_list_screen.dart';
import '../../features/timetracking/screens/timetracking_list_screen.dart';
import '../../features/employees/screens/employees_list_screen.dart';
import '../../features/hearings/screens/hearings_list_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/consultations/screens/consultations_list_screen.dart';
import '../../features/documents/screens/documents_list_screen.dart';
import '../../features/tenants/screens/tenants_list_screen.dart';
import 'package:qadaya_lawyersys/features/users/screens/users_list_screen.dart';
import '../../features/intake/screens/intake_leads_list_screen.dart';
import '../../features/files/screens/files_list_screen.dart';
import '../../features/esign/screens/esign_list_screen.dart';
import '../../features/ai-assistant/screens/ai_assistant_screen.dart';
import '../../features/auditlogs/screens/audit_logs_screen.dart';
import '../../features/sitings/screens/sitings_list_screen.dart';
import '../../features/about/screens/about_screen.dart';
import '../../features/contact/screens/contact_screen.dart';
import '../../features/document-generation/screens/doc_generation_screen.dart';
import '../../features/court-automation/screens/court_automation_screen.dart';
import '../../features/workqueue/screens/workqueue_screen.dart';
import '../../features/administration/screens/administration_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../features/trust-reports/screens/trust_reports_screen.dart';
import '../../core/realtime/signalr_service.dart';
import '../../features/notifications/models/notification.dart' as model;
import '../../features/notifications/bloc/notifications_bloc.dart';
import '../../features/notifications/bloc/notifications_event.dart';
import '../../features/notifications/bloc/notifications_state.dart';

// Theme constants matching ClientApp
const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kGold = Color(0xFFB98746);
const _kBg = Color(0xFFEEF4FA);
const _kText = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF5F7085);

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
    final bloc = context.read<NotificationsBloc>();
    bloc.add(LoadNotifications());
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
          notificationId: id, title: title, message: message);
      if (mounted) bloc.add(NewNotificationReceived(notification));
    });
  }

  @override
  void dispose() {
    _signalRSub?.cancel();
    super.dispose();
  }

  List<_NavItem> _buildNavItems(AppLocalizations l, UserSession? session) {
    final isCustomer = session?.hasRole('Customer') == true &&
        session?.hasRole('Admin') != true &&
        session?.hasRole('Employee') != true &&
        session?.hasRole('SuperAdmin') != true;
    final isEmployee = session?.hasRole('Employee') == true &&
        session?.hasRole('Admin') != true &&
        session?.hasRole('SuperAdmin') != true;

    if (isCustomer) {
      return [
        _NavItem(Icons.dashboard, l.dashboard, const DashboardScreen()),
        _NavItem(Icons.folder, l.cases, const CasesListScreen()),
        _NavItem(
            Icons.mail_outline, l.portalMessages, const PortalMessagesScreen()),
        _NavItem(Icons.folder_shared, l.portalDocuments,
            const PortalDocumentsScreen()),
        _NavItem(Icons.notifications, l.notifications,
            const NotificationsInboxScreen()),
        _NavItem(Icons.settings, l.settings, const SettingsScreen()),
      ];
    }

    final canAccessEmployees = session?.hasRole('SuperAdmin') == true ||
        session?.hasRole('Admin') == true ||
        session?.hasAnyPermission(
              [Permissions.createEmployees, Permissions.editEmployees],
            ) ==
            true;
    final canAccessAdminModules =
        session?.hasRole('SuperAdmin') == true || session?.hasRole('Admin') == true;

    final all = <_NavItem>[
      _NavItem(Icons.dashboard, l.dashboard, const DashboardScreen()),
      _NavItem(Icons.gavel, l.cases, const CasesListScreen(),
          permission: Permissions.viewCases),
      _NavItem(Icons.people, l.customers, const CustomersListScreen(),
          permission: Permissions.viewCustomers),
      _NavItem(Icons.location_city, l.governments, const GovernmentsListScreen()),
      _NavItem(Icons.person_search, l.contenders, const ContendersListScreen()),
      if (!isEmployee && canAccessEmployees)
        _NavItem(Icons.badge, l.employees, const EmployeesListScreen()),
      _NavItem(Icons.account_balance, l.courts, const CourtsListScreen(),
          permission: Permissions.viewCourts),
      _NavItem(Icons.event, l.hearings, const HearingsListScreen(),
          permission: Permissions.viewHearings),
      _NavItem(Icons.description, l.judicial, const JudicialDocumentsListScreen()),
      _NavItem(Icons.calendar_today, l.calendar, const CalendarScreen(),
          permission: Permissions.viewHearings),
      _NavItem(Icons.task_alt, l.tasks, const TasksListScreen()),
      _NavItem(Icons.receipt, l.billing, const BillingListScreen(),
          permission: Permissions.viewBilling),
      _NavItem(Icons.savings, l.trustAccounting, const TrustListScreen(),
          permission: Permissions.viewTrustAccounting),
      _NavItem(Icons.timer, l.timeTracking, const TimeTrackingListScreen()),
      _NavItem(Icons.chat_bubble_outline, l.consultations,
          const ConsultationsListScreen()),
      _NavItem(Icons.description, l.documents, const DocumentsListScreen()),
      _NavItem(Icons.mail_outline, l.portalMessages, const PortalMessagesScreen(),
          permission: Permissions.viewClientPortal),
      _NavItem(Icons.folder_shared, l.portalDocuments, const PortalDocumentsScreen(),
          permission: Permissions.viewClientPortal),
      _NavItem(Icons.bar_chart, l.reports, const ReportsScreen()),
      if (canAccessAdminModules)
        _NavItem(Icons.supervisor_account, 'Users', const UsersListScreen()),
      if (canAccessAdminModules)
        _NavItem(Icons.apartment, 'Tenants', const TenantsListScreen()),
      _NavItem(Icons.assignment_ind, 'Intake', const IntakeLeadsListScreen()),
      _NavItem(Icons.folder_open, 'Files', const FilesListScreen()),
      _NavItem(Icons.draw, 'E-Sign', const ESignListScreen()),
      _NavItem(Icons.smart_toy, 'AI Assistant', const AiAssistantScreen()),
      _NavItem(Icons.create_new_folder, 'Document Generation', const DocGenerationScreen()),
      _NavItem(Icons.gavel, 'Court Automation', const CourtAutomationScreen()),
      _NavItem(Icons.event_seat, 'Sitings', const SitingsListScreen()),
      _NavItem(Icons.queue, 'My Queue', const WorkqueueScreen()),
      if (canAccessAdminModules) ...[
        _NavItem(Icons.admin_panel_settings, 'Administration', const AdministrationScreen()),
        _NavItem(Icons.subscriptions, 'Subscription', const SubscriptionScreen()),
        _NavItem(Icons.bar_chart, 'Trust Reports', const TrustReportsScreen()),
        _NavItem(Icons.history, 'Audit Logs', const AuditLogsScreen()),
      ],
      _NavItem(Icons.info_outline, 'About', const AboutScreen()),
      _NavItem(Icons.contact_mail, 'Contact', const ContactScreen()),
      _NavItem(Icons.notifications, l.notifications,
          const NotificationsInboxScreen(),
          permission: Permissions.viewNotifications),
      _NavItem(Icons.settings, l.settings, const SettingsScreen()),
    ];

    return all.where((item) {
      if (item.permission == null) return true;
      return session?.hasPermission(item.permission!) ?? false;
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
                  color: _kPrimary, fontWeight: FontWeight.w700)),
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
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
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
                  (session?.fullName.isNotEmpty == true
                          ? session!.fullName[0]
                          : session?.email[0] ?? 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
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
  final List<_NavItem> items;
  final int selectedIndex;
  final UserSession? session;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.items,
    required this.selectedIndex,
    required this.session,
    required this.onItemTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimary, _kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gavel,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'LawyerSys',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _kGold,
                  child: Text(
                    (session?.fullName.isNotEmpty == true
                            ? session!.fullName[0]
                            : session?.email[0] ?? 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session?.fullName ?? session?.email ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                if (session?.roles.isNotEmpty == true)
                  Text(
                    session!.roles.first,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onItemTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [_kPrimary, _kPrimaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _kPrimary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color:
                                  isSelected ? Colors.white : _kTextSecondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _kText,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 14.5,
                                ),
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

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onLogout,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 22),
                      const SizedBox(width: 14),
                      Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5),
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
  final IconData icon;
  final String label;
  final Widget page;
  final String? permission;

  _NavItem(this.icon, this.label, this.page, {this.permission});
}


