abstract class GovernmentsEvent {}

class LoadGovernments extends GovernmentsEvent {}

class RefreshGovernments extends GovernmentsEvent {}

class CreateGovernment extends GovernmentsEvent {
  final Map<String, dynamic> data;
  CreateGovernment(this.data);
}

class UpdateGovernment extends GovernmentsEvent {
  final String id;
  final Map<String, dynamic> data;
  UpdateGovernment(this.id, this.data);
}

class DeleteGovernment extends GovernmentsEvent {
  final String id;
  DeleteGovernment(this.id);
}
