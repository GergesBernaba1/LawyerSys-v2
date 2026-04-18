abstract class WorkqueueEvent {}

class LoadWorkqueue extends WorkqueueEvent {
  final String? status;
  LoadWorkqueue({this.status});
}

class RefreshWorkqueue extends WorkqueueEvent {}

class UpdateTaskStatus extends WorkqueueEvent {
  final int id;
  final String status;
  UpdateTaskStatus(this.id, this.status);
}

class CompleteTask extends WorkqueueEvent {
  final int id;
  CompleteTask(this.id);
}

class ReassignTask extends WorkqueueEvent {
  final int id;
  final int newEmployeeId;
  ReassignTask(this.id, this.newEmployeeId);
}
