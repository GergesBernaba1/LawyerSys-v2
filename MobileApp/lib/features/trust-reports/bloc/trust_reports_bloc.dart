import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_event.dart';
import 'package:qadaya_lawyersys/features/trust-reports/bloc/trust_reports_state.dart';
import 'package:qadaya_lawyersys/features/trust-reports/repositories/trust_reports_repository.dart';

class TrustReportsBloc extends Bloc<TrustReportsEvent, TrustReportsState> {

  TrustReportsBloc({required this.repository}) : super(TrustReportsInitial()) {
    on<LoadFinancialSummary>(_onLoadFinancialSummary);
    on<LoadOutstandingBalances>(_onLoadOutstandingBalances);
    on<RefreshTrustReports>(_onRefreshTrustReports);
  }
  final TrustReportsRepository repository;

  Future<void> _onLoadFinancialSummary(
      LoadFinancialSummary event, Emitter<TrustReportsState> emit,) async {
    emit(TrustReportsLoading());
    try {
      final summary = await repository.getFinancialSummary(
        year: event.year,
        month: event.month,
      );
      emit(FinancialSummaryLoaded(summary, year: event.year, month: event.month));
    } catch (e) {
      emit(TrustReportsError(e.toString()));
    }
  }

  Future<void> _onLoadOutstandingBalances(
      LoadOutstandingBalances event, Emitter<TrustReportsState> emit,) async {
    emit(TrustReportsLoading());
    try {
      final balances = await repository.getOutstandingBalances();
      balances.sort((a, b) => b.amount.compareTo(a.amount));
      emit(OutstandingBalancesLoaded(balances));
    } catch (e) {
      emit(TrustReportsError(e.toString()));
    }
  }

  Future<void> _onRefreshTrustReports(
      RefreshTrustReports event, Emitter<TrustReportsState> emit,) async {
    // Refresh based on the previous state context
    if (state is FinancialSummaryLoaded) {
      final prev = state as FinancialSummaryLoaded;
      try {
        final summary = await repository.getFinancialSummary(
          year: prev.year,
          month: prev.month,
        );
        emit(FinancialSummaryLoaded(summary, year: prev.year, month: prev.month));
      } catch (e) {
        emit(TrustReportsError(e.toString()));
      }
    } else if (state is OutstandingBalancesLoaded) {
      try {
        final balances = await repository.getOutstandingBalances();
        balances.sort((a, b) => b.amount.compareTo(a.amount));
        emit(OutstandingBalancesLoaded(balances));
      } catch (e) {
        emit(TrustReportsError(e.toString()));
      }
    } else {
      // Default to financial summary
      try {
        final summary = await repository.getFinancialSummary();
        emit(FinancialSummaryLoaded(summary));
      } catch (e) {
        emit(TrustReportsError(e.toString()));
      }
    }
  }
}
