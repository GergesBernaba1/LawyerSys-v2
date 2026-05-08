import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_event.dart';
import 'package:qadaya_lawyersys/features/contenders/bloc/contenders_state.dart';
import 'package:qadaya_lawyersys/features/contenders/repositories/contenders_repository.dart';

class ContendersBloc extends Bloc<ContendersEvent, ContendersState> {
  ContendersBloc({required this.contendersRepository}) : super(ContendersInitial()) {
    on<LoadContenders>(_onLoad);
    on<RefreshContenders>(_onRefresh);
    on<SearchContenders>(_onSearch);
    on<SelectContender>(_onSelect);
    on<CreateContender>(_onCreate);
    on<UpdateContender>(_onUpdate);
    on<DeleteContender>(_onDelete);
  }

  final ContendersRepository contendersRepository;

  Future<void> _onLoad(LoadContenders event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshContenders event, Emitter<ContendersState> emit) async {
    try {
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchContenders event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contenders = await contendersRepository.getContenders(
        search: event.query.isEmpty ? null : event.query,
      );
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onSelect(SelectContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      final contender = await contendersRepository.getContenderById(event.contenderId);
      if (contender != null) {
        emit(ContenderDetailLoaded(contender));
      } else {
        emit(ContendersError('contenderNotFound'));
      }
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      await contendersRepository.createContender(event.contender);
      emit(ContenderOperationSuccess('contenderCreated'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      await contendersRepository.updateContender(event.contender);
      emit(ContenderOperationSuccess('contenderUpdated'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteContender event, Emitter<ContendersState> emit) async {
    emit(ContendersLoading());
    try {
      await contendersRepository.deleteContender(event.contenderId);
      emit(ContenderOperationSuccess('contenderDeleted'));
      final contenders = await contendersRepository.getContenders();
      emit(ContendersLoaded(contenders));
    } catch (e) {
      emit(ContendersError(e.toString()));
    }
  }
}
