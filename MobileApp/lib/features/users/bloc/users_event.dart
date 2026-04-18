abstract class UsersEvent {}

class LoadUsers extends UsersEvent {}

class SearchUsers extends UsersEvent {
  final String query;
  SearchUsers(this.query);
}

class RefreshUsers extends UsersEvent {}
