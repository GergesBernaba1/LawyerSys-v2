abstract class UsersEvent {}

class LoadUsers extends UsersEvent {}

class SearchUsers extends UsersEvent {
  final String query;
  SearchUsers(this.query);
}

class RefreshUsers extends UsersEvent {}

class CreateUser extends UsersEvent {
  final String email, password, firstName, lastName;
  final String? phoneNumber, job;
  final String role;
  CreateUser({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.job,
    this.role = 'Employee',
  });
}

class UpdateUser extends UsersEvent {
  final String id, firstName, lastName;
  final String? phoneNumber, job;
  final bool isActive;
  UpdateUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.job,
    this.isActive = true,
  });
}

class DeleteUser extends UsersEvent {
  final String id;
  DeleteUser(this.id);
}
