import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_event.dart';
import 'package:qadaya_lawyersys/features/dashboard/bloc/dashboard_state.dart';
import 'package:qadaya_lawyersys/features/dashboard/repositories/dashboard_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {

  DashboardBloc({required this.dashboardRepository}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }
  final DashboardRepository dashboardRepository;

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final summary = await dashboardRepository.getSummary();
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboard event, Emitter<DashboardState> emit) async {
    try {
      final summary = await dashboardRepository.getSummary();
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
