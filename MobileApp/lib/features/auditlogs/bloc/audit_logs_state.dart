import 'package:qadaya_lawyersys/features/auditlogs/models/audit_log.dart';

abstract class AuditLogsState {}

class AuditLogsInitial extends AuditLogsState {}

class AuditLogsLoading extends AuditLogsState {}

class AuditLogsLoaded extends AuditLogsState {
  AuditLogsLoaded(this.logs);
  final List<AuditLog> logs;
}

class AuditLogsError extends AuditLogsState {
  AuditLogsError(this.message);
  final String message;
}
