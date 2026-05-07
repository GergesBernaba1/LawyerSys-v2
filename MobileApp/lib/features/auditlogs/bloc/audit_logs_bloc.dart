import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/auditlogs/bloc/audit_logs_event.dart';
import 'package:qadaya_lawyersys/features/auditlogs/bloc/audit_logs_state.dart';
import 'package:qadaya_lawyersys/features/auditlogs/repositories/audit_logs_repository.dart';

class AuditLogsBloc extends Bloc<AuditLogsEvent, AuditLogsState> {

  AuditLogsBloc({required this.repository}) : super(AuditLogsInitial()) {
    on<LoadAuditLogs>(_onLoadAuditLogs);
    on<RefreshAuditLogs>(_onRefreshAuditLogs);
  }
  final AuditLogsRepository repository;

  // Remember last filter params so RefreshAuditLogs can replay them.
  String? _lastSearch;
  String? _lastEntityName;
  String? _lastAction;

  Future<void> _onLoadAuditLogs(
    LoadAuditLogs event,
    Emitter<AuditLogsState> emit,
  ) async {
    _lastSearch = event.search;
    _lastEntityName = event.entityName;
    _lastAction = event.action;

    emit(AuditLogsLoading());
    try {
      final logs = await repository.getLogs(
        search: event.search,
        entityName: event.entityName,
        action: event.action,
      );
      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditLogsError(e.toString()));
    }
  }

  Future<void> _onRefreshAuditLogs(
    RefreshAuditLogs event,
    Emitter<AuditLogsState> emit,
  ) async {
    try {
      final logs = await repository.getLogs(
        search: _lastSearch,
        entityName: _lastEntityName,
        action: _lastAction,
      );
      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditLogsError(e.toString()));
    }
  }
}
