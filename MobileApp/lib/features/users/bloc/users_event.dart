abstract class UsersEvent {}

class LoadUsers extends UsersEvent {}

class SearchUsers extends UsersEvent {
  SearchUsers(this.query);
  final String query;
}

class RefreshUsers extends UsersEvent {}

class CreateUser extends UsersEvent {
  CreateUser({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.job,
    this.role = 'Employee',
  });
  final String email, password, firstName, lastName;
  final String? phoneNumber, job;
  final String role;
}

class UpdateUser extends UsersEvent {
  UpdateUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.job,
    this.isActive = true,
  });
  final String id, firstName, lastName;
  final String? phoneNumber, job;
  final bool isActive;
}

class DeleteUser extends UsersEvent {
  DeleteUser(this.id);
  final String id;
}

class ChangeUserRole extends UsersEvent {
  ChangeUserRole({required this.id, required this.role});
  final String id;
  final String role;
}
