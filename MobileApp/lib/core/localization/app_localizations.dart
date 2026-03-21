import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key) {
    final localeValues = _localizedValues[locale.languageCode];
    if (localeValues != null && localeValues.containsKey(key)) {
      return localeValues[key]!;
    }
    return _localizedValues['en']?[key] ?? key;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      final key = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');
      return translate(key);
    }
    return super.noSuchMethod(invocation);
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'register': 'Register',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'phoneNumber': 'Phone Number',
      'confirmPassword': 'Confirm Password',
      'alreadyHaveAccount': 'Already have an account? Login',
      'noAccount': "Don't have an account?",
      'dashboard': 'Dashboard',
      'email': 'Email',
      'password': 'Password',
      'cases': 'Cases',
      'customers': 'Customers',
      'hearings': 'Hearings',
      'employees': 'Employees',
      'calendar': 'Calendar',
      'consultations': 'Consultations',
      'documents': 'Documents',
      'reports': 'Reports',
      'courts': 'Courts',
      'settings': 'Settings',
      'logout': 'Logout',
      'search': 'Search',
      'noData': 'No data available',
      'pushNotifications': 'Push Notifications',
      'error': 'Error',
      'offline': 'Offline',
      'refresh': 'Pull to refresh',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',
      'sessionExpired': 'Session expired. Please log in again.',
      'accessDenied': 'Access denied',
      'accessDeniedMessage': 'You do not have permission to access this section.',
      'caseDetail': 'Case Details',
      'customerDetail': 'Customer Details',
      'contenders': 'Contenders',
      'court': 'Court',
      'courtLocation': 'Court Location',
      'address': 'Address',
      'governorate': 'Governorate',
      'phone': 'Phone',
      'notifications': 'Notifications',
      'forgotPassword': 'Forgot Password',
      'forgotPasswordDescription': 'Enter your email to receive password reset instructions.',
      'resetEmailSent': 'Reset email sent. Check your inbox.',
      'sendResetLink': 'Send Reset Link',
      'backToLogin': 'Back to Login',
      'resetPassword': 'Reset Password',
      'passwordResetSuccess': 'Password reset successful',
      'resetPasswordFor': 'Reset password for',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'biometricLogin': 'Biometric Login',
      'biometricLoginDisabled': 'Biometric login is disabled',
      'biometricEnabled': 'Biometric login enabled',
      'biometricDisabled': 'Biometric login disabled',
      'caseNumber': 'Case Number',
      'caseType': 'Type',
      'status': 'Status',
      'customer': 'Customer',
      'filingDate': 'Filing Date',
      'closingDate': 'Closing Date',
      'assignedEmployees': 'Assigned Employees',
      'noCasesFound': 'No cases found',
      'searchCases': 'Search cases',
      'call': 'Call',
      'message': 'Message',
      'noTimeEntriesFound': 'No time entries found',
      'startTrackingTime': 'Start Tracking Time',
      'viewRunningTimers': 'View running timers',
      'selectACase': 'Select a case',
      'all': 'All',
      'running': 'Running',
      'stopped': 'Stopped',
      'start': 'Start',
      'workType': 'Work Type',
      'duration': 'Duration',
      'statusLabel': 'Status',
      'save': 'Save',
      'timeEntryForm': 'Time Entry Form',
      'pleaseEnterWorkType': 'Please enter work type',
      'customerIdOptional': 'Customer ID (optional)',
      'timeEntrySavedSuccessfully': 'Time entry saved successfully',
      'stopTimerFunctionality': 'Stop timer functionality',
      'amount': 'Amount',
      'actions': 'Actions',
      'noDataAvailable': 'No data available',
      'unableToUpdateBiometricSettings': 'Unable to update biometric settings',
      'appVersion': 'App version',
      'noTasksFound': 'No tasks found',
      'createFirstTask': 'Create first task',
      'deleteTask': 'Delete Task',
      'deleteTaskConfirm': 'Are you sure you want to delete this task?',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'task': 'Task',
      'tasks': 'Tasks',
      'taskEdit': 'Edit',
      'taskDelete': 'Delete',
      'taskDeleteAlert': 'Are you sure you want to delete',
      'searchTasks': 'Search tasks',
      'notificationsLabel': 'Notifications',
      'billing': 'Billing',
      'clientPortal': 'Client Portal',
      'portalMessages': 'Portal Messages',
      'portalDocuments': 'Portal Documents',
      'markedAsRead': 'Marked as read',
      'downloadStarted': 'Download started',
      'timeTracking': 'Time Tracking',
      'payments': 'Payments',
      'receipts': 'Receipts',
      'notes': 'Notes',
      'noPaymentsFound': 'No payments found',
      'noReceiptsFound': 'No receipts found',
      'balance': 'Balance',
      'hearingDetail': 'Hearing Detail',
      'hearingId': 'Hearing ID',
      'createHearing': 'Create Hearing',
      'editHearing': 'Edit Hearing',
      'deleteHearing': 'Delete Hearing',
      'deleteHearingConfirm': 'Are you sure you want to delete this hearing?',
      'addHearing': 'Add Hearing',
      'hearingNotificationDetails': 'Notification Details',
      'dateLabel': 'Date',
      'timeEntries': 'Time Entries',
      'calendarView': 'Calendar View',
      'listView': 'List View',
      'judgeLabel': 'Judge',
      'suggestions': 'Suggestions',
      'caseCode': 'Case Code',
      'workTypeLabel': 'Work Type',
      'description': 'Description',
      'noEventsFound': 'No events found',
      'monthly': 'Monthly',
      'weekly': 'Weekly',
      'dataColumnCase': 'Case',
      'dataColumnCustomer': 'Customer',
      'dataColumnMinutes': 'Minutes',
      'dataColumnAmount': 'Amount',
      'dataColumnActions': 'Actions',
      'passwordsDoNotMatch': 'Passwords do not match',
      'allFieldsAreRequired': 'All fields are required',
      'emailIsRequired': 'Email is required',
      'addEventComingSoon': 'Add event functionality coming soon',
      'recentActivity': 'Recent Activity',
      'consultationDetail': 'Consultation Details',
      'assignedEmployee': 'Assigned Employee',
      'create': 'Create',
      'add': 'Add',
      'ssn': 'SSN',
      'salary': 'Salary',
      'lastSyncedAt': 'Last synced',
      'never': 'Never',
      'isDirty': 'Has pending changes',
      'yes': 'Yes',
      'no': 'No',
      'notificationDetails': 'Notification Details',
      'searchEmployees': 'Search employees',
      'noEmployeesFound': 'No employees found',
      'job': 'Job',
      'department': 'Department',
      'employeeDetails': 'Employee Details',
      'employeeInformation': 'Employee Information',
      'fullName': 'Full Name',
      'caseHistory': 'Case History',
      'noCaseHistory': 'No case history found',
      'assignedTo': 'Assigned to',
      'editTask': 'Edit Task',
      'createTask': 'Create Task',
      'taskName': 'Task Name',
      'taskType': 'Task Type',
      'startDate': 'Start Date',
      'reminderDate': 'Reminder Date',
      'pleaseEnterTaskName': 'Please enter task name',
      'pleaseEnterTaskType': 'Please enter task type',
      'createCase': 'Create Case',
      'editCase': 'Edit Case',
      'deleteCase': 'Delete Case',
      'deleteConfirm': 'Are you sure?',
      'delete': 'Delete',
      'caseSaved': 'Case saved',
      'caseDeleted': 'Case deleted',
    },
    'ar': {
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'phoneNumber': 'رقم الهاتف',
      'confirmPassword': 'تأكيد كلمة المرور',
      'alreadyHaveAccount': 'هل لديك حساب؟ تسجيل الدخول',
      'noAccount': 'ليس لديك حساب؟',
      'dashboard': 'لوحة القيادة',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'cases': 'القضايا',
      'customers': 'العملاء',
      'hearings': 'الجلسات',
      'employees': 'الموظفون',
      'calendar': 'التقويم',
      'consultations': 'الاستشارات',
      'documents': 'المستندات',
      'reports': 'التقارير',
      'courts': 'المحاكم',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
      'search': 'بحث',
      'noData': 'لا توجد بيانات',
      'pushNotifications': 'الإشعارات الفورية',
      'error': 'خطأ',
      'offline': 'غير متصل',
      'refresh': 'اسحب للتحديث',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'sessionExpired': 'انتهت الجلسة. الرجاء تسجيل الدخول مرة أخرى.',
      'accessDenied': 'تم رفض الوصول',
      'accessDeniedMessage': 'ليس لديك إذن بالوصول إلى هذا القسم.',
      'caseDetail': 'تفاصيل القضية',
      'customerDetail': 'تفاصيل العميل',
      'contenders': 'الطرف المقابل',
      'court': 'المحكمة',
      'courtLocation': 'موقع المحكمة',
      'address': 'العنوان',
      'governorate': 'المحافظة',
      'phone': 'الهاتف',
      'notifications': 'الإشعارات',
      'forgotPassword': 'نسيت كلمة المرور',
      'forgotPasswordDescription': 'أدخل بريدك الإلكتروني لتلقي تعليمات إعادة تعيين كلمة المرور.',
      'resetEmailSent': 'تم إرسال بريد إعادة التعيين. تحقق من صندوق الوارد.',
      'sendResetLink': 'إرسال رابط إعادة التعيين',
      'backToLogin': 'العودة لتسجيل الدخول',
      'resetPassword': 'إعادة تعيين كلمة المرور',
      'passwordResetSuccess': 'تم إعادة تعيين كلمة المرور بنجاح',
      'resetPasswordFor': 'إعادة تعيين كلمة المرور لـ',
      'newPassword': 'كلمة المرور الجديدة',
      'confirmNewPassword': 'تأكيد كلمة المرور الجديدة',
      'biometricLogin': 'تسجيل الدخول البيومتري',
      'biometricLoginDisabled': 'تم تعطيل تسجيل الدخول البيومتري',
      'biometricEnabled': 'تم تفعيل تسجيل الدخول البيومتري',
      'biometricDisabled': 'تم تعطيل تسجيل الدخول البيومتري',
      'caseNumber': 'رقم القضية',
      'caseType': 'نوع القضية',
      'status': 'الوضع',
      'customer': 'العميل',
      'filingDate': 'تاريخ التسجيل',
      'closingDate': 'تاريخ الإغلاق',
      'assignedEmployees': 'الموظفون المعنيون',
      'noCasesFound': 'لم يتم العثور على قضايا',
      'searchCases': 'البحث في القضايا',
      'call': 'اتصال',
      'message': 'رسالة',
      'noTimeEntriesFound': 'لم يتم العثور على سجلات وقت',
      'startTrackingTime': 'بدء تتبع الوقت',
      'viewRunningTimers': 'عرض المؤقتات الجارية',
      'selectACase': 'اختر قضية',
      'all': 'الكل',
      'running': 'جارٍ',
      'stopped': 'متوقف',
      'start': 'ابدأ',
      'workType': 'نوع العمل',
      'duration': 'المدة',
      'statusLabel': 'الحالة',
      'save': 'حفظ',
      'timeEntryForm': 'نموذج إدخال الوقت',
      'pleaseEnterWorkType': 'يرجى إدخال نوع العمل',
      'customerIdOptional': 'معرف العميل (اختياري)',
      'timeEntrySavedSuccessfully': 'تم حفظ إدخال الوقت بنجاح',
      'stopTimerFunctionality': 'وظيفة إيقاف المؤقت',
      'amount': 'المبلغ',
      'actions': 'إجراءات',
      'noDataAvailable': 'لا توجد بيانات متاحة',
      'unableToUpdateBiometricSettings': 'يتعذر تحديث إعدادات البيومترية',
      'appVersion': 'إصدار التطبيق',
      'noTasksFound': 'لم يتم العثور على مهام',
      'createFirstTask': 'إنشاء المهمة الأولى',
      'deleteTask': 'حذف المهمة',
      'deleteTaskConfirm': 'هل أنت متأكد من أنك تريد حذف هذه المهمة؟',
      'cancel': 'إلغاء',
      'edit': 'تعديل',
      'task': 'مهمة',
      'tasks': 'المهام',
      'taskEdit': 'تعديل',
      'taskDelete': 'حذف',
      'taskDeleteAlert': 'هل أنت متأكد من أنك تريد حذف',
      'searchTasks': 'البحث في المهام',
      'notificationsLabel': 'الإشعارات',
      'billing': 'الفوترة',
      'clientPortal': 'بوابة العملاء',
      'portalMessages': 'رسائل البوابة',
      'portalDocuments': 'مستندات البوابة',
      'markedAsRead': 'تم وسمها كمقروءة',
      'downloadStarted': 'بدء التنزيل',
      'timeTracking': 'تتبع الوقت',
      'payments': 'المدفوعات',
      'receipts': 'الإيصالات',
      'notes': 'الملاحظات',
      'noPaymentsFound': 'لم يتم العثور على مدفوعات',
      'noReceiptsFound': 'لم يتم العثور على إيصالات',
      'balance': 'الرصيد',
      'hearingDetail': 'تفاصيل الجلسة',
      'hearingId': 'معرف الجلسة',
      'createHearing': 'إنشاء جلسة',
      'editHearing': 'تعديل الجلسة',
      'deleteHearing': 'حذف الجلسة',
      'deleteHearingConfirm': 'هل أنت متأكد من أنك تريد حذف هذه الجلسة؟',
      'addHearing': 'إضافة جلسة',
      'hearingNotificationDetails': 'تفاصيل الإخطار',
      'dateLabel': 'التاريخ',
      'timeEntries': 'إدخالات الوقت',
      'calendarView': 'عرض التقويم',
      'listView': 'عرض القائمة',
      'judgeLabel': 'القاضي',
      'suggestions': 'الاقتراحات',
      'caseCode': 'رمز القضية',
      'workTypeLabel': 'نوع العمل',
      'description': 'الوصف',
      'noEventsFound': 'لم يتم العثور على أحداث',
      'monthly': 'شهري',
      'weekly': 'أسبوعي',
      'dataColumnCase': 'القضية',
      'dataColumnCustomer': 'العميل',
      'dataColumnMinutes': 'الدقائق',
      'dataColumnAmount': 'المبلغ',
      'dataColumnActions': 'الإجراءات',
      'passwordsDoNotMatch': 'كلمات المرور غير متطابقة',
      'allFieldsAreRequired': 'جميع الحقول مطلوبة',
      'emailIsRequired': 'البريد الإلكتروني مطلوب',
      'addEventComingSoon': 'ميزة إضافة حدث قادمة قريباً',
      'recentActivity': 'النشاط الحديث',
      'consultationDetail': 'تفاصيل الاستشارة',
      'assignedEmployee': 'الموظف المعين',
      'create': 'إنشاء',
      'add': 'إضافة',
      'ssn': 'رقم الهوية',
      'salary': 'الراتب',
      'lastSyncedAt': 'آخر مزامنة',
      'never': 'أبداً',
      'isDirty': 'يوجد تغييرات معلقة',
      'yes': 'نعم',
      'no': 'لا',
      'notificationDetails': 'تفاصيل الإشعار',
      'searchEmployees': 'البحث في الموظفين',
      'noEmployeesFound': 'لم يتم العثور على موظفين',
      'job': 'الوظيفة',
      'department': 'القسم',
      'employeeDetails': 'تفاصيل الموظف',
      'employeeInformation': 'معلومات الموظف',
      'fullName': 'الاسم الكامل',
      'caseHistory': 'سجل القضايا',
      'noCaseHistory': 'لا يوجد سجل قضايا',
      'assignedTo': 'مسند إلى',
      'editTask': 'تعديل المهمة',
      'createTask': 'إنشاء مهمة',
      'taskName': 'اسم المهمة',
      'taskType': 'نوع المهمة',
      'startDate': 'تاريخ البدء',
      'reminderDate': 'تاريخ التذكير',
      'pleaseEnterTaskName': 'يرجى إدخال اسم المهمة',
      'pleaseEnterTaskType': 'يرجى إدخال نوع المهمة',
      'createCase': 'إنشاء قضية',
      'editCase': 'تعديل القضية',
      'deleteCase': 'حذف القضية',
      'deleteConfirm': 'هل أنت متأكد؟',
      'delete': 'حذف',
      'caseSaved': 'تم حفظ القضية',
      'caseDeleted': 'تم حذف القضية',
    },
  };

  String _translate(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  String translate(String key) => _translate(key);

  String get login => _translate('login');
  String get register => _translate('register');
  String get firstName => _translate('firstName');
  String get lastName => _translate('lastName');
  String get phoneNumber => _translate('phoneNumber');
  String get confirmPassword => _translate('confirmPassword');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get noAccount => _translate('noAccount');
  String get dashboard => _translate('dashboard');
  String get email => _translate('email');
  String get password => _translate('password');
  String get cases => _translate('cases');
  String get customers => _translate('customers');
  String get hearings => _translate('hearings');
  String get employees => _translate('employees');
  String get calendar => _translate('calendar');
  String get consultations => _translate('consultations');
  String get documents => _translate('documents');
  String get reports => _translate('reports');
  String get courts => _translate('courts');
  String get settings => _translate('settings');
  String get logout => _translate('logout');
  String get search => _translate('search');
  String get noData => _translate('noData');
  String get error => _translate('error');
  String get offline => _translate('offline');
  String get refresh => _translate('refresh');
  String get language => _translate('language');
  String get english => _translate('english');
  String get arabic => _translate('arabic');
  String get pushNotifications => _translate('pushNotifications');
  String get sessionExpired => _translate('sessionExpired');
  String get accessDenied => _translate('accessDenied');
  String get accessDeniedMessage => _translate('accessDeniedMessage');
  String get caseDetail => _translate('caseDetail');
  String get customerDetail => _translate('customerDetail');
  String get contenders => _translate('contenders');
  String get court => _translate('court');
  String get courtLocation => _translate('courtLocation');
  String get address => _translate('address');
  String get governorate => _translate('governorate');
  String get phone => _translate('phone');
  String get notifications => _translate('notifications');
  String get forgotPassword => _translate('forgotPassword');
  String get forgotPasswordDescription => _translate('forgotPasswordDescription');
  String get resetEmailSent => _translate('resetEmailSent');
  String get sendResetLink => _translate('sendResetLink');
  String get backToLogin => _translate('backToLogin');
  String get resetPassword => _translate('resetPassword');
  String get passwordResetSuccess => _translate('passwordResetSuccess');
  String get resetPasswordFor => _translate('resetPasswordFor');
  String get newPassword => _translate('newPassword');
  String get confirmNewPassword => _translate('confirmNewPassword');
  String get biometricLogin => _translate('biometricLogin');
  String get biometricLoginDisabled => _translate('biometricLoginDisabled');
  String get biometricEnabled => _translate('biometricEnabled');
  String get biometricDisabled => _translate('biometricDisabled');
  String get caseNumber => _translate('caseNumber');
  String get caseType => _translate('caseType');
  String get status => _translate('status');
  String get customer => _translate('customer');
  String get filingDate => _translate('filingDate');
  String get closingDate => _translate('closingDate');
  String get assignedEmployees => _translate('assignedEmployees');
  String get noCasesFound => _translate('noCasesFound');
  String get searchCases => _translate('searchCases');
  String get createCase => _translate('createCase');
  String get editCase => _translate('editCase');
  String get deleteCase => _translate('deleteCase');
  String get deleteConfirm => _translate('deleteConfirm');
  String get delete => _translate('delete');
  String get caseSaved => _translate('caseSaved');
  String get caseDeleted => _translate('caseDeleted');
  String get call => _translate('call');
  String get message => _translate('message');
  String get noTimeEntriesFound => _translate('noTimeEntriesFound');
  String get startTrackingTime => _translate('startTrackingTime');
  String get viewRunningTimers => _translate('viewRunningTimers');
  String get selectACase => _translate('selectACase');
  String get all => _translate('all');
  String get running => _translate('running');
  String get stopped => _translate('stopped');
  String get runningStatus => _translate('running');
  String get stoppedStatus => _translate('stopped');
  String get start => _translate('start');
  String get workType => _translate('workType');
  String get duration => _translate('duration');
  String get statusLabel => _translate('statusLabel');
  String get save => _translate('save');
  String get timeEntryForm => _translate('timeEntryForm');
  String get pleaseEnterWorkType => _translate('pleaseEnterWorkType');
  String get customerIdOptional => _translate('customerIdOptional');
  String get timeEntrySaved => _translate('timeEntrySavedSuccessfully');
  String get stopTimerFunctionality => _translate('stopTimerFunctionality');
  String get amount => _translate('amount');
  String get actions => _translate('actions');
  String get noDataAvailable => _translate('noDataAvailable');
  String get unableToUpdateBiometricSettings => _translate('unableToUpdateBiometricSettings');
  String get appVersion => _translate('appVersion');
  String get noTasksFound => _translate('noTasksFound');
  String get createFirstTask => _translate('createFirstTask');
  String get deleteTask => _translate('deleteTask');
  String get deleteTaskConfirm => _translate('deleteTaskConfirm');
  String get cancel => _translate('cancel');
  String get edit => _translate('edit');
  String get task => _translate('task');
  String get tasks => _translate('tasks');
  String get taskEdit => _translate('taskEdit');
  String get taskDelete => _translate('taskDelete');
  String get taskDeleteAlert => _translate('taskDeleteAlert');
  String get searchTasks => _translate('searchTasks');
  String get notificationsLabel => _translate('notificationsLabel');
  String get billing => _translate('billing');
  String get clientPortal => _translate('clientPortal');
  String get portalMessages => _translate('portalMessages');
  String get portalDocuments => _translate('portalDocuments');
  String get markedAsRead => _translate('markedAsRead');
  String get downloadStarted => _translate('downloadStarted');
  String get timeTracking => _translate('timeTracking');
  String get payments => _translate('payments');
  String get receipts => _translate('receipts');
  String get notes => _translate('notes');
  String get noPaymentsFound => _translate('noPaymentsFound');
  String get noReceiptsFound => _translate('noReceiptsFound');
  String get balance => _translate('balance');
  String get hearingDetail => _translate('hearingDetail');
  String get hearingId => _translate('hearingId');
  String get createHearing => _translate('createHearing');
  String get editHearing => _translate('editHearing');
  String get deleteHearing => _translate('deleteHearing');
  String get deleteHearingConfirm => _translate('deleteHearingConfirm');
  String get addHearing => _translate('addHearing');
  String get hearingNotificationDetails => _translate('hearingNotificationDetails');
  String get dateLabel => _translate('dateLabel');
  String get timeEntries => _translate('timeEntries');
  String get calendarView => _translate('calendarView');
  String get listView => _translate('listView');
  String get judgeLabel => _translate('judgeLabel');
  String get suggestions => _translate('suggestions');
  String get caseCode => _translate('caseCode');
  String get workTypeLabel => _translate('workTypeLabel');
  String get description => _translate('description');
  String get noEventsFound => _translate('noEventsFound');
  String get monthly => _translate('monthly');
  String get weekly => _translate('weekly');
  String get dataColumnCase => _translate('dataColumnCase');
  String get dataColumnCustomer => _translate('dataColumnCustomer');
  String get dataColumnMinutes => _translate('dataColumnMinutes');
  String get dataColumnAmount => _translate('dataColumnAmount');
  String get dataColumnActions => _translate('dataColumnActions');
  String get passwordsDoNotMatch => _translate('passwordsDoNotMatch');
  String get allFieldsAreRequired => _translate('allFieldsAreRequired');
  String get emailIsRequired => _translate('emailIsRequired');
  String get addEventComingSoon => _translate('addEventComingSoon');
  String get recentActivity => _translate('recentActivity');
  String get consultationDetail => _translate('consultationDetail');
  String get assignedEmployee => _translate('assignedEmployee');
  String get myCalendar => _translate('calendar');
  String get trustAccounting => _translate('trustAccounting');
  String get trustTransaction => _translate('trustTransaction');
  String get transactionType => _translate('transactionType');
  String get transactionId => _translate('transactionId');
  String get accountId => _translate('accountId');
  String get trustType => _translate('trustType');
  String get year => _translate('year');
  String get noSuggestions => _translate('noSuggestions');
  String get languageSelectionScreen => _translate('languageSelectionScreen');
  String get create => _translate('create');
  String get add => _translate('add');
  String get notificationDetails => _translate('notificationDetails');
  String get searchEmployees => _translate('searchEmployees');
  String get noEmployeesFound => _translate('noEmployeesFound');
  String get job => _translate('job');
  String get department => _translate('department');
  String get employeeDetails => _translate('employeeDetails');
  String get employeeInformation => _translate('employeeInformation');
  String get fullName => _translate('fullName');
  String get caseHistory => _translate('caseHistory');
  String get noCaseHistory => _translate('noCaseHistory');
  String get assignedTo => _translate('assignedTo');
  String get editTask => _translate('editTask');
  String get createTask => _translate('createTask');
  String get taskName => _translate('taskName');
  String get taskType => _translate('taskType');
  String get startDate => _translate('startDate');
  String get reminderDate => _translate('reminderDate');
  String get pleaseEnterTaskName => _translate('pleaseEnterTaskName');
  String get pleaseEnterTaskType => _translate('pleaseEnterTaskType');
  String get ssn => _translate('ssn');
  String get salary => _translate('salary');
  String get lastSyncedAt => _translate('lastSyncedAt');
  String get never => _translate('never');
  String get isDirty => _translate('isDirty');
  String get yes => _translate('yes');
  String get no => _translate('no');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
