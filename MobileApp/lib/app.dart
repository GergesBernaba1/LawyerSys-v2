import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/network/connectivity_service.dart';
import 'package:qadaya_lawyersys/core/notifications/push_notification_service.dart';
import 'package:qadaya_lawyersys/core/realtime/signalr_service.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/core/storage/preferences_storage.dart';
import 'package:qadaya_lawyersys/core/storage/secure_storage.dart';
import 'package:qadaya_lawyersys/core/sync/conflict_resolver.dart';
import 'package:qadaya_lawyersys/core/sync/sync_service.dart';
import 'package:qadaya_lawyersys/core/theme/app_theme.dart';
import 'package:qadaya_lawyersys/core/theme/theme_cubit.dart';
import 'package:qadaya_lawyersys/features/about/screens/about_screen.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_bloc.dart';
import 'package:qadaya_lawyersys/features/administration/repositories/administration_repository.dart';
import 'package:qadaya_lawyersys/features/administration/screens/administration_screen.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/bloc/ai_assistant_bloc.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/repositories/ai_assistant_repository.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/screens/ai_assistant_screen.dart';
import 'package:qadaya_lawyersys/features/auditlogs/bloc/audit_logs_bloc.dart';
import 'package:qadaya_lawyersys/features/auditlogs/repositories/audit_logs_repository.dart';
import 'package:qadaya_lawyersys/features/auditlogs/screens/audit_logs_screen.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';
import 'package:qadaya_lawyersys/features/authentication/screens/forgot_password_screen.dart';
import 'package:qadaya_lawyersys/features/authentication/screens/login_screen.dart';
import 'package:qadaya_lawyersys/features/authentication/screens/register_screen.dart';
import 'package:qadaya_lawyersys/features/authentication/screens/reset_password_screen.dart';
import 'package:qadaya_lawyersys/features/billing/bloc/billing_bloc.dart';
import 'package:qadaya_lawyersys/features/billing/repositories/billing_repository.dart';
import 'package:qadaya_lawyersys/features/billing/screens/billing_list_screen.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_bloc.dart';
import 'package:qadaya_lawyersys/features/calendar/repositories/calendar_repository.dart';
import 'package:qadaya_lawyersys/features/calendar/screens/calendar_screen.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/cases_repository.dart';
import 'package:qadaya_lawyersys/features/cases/screens/cases_list_screen.dart';
import 'package:qadaya_lawyersys/features/client-portal/bloc/client_portal_bloc.dart';
import 'package:qadaya_lawyersys/features/client-portal/repositories/client_portal_repository.dart';
import 'package:qadaya_lawyersys/features/client-portal/screens/portal_documents_screen.dart';
import 'package:qadaya_lawyersys/features/client-portal/screens/portal_messages_screen.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_bloc.dart';
import 'package:qadaya_lawyersys/features/consultations/repositories/consultations_repository.dart';
import 'package:qadaya_lawyersys/features/consultations/screens/consultations_list_screen.dart';
import 'package:qadaya_lawyersys/features/contact/screens/contact_screen.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_bloc.dart';
import 'package:qadaya_lawyersys/features/contenders/repositories/contenders_repository.dart';
import 'package:qadaya_lawyersys/features/contenders/screens/contenders_list_screen.dart';
import 'package:qadaya_lawyersys/features/court-automation/bloc/court_automation_bloc.dart';
import 'package:qadaya_lawyersys/features/court-automation/repositories/court_automation_repository.dart';
import 'package:qadaya_lawyersys/features/court-automation/screens/court_automation_screen.dart';
import 'package:qadaya_lawyersys/features/courts/bloc/courts_bloc.dart';
import 'package:qadaya_lawyersys/features/courts/repositories/courts_repository.dart';
import 'package:qadaya_lawyersys/features/courts/screens/courts_list_screen.dart';
import 'package:qadaya_lawyersys/features/customers/bloc/customers_bloc.dart';
import 'package:qadaya_lawyersys/features/customers/repositories/customers_repository.dart';
import 'package:qadaya_lawyersys/features/customers/screens/customers_list_screen.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:qadaya_lawyersys/features/dashboard/repositories/dashboard_repository.dart';
import 'package:qadaya_lawyersys/features/dashboard/screens/dashboard_screen.dart';
import 'package:qadaya_lawyersys/features/document-generation/bloc/doc_generation_bloc.dart';
import 'package:qadaya_lawyersys/features/document-generation/repositories/doc_generation_repository.dart';
import 'package:qadaya_lawyersys/features/document-generation/screens/doc_generation_screen.dart';
import 'package:qadaya_lawyersys/features/documents/screens/documents_list_screen.dart';
import 'package:qadaya_lawyersys/features/employees/bloc/employees_bloc.dart';
import 'package:qadaya_lawyersys/features/employees/repositories/employees_repository.dart';
import 'package:qadaya_lawyersys/features/employees/screens/employees_list_screen.dart';
import 'package:qadaya_lawyersys/features/esign/bloc/esign_bloc.dart';
import 'package:qadaya_lawyersys/features/esign/repositories/esign_repository.dart';
import 'package:qadaya_lawyersys/features/esign/screens/esign_list_screen.dart';
import 'package:qadaya_lawyersys/features/files/bloc/files_bloc.dart';
import 'package:qadaya_lawyersys/features/files/repositories/files_repository.dart';
import 'package:qadaya_lawyersys/features/files/screens/files_list_screen.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_bloc.dart';
import 'package:qadaya_lawyersys/features/governments/repositories/governments_repository.dart';
import 'package:qadaya_lawyersys/features/governments/screens/governments_list_screen.dart';
import 'package:qadaya_lawyersys/features/hearings/bloc/hearings_bloc.dart';
import 'package:qadaya_lawyersys/features/hearings/repositories/hearings_repository.dart';
import 'package:qadaya_lawyersys/features/hearings/screens/hearings_list_screen.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_bloc.dart';
import 'package:qadaya_lawyersys/features/intake/bloc/intake_event.dart';
import 'package:qadaya_lawyersys/features/intake/repositories/intake_repository.dart';
import 'package:qadaya_lawyersys/features/intake/screens/intake_leads_list_screen.dart';
import 'package:qadaya_lawyersys/features/judicial/screens/judicial_documents_list_screen.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_bloc.dart';
import 'package:qadaya_lawyersys/features/notifications/repositories/notifications_repository.dart';
import 'package:qadaya_lawyersys/features/notifications/screens/notifications_inbox_screen.dart';
import 'package:qadaya_lawyersys/features/reports/bloc/reports_bloc.dart';
import 'package:qadaya_lawyersys/features/reports/repositories/reports_repository.dart';
import 'package:qadaya_lawyersys/features/reports/screens/reports_screen.dart';
import 'package:qadaya_lawyersys/features/settings/screens/profile_screen.dart';
import 'package:qadaya_lawyersys/features/settings/screens/settings_screen.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_bloc.dart';
import 'package:qadaya_lawyersys/features/sitings/repositories/sitings_repository.dart';
import 'package:qadaya_lawyersys/features/sitings/screens/sitings_list_screen.dart';
import 'package:qadaya_lawyersys/features/subscription/bloc/subscription_bloc.dart';
import 'package:qadaya_lawyersys/features/subscription/repositories/subscription_repository.dart';
import 'package:qadaya_lawyersys/features/subscription/screens/subscription_screen.dart';
import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_bloc.dart';
import 'package:qadaya_lawyersys/features/tasks/repositories/tasks_repository.dart';
import 'package:qadaya_lawyersys/features/tasks/screens/tasks_list_screen.dart';
import 'package:qadaya_lawyersys/features/tenants/bloc/tenants_bloc.dart';
import 'package:qadaya_lawyersys/features/tenants/repositories/tenants_repository.dart';
import 'package:qadaya_lawyersys/features/tenants/screens/tenants_list_screen.dart';
import 'package:qadaya_lawyersys/features/timetracking/bloc/timetracking_bloc.dart';
import 'package:qadaya_lawyersys/features/timetracking/repositories/timetracking_repository.dart';
import 'package:qadaya_lawyersys/features/timetracking/screens/timetracking_list_screen.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/bloc/trust_accounting_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/repositories/trust_accounting_repository.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/screens/trust_list_screen.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-reports/repositories/trust_reports_repository.dart';
import 'package:qadaya_lawyersys/features/trust-reports/screens/trust_reports_screen.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_bloc.dart';
import 'package:qadaya_lawyersys/features/users/repositories/users_repository.dart';
import 'package:qadaya_lawyersys/features/users/screens/users_list_screen.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_bloc.dart';
import 'package:qadaya_lawyersys/features/workqueue/repositories/workqueue_repository.dart';
import 'package:qadaya_lawyersys/features/workqueue/screens/workqueue_screen.dart';
import 'package:qadaya_lawyersys/shared/screens/main_screen.dart';
import 'package:qadaya_lawyersys/shared/screens/splash_screen.dart';
import 'package:qadaya_lawyersys/shared/screens/unauthorized_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Created once and reused — never recreated on rebuild.
  late final ApiClient _apiClient;
  late final LocalDatabase _localDatabase;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _localDatabase = LocalDatabase.instance;
  }

  bool _canAccessRoute(String? route, UserSession? session) {
    if (route == null) return false;

    // Public routes — no auth needed.
    const publicRoutes = {
      '/', '/login', '/register', '/forgot-password', '/reset-password',
    };
    if (publicRoutes.contains(route)) return true;

    // All other routes require at minimum an active session.
    if (session == null) return false;

    // Route → required permission (null = any authenticated user).
    final routePermissions = <String, String?>{
      '/main': null,
      '/dashboard': null,
      '/cases': null,
      '/tasks': null,
      '/calendar': Permissions.viewHearings,
      '/hearings': Permissions.viewHearings,
      '/courts': Permissions.viewCourts,
      '/timetracking': null,
      '/billing': Permissions.viewBilling,
      '/trust-accounting': Permissions.viewTrustAccounting,
      '/trust-reports': Permissions.viewBilling,
      '/client-portal-messages': Permissions.viewClientPortal,
      '/client-portal-documents': Permissions.viewClientPortal,
      '/customers': Permissions.viewCustomers,
      '/governments': null,
      '/employees': null,
      '/contenders': null,
      '/judicial': null,
      '/consultations': null,
      '/reports': null,
      '/notifications': null,
      '/settings': null,
      '/profile': null,
      '/documents': null,
      '/intake': null,
      '/files': null,
      '/esign': null,
      '/ai-assistant': null,
      '/sitings': Permissions.viewHearings,
      '/about': null,
      '/contact': null,
      '/document-generation': null,
      '/court-automation': null,
      '/workqueue': null,
      // Admin / SuperAdmin only routes.
      '/users': Permissions.manageUsers,
      '/tenants': Permissions.manageTenants,
      '/audit-logs': Permissions.viewAuditLogs,
      '/administration': Permissions.manageAdministration,
      '/subscription': Permissions.manageSubscription,
    };

    if (!routePermissions.containsKey(route)) return false;

    final required = routePermissions[route];
    if (required == null) return true;

    // Admin and SuperAdmin implicitly have all admin permissions.
    if (session.isAdmin()) return true;

    return session.hasPermission(required);
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = _apiClient;
    final localDatabase = _localDatabase;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository(apiClient)),
        RepositoryProvider(
            create: (_) => DashboardRepository(apiClient, localDatabase),),
        RepositoryProvider(
            create: (_) => CasesRepository(apiClient, localDatabase),),
        RepositoryProvider(create: (_) => TasksRepository(apiClient)),
        RepositoryProvider(create: (_) => CalendarRepository(apiClient)),
        RepositoryProvider(create: (_) => TimeTrackingRepository(apiClient)),
        RepositoryProvider(create: (_) => CourtsRepository(apiClient)),
        RepositoryProvider(create: (_) => BillingRepository(apiClient)),
        RepositoryProvider(create: (_) => CustomersRepository(apiClient)),
        RepositoryProvider(create: (_) => TrustAccountingRepository(apiClient)),
        RepositoryProvider(create: (_) => ClientPortalRepository(apiClient)),
        RepositoryProvider(
            create: (_) => HearingsRepository(apiClient, localDatabase),),
        RepositoryProvider(create: (_) => ContendersRepository(apiClient)),
        RepositoryProvider(create: (_) => ConsultationsRepository(apiClient)),
        RepositoryProvider(create: (_) => ReportsRepository(apiClient)),
        RepositoryProvider(create: (_) => UsersRepository(apiClient)),
        RepositoryProvider(create: (_) => TenantsRepository(apiClient)),
        RepositoryProvider(create: (_) => GovernmentsRepository(apiClient)),
        RepositoryProvider(
            create: (_) => EmployeesRepository(apiClient, localDatabase),),
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
        RepositoryProvider(
            create: (_) => NotificationsRepository(localDatabase, apiClient),),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (ctx) => ThemeCubit(PreferencesStorage()),),
          BlocProvider(
              create: (ctx) => AuthBloc(
                  authRepository: RepositoryProvider.of<AuthRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => DashboardBloc(
                  dashboardRepository:
                      RepositoryProvider.of<DashboardRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => CasesBloc(
                  casesRepository:
                      RepositoryProvider.of<CasesRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => TrustAccountingBloc(
                  trustAccountingRepository:
                      RepositoryProvider.of<TrustAccountingRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => ClientPortalBloc(
                  clientPortalRepository:
                      RepositoryProvider.of<ClientPortalRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => TasksBloc(
                  tasksRepository:
                      RepositoryProvider.of<TasksRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => CalendarBloc(
                  calendarRepository:
                      RepositoryProvider.of<CalendarRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => TimeTrackingBloc(
                  timeTrackingRepository:
                      RepositoryProvider.of<TimeTrackingRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => CourtsBloc(
                  courtsRepository:
                      RepositoryProvider.of<CourtsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => BillingBloc(
                  billingRepository:
                      RepositoryProvider.of<BillingRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => CustomersBloc(
                  customersRepository:
                      RepositoryProvider.of<CustomersRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => HearingsBloc(
                  hearingsRepository:
                      RepositoryProvider.of<HearingsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => ContendersBloc(
                  contendersRepository:
                      RepositoryProvider.of<ContendersRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => ConsultationsBloc(
                  consultationsRepository:
                      RepositoryProvider.of<ConsultationsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => ReportsBloc(
                  repository: RepositoryProvider.of<ReportsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => EmployeesBloc(
                  employeesRepository:
                      RepositoryProvider.of<EmployeesRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => GovernmentsBloc(
                  governmentsRepository:
                      RepositoryProvider.of<GovernmentsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => UsersBloc(
                  usersRepository: RepositoryProvider.of<UsersRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => TenantsBloc(
                  tenantsRepository:
                      RepositoryProvider.of<TenantsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => IntakeBloc(
                  repository: RepositoryProvider.of<IntakeRepository>(ctx),)
                ..add(LoadIntakeLeads()),),
          BlocProvider(
              create: (ctx) => FilesBloc(
                  filesRepository: RepositoryProvider.of<FilesRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => ESignBloc(
                  repository: RepositoryProvider.of<ESignRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => AiAssistantBloc(
                  repository: RepositoryProvider.of<AiAssistantRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => AuditLogsBloc(
                  repository: RepositoryProvider.of<AuditLogsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => SitingsBloc(
                  repository: RepositoryProvider.of<SitingsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => DocGenerationBloc(
                  repository: RepositoryProvider.of<DocGenerationRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => CourtAutomationBloc(
                  repository: RepositoryProvider.of<CourtAutomationRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => WorkqueueBloc(
                  repository: RepositoryProvider.of<WorkqueueRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => AdministrationBloc(
                  repository: RepositoryProvider.of<AdministrationRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => SubscriptionBloc(
                  repository: RepositoryProvider.of<SubscriptionRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => TrustReportsBloc(
                  repository: RepositoryProvider.of<TrustReportsRepository>(ctx),),),
          BlocProvider(
              create: (ctx) => NotificationsBloc(
                  notificationsRepository:
                      RepositoryProvider.of<NotificationsRepository>(ctx),),),
        ],
        child: _AppInitializer(canAccessRoute: _canAccessRoute),
      ),
    );
  }
}

/// Lives inside the provider tree so it can safely access repositories and blocs.
class _AppInitializer extends StatefulWidget {
  const _AppInitializer({required this.canAccessRoute});
  final bool Function(String?, UserSession?) canAccessRoute;

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
    // Capture context-dependent values before any await.
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final notificationsRepository =
        RepositoryProvider.of<NotificationsRepository>(context);

    // Load saved locale.
    final langCode = await PreferencesStorage().getLanguageCode();
    if (mounted) {
      setState(() {
        _locale = (langCode?.isNotEmpty ?? false)
            ? Locale(langCode!)
            : const Locale('ar');
        _localeLoaded = true;
      });
    }

    final pushService = PushNotificationService();
    pushService.configure(
      authRepository,
      notificationsRepository: notificationsRepository,
    );
    pushService.init();

    final signalRService = SignalRService();
    String? signalRToken;
    try {
      signalRToken = await SecureStorage().read(SecureStorage.keyAccessToken);
    } catch (_) {}
    try {
      await signalRService.init(
        '${ApiConstants.apiRoot}${ApiConstants.signalRHub}',
        tokenFactory: signalRToken != null ? () async => signalRToken! : null,
      );
    } catch (e) {
      debugPrint('[SignalR] init failed — backend unavailable: $e');
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
          .catchError((Object error) {
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
            textDirection: dir, child: child ?? const SizedBox.shrink(),);
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
                builder: (_) => const ForgotPasswordScreen(),);
          case '/reset-password':
            return MaterialPageRoute(builder: (_) => const _ResetScreen());
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/cases':
            return MaterialPageRoute(builder: (_) => const CasesListScreen());
          case '/tasks':
            return MaterialPageRoute(builder: (_) => const TasksListScreen());
          case '/calendar':
            return MaterialPageRoute(builder: (_) => const CalendarScreen());
          case '/hearings':
            return MaterialPageRoute(
                builder: (_) => const HearingsListScreen(),);
          case '/courts':
            return MaterialPageRoute(builder: (_) => const CourtsListScreen());
          case '/timetracking':
            return MaterialPageRoute(
                builder: (_) => const TimeTrackingListScreen(),);
          case '/billing':
            return MaterialPageRoute(builder: (_) => const BillingListScreen());
          case '/trust-accounting':
            return MaterialPageRoute(builder: (_) => const TrustListScreen());
          case '/client-portal-messages':
            return MaterialPageRoute(
                builder: (_) => const PortalMessagesScreen(),);
          case '/client-portal-documents':
            return MaterialPageRoute(
                builder: (_) => const PortalDocumentsScreen(),);
          case '/customers':
            return MaterialPageRoute(
                builder: (_) => const CustomersListScreen(),);
          case '/governments':
            return MaterialPageRoute(
                builder: (_) => const GovernmentsListScreen(),);
          case '/employees':
            return MaterialPageRoute(
                builder: (_) => const EmployeesListScreen(),);
          case '/contenders':
            return MaterialPageRoute(
                builder: (_) => const ContendersListScreen(),);
          case '/judicial':
            return MaterialPageRoute(
                builder: (_) => const JudicialDocumentsListScreen(),);
          case '/consultations':
            return MaterialPageRoute(
                builder: (_) => const ConsultationsListScreen(),);
          case '/reports':
            return MaterialPageRoute(builder: (_) => const ReportsScreen());
          case '/notifications':
            return MaterialPageRoute(
                builder: (_) => const NotificationsInboxScreen(),);
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
                builder: (_) => const DocumentsListScreen(),);
          case '/intake':
            return MaterialPageRoute(
                builder: (_) => const IntakeLeadsListScreen(),);
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
                builder: (_) => const DocGenerationScreen(),);
          case '/court-automation':
            return MaterialPageRoute(
                builder: (_) => const CourtAutomationScreen(),);
          case '/workqueue':
            return MaterialPageRoute(builder: (_) => const WorkqueueScreen());
          case '/administration':
            return MaterialPageRoute(
                builder: (_) => const AdministrationScreen(),);
          case '/subscription':
            return MaterialPageRoute(
                builder: (_) => const SubscriptionScreen(),);
          case '/trust-reports':
            return MaterialPageRoute(
                builder: (_) => const TrustReportsScreen(),);
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
        email: args['email'] ?? '', token: args['token'] ?? '',);
  }
}



