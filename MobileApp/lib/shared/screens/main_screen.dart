import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/cases/screens/cases_list_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/notifications/screens/notifications_inbox_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
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

  static final List<Widget> _pages = <Widget>[
    const DashboardScreen(),
    const CasesListScreen(),
    const CustomersListScreen(),
    const CalendarScreen(),
    const NotificationsInboxScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: localizer.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.folder), label: localizer.cases),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: localizer.customers),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: localizer.hearings),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: localizer.notifications),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: localizer.settings),
        ],
      ),
    );
  }
}
