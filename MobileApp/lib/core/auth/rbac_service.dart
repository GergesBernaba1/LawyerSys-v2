import 'package:qadaya_lawyersys/core/auth/permissions.dart';
import 'package:qadaya_lawyersys/core/auth/roles.dart';

/// Derives the complete permission set for a user from their assigned roles.
///
/// The backend JWT carries role claims only. This service translates
/// role membership into the fine-grained permission list used throughout
/// the mobile app for UI guards and route protection.
class RbacService {
  static const List<String> _employeePermissions = [
    Permissions.dashboard,
    Permissions.viewCases,
    Permissions.createCases,
    Permissions.editCases,
    Permissions.viewCourts,
    Permissions.viewCustomers,
    Permissions.viewHearings,
    Permissions.viewCalendar,
    Permissions.viewSitings,
    Permissions.viewBilling,
    Permissions.viewTrustAccounting,
    Permissions.viewClientPortal,
    Permissions.viewNotifications,
    Permissions.viewContenders,
    Permissions.viewGovernments,
    Permissions.viewJudicial,
    Permissions.viewDocuments,
    Permissions.viewFiles,
    Permissions.viewTasks,
    Permissions.viewTimeTracking,
    Permissions.viewConsultations,
    Permissions.viewReports,
    Permissions.viewESign,
    Permissions.viewDocumentGeneration,
    Permissions.viewCourtAutomation,
    Permissions.viewWorkqueue,
    Permissions.viewAiAssistant,
    Permissions.viewIntake,
    Permissions.viewSitings,
  ];

  static const List<String> _adminPermissions = [
    ..._employeePermissions,
    Permissions.deleteCases,
    Permissions.createBilling,
    Permissions.deleteBilling,
    Permissions.createTrustAccounting,
    Permissions.editTrustAccounting,
    Permissions.deleteTrustAccounting,
    Permissions.manageClientPortal,
    Permissions.viewEmployees,
    Permissions.createEmployees,
    Permissions.editEmployees,
    Permissions.viewTrustReports,
    Permissions.manageIntake,
    Permissions.qualifyLeads,
    Permissions.manageSettings,
    Permissions.manageUsers,
    Permissions.manageTenants,
    Permissions.viewAuditLogs,
    Permissions.manageAdministration,
    Permissions.manageSubscription,
  ];

  static const List<String> _customerPermissions = [
    Permissions.dashboard,
    Permissions.viewCases,
    Permissions.viewNotifications,
    Permissions.viewClientPortal,
  ];

  static const Map<String, List<String>> _roleMap = {
    Roles.superAdmin: _adminPermissions,
    Roles.admin: _adminPermissions,
    Roles.employee: _employeePermissions,
    Roles.customer: _customerPermissions,
  };

  /// Returns the merged, deduplicated permission list for the given roles.
  static List<String> permissionsForRoles(List<String> roles) {
    final perms = <String>{};
    for (final role in roles) {
      final mapped = _roleMap[role];
      if (mapped != null) perms.addAll(mapped);
    }
    return perms.toList();
  }
}
