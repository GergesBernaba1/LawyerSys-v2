import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/workqueue_repository.dart';
import 'workqueue_event.dart';
import 'workqueue_state.dart';

class WorkqueueBloc extends Bloc<WorkqueueEvent, WorkqueueState> {
  final WorkqueueRepository repository;

  // Track the active filter so reloads use the same filter.
  String? _activeStatus;

  WorkqueueBloc({required this.repository}) : super(WorkqueueInitial()) {
    on<LoadWorkqueue>(_onLoadWorkqueue);
    on<RefreshWorkqueue>(_onRefreshWorkqueue);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
    on<CompleteTask>(_onCompleteTask);
    on<ReassignTask>(_onReassignTask);
  }

  Future<void> _onLoadWorkqueue(
      LoadWorkqueue event, Emitter<WorkqueueState> emit) async {
    _activeStatus = event.status;
    emit(WorkqueueLoading());
    try {
      final tasks = await repository.getMyTasks(status: _activeStatus);
      emit(WorkqueueLoaded(tasks));
    } catch (e) {
      emit(WorkqueueError(e.toString()));
    }
  }

  Future<void> _onRefreshWorkqueue(
      RefreshWorkqueue event, Emitter<WorkqueueState> emit) async {
    try {
      final tasks = await repository.getMyTasks(status: _activeStatus);
      emit(WorkqueueLoaded(tasks));
    } catch (e) {
      emit(WorkqueueError(e.toString()));
    }
  }

  Future<void> _onUpdateTaskStatus(
      UpdateTaskStatus event, Emitter<WorkqueueState> emit) async {
    try {
      await repository.updateTaskStatus(event.id, event.status);
      emit(WorkqueueTaskUpdated('Task status updated to ${event.status}'));
      final tasks = await repository.getMyTasks(status: _activeStatus);
      emit(WorkqueueLoaded(tasks));
    } catch (e) {
      emit(WorkqueueError(e.toString()));
    }
  }

  Future<void> _onCompleteTask(
      CompleteTask event, Emitter<WorkqueueState> emit) async {
    try {
      await repository.completeTask(event.id);
      emit(WorkqueueTaskUpdated('Task marked as complete'));
      final tasks = await repository.getMyTasks(status: _activeStatus);
      emit(WorkqueueLoaded(tasks));
    } catch (e) {
      emit(WorkqueueError(e.toString()));
    }
  }

  Future<void> _onReassignTask(
      ReassignTask event, Emitter<WorkqueueState> emit) async {
    try {
      await repository.reassignTask(event.id, event.newEmployeeId);
      emit(WorkqueueTaskUpdated('Task reassigned successfully'));
      final tasks = await repository.getMyTasks(status: _activeStatus);
      emit(WorkqueueLoaded(tasks));
    } catch (e) {
      emit(WorkqueueError(e.toString()));
    }
  }
}
