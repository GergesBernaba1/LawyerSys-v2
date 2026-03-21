import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/governments_repository.dart';
import 'governments_event.dart';
import 'governments_state.dart';

class GovernmentsBloc extends Bloc<GovernmentsEvent, GovernmentsState> {
  final GovernmentsRepository governmentsRepository;

  GovernmentsBloc({required this.governmentsRepository}) : super(GovernmentsInitial()) {
    on<LoadGovernments>(_onLoad);
    on<RefreshGovernments>(_onRefresh);
  }

  Future<void> _onLoad(LoadGovernments event, Emitter<GovernmentsState> emit) async {
    emit(GovernmentsLoading());
    try {
      final governments = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(governments));
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshGovernments event, Emitter<GovernmentsState> emit) async {
    try {
      final governments = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(governments));
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }
}
