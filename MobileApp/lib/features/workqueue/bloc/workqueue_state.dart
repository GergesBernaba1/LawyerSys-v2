import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';

abstract class WorkqueueState {}

class WorkqueueInitial extends WorkqueueState {}

class WorkqueueLoading extends WorkqueueState {}

class WorkqueueLoaded extends WorkqueueState {
  WorkqueueLoaded(this.tasks);
  final List<WorkqueueTask> tasks;
}

class WorkqueueError extends WorkqueueState {
  WorkqueueError(this.message);
  final String message;
}

class WorkqueueTaskUpdated extends WorkqueueState {
  WorkqueueTaskUpdated(this.message);
  final String message;
}
