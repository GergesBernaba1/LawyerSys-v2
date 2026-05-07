import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/reports/bloc/reports_event.dart';
import 'package:qadaya_lawyersys/features/reports/bloc/reports_state.dart';
import 'package:qadaya_lawyersys/features/reports/models/report.dart';
import 'package:qadaya_lawyersys/features/reports/repositories/reports_repository.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {

  ReportsBloc({required this.repository}) : super(ReportsInitial()) {
    on<LoadFinancialReport>(_onLoadFinancial);
    on<LoadOutstandingBalances>(_onLoadBalances);
    on<LoadCustomerBillingHistory>(_onLoadBillingHistory);
    on<RefreshReports>(_onRefresh);
  }
  final ReportsRepository repository;

  Future<void> _onLoadFinancial(
      LoadFinancialReport event, Emitter<ReportsState> emit,) async {
    emit(ReportsLoading());
    try {
      final results = await Future.wait([
        repository.getFinancialSummary(
            year: event.year,
            month: event.month,
            customerId: event.customerId,),
        repository.getOutstandingBalances(),
      ]);
      emit(ReportsLoaded(
        financialReport: results[0] as FinancialReport,
        outstandingBalances: results[1] as List<OutstandingBalance>,
        year: event.year,
        month: event.month,
        customerId: event.customerId,
      ),);
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadBalances(
      LoadOutstandingBalances event, Emitter<ReportsState> emit,) async {
    final current = state is ReportsLoaded ? state as ReportsLoaded : null;
    try {
      final balances = await repository.getOutstandingBalances();
      if (current != null) {
        emit(current.copyWith(outstandingBalances: balances));
      } else {
        final now = DateTime.now();
        emit(ReportsLoaded(
          outstandingBalances: balances,
          year: now.year,
          month: now.month,
        ),);
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadBillingHistory(
      LoadCustomerBillingHistory event, Emitter<ReportsState> emit,) async {
    final current = state is ReportsLoaded ? state as ReportsLoaded : null;
    try {
      final history =
          await repository.getCustomerBillingHistory(event.customerId);
      if (current != null) {
        emit(current.copyWith(customerBillingHistory: history));
      } else {
        final now = DateTime.now();
        emit(ReportsLoaded(
          customerBillingHistory: history,
          year: now.year,
          month: now.month,
        ),);
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshReports event, Emitter<ReportsState> emit,) async {
    try {
      final results = await Future.wait([
        repository.getFinancialSummary(
            year: event.year,
            month: event.month,
            customerId: event.customerId,),
        repository.getOutstandingBalances(),
      ]);
      emit(ReportsLoaded(
        financialReport: results[0] as FinancialReport,
        outstandingBalances: results[1] as List<OutstandingBalance>,
        year: event.year,
        month: event.month,
        customerId: event.customerId,
      ),);
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }
}
