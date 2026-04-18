import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/administration_repository.dart';
import 'administration_event.dart';
import 'administration_state.dart';

class AdministrationBloc extends Bloc<AdministrationEvent, AdminState> {
  final AdministrationRepository repository;

  AdministrationBloc({required this.repository}) : super(AdminInitial()) {
    on<LoadAdminOverview>(_onLoadAdminOverview);
    on<RefreshAdminOverview>(_onRefreshAdminOverview);
  }

  Future<void> _onLoadAdminOverview(
      LoadAdminOverview event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final overview = await repository.getOverview();
      emit(AdminLoaded(overview));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onRefreshAdminOverview(
      RefreshAdminOverview event, Emitter<AdminState> emit) async {
    try {
      final overview = await repository.getOverview();
      emit(AdminLoaded(overview));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
