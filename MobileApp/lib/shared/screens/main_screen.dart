import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/permissions.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/authentication/bloc/auth_bloc.dart';
import '../../features/authentication/bloc/auth_state.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/cases/screens/cases_list_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/client-portal/screens/portal_messages_screen.dart';
import '../../features/client-portal/screens/portal_documents_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/notifications/screens/notifications_inbox_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/trust-accounting/screens/trust_list_screen.dart';
import '../../core/realtime/signalr_service.dart';
import '../../features/notifications/models/notification.dart' as model;
import '../../features/notifications/bloc/notifications_bloc.dart';
import '../../features/notifications/bloc/notifications_event.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index, int maxIndex) {
    setState(() {
      _selectedIndex = index.clamp(0, maxIndex); // safe fallback
    });
  }

  @override
  void initState() {
    super.initState();

    final signalRService = SignalRService();
    signalRService.events.listen((event) {
      final title = event['title']?.toString() ?? 'Update';
      final message = event['message']?.toString() ?? 'You have a new update';
      final id = event['notificationId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final notification = model.AppNotification(notificationId: id, title: title, message: message);

      if (context.mounted) {
        context.read<NotificationsBloc>().add(NewNotificationReceived(notification));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    final authState = context.select((AuthBloc bloc) => bloc.state);
    final session = authState is AuthAuthenticated ? authState.session : null;

    final navigationItems = <_NavItem>[
      _NavItem(icon: Icons.dashboard, label: localizer.dashboard, page: const DashboardScreen(), permission: Permissions.dashboard),
      _NavItem(icon: Icons.folder, label: localizer.cases, page: const CasesListScreen(), permission: Permissions.viewCases),
      _NavItem(icon: Icons.location_city, label: localizer.court ?? 'Courts', page: const CourtsListScreen(), permission: Permissions.viewCourts),
      _NavItem(icon: Icons.mail_outline, label: localizer.portalMessages ?? 'Client Messages', page: const PortalMessagesScreen(), permission: Permissions.viewClientPortal),
      _NavItem(icon: Icons.folder_shared, label: localizer.portalDocuments ?? 'Client Documents', page: const PortalDocumentsScreen(), permission: Permissions.viewClientPortal),
      _NavItem(icon: Icons.account_balance, label: localizer.trustAccounting ?? 'Trust Accounting', page: const TrustListScreen(), permission: Permissions.viewTrustAccounting),
      _NavItem(icon: Icons.people, label: localizer.customers, page: const CustomersListScreen(), permission: Permissions.viewCustomers),
      _NavItem(icon: Icons.calendar_today, label: localizer.hearings, page: const CalendarScreen(), permission: Permissions.viewHearings),
      _NavItem(icon: Icons.notifications, label: localizer.notifications, page: const NotificationsInboxScreen(), permission: Permissions.viewNotifications),
      _NavItem(icon: Icons.settings, label: localizer.settings, page: const SettingsScreen(), permission: Permissions.manageSettings),
    ];

    final availableItems = navigationItems.where((item) {
      return item.permission == null || (session?.hasPermission(item.permission!) ?? false);
    }).toList();

    if (availableItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(localizer.dashboard)),
        body: Center(child: Text(localizer.accessDenied ?? 'Access denied')),
      );
    }

    if (_selectedIndex >= availableItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: availableItems[_selectedIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index, availableItems.length - 1),
        items: availableItems
            .map((item) => BottomNavigationBarItem(icon: Icon(item.icon), label: item.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;
  final String? permission;

  _NavItem({required this.icon, required this.label, required this.page, this.permission});
}
