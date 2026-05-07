import 'package:qadaya_lawyersys/features/users/models/user_model.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  UsersLoaded(this.users);
  final List<UserModel> users;
}

class UsersError extends UsersState {
  UsersError(this.message);
  final String message;
}

class UserOperationSuccess extends UsersState {
  UserOperationSuccess(this.message);
  final String message;
}
