import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/contender.dart';
import '../repositories/contenders_repository.dart';
import 'contenders_event.dart';
import 'contenders_state.dart';

class ContendersBloc extends Bloc<ContendersEvent, ContendersState> {
  final ContendersRepository contendersRepository;

  ContendersBloc({required this.contendersRepository}) : super(ContendersInitial()) {
    on<LoadContenders>(_onLoadContenders);
    on<RefreshContenders>(_onRefreshContenders);
    on<SearchContenders>(_onSearchContenders);
    on<SelectContender>(_onSelectContender);
    on<CreateContender>(_onCreateContender);
    on<UpdateContender>(_onUpdateContender);
    on<DeleteContender>(_onDeleteContender);
  }

  Future<void> _onLoadContenders(LoadContenders event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onRefreshContenders(RefreshContenders event, Emitter<ContendersState> emit) async {
    try {
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onSearchContenders(SearchContenders event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contenders = await contendersRepository.searchContenders(event.query);
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onSelectContender(SelectContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contender = await contendersRepository.getContenderById(event.contenderId);
      if (contender != null) {
        emit(ContenderDetailLoaded(contender));
      } else {
        emit(ContendersError('Contender not found'));
      }
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onCreateContender(CreateContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final created = await contendersRepository.createContender(event.contender);
      emit(ContenderOperationSuccess('Contender created: ${created.fullName}'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onUpdateContender(UpdateContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final updated = await contendersRepository.updateContender(event.contender);
      emit(ContenderOperationSuccess('Contender updated: ${updated.fullName}'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onDeleteContender(DeleteContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      await contendersRepository.deleteContender(event.contenderId);
      emit(ContenderOperationSuccess('Contender deleted'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }
}
