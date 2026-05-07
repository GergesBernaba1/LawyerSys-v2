import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_event.dart';
import 'package:qadaya_lawyersys/features/tasks/bloc/tasks_state.dart';
import 'package:qadaya_lawyersys/features/tasks/models/task.dart';
import 'package:qadaya_lawyersys/features/tasks/repositories/tasks_repository.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {

  TasksBloc({required this.tasksRepository}) : super(TasksInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<SearchTasks>(_onSearchTasks);
    on<RefreshTasks>(_onRefreshTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
  }
  final TasksRepository tasksRepository;
  final List<Task> _tasks = [];

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await tasksRepository.getTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onSearchTasks(SearchTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final results = await tasksRepository.searchTasks(event.query);
      emit(TasksLoaded(results));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onRefreshTasks(RefreshTasks event, Emitter<TasksState> emit) async {
    try {
      final tasks = await tasksRepository.getTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      await tasksRepository.addTask(event.task);
      // Reload tasks to get the updated list
      final tasks = await tasksRepository.getTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      emit(TasksLoaded(_tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      await tasksRepository.updateTask(event.task);
      // Reload tasks to get the updated list
      final tasks = await tasksRepository.getTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      emit(TasksLoaded(_tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      await tasksRepository.deleteTask(event.taskId);
      // Reload tasks to get the updated list
      final tasks = await tasksRepository.getTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      emit(TasksLoaded(_tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
