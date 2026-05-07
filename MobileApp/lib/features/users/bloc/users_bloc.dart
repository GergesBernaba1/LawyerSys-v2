import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_event.dart';
import 'package:qadaya_lawyersys/features/users/bloc/users_state.dart';
import 'package:qadaya_lawyersys/features/users/models/user_model.dart';
import 'package:qadaya_lawyersys/features/users/repositories/users_repository.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {

  UsersBloc({required this.usersRepository}) : super(UsersInitial()) {
    on<LoadUsers>(_onLoad);
    on<SearchUsers>(_onSearch);
    on<RefreshUsers>(_onRefresh);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<ChangeUserRole>(_onChangeUserRole);
  }
  final UsersRepository usersRepository;

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

  Future<void> _onCreateUser(CreateUser event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await usersRepository.createUser(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        job: event.job,
        role: event.role,
      );
      emit(UserOperationSuccess('User created successfully'));
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await usersRepository.updateUser(
        event.id,
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        job: event.job,
        isActive: event.isActive,
      );
      emit(UserOperationSuccess('User updated successfully'));
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await usersRepository.deleteUser(event.id);
      emit(UserOperationSuccess('User deleted successfully'));
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onChangeUserRole(ChangeUserRole event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await usersRepository.changeUserRole(event.id, event.role);
      emit(UserOperationSuccess('User role changed successfully'));
      final raw = await usersRepository.getUsers();
      emit(UsersLoaded(raw.map(UserModel.fromJson).toList()));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}
