import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';

/// Conditionally renders [child] based on the current user's roles and
/// permissions. Falls back to [fallback] (default: [SizedBox.shrink]) when
/// access is denied.
///
/// Usage examples:
///
/// ```dart
/// // Show only to admins
/// RbacGuard(requireAdmin: true, child: DeleteButton())
///
/// // Show if the user has a specific permission
/// RbacGuard(permission: Permissions.createCases, child: AddCaseButton())
///
/// // Show if the user has any of several permissions
/// RbacGuard(anyPermission: [Permissions.editCases, Permissions.deleteCases],
///           child: ActionsMenu())
///
/// // Show only to employees (not customers)
/// RbacGuard(role: Roles.employee, child: TimeEntryButton())
/// ```
class RbacGuard extends StatelessWidget {
  const RbacGuard({
    super.key,
    required this.child,
    this.permission,
    this.anyPermission,
    this.allPermissions,
    this.role,
    this.requireAdmin = false,
    this.fallback,
  }) : assert(
          permission != null ||
              anyPermission != null ||
              allPermissions != null ||
              role != null ||
              requireAdmin,
          'RbacGuard requires at least one of: permission, anyPermission, '
          'allPermissions, role, or requireAdmin = true',
        );

  /// Show when the user has this single permission.
  final String? permission;

  /// Show when the user has at least one of these permissions.
  final List<String>? anyPermission;

  /// Show when the user has ALL of these permissions.
  final List<String>? allPermissions;

  /// Show when the user has this role (case-insensitive).
  final String? role;

  /// When true, show only to Admin / SuperAdmin users.
  final bool requireAdmin;

  /// Widget to display when access is denied. Defaults to an empty box.
  final Widget? fallback;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final session =
        authState is AuthAuthenticated ? authState.session : null;

    if (_isAllowed(session)) return child;
    return fallback ?? const SizedBox.shrink();
  }

  bool _isAllowed(UserSession? session) {
    if (session == null) return false;

    if (requireAdmin) return session.isAdmin();

    // Admins implicitly pass all non-admin-only guards too.
    if (session.isAdmin()) return true;

    if (role != null && !session.hasRole(role!)) return false;
    if (permission != null && !session.hasPermission(permission!)) return false;
    if (anyPermission != null && !session.hasAnyPermission(anyPermission!)) {
      return false;
    }
    if (allPermissions != null && !session.hasAllPermissions(allPermissions!)) {
      return false;
    }

    return true;
  }
}
