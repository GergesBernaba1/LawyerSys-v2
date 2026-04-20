import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_bloc.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_event.dart';
import 'package:qadaya_lawyersys/features/workqueue/bloc/workqueue_state.dart';
import 'package:qadaya_lawyersys/features/workqueue/models/workqueue_task.dart';
import 'package:qadaya_lawyersys/features/workqueue/repositories/workqueue_repository.dart';

class FakeWorkqueueRepository extends WorkqueueRepository {
  List<WorkqueueTask> _tasks;
  String? lastStatusFilter;
  int? completedTaskId;

  FakeWorkqueueRepository(this._tasks) : super(ApiClient());

  @override
  Future<List<WorkqueueTask>> getMyTasks({String? status}) async {
    lastStatusFilter = status;
    if (status != null && status.isNotEmpty) {
      return _tasks.where((t) => t.status == status).toList();
    }
    return List.of(_tasks);
  }

  @override
  Future<void> completeTask(int id) async {
    completedTaskId = id;
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final t = _tasks[index];
      _tasks[index] = WorkqueueTask(
        id: t.id,
        title: t.title,
        description: t.description,
        status: 'Completed',
        priority: t.priority,
        dueDate: t.dueDate,
        caseCode: t.caseCode,
        assignedToName: t.assignedToName,
        assignedToId: t.assignedToId,
      );
    }
  }

  @override
  Future<void> updateTaskStatus(int id, String status) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final t = _tasks[index];
      _tasks[index] = WorkqueueTask(
        id: t.id,
        title: t.title,
        description: t.description,
        status: status,
        priority: t.priority,
        dueDate: t.dueDate,
        caseCode: t.caseCode,
        assignedToName: t.assignedToName,
        assignedToId: t.assignedToId,
      );
    }
  }

  @override
  Future<void> reassignTask(int id, int newEmployeeId) async {}
}

void main() {
  final task1 = WorkqueueTask(
    id: 1,
    title: 'Draft contract',
    status: 'Pending',
    priority: 'High',
  );
  final task2 = WorkqueueTask(
    id: 2,
    title: 'File motion',
    status: 'InProgress',
    priority: 'Medium',
  );

  late FakeWorkqueueRepository repo;
  late WorkqueueBloc bloc;

  setUp(() {
    repo = FakeWorkqueueRepository([task1, task2]);
    bloc = WorkqueueBloc(repository: repo);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('WorkqueueBloc', () {
    test('LoadWorkqueue emits WorkqueueLoading then WorkqueueLoaded', () async {
      final states = <WorkqueueState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(LoadWorkqueue());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0], isA<WorkqueueLoading>());
      expect(states[1], isA<WorkqueueLoaded>());

      final loaded = states[1] as WorkqueueLoaded;
      expect(loaded.tasks.length, 2);

      await sub.cancel();
    });

    test('LoadWorkqueue with status filter passes filter to repo', () async {
      final states = <WorkqueueState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(LoadWorkqueue(status: 'Pending'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states[0], isA<WorkqueueLoading>());
      expect(states[1], isA<WorkqueueLoaded>());

      final loaded = states[1] as WorkqueueLoaded;
      expect(loaded.tasks.length, 1);
      expect(loaded.tasks.first.status, 'Pending');
      expect(repo.lastStatusFilter, 'Pending');

      await sub.cancel();
    });

    test('CompleteTask calls repo and reloads with WorkqueueTaskUpdated then WorkqueueLoaded',
        () async {
      final states = <WorkqueueState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(CompleteTask(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states, containsAllInOrder([
        isA<WorkqueueTaskUpdated>(),
        isA<WorkqueueLoaded>(),
      ]));

      expect(repo.completedTaskId, 1);

      // Task 1 should now be Completed in the repo
      final tasks = await repo.getMyTasks();
      final completedTask = tasks.firstWhere((t) => t.id == 1);
      expect(completedTask.status, 'Completed');

      await sub.cancel();
    });
  });
}
