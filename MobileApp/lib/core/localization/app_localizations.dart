import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
      'dashboard': 'Dashboard',
      'email': 'Email',
      'password': 'Password',
      'cases': 'Cases',
      'customers': 'Customers',
      'hearings': 'Hearings',
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
      'caseDetail': 'Case Details',
      'customerDetail': 'Customer Details',
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
      'register': 'Register',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'phoneNumber': 'Phone Number',
      'confirmPassword': 'Confirm Password',
      'alreadyHaveAccount': 'Already have an account? Login',
      'biometricLogin': 'Biometric Login',
      'biometricLoginDisabled': 'Biometric login is disabled',
      'biometricEnabled': 'Biometric login enabled',
      'biometricDisabled': 'Biometric login disabled',
      'caseNumber': 'Case Number',
      'caseType': 'Type',
      'status': 'Status',
      'customer': 'Customer',
      'court': 'Court',
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
      'notificationsLabel': 'Notifications',
      'billing': 'Billing',
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
      'courtLocation': 'Court Location',
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
      'taskDeleteAlert': 'Are you sure you want to delete',
      'passwordsDoNotMatch': 'Passwords do not match',
      'allFieldsAreRequired': 'All fields are required',
      'emailIsRequired': 'Email is required',
      'addEventComingSoon': 'Add event functionality coming soon',
      'tasks': 'Tasks',
      'recentActivity': 'Recent Activity',
      'task': 'Task',
      'taskEdit': 'Edit',
      'taskDelete': 'Delete',
      'cancel': 'Cancel',
    },
    'ar': {
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'phoneNumber': 'رقم الهاتف',
      'confirmPassword': 'تأكيد كلمة المرور',
      'alreadyHaveAccount': 'هل لديك حساب؟ تسجيل الدخول',
      'dashboard': 'لوحة القيادة',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'cases': 'القضايا',
      'customers': 'العملاء',
      'hearings': 'الجلسات',
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
      'caseDetail': 'تفاصيل القضية',
      'customerDetail': 'تفاصيل العميل',
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
      'register': 'تسجيل',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'phoneNumber': 'رقم الهاتف',
      'confirmPassword': 'تأكيد كلمة المرور',
      'alreadyHaveAccount': 'هل لديك حساب؟ تسجيل الدخول',
      'biometricLogin': 'تسجيل الدخول البيومتري',
      'biometricLoginDisabled': 'تم تعطيل تسجيل الدخول البيومتري',
      'biometricEnabled': 'تم تفعيل تسجيل الدخول البيومتري',
      'biometricDisabled': 'تم تعطيل تسجيل الدخول البيومتري',
      'caseNumber': 'رقم القضية',
      'caseType': 'نوع القضية',
      'status': 'الوضع',
      'customer': 'العميل',
      'court': 'المحكمة',
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
      'notificationsLabel': 'الإشعارات',
      'billing': 'الفوترة',
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
      'courtLocation': 'موقع المحكمة',
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
      'taskDeleteAlert': 'هل أنت متأكد من أنك تريد حذف',
      'passwordsDoNotMatch': 'كلمات المرور غير متطابقة',
      'allFieldsAreRequired': 'جميع الحقول مطلوبة',
      'emailIsRequired': 'البريد الإلكتروني مطلوب',
      'addEventComingSoon': 'ميزة إضافة حدث قادمة قريباً',
      'tasks': 'المهام',
      'recentActivity': 'النشاط الحديث',
      'task': 'مهمة',
      'taskEdit': 'تعديل',
      'taskDelete': 'حذف',
      'cancel': 'إلغاء',
      'allFieldsAreRequired': 'All fields are required',
      'emailIsRequired': 'Email is required',
      'addEventComingSoon': 'Add event functionality coming soon',
      'tasks': 'Tasks',
      'recentActivity': 'Recent Activity',
      'task': 'Task',
      'taskEdit': 'Edit',
      'taskDelete': 'Delete',
      'cancel': 'Cancel',
    },
  };

  String _translate(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  String get login => _translate('login');
  String get dashboard => _translate('dashboard');
  String get email => _translate('email');
  String get password => _translate('password');
  String get cases => _translate('cases');
  String get customers => _translate('customers');
  String get hearings => _translate('hearings');
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
  String get caseDetail => _translate('caseDetail');
  String get customerDetail => _translate('customerDetail');
  String get notifications => _translate('notifications');
  String get register => _translate('register');
  String get firstName => _translate('firstName');
  String get lastName => _translate('lastName');
  String get phoneNumber => _translate('phoneNumber');
  String get confirmPassword => _translate('confirmPassword');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get biometricLogin => _translate('biometricLogin');
  String get biometricLoginDisabled => _translate('biometricLoginDisabled');
  String get biometricEnabled => _translate('biometricEnabled');
  String get biometricDisabled => _translate('biometricDisabled');
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

  String translate(String key) => _translate(key);

  String get caseNumber => _translate('caseNumber');
  String get caseType => _translate('caseType');
  String get status => _translate('status');
  String get customer => _translate('customer');
  String get court => _translate('court');
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
  String get searchTasks => _translate('searchTasks');
  String get call => _translate('call');
  String get message => _translate('message');
  String get noTimeEntriesFound => _translate('noTimeEntriesFound');
  String get startTrackingTime => _translate('startTrackingTime');
  String get viewRunningTimers => _translate('viewRunningTimers');
  String get selectACase => _translate('selectACase');
  String get all => _translate('all');
  String get runningStatus => _translate('running');
  String get stoppedStatus => _translate('stopped');
  String get start => _translate('start');
  String get workType => _translate('workType');
  String get duration => _translate('duration');
  String get year => _translate('year');
  String get stopTimerFunctionality => _translate('stopTimerFunctionality');
  String get statusLabel => _translate('statusLabel');
  String get stopped => _translate('stopped');
  String get running => _translate('running');
  String get save => _translate('save');
  String get timeEntryForm => _translate('timeEntryForm');
  String get pleaseEnterWorkType => _translate('pleaseEnterWorkType');
  String get customerIdOptional => _translate('customerIdOptional');
  String get timeEntrySaved => _translate('timeEntrySavedSuccessfully');

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
  String get searchTasks => _translate('searchTasks');
  String get languageSelectionScreen => _translate('languageSelectionScreen');
  String get passwordsDoNotMatch => _translate('passwordsDoNotMatch');
  String get allFieldsAreRequired => _translate('allFieldsAreRequired');
  String get emailIsRequired => _translate('emailIsRequired');
  String get addEventComingSoon => _translate('addEventComingSoon');
  String get tasks => _translate('tasks');
  String get recentActivity => _translate('recentActivity');
  String get taskEdit => _translate('taskEdit');
  String get taskDelete => _translate('taskDelete');
  String get noSuggestions => _translate('noSuggestions');
  String get notificationsLabel => _translate('notificationsLabel');
  String get billing => _translate('billing');
  String get timeTracking => _translate('timeTracking');
  String get payments => _translate('payments');
  String get receipts => _translate('receipts');
  String get balance => _translate('balance');
  String get notes => _translate('notes');
  String get noPaymentsFound => _translate('noPaymentsFound');
  String get noReceiptsFound => _translate('noReceiptsFound');
  String get hearingDetail => _translate('hearingDetail');
  String get hearingId => _translate('hearingId');
  String get createHearing => _translate('createHearing');
  String get editHearing => _translate('editHearing');
  String get deleteHearing => _translate('deleteHearing');
  String get deleteHearingConfirm => _translate('deleteHearingConfirm');
  String get addHearing => _translate('addHearing');
  String get hearingNotificationDetails => _translate('hearingNotificationDetails');
  String get courtLocation => _translate('courtLocation');
  String get dateLabel => _translate('dateLabel');
  String get calendarView => _translate('calendarView');
  String get listView => _translate('listView');
  String get judgeLabel => _translate('judgeLabel');
  String get caseDetail => _translate('caseDetail');
  String get customerDetail => _translate('customerDetail');
  String get timeEntries => _translate('timeEntries');
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
  String get taskDeleteAlert => _translate('taskDeleteAlert');
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

