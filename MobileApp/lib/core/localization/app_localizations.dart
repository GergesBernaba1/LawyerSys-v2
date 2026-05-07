import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)!`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @hearings.
  ///
  /// In en, this message translates to:
  /// **'Hearings'**
  String get hearings;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get refresh;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @caseDetail.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetail;

  /// No description provided for @customerDetail.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetail;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive password reset instructions.'**
  String get forgotPasswordDescription;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get passwordResetSuccess;

  /// No description provided for @resetPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Reset password for'**
  String get resetPasswordFor;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricLoginDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is disabled'**
  String get biometricLoginDisabled;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get biometricDisabled;

  /// No description provided for @caseNumber.
  ///
  /// In en, this message translates to:
  /// **'Case Number'**
  String get caseNumber;

  /// No description provided for @caseType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get caseType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @court.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get court;

  /// No description provided for @filingDate.
  ///
  /// In en, this message translates to:
  /// **'Filing Date'**
  String get filingDate;

  /// No description provided for @closingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing Date'**
  String get closingDate;

  /// No description provided for @assignedEmployees.
  ///
  /// In en, this message translates to:
  /// **'Assigned Employees'**
  String get assignedEmployees;

  /// No description provided for @noCasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cases found'**
  String get noCasesFound;

  /// No description provided for @searchCases.
  ///
  /// In en, this message translates to:
  /// **'Search cases'**
  String get searchCases;

  /// No description provided for @createCase.
  ///
  /// In en, this message translates to:
  /// **'Create Case'**
  String get createCase;

  /// No description provided for @editCase.
  ///
  /// In en, this message translates to:
  /// **'Edit Case'**
  String get editCase;

  /// No description provided for @deleteCase.
  ///
  /// In en, this message translates to:
  /// **'Delete Case'**
  String get deleteCase;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this case?'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @caseSaved.
  ///
  /// In en, this message translates to:
  /// **'Case saved successfully'**
  String get caseSaved;

  /// No description provided for @caseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Case deleted successfully'**
  String get caseDeleted;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noTimeEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No time entries found'**
  String get noTimeEntriesFound;

  /// No description provided for @startTrackingTime.
  ///
  /// In en, this message translates to:
  /// **'Start Tracking Time'**
  String get startTrackingTime;

  /// No description provided for @viewRunningTimers.
  ///
  /// In en, this message translates to:
  /// **'View running timers'**
  String get viewRunningTimers;

  /// No description provided for @selectACase.
  ///
  /// In en, this message translates to:
  /// **'Select a case'**
  String get selectACase;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @workType.
  ///
  /// In en, this message translates to:
  /// **'Work Type'**
  String get workType;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @unableToUpdateBiometricSettings.
  ///
  /// In en, this message translates to:
  /// **'Unable to update biometric settings'**
  String get unableToUpdateBiometricSettings;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @lightMode.
  String get lightMode;

  /// No description provided for @darkMode.
  String get darkMode;

  /// No description provided for @systemDefault.
  String get systemDefault;

  /// No description provided for @theme.
  String get theme;

  /// No description provided for @myWorkqueue.
  String get myWorkqueue;

  /// No description provided for @retry.
  String get retry;

  /// No description provided for @noTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// No description provided for @createFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Create first task'**
  String get createFirstTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirm;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @trustAccounting.
  ///
  /// In en, this message translates to:
  /// **'Trust Accounting'**
  String get trustAccounting;

  /// No description provided for @trustTransaction.
  ///
  /// In en, this message translates to:
  /// **'Trust Transaction'**
  String get trustTransaction;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @accountId.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get accountId;

  /// No description provided for @trustType.
  ///
  /// In en, this message translates to:
  /// **'Trust Type'**
  String get trustType;

  /// No description provided for @timeTracking.
  ///
  /// In en, this message translates to:
  /// **'Time Tracking'**
  String get timeTracking;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments found'**
  String get noPaymentsFound;

  /// No description provided for @noReceiptsFound.
  ///
  /// In en, this message translates to:
  /// **'No receipts found'**
  String get noReceiptsFound;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @hearingDetail.
  ///
  /// In en, this message translates to:
  /// **'Hearing Detail'**
  String get hearingDetail;

  /// No description provided for @hearingId.
  ///
  /// In en, this message translates to:
  /// **'Hearing ID'**
  String get hearingId;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeEntries.
  ///
  /// In en, this message translates to:
  /// **'Time Entries'**
  String get timeEntries;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @caseCode.
  ///
  /// In en, this message translates to:
  /// **'Case Code'**
  String get caseCode;

  /// No description provided for @workTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Type'**
  String get workTypeLabel;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @stopTimerFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Stop timer functionality'**
  String get stopTimerFunctionality;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @dataColumnCase.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get dataColumnCase;

  /// No description provided for @dataColumnCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get dataColumnCustomer;

  /// No description provided for @dataColumnMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get dataColumnMinutes;

  /// No description provided for @dataColumnAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get dataColumnAmount;

  /// No description provided for @dataColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get dataColumnActions;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @allFieldsAreRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsAreRequired;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @addEventComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add event functionality coming soon'**
  String get addEventComingSoon;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get taskEdit;

  /// No description provided for @taskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get taskDelete;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get noSuggestions;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @languageSelectionScreen.
  ///
  /// In en, this message translates to:
  /// **'Language selection screen (EN / AR)'**
  String get languageSelectionScreen;

  /// No description provided for @caseHistory.
  ///
  /// In en, this message translates to:
  /// **'Case History'**
  String get caseHistory;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @noCaseHistory.
  ///
  /// In en, this message translates to:
  /// **'No case history available'**
  String get noCaseHistory;

  /// No description provided for @taskDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get taskDeleteAlert;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account'**
  String get noAccount;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @portalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Portal Documents'**
  String get portalDocuments;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// No description provided for @portalMessages.
  ///
  /// In en, this message translates to:
  /// **'Portal Messages'**
  String get portalMessages;

  /// No description provided for @markedAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markedAsRead;

  /// No description provided for @consultationDetail.
  ///
  /// In en, this message translates to:
  /// **'Consultation Detail'**
  String get consultationDetail;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create Trust Transaction'**
  String get create;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @employeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get employeeDetails;

  /// No description provided for @employeeInformation.
  ///
  /// In en, this message translates to:
  /// **'Employee Information'**
  String get employeeInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @searchEmployees.
  ///
  /// In en, this message translates to:
  /// **'Search Employees'**
  String get searchEmployees;

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployeesFound;

  /// No description provided for @deleteHearing.
  ///
  /// In en, this message translates to:
  /// **'Delete Hearing'**
  String get deleteHearing;

  /// No description provided for @deleteHearingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this hearing?'**
  String get deleteHearingConfirm;

  /// No description provided for @judgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Judge'**
  String get judgeLabel;

  /// No description provided for @editHearing.
  ///
  /// In en, this message translates to:
  /// **'Edit Hearing'**
  String get editHearing;

  /// No description provided for @createHearing.
  ///
  /// In en, this message translates to:
  /// **'Create Hearing'**
  String get createHearing;

  /// No description provided for @courtLocation.
  ///
  /// In en, this message translates to:
  /// **'Court Location'**
  String get courtLocation;

  /// No description provided for @notificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Notification Details'**
  String get notificationDetails;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar View'**
  String get calendarView;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskName;

  /// No description provided for @pleaseEnterTaskName.
  ///
  /// In en, this message translates to:
  /// **'Please enter task name'**
  String get pleaseEnterTaskName;

  /// No description provided for @taskType.
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get taskType;

  /// No description provided for @pleaseEnterTaskType.
  ///
  /// In en, this message translates to:
  /// **'Please enter task type'**
  String get pleaseEnterTaskType;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @reminderDate.
  ///
  /// In en, this message translates to:
  /// **'Reminder Date'**
  String get reminderDate;

  /// No description provided for @assignedEmployee.
  ///
  /// In en, this message translates to:
  /// **'Assigned Employee'**
  String get assignedEmployee;

  /// No description provided for @timeEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Time entry saved'**
  String get timeEntrySaved;

  /// No description provided for @runningStatus.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runningStatus;

  /// No description provided for @stoppedStatus.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stoppedStatus;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @timeEntryForm.
  ///
  /// In en, this message translates to:
  /// **'Time Entry Form'**
  String get timeEntryForm;

  /// No description provided for @contenders.
  ///
  /// In en, this message translates to:
  /// **'Contenders'**
  String get contenders;

  /// No description provided for @ssn.
  ///
  /// In en, this message translates to:
  /// **'SSN'**
  String get ssn;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @governorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorate;

  /// No description provided for @courts.
  ///
  /// In en, this message translates to:
  /// **'Courts'**
  String get courts;

  /// No description provided for @addHearing.
  ///
  /// In en, this message translates to:
  /// **'Add Hearing'**
  String get addHearing;

  /// No description provided for @pleaseEnterWorkType.
  ///
  /// In en, this message translates to:
  /// **'Please enter work type'**
  String get pleaseEnterWorkType;

  /// No description provided for @governments.
  ///
  /// In en, this message translates to:
  /// **'Governments'**
  String get governments;

  /// No description provided for @judicial.
  ///
  /// In en, this message translates to:
  /// **'Judicial'**
  String get judicial;

  /// No description provided for @consultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultations;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page'**
  String get accessDeniedMessage;

  /// No description provided for @consultationSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get consultationSubject;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get consultationType;

  /// No description provided for @consultationState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get consultationState;

  /// No description provided for @consultationDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get consultationDateTime;

  /// No description provided for @consultationFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get consultationFeedback;

  /// No description provided for @consultationCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Consultation created successfully'**
  String get consultationCreatedSuccessfully;

  /// No description provided for @consultationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Consultation updated successfully'**
  String get consultationUpdatedSuccessfully;

  /// No description provided for @noOptions.
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get noOptions;

  /// No description provided for @myConsultations.
  ///
  /// In en, this message translates to:
  /// **'My Consultations'**
  String get myConsultations;

  /// No description provided for @consultationManagement.
  ///
  /// In en, this message translates to:
  /// **'Consultation Management'**
  String get consultationManagement;

  /// No description provided for @consultationEmployeeHint.
  ///
  /// In en, this message translates to:
  /// **'You can only view and update consultations assigned to you'**
  String get consultationEmployeeHint;

  /// No description provided for @consultationAssignmentHint.
  ///
  /// In en, this message translates to:
  /// **'You can assign consultations to employees from your team'**
  String get consultationAssignmentHint;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  // Calendar
  String get createCalendarEvent;
  String get editCalendarEvent;
  String get deleteCalendarEvent;
  String get deleteCalendarEventConfirm;
  String get calendarEventTitle;
  String get calendarEventType;
  String get calendarEventEnd;
  String get calendarEventEndOptional;
  String get calendarReminderEvent;
  String get calendarEventSaved;
  String get calendarEventDeleted;
  String get noEventsFound;

  // Intake
  String get intake;
  String get leads;
  String get noLeadsFound;
  String get leadStatus;
  String get leadSubject;
  String get leadAssignedTo;
  String get leadQualify;
  String get leadReject;
  String get leadAssign;
  String get leadConflictCheck;
  String get conflictDetected;
  String get noConflict;
  String get leadConvert;
  String get nextFollowUp;
  String get qualificationNotes;

  // Portal
  String get replyMessage;
  String get sendMessage;
  String get messageBody;
  String get messageSent;

  // Contenders
  String get dateOfBirth;

  // Courts
  String get createCourt;
  String get editCourt;
  String get deleteCourt;
  String get deleteCourtConfirm;
  String get courtName;
  String get courtSaved;
  String get courtDeleted;
  String get noCourtsFound;

  // Customers
  String get createCustomer;
  String get editCustomer;
  String get deleteCustomer;
  String get deleteCustomerConfirm;
  String get customerSaved;
  String get customerDeleted;
  String get noCustomersFound;

  // Governments
  String get createGovernment;
  String get editGovernment;
  String get deleteGovernment;
  String get deleteGovernmentConfirm;
  String get governmentName;
  String get governmentSaved;
  String get governmentDeleted;
  String get noGovernmentsFound;

  // Users
  String get users;
  String get noUsersFound;

  // Tenants
  String get tenants;
  String get noTenantsFound;
  String get tenantStatusUpdated;
  String get currentTenant;
  String get createTenant;
  String get editTenant;
  String get deleteTenant;
  String get deleteTenantConfirm;
  String get tenantName;
  String get tenantSaved;
  String get tenantDeleted;

  // Users / Roles
  String get changeRole;
  String get roleSaved;

  // Documents
  String get uploadDocument;
  String get shareDocument;
  String get shareLink;
  String get copyLink;
  String get openInBrowser;

  // Case Relations
  String get caseRelations;
  String get addRelation;
  String get deleteRelation;
  String get relationType;
  String get relatedCase;
  String get noRelationsFound;

  // Dashboard
  String get welcomeBack;
  String get statistics;
  String get onTrack;
  String get needsAttention;
  String get critical;
  String get operationalFocus;
  String get activityHealth;
  String get completionReadiness;
  String get quickActions;
  String get newCase;
  String get newCustomer;
  String get viewBilling;
  String get adminTasks;
  String get workQueue;
  String get myCases;
  String get totalCases;
  String get myTasks;
  String get files;
  String get openCases;
  String get revenue;
  String get qualifiedLeads;
  String get upcomingHearings;
  String get overdueTasks;
  String get myLeads;
  String get recentCases;
  String get viewAll;
  String get noRecentCases;
  String get startCreatingCase;
  String get noCaseNumber;
  String get myOverdueTasks;
  String get noOverdueTasks;
  String get myFollowUps;
  String get noFollowUpsScheduled;
  String get employeeDashboardSubtitle;
  String get adminDashboardSubtitle;
  String get refreshing;
  String get overdue;
  String get health;
  String get updated;
  String get updatedNow;

  // General UI
  String get aboutUs;
  String get active;
  String get administration;
  String get admin;
  String get clear;
  String get confirm;
  String get contactUs;
  String get submit;
  String get update;
  String get updateStatus;
  String get role;
  String get filteredBy;
  String get noAssignedTasks;

  // Documents
  String get noDocumentsFound;
  String get rename;
  String get renameDocument;
  String get renamedSuccessfully;
  String get documentUploaded;
  String get documentUploadedSuccessfully;
  String get pleaseEnterFilePath;
  String get getShareLink;
  String get shareLinkCopied;
  String get linkCopied;

  // Court Sittings / Judicial Documents
  String get courtSittings;
  String get deleteCourtSitting;

  // Users
  String get deleteUser;

  // eSignatures
  String get eSignatures;
  String get newESignRequest;

  // Intake / CRM
  String get publicIntakeLinkNotAvailable;
  String get messageSentSuccessfully;
  String get addCaseRelation;

  // Court Automation
  String get calculateDeadlines;
  String get deadlines;
  String get due;
  String get noDeadlinesReturned;
  String get noFilingsYet;
  String get selectADate;
  String get submitFiling;
  String get packLabel;
  String get submittedLabel;
  String get caseLabel;

  // Document Generation
  String get documentGeneration;
  String get selectTemplate;
  String get noTemplatesFound;
  String get fillInFields;
  String get documentGenerated;
  String get generatedOn;
  String get generateDocument;
  String get isRequired;
  String get pickADate;
  String get newDraft;
  String get title;
  String get content;
  String get deleteDraft;
  String get templateLabel;
  String get generatedLabel;

  // AI Assistant
  String get aiAssistant;
  String get draft;
  String get enterTextToSummarize;
  String get summarize;

  // Bloc success messages
  String get eSignRequestCreated;
  String get statusUpdatedSuccessfully;
  String get userCreatedSuccessfully;
  String get userUpdatedSuccessfully;
  String get userDeletedSuccessfully;
  String get userRoleChangedSuccessfully;
  String get tenantCreatedSuccessfully;
  String get tenantUpdatedSuccessfully;
  String get tenantDeletedSuccessfully;
  String get draftCreatedSuccessfully;
  String get draftDeletedSuccessfully;

  // Contact form
  String get contactInformation;
  String get getInTouch;
  String get weLoveToHear;
  String get yourName;
  String get enterFullName;
  String get nameRequired;
  String get emailAddress;
  String get enterEmail;
  String get enterValidEmail;
  String get writeYourMessage;
  String get messageRequired;
  String get messageTooShort;
  String get sendMessageLabel;

  // About
  String get website;

  // Court Sittings
  String get courtId;
  String get deleteCourtSittingConfirm;
  String get addCourtSitting;
  String get searchSittings;
  String get noCourtSittingsFound;

  // Case Relations
  String get relatedCaseId;
  String get notesOptional;
  String get relationTypeRelated;
  String get relationTypeAppeal;
  String get relationTypeConsolidated;
  String get relationTypeCompanion;
  String get failedToLoadRelations;

  // Court Automation
  String get pleaseEnterCaseCode;

  // Files
  String get couldNotOpenUrl;
  String get downloadFailed;

  // Governments
  String get governorateId;
  String get governorateName;

  // Cases
  String get caseCodeMustBePositive;
  String get statement;

  // Audit Logs
  String get auditLogs;
  String get searchAuditLogs;
  String get entity;
  String get action;
  String get noAuditLogsFound;

  // Auth
  String get rememberMe;

  // Workqueue
  String get reassignTask;
  String get employeeIdLabel;
  String get enterTargetEmployeeId;
  String get markComplete;
  String get markInProgress;
  String get workqueueEmpty;
  String get markCompletePrompt;
  String get statusPending;
  String get statusInProgress;
  String get statusCompleted;

  // Payment proof
  String get submitPaymentProof;
  String get pleaseSelectFile;
  String get paymentProofSubmitted;
  String get paymentDate;
  String get proofFilePath;
  String get submitting;

  // Employee
  String get profilePhotoUpdated;
  String get uploadFailed;

  // Requested documents
  String get requestedDocuments;
  String get documentSubmittedSuccessfully;
  String get filePath;
  String get noRequestedDocuments;

  // Billing
  String get pleaseSelectCustomer;
  String get pleaseSelectAnEmployee;
  String get newPayment;
  String get newReceipt;

  // Notification settings
  String get notificationSettings;
  String get notificationSettingsUpdated;
  String get enableNotifications;
  String get enableNotificationsSubtitle;
  String get aboutNotifications;
  String get manageNotificationPreferences;
  String get notificationsWhenEnabledDescription;
  String get notificationItemDocumentRequests;
  String get notificationItemCaseStatusChanges;
  String get notificationItemPaymentConfirmations;
  String get notificationItemStaffMessages;

  // Judicial documents
  String get documentType;
  String get documentNumber;
  String get agentNumber;
  String get details;
  String get customerId;
  String get searchJudicialDocuments;
  String get editDocument;
  String get createDocument;
  String get requiredField;

  // Profile
  String get username;
  String get country;
  String get jobTitle;
  String get tenantPhone;
  String get usernameRequired;
  String get fullNameRequired;
  String get countryRequired;
  // Intake
  String get intakeLeads;
  String get submitPublicLead;
  String get runConflictCheck;
  String get qualify;
  String get reject;
  String get convertToCustomerAndCase;
  String get assignToEmployeeLabel;
  String get assign;
  String get subject;
  String get nationalId;
  String get desiredCaseType;
  String get createFirstDocument;
  String get noLeadsFoundCreate;
  String get searchIntakeHint;
  // Reports & trust reports
  String get financial;
  String get outstanding;
  String get month;
  String get year;
  String get net;
  String get noFinancialData;
  String get noOutstandingBalances;
  String get selectTabToLoadData;
  // Billing form
  String get pleaseEnterAmount;
  String get pleaseEnterValidNumber;
  // Misc
  String get pullToRefresh;
  String get noPackagesAvailable;
  String get contactSales;
  String get notification;
  String get clearAll;
  String get profileUpdatedSuccessfully;
  // Misc missing
  String get document;
  String get lastSixMonths;
  String get pleaseContactSales;
  String get cannotPreviewDocumentType;
  // Administration stats
  String get totalUsers;
  String get totalCustomers;
  String get totalEmployees;
  String get totalTenants;
  String get activeTenants;
  // Judicial detail
  String get deleteDocument;
  String get deleteDocumentConfirm;
  String get judicialDocuments;
  String get agentsCount;
  // Trust report summary
  String get totalRevenue;
  String get totalExpenses;
  String get netBalance;
  String get totalInvoices;
  String get paidInvoices;
  String get pendingInvoices;
  String get trustBalance;
  // Employee
  String get uploadProfilePhoto;
  // Requested documents
  String get areYouSureDelete;
  // Navigation menu
  String get courtAutomation;
  String get myQueue;
  String get trustReports;
  String get subscription;
  String get sitings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
