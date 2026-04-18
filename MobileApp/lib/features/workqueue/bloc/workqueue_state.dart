import '../models/workqueue_task.dart';

abstract class WorkqueueState {}

class WorkqueueInitial extends WorkqueueState {}

class WorkqueueLoading extends WorkqueueState {}

class WorkqueueLoaded extends WorkqueueState {
  final List<WorkqueueTask> tasks;
  WorkqueueLoaded(this.tasks);
}

class WorkqueueError extends WorkqueueState {
  final String message;
  WorkqueueError(this.message);
}

class WorkqueueTaskUpdated extends WorkqueueState {
  final String message;
  WorkqueueTaskUpdated(this.message);
}
