import 'package:qadaya_lawyersys/features/tasks/models/task.dart';

abstract class TasksEvent {}

class LoadTasks extends TasksEvent {}

class SearchTasks extends TasksEvent {
  SearchTasks(this.query);
  final String query;
}

class RefreshTasks extends TasksEvent {}

class AddTask extends TasksEvent {
  AddTask(this.task);
  final Task task;
}

class UpdateTask extends TasksEvent {
  UpdateTask(this.task);
  final Task task;
}

class DeleteTask extends TasksEvent {
  DeleteTask(this.taskId);
  final int taskId;
}

class LoadUpcomingTasks extends TasksEvent {}

class LoadTasksByEmployee extends TasksEvent {
  LoadTasksByEmployee(this.employeeId);
  final int employeeId;
}
