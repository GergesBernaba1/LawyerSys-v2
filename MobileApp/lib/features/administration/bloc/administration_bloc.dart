import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_event.dart';
import 'package:qadaya_lawyersys/features/administration/bloc/administration_state.dart';
import 'package:qadaya_lawyersys/features/administration/repositories/administration_repository.dart';

class AdministrationBloc extends Bloc<AdministrationEvent, AdminState> {

  AdministrationBloc({required this.repository}) : super(AdminInitial()) {
    on<LoadAdminOverview>(_onLoadAdminOverview);
    on<RefreshAdminOverview>(_onRefreshAdminOverview);
  }
  final AdministrationRepository repository;

  Future<void> _onLoadAdminOverview(
      LoadAdminOverview event, Emitter<AdminState> emit,) async {
    emit(AdminLoading());
    try {
      final overview = await repository.getOverview();
      emit(AdminLoaded(overview));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onRefreshAdminOverview(
      RefreshAdminOverview event, Emitter<AdminState> emit,) async {
    try {
      final overview = await repository.getOverview();
      emit(AdminLoaded(overview));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
