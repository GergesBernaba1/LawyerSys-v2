import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api/api_client.dart';
import 'core/api/api_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/realtime/signalr_service.dart';
import 'core/storage/local_database.dart';
import 'core/storage/secure_storage.dart';
import 'core/sync/sync_service.dart';
import 'core/storage/preferences_storage.dart';
import 'core/localization/app_localizations.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/authentication/repositories/auth_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/repositories/dashboard_repository.dart';
import 'features/cases/bloc/cases_bloc.dart';
import 'features/cases/repositories/cases_repository.dart';
import 'features/tasks/bloc/tasks_bloc.dart';
import 'features/tasks/repositories/tasks_repository.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/calendar/repositories/calendar_repository.dart';
import 'features/timetracking/bloc/timetracking_bloc.dart';
import 'features/timetracking/repositories/timetracking_repository.dart';
import 'features/billing/bloc/billing_bloc.dart';
import 'features/billing/repositories/billing_repository.dart';
import 'features/customers/bloc/customers_bloc.dart';
import 'features/customers/repositories/customers_repository.dart';
import 'features/hearings/bloc/hearings_bloc.dart';
import 'features/hearings/repositories/hearings_repository.dart';
import 'features/notifications/bloc/notifications_bloc.dart';
import 'features/notifications/repositories/notifications_repository.dart';
import 'features/documents/screens/documents_list_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/register_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/reset_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/tasks/screens/tasks_list_screen.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/timetracking/screens/timetracking_list_screen.dart';
import 'features/billing/screens/billing_list_screen.dart';
import 'features/customers/screens/customers_list_screen.dart';
import 'features/hearings/screens/hearings_list_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'shared/screens/main_screen.dart';
import 'shared/screens/splash_screen.dart';


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _notificationsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      final authRepository = RepositoryProvider.of<AuthRepository>(context);

      final pushService = PushNotificationService();
      pushService.configure(
        authRepository,
        notificationsRepository: NotificationsRepository(LocalDatabase.instance),
      );
      pushService.init();

      final signalRService = SignalRService();
      SecureStorage().read(SecureStorage.keyAccessToken).then((token) {
        signalRService.init('${ApiConstants.baseUrl}${ApiConstants.signalRHub}', accessToken: token);
      }).catchError((error) {
        signalRService.init('${ApiConstants.baseUrl}${ApiConstants.signalRHub}');
      });

      // Automatically attempt to sync pending offline changes when possible
      SyncService().syncPendingOperations(context).catchError((error) {
        debugPrint('Startup sync failed: $error');
      });

      ConnectivityService().startListening();
    }
  }

  @override
  void dispose() {
    ConnectivityService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final localDatabase = LocalDatabase.instance;
    final preferencesStorage = PreferencesStorage();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(apiClient)),
        RepositoryProvider(create: (_) => DashboardRepository(apiClient, localDatabase)),
        RepositoryProvider(create: (_) => CasesRepository(apiClient, localDatabase)),
        RepositoryProvider(create: (_) => TasksRepository(apiClient)),
        RepositoryProvider(create: (_) => CalendarRepository(apiClient)),
        RepositoryProvider(create: (_) => TimeTrackingRepository(apiClient)),
        RepositoryProvider(create: (_) => BillingRepository(apiClient)),
        RepositoryProvider(create: (_) => CustomersRepository(apiClient)),
        RepositoryProvider(create: (_) => HearingsRepository(apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(authRepository: RepositoryProvider.of<AuthRepository>(context))),
          BlocProvider(create: (context) => DashboardBloc(dashboardRepository: RepositoryProvider.of<DashboardRepository>(context))),
          BlocProvider(create: (context) => CasesBloc(casesRepository: RepositoryProvider.of<CasesRepository>(context))),
          BlocProvider(create: (context) => TasksBloc(tasksRepository: RepositoryProvider.of<TasksRepository>(context))),
          BlocProvider(create: (context) => CalendarBloc(calendarRepository: RepositoryProvider.of<CalendarRepository>(context))),
          BlocProvider(create: (context) => TimeTrackingBloc(timeTrackingRepository: RepositoryProvider.of<TimeTrackingRepository>(context))),
          BlocProvider(create: (context) => BillingBloc(billingRepository: RepositoryProvider.of<BillingRepository>(context))),
          BlocProvider(create: (context) => CustomersBloc(customersRepository: RepositoryProvider.of<CustomersRepository>(context))),
          BlocProvider(create: (context) => HearingsBloc(hearingsRepository: RepositoryProvider.of<HearingsRepository>(context))),
          BlocProvider(create: (context) => NotificationsBloc(notificationsRepository: NotificationsRepository(LocalDatabase.instance))),
        ],
        child: FutureBuilder<String?>(
          future: preferencesStorage.getLanguageCode(),
          builder: (context, snapshot) {
            final locale = snapshot.data != null && snapshot.data!.isNotEmpty ? Locale(snapshot.data!) : const Locale('en');
            return MaterialApp(
              title: 'LawyerSys Mobile',
              navigatorKey: PushNotificationService.navigatorKey,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('ar')],
              locale: locale,
              localeResolutionCallback: (currentLocale, supportedLocales) {
                if (currentLocale == null) return const Locale('en');
                for (final supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == currentLocale.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              builder: (context, child) {
                final localeContext = Localizations.localeOf(context);
                final textDirection = localeContext.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
                return Directionality(textDirection: textDirection, child: child ?? const SizedBox.shrink());
              },
              initialRoute: '/',
              routes: {
                '/': (_) => const SplashScreen(),
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/forgot-password': (_) => const ForgotPasswordScreen(),
                '/reset-password': (_) => const ResetScreen(),
                '/main': (_) => const MainScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                '/tasks': (_) => const TasksListScreen(),
                '/calendar': (_) => const CalendarScreen(),
                '/hearings': (_) => const HearingsListScreen(),
                '/timetracking': (_) => const TimeTrackingListScreen(),
                '/billing': (_) => const BillingListScreen(),
                '/customers': (_) => const CustomersListScreen(),
                '/settings': (_) => const SettingsScreen(),
                '/documents': (_) => const DocumentsListScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}


// Helper class for reset password screen parameters
class ResetScreen extends StatelessWidget {
  final String email;
  final String token;

  const ResetScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    // Extract email and token from route settings
    final Map<String, String> arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final String emailArg = arguments?['email'] ?? '';
    final String tokenArg = arguments?['token'] ?? '';

    return ResetPasswordScreen(
      email: emailArg,
      token: tokenArg,
    );
  }
}

