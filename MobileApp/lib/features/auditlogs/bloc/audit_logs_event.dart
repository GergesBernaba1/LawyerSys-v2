abstract class AuditLogsEvent {}

class LoadAuditLogs extends AuditLogsEvent {
  final String? search;
  final String? entityName;
  final String? action;

  LoadAuditLogs({this.search, this.entityName, this.action});
}

class RefreshAuditLogs extends AuditLogsEvent {}
