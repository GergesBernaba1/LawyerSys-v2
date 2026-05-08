import 'package:qadaya_lawyersys/features/tasks/models/task.dart';

abstract class TasksState {}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  TasksLoaded(this.tasks);
  final List<Task> tasks;
}

class TasksError extends TasksState {
  TasksError(this.message);
  final String message;
}

class UpcomingTasksLoaded extends TasksState {
  UpcomingTasksLoaded(this.tasks);
  final List<Task> tasks;
}

class EmployeeTasksLoaded extends TasksState {
  EmployeeTasksLoaded({required this.tasks, required this.employeeId});
  final List<Task> tasks;
  final int employeeId;
}
