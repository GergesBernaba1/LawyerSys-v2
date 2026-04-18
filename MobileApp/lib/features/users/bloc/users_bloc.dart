import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/user_model.dart';
import '../repositories/users_repository.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository usersRepository;

  UsersBloc({required this.usersRepository}) : super(UsersInitial()) {
    on<LoadUsers>(_onLoad);
    on<SearchUsers>(_onSearch);
    on<RefreshUsers>(_onRefresh);
  }

  Future<void> _onLoad(LoadUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      final raw = await usersRepository.getUsers(search: event.query);
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshUsers event, Emitter<UsersState> emit) async {
    try {
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}
