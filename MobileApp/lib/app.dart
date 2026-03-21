import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api/api_client.dart';
import 'core/api/api_constants.dart';
import 'core/auth/permissions.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/connectivity_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/realtime/signalr_service.dart';
import 'core/storage/local_database.dart';
import 'core/storage/preferences_storage.dart';
import 'core/storage/secure_storage.dart';
import 'core/sync/sync_service.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/authentication/bloc/auth_state.dart';
import 'features/authentication/models/user_session.dart';
import 'features/authentication/repositories/auth_repository.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/register_screen.dart';
import 'features/authentication/screens/reset_password_screen.dart';
import 'features/billing/bloc/billing_bloc.dart';
import 'features/billing/repositories/billing_repository.dart';
import 'features/billing/screens/billing_list_screen.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/calendar/repositories/calendar_repository.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/cases/bloc/cases_bloc.dart';
import 'features/cases/repositories/cases_repository.dart';
import 'features/client-portal/bloc/client_portal_bloc.dart';
import 'features/client-portal/repositories/client_portal_repository.dart';
import 'features/client-portal/screens/portal_documents_screen.dart';
import 'features/client-portal/screens/portal_messages_screen.dart';
import 'features/courts/bloc/courts_bloc.dart';
import 'features/courts/repositories/courts_repository.dart';
import 'features/courts/screens/courts_list_screen.dart';
import 'features/customers/bloc/customers_bloc.dart';
import 'features/customers/repositories/customers_repository.dart';
import 'features/customers/screens/customers_list_screen.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/repositories/dashboard_repository.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/documents/screens/documents_list_screen.dart';
import 'features/hearings/bloc/hearings_bloc.dart';
import 'features/hearings/repositories/hearings_repository.dart';
import 'features/hearings/screens/hearings_list_screen.dart';
import 'features/notifications/bloc/notifications_bloc.dart';
import 'features/notifications/repositories/notifications_repository.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tasks/bloc/tasks_bloc.dart';
import 'features/tasks/repositories/tasks_repository.dart';
import 'features/tasks/screens/tasks_list_screen.dart';
import 'features/timetracking/bloc/timetracking_bloc.dart';
import 'features/timetracking/repositories/timetracking_repository.dart';
import 'features/timetracking/screens/timetracking_list_screen.dart';
import 'features/trust-accounting/bloc/trust_accounting_bloc.dart';
import 'features/trust-accounting/repositories/trust_accounting_repository.dart';
import 'features/trust-accounting/screens/trust_list_screen.dart';
import 'shared/screens/main_screen.dart';
import 'shared/screens/splash_screen.dart';
import 'shared/screens/unauthorized_screen.dart';

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
        signalRService.init('${ApiConstants.baseUrl}${ApiConstants.signalRHub}',
            accessToken: token);
      }).catchError((error) {
        signalRService.init('${ApiConstants.baseUrl}${ApiConstants.signalRHub}');
      });

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

  bool _canAccessRoute(String? route, UserSession? session) {
    if (route == null) return false;

    final routePermissions = <String, String?>{
      '/': null,
      '/login': null,
      '/register': null,
      '/forgot-password': null,
      '/reset-password': null,
      '/main': null, // MainScreen handles its own permission filtering
      '/dashboard': Permissions.dashboard,
      '/tasks': Permissions.dashboard,
      '/calendar': Permissions.viewHearings,
      '/hearings': Permissions.viewHearings,
      '/courts': Permissions.viewCourts,
      '/timetracking': Permissions.dashboard,
      '/billing': Permissions.viewBilling,
      '/trust-accounting': Permissions.viewTrustAccounting,
      '/client-portal-messages': Permissions.viewClientPortal,
      '/client-portal-documents': Permissions.viewClientPortal,
      '/customers': Permissions.viewCustomers,
      '/settings': Permissions.manageSettings,
      '/documents': Permissions.dashboard,
    };

    final requiredPermission = routePermissions[route];
    if (requiredPermission == null) return true;
    return session?.hasPermission(requiredPermission) ?? false;
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
        RepositoryProvider(create: (_) => CourtsRepository(apiClient)),
        RepositoryProvider(create: (_) => BillingRepository(apiClient)),
        RepositoryProvider(create: (_) => CustomersRepository(apiClient)),
        RepositoryProvider(create: (_) => TrustAccountingRepository(apiClient)),
        RepositoryProvider(create: (_) => ClientPortalRepository(apiClient)),
        RepositoryProvider(create: (_) => HearingsRepository(apiClient, localDatabase)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => AuthBloc(authRepository: RepositoryProvider.of<AuthRepository>(ctx))),
          BlocProvider(create: (ctx) => DashboardBloc(dashboardRepository: RepositoryProvider.of<DashboardRepository>(ctx))),
          BlocProvider(create: (ctx) => CasesBloc(casesRepository: RepositoryProvider.of<CasesRepository>(ctx))),
          BlocProvider(create: (ctx) => TrustAccountingBloc(trustAccountingRepository: RepositoryProvider.of<TrustAccountingRepository>(ctx))),
          BlocProvider(create: (ctx) => ClientPortalBloc(clientPortalRepository: RepositoryProvider.of<ClientPortalRepository>(ctx))),
          BlocProvider(create: (ctx) => TasksBloc(tasksRepository: RepositoryProvider.of<TasksRepository>(ctx))),
          BlocProvider(create: (ctx) => CalendarBloc(calendarRepository: RepositoryProvider.of<CalendarRepository>(ctx))),
          BlocProvider(create: (ctx) => TimeTrackingBloc(timeTrackingRepository: RepositoryProvider.of<TimeTrackingRepository>(ctx))),
          BlocProvider(create: (ctx) => CourtsBloc(courtsRepository: RepositoryProvider.of<CourtsRepository>(ctx))),
          BlocProvider(create: (ctx) => BillingBloc(billingRepository: RepositoryProvider.of<BillingRepository>(ctx))),
          BlocProvider(create: (ctx) => CustomersBloc(customersRepository: RepositoryProvider.of<CustomersRepository>(ctx))),
          BlocProvider(create: (ctx) => HearingsBloc(hearingsRepository: RepositoryProvider.of<HearingsRepository>(ctx))),
          BlocProvider(create: (_) => NotificationsBloc(notificationsRepository: NotificationsRepository(LocalDatabase.instance))),
        ],
        child: FutureBuilder<String?>(
          future: preferencesStorage.getLanguageCode(),
          builder: (context, snapshot) {
            final locale = (snapshot.data?.isNotEmpty == true)
                ? Locale(snapshot.data!)
                : const Locale('en');
            return MaterialApp(
              title: 'LawyerSys Mobile',
              navigatorKey: PushNotificationService.navigatorKey,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF14345A),
                  primary: const Color(0xFF14345A),
                  secondary: const Color(0xFFB98746),
                  surface: Colors.white,
                ),
                scaffoldBackgroundColor: const Color(0xFFEEF4FA),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0F172A),
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                        color: const Color(0xFF14345A).withOpacity(0.08)),
                  ),
                  color: Colors.white,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: const Color(0xFF14345A).withOpacity(0.12)),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14345A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                useMaterial3: true,
              ),
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
                for (final supported in supportedLocales) {
                  if (supported.languageCode == currentLocale.languageCode) {
                    return supported;
                  }
                }
                return supportedLocales.first;
              },
              builder: (context, child) {
                final loc = Localizations.localeOf(context);
                final dir = loc.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr;
                return Directionality(
                    textDirection: dir,
                    child: child ?? const SizedBox.shrink());
              },
              initialRoute: '/',
              onGenerateRoute: (settings) {
                final authState = context.read<AuthBloc>().state;
                final session = authState is AuthAuthenticated
                    ? authState.session
                    : null;

                if (!_canAccessRoute(settings.name, session)) {
                  return MaterialPageRoute(
                      builder: (_) => const UnauthorizedScreen());
                }

                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(
                        builder: (_) => const SplashScreen());
                  case '/login':
                    return MaterialPageRoute(
                        builder: (_) => const LoginScreen());
                  case '/register':
                    return MaterialPageRoute(
                        builder: (_) => const RegisterScreen());
                  case '/forgot-password':
                    return MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen());
                  case '/reset-password':
                    return MaterialPageRoute(
                        builder: (_) => const _ResetScreen());
                  case '/main':
                    return MaterialPageRoute(
                        builder: (_) => const MainScreen());
                  case '/dashboard':
                    return MaterialPageRoute(
                        builder: (_) => const DashboardScreen());
                  case '/tasks':
                    return MaterialPageRoute(
                        builder: (_) => const TasksListScreen());
                  case '/calendar':
                    return MaterialPageRoute(
                        builder: (_) => const CalendarScreen());
                  case '/hearings':
                    return MaterialPageRoute(
                        builder: (_) => const HearingsListScreen());
                  case '/courts':
                    return MaterialPageRoute(
                        builder: (_) => const CourtsListScreen());
                  case '/timetracking':
                    return MaterialPageRoute(
                        builder: (_) => const TimeTrackingListScreen());
                  case '/billing':
                    return MaterialPageRoute(
                        builder: (_) => const BillingListScreen());
                  case '/trust-accounting':
                    return MaterialPageRoute(
                        builder: (_) => const TrustListScreen());
                  case '/client-portal-messages':
                    return MaterialPageRoute(
                        builder: (_) => const PortalMessagesScreen());
                  case '/client-portal-documents':
                    return MaterialPageRoute(
                        builder: (_) => const PortalDocumentsScreen());
                  case '/customers':
                    return MaterialPageRoute(
                        builder: (_) => const CustomersListScreen());
                  case '/settings':
                    return MaterialPageRoute(
                        builder: (_) => const SettingsScreen());
                  case '/documents':
                    return MaterialPageRoute(
                        builder: (_) => const DocumentsListScreen());
                  default:
                    return null;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResetScreen extends StatelessWidget {
  const _ResetScreen();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, String>? ?? {};
    return ResetPasswordScreen(
      email: args['email'] ?? '',
      token: args['token'] ?? '',
    );
  }
}
