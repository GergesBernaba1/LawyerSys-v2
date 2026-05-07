import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
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
import 'core/sync/conflict_resolver.dart';
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
import 'features/cases/screens/cases_list_screen.dart';
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
import 'features/settings/screens/profile_screen.dart';
import 'features/tasks/bloc/tasks_bloc.dart';
import 'features/tasks/repositories/tasks_repository.dart';
import 'features/tasks/screens/tasks_list_screen.dart';
import 'features/timetracking/bloc/timetracking_bloc.dart';
import 'features/timetracking/repositories/timetracking_repository.dart';
import 'features/timetracking/screens/timetracking_list_screen.dart';
import 'features/trust-accounting/bloc/trust_accounting_bloc.dart';
import 'features/trust-accounting/repositories/trust_accounting_repository.dart';
import 'features/contenders/bloc/contenders_bloc.dart';
import 'features/contenders/repositories/contenders_repository.dart';
import 'features/employees/bloc/employees_bloc.dart';
import 'features/employees/repositories/employees_repository.dart';
import 'features/consultations/bloc/consultations_bloc.dart';
import 'features/consultations/repositories/consultations_repository.dart';
import 'features/reports/bloc/reports_bloc.dart';
import 'features/reports/repositories/reports_repository.dart';
import 'features/governments/bloc/governments_bloc.dart';
import 'features/governments/repositories/governments_repository.dart';
import 'features/tenants/bloc/tenants_bloc.dart';
import 'features/tenants/repositories/tenants_repository.dart';
import 'features/tenants/screens/tenants_list_screen.dart';
import 'features/trust-accounting/screens/trust_list_screen.dart';
import 'features/intake/bloc/intake_bloc.dart';
import 'features/intake/bloc/intake_event.dart';
import 'features/intake/repositories/intake_repository.dart';
import 'features/intake/screens/intake_leads_list_screen.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/users/repositories/users_repository.dart';
import 'package:qadaya_lawyersys/features/users/screens/users_list_screen.dart';
import 'features/files/bloc/files_bloc.dart';
import 'features/files/repositories/files_repository.dart';
import 'features/files/screens/files_list_screen.dart';
import 'features/esign/bloc/esign_bloc.dart';
import 'features/esign/repositories/esign_repository.dart';
import 'features/esign/screens/esign_list_screen.dart';
import 'features/ai-assistant/bloc/ai_assistant_bloc.dart';
import 'features/ai-assistant/repositories/ai_assistant_repository.dart';
import 'features/ai-assistant/screens/ai_assistant_screen.dart';
import 'features/auditlogs/bloc/audit_logs_bloc.dart';
import 'features/auditlogs/repositories/audit_logs_repository.dart';
import 'features/auditlogs/screens/audit_logs_screen.dart';
import 'features/sitings/bloc/sitings_bloc.dart';
import 'features/sitings/repositories/sitings_repository.dart';
import 'features/sitings/screens/sitings_list_screen.dart';
import 'features/about/screens/about_screen.dart';
import 'features/contact/screens/contact_screen.dart';
import 'features/document-generation/bloc/doc_generation_bloc.dart';
import 'features/document-generation/repositories/doc_generation_repository.dart';
import 'features/document-generation/screens/doc_generation_screen.dart';
import 'features/court-automation/bloc/court_automation_bloc.dart';
import 'features/court-automation/repositories/court_automation_repository.dart';
import 'features/court-automation/screens/court_automation_screen.dart';
import 'features/workqueue/bloc/workqueue_bloc.dart';
import 'features/workqueue/repositories/workqueue_repository.dart';
import 'features/workqueue/screens/workqueue_screen.dart';
import 'features/administration/bloc/administration_bloc.dart';
import 'features/administration/repositories/administration_repository.dart';
import 'features/administration/screens/administration_screen.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/subscription/repositories/subscription_repository.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'features/trust-reports/bloc/trust_reports_bloc.dart';
import 'features/trust-reports/repositories/trust_reports_repository.dart';
import 'features/trust-reports/screens/trust_reports_screen.dart';
import 'shared/screens/main_screen.dart';
import 'shared/screens/splash_screen.dart';
import 'shared/screens/unauthorized_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  bool _canAccessRoute(String? route, UserSession? session) {
    if (route == null) return false;

    final routePermissions = <String, String?>{
      '/': null,
      '/login': null,
      '/register': null,
      '/forgot-password': null,
      '/reset-password': null,
      '/main': null,
      '/dashboard': null,
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
      '/settings': null,
      '/profile': null,
      '/users': null,
      '/tenants': null,
      '/documents': Permissions.dashboard,
      '/intake': null,
      '/files': Permissions.dashboard,
      '/esign': null,
      '/ai-assistant': null,
      '/audit-logs': null,
      '/sitings': null,
      '/about': null,
      '/contact': null,
      '/document-generation': null,
      '/court-automation': null,
      '/workqueue': null,
      '/administration': null,
      '/subscription': null,
      '/trust-reports': Permissions.viewBilling,
    };

    final requiredPermission = routePermissions[route];
    if (requiredPermission == null) return true;
    return session?.hasPermission(requiredPermission) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final localDatabase = LocalDatabase.instance;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(apiClient)),
        RepositoryProvider(
            create: (_) => DashboardRepository(apiClient, localDatabase)),
        RepositoryProvider(
            create: (_) => CasesRepository(apiClient, localDatabase)),
        RepositoryProvider(create: (_) => TasksRepository(apiClient)),
        RepositoryProvider(create: (_) => CalendarRepository(apiClient)),
        RepositoryProvider(create: (_) => TimeTrackingRepository(apiClient)),
        RepositoryProvider(create: (_) => CourtsRepository(apiClient)),
        RepositoryProvider(create: (_) => BillingRepository(apiClient)),
        RepositoryProvider(create: (_) => CustomersRepository(apiClient)),
        RepositoryProvider(create: (_) => TrustAccountingRepository(apiClient)),
        RepositoryProvider(create: (_) => ClientPortalRepository(apiClient)),
        RepositoryProvider(
            create: (_) => HearingsRepository(apiClient, localDatabase)),
        RepositoryProvider(create: (_) => ContendersRepository(apiClient)),
        RepositoryProvider(create: (_) => ConsultationsRepository(apiClient)),
        RepositoryProvider(create: (_) => ReportsRepository(apiClient)),
        RepositoryProvider(create: (_) => UsersRepository(apiClient)),
        RepositoryProvider(create: (_) => TenantsRepository(apiClient)),
        RepositoryProvider(create: (_) => GovernmentsRepository(apiClient)),
        RepositoryProvider(
            create: (_) => EmployeesRepository(apiClient, localDatabase)),
        RepositoryProvider(create: (_) => IntakeRepository(apiClient)),
        RepositoryProvider(create: (_) => FilesRepository(apiClient)),
        RepositoryProvider(create: (_) => ESignRepository(apiClient)),
        RepositoryProvider(create: (_) => AiAssistantRepository(apiClient)),
        RepositoryProvider(create: (_) => AuditLogsRepository(apiClient)),
        RepositoryProvider(create: (_) => SitingsRepository(apiClient: apiClient)),
        RepositoryProvider(create: (_) => DocGenerationRepository(apiClient)),
        RepositoryProvider(create: (_) => CourtAutomationRepository(apiClient)),
        RepositoryProvider(create: (_) => WorkqueueRepository(apiClient)),
        RepositoryProvider(create: (_) => AdministrationRepository(apiClient)),
        RepositoryProvider(create: (_) => SubscriptionRepository(apiClient)),
        RepositoryProvider(create: (_) => TrustReportsRepository(apiClient)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (ctx) => ThemeCubit(PreferencesStorage.instance)),
          BlocProvider(
              create: (ctx) => AuthBloc(
                  authRepository: RepositoryProvider.of<AuthRepository>(ctx))),
          BlocProvider(
              create: (ctx) => DashboardBloc(
                  dashboardRepository:
                      RepositoryProvider.of<DashboardRepository>(ctx))),
          BlocProvider(
              create: (ctx) => CasesBloc(
                  casesRepository:
                      RepositoryProvider.of<CasesRepository>(ctx))),
          BlocProvider(
              create: (ctx) => TrustAccountingBloc(
                  trustAccountingRepository:
                      RepositoryProvider.of<TrustAccountingRepository>(ctx))),
          BlocProvider(
              create: (ctx) => ClientPortalBloc(
                  clientPortalRepository:
                      RepositoryProvider.of<ClientPortalRepository>(ctx))),
          BlocProvider(
              create: (ctx) => TasksBloc(
                  tasksRepository:
                      RepositoryProvider.of<TasksRepository>(ctx))),
          BlocProvider(
              create: (ctx) => CalendarBloc(
                  calendarRepository:
                      RepositoryProvider.of<CalendarRepository>(ctx))),
          BlocProvider(
              create: (ctx) => TimeTrackingBloc(
                  timeTrackingRepository:
                      RepositoryProvider.of<TimeTrackingRepository>(ctx))),
          BlocProvider(
              create: (ctx) => CourtsBloc(
                  courtsRepository:
                      RepositoryProvider.of<CourtsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => BillingBloc(
                  billingRepository:
                      RepositoryProvider.of<BillingRepository>(ctx))),
          BlocProvider(
              create: (ctx) => CustomersBloc(
                  customersRepository:
                      RepositoryProvider.of<CustomersRepository>(ctx))),
          BlocProvider(
              create: (ctx) => HearingsBloc(
                  hearingsRepository:
                      RepositoryProvider.of<HearingsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => ContendersBloc(
                  contendersRepository:
                      RepositoryProvider.of<ContendersRepository>(ctx))),
          BlocProvider(
              create: (ctx) => ConsultationsBloc(
                  consultationsRepository:
                      RepositoryProvider.of<ConsultationsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => ReportsBloc(
                  repository: RepositoryProvider.of<ReportsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => EmployeesBloc(
                  employeesRepository:
                      RepositoryProvider.of<EmployeesRepository>(ctx))),
          BlocProvider(
              create: (ctx) => GovernmentsBloc(
                  governmentsRepository:
                      RepositoryProvider.of<GovernmentsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => UsersBloc(
                  usersRepository: RepositoryProvider.of<UsersRepository>(ctx))),
          BlocProvider(
              create: (ctx) => TenantsBloc(
                  tenantsRepository:
                      RepositoryProvider.of<TenantsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => IntakeBloc(
                  repository: RepositoryProvider.of<IntakeRepository>(ctx))
                ..add(LoadIntakeLeads())),
          BlocProvider(
              create: (ctx) => FilesBloc(
                  filesRepository: RepositoryProvider.of<FilesRepository>(ctx))),
          BlocProvider(
              create: (ctx) => ESignBloc(
                  repository: RepositoryProvider.of<ESignRepository>(ctx))),
          BlocProvider(
              create: (ctx) => AiAssistantBloc(
                  repository: RepositoryProvider.of<AiAssistantRepository>(ctx))),
          BlocProvider(
              create: (ctx) => AuditLogsBloc(
                  repository: RepositoryProvider.of<AuditLogsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => SitingsBloc(
                  repository: RepositoryProvider.of<SitingsRepository>(ctx))),
          BlocProvider(
              create: (ctx) => DocGenerationBloc(
                  repository: RepositoryProvider.of<DocGenerationRepository>(ctx))),
          BlocProvider(
              create: (ctx) => CourtAutomationBloc(
                  repository: RepositoryProvider.of<CourtAutomationRepository>(ctx))),
          BlocProvider(
              create: (ctx) => WorkqueueBloc(
                  repository: RepositoryProvider.of<WorkqueueRepository>(ctx))),
          BlocProvider(
              create: (ctx) => AdministrationBloc(
                  repository: RepositoryProvider.of<AdministrationRepository>(ctx))),
          BlocProvider(
              create: (ctx) => SubscriptionBloc(
                  repository: RepositoryProvider.of<SubscriptionRepository>(ctx))),
          BlocProvider(
              create: (ctx) => TrustReportsBloc(
                  repository: RepositoryProvider.of<TrustReportsRepository>(ctx))),
          BlocProvider(
              create: (_) => NotificationsBloc(
                  notificationsRepository: NotificationsRepository(
                      LocalDatabase.instance, apiClient))),
        ],
        child: _AppInitializer(canAccessRoute: _canAccessRoute),
      ),
    );
  }
}

/// Lives inside the provider tree so it can safely access repositories and blocs.
class _AppInitializer extends StatefulWidget {
  final bool Function(String?, UserSession?) canAccessRoute;
  const _AppInitializer({required this.canAccessRoute});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  Locale _locale = const Locale('ar');
  bool _localeLoaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Capture context-dependent values before any await
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final apiClient = ApiClient();

    // Load saved locale
    final langCode = await PreferencesStorage().getLanguageCode();
    if (mounted) {
      setState(() {
        _locale = (langCode?.isNotEmpty == true)
            ? Locale(langCode!)
            : const Locale('ar');
        _localeLoaded = true;
      });
    }

    final pushService = PushNotificationService();
    pushService.configure(
      authRepository,
      notificationsRepository:
          NotificationsRepository(LocalDatabase.instance, apiClient),
    );
    pushService.init();

    final signalRService = SignalRService();
    try {
      final token = await SecureStorage().read(SecureStorage.keyAccessToken);
      signalRService.init(
        '${ApiConstants.apiRoot}${ApiConstants.signalRHub}',
        tokenFactory: token != null ? () async => token : null,
      );
    } catch (_) {
      signalRService.init('${ApiConstants.apiRoot}${ApiConstants.signalRHub}');
    }

    if (mounted) {
      SyncService()
          .syncPendingOperations(
        (local, remote) => showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => ConflictResolverWidget(
            entityName: 'Case',
            localData: local,
            remoteData: remote,
          ),
        ),
      )
          .catchError((error) {
        debugPrint('Startup sync failed: $error');
      });
    }

    ConnectivityService().startListening();
  }

  @override
  void dispose() {
    ConnectivityService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeLoaded) {
      return const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      );
    }

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Qadaya LawyerSys',
          navigatorKey: PushNotificationService.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: _locale,
      localeResolutionCallback: (currentLocale, supportedLocales) {
        if (currentLocale == null) return const Locale('ar');
        for (final supported in supportedLocales) {
          if (supported.languageCode == currentLocale.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      builder: (context, child) {
        final loc = Localizations.localeOf(context);
        final dir =
            loc.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
        return Directionality(
            textDirection: dir, child: child ?? const SizedBox.shrink());
      },
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final authState = context.read<AuthBloc>().state;
        final session =
            authState is AuthAuthenticated ? authState.session : null;

        if (!widget.canAccessRoute(settings.name, session)) {
          return MaterialPageRoute(builder: (_) => const UnauthorizedScreen());
        }

        // ── Deep-link / parameterized route handling ──────────────────────────────
        final rawPath = settings.name ?? '';
        final segments = rawPath.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.length == 2) {
          final entityType = segments[0];
          // final entityId   = segments[1];
          switch (entityType) {
            case 'cases':
              // CaseDetailScreen requires a full CaseModel, not just an ID.
              // Fall back to the cases list screen for deep links.
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CasesListScreen(),
              );
          }
        }
        // ── end deep-link handling ────────────────────────────────────────────────

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen());
          case '/reset-password':
            return MaterialPageRoute(builder: (_) => const _ResetScreen());
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/tasks':
            return MaterialPageRoute(builder: (_) => const TasksListScreen());
          case '/calendar':
            return MaterialPageRoute(builder: (_) => const CalendarScreen());
          case '/hearings':
            return MaterialPageRoute(
                builder: (_) => const HearingsListScreen());
          case '/courts':
            return MaterialPageRoute(builder: (_) => const CourtsListScreen());
          case '/timetracking':
            return MaterialPageRoute(
                builder: (_) => const TimeTrackingListScreen());
          case '/billing':
            return MaterialPageRoute(builder: (_) => const BillingListScreen());
          case '/trust-accounting':
            return MaterialPageRoute(builder: (_) => const TrustListScreen());
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
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/users':
            return MaterialPageRoute(builder: (_) => const UsersListScreen());
          case '/tenants':
            return MaterialPageRoute(builder: (_) => const TenantsListScreen());
          case '/documents':
            return MaterialPageRoute(
                builder: (_) => const DocumentsListScreen());
          case '/intake':
            return MaterialPageRoute(
                builder: (_) => const IntakeLeadsListScreen());
          case '/files':
            return MaterialPageRoute(builder: (_) => const FilesListScreen());
          case '/esign':
            return MaterialPageRoute(builder: (_) => const ESignListScreen());
          case '/ai-assistant':
            return MaterialPageRoute(builder: (_) => const AiAssistantScreen());
          case '/audit-logs':
            return MaterialPageRoute(builder: (_) => const AuditLogsScreen());
          case '/sitings':
            return MaterialPageRoute(builder: (_) => const SitingsListScreen());
          case '/about':
            return MaterialPageRoute(builder: (_) => const AboutScreen());
          case '/contact':
            return MaterialPageRoute(builder: (_) => const ContactScreen());
          case '/document-generation':
            return MaterialPageRoute(
                builder: (_) => const DocGenerationScreen());
          case '/court-automation':
            return MaterialPageRoute(
                builder: (_) => const CourtAutomationScreen());
          case '/workqueue':
            return MaterialPageRoute(builder: (_) => const WorkqueueScreen());
          case '/administration':
            return MaterialPageRoute(
                builder: (_) => const AdministrationScreen());
          case '/subscription':
            return MaterialPageRoute(
                builder: (_) => const SubscriptionScreen());
          case '/trust-reports':
            return MaterialPageRoute(
                builder: (_) => const TrustReportsScreen());
          default:
            return null;
        }
      },
    );
      },
    );
  }
}

class _ResetScreen extends StatelessWidget {
  const _ResetScreen();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};
    return ResetPasswordScreen(
        email: args['email'] ?? '', token: args['token'] ?? '');
  }
}


