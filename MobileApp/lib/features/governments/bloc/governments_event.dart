abstract class GovernmentsEvent {}

class LoadGovernments extends GovernmentsEvent {}

class LoadGovernmentsNextPage extends GovernmentsEvent {}

class RefreshGovernments extends GovernmentsEvent {}

class SearchGovernments extends GovernmentsEvent {
  SearchGovernments(this.query);
  final String query;
}

class CreateGovernment extends GovernmentsEvent {
  CreateGovernment(this.data);
  final Map<String, dynamic> data;
}

class UpdateGovernment extends GovernmentsEvent {
  UpdateGovernment(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

class DeleteGovernment extends GovernmentsEvent {
  DeleteGovernment(this.id);
  final String id;
}
