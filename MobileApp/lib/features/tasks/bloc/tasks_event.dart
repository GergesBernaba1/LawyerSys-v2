abstract class TasksEvent {}

class LoadTasks extends TasksEvent {}

class SearchTasks extends TasksEvent {
  final String query;
  SearchTasks(this.query);
}

class RefreshTasks extends TasksEvent {}

class AddTask extends TasksEvent {
  final Task task;
  AddTask(this.task);
}

class UpdateTask extends TasksEvent {
  final Task task;
  UpdateTask(this.task);
}

class DeleteTask extends TasksEvent {
  final int taskId;
  DeleteTask(this.taskId);
}