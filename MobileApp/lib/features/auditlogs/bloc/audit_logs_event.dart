abstract class AuditLogsEvent {}

class LoadAuditLogs extends AuditLogsEvent {

  LoadAuditLogs({this.search, this.entityName, this.action});
  final String? search;
  final String? entityName;
  final String? action;
}

class RefreshAuditLogs extends AuditLogsEvent {}
