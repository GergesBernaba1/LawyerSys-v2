abstract class WorkqueueEvent {}

class LoadWorkqueue extends WorkqueueEvent {
  LoadWorkqueue({this.status});
  final String? status;
}

class RefreshWorkqueue extends WorkqueueEvent {}

class UpdateTaskStatus extends WorkqueueEvent {
  UpdateTaskStatus(this.id, this.status);
  final int id;
  final String status;
}

class CompleteTask extends WorkqueueEvent {
  CompleteTask(this.id);
  final int id;
}

class ReassignTask extends WorkqueueEvent {
  ReassignTask(this.id, this.newEmployeeId);
  final int id;
  final int newEmployeeId;
}
