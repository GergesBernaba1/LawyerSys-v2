import '../models/audit_log.dart';

abstract class AuditLogsState {}

class AuditLogsInitial extends AuditLogsState {}

class AuditLogsLoading extends AuditLogsState {}

class AuditLogsLoaded extends AuditLogsState {
  final List<AuditLog> logs;
  AuditLogsLoaded(this.logs);
}

class AuditLogsError extends AuditLogsState {
  final String message;
  AuditLogsError(this.message);
}
