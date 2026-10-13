import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/data/shared_preferences_todo_repository.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  repositoryRobustnessTests();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('upsert persists a task and preserves its sync metadata', () async {
    final repository = SharedPreferencesTodoRepository();
    final updatedAt = DateTime.utc(2026, 9, 30, 9, 0);
    final task = TodoTask(
      id: 'task-1',
      title: 'Write sync adapter',
      dueDate: DateTime(2026, 10, 2),
      createdAt: updatedAt,
      updatedAt: updatedAt,
      isDone: false,
      syncState: TodoTaskSyncState.pending,
    );

    await repository.upsert(task);
    final persistedTasks = await repository.getAll();

    expect(persistedTasks, hasLength(1));
    expect(persistedTasks.single.toJson(), task.toJson());
  });
}

TodoTask _task(String id, {String? title}) {
  final now = DateTime.utc(2026, 9, 30, 9, 0);
  return TodoTask(
    id: id,
    title: title ?? 'Task $id',
    dueDate: DateTime(2026, 10, 2),
    createdAt: now,
    updatedAt: now,
    isDone: false,
    syncState: TodoTaskSyncState.pending,
  );
}

void repositoryRobustnessTests() {
  group('SharedPreferencesTodoRepository robustness', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('concurrent upserts do not overwrite each other', () async {
      final repository = SharedPreferencesTodoRepository();

      await Future.wait([
        for (var i = 0; i < 10; i++) repository.upsert(_task('task-$i')),
      ]);

      final ids = (await repository.getAll()).map((task) => task.id).toSet();
      expect(ids, {for (var i = 0; i < 10; i++) 'task-$i'});
    });

    test('skips one unreadable entry instead of dropping every task', () async {
      final good = _task('good');
      SharedPreferences.setMockInitialValues({
        'todo.tasks.v1': jsonEncode([
          good.toJson(),
          'garbage',
          {'id': 1},
        ]),
      });
      final repository = SharedPreferencesTodoRepository();

      final tasks = await repository.getAll();

      expect(tasks.map((task) => task.id), ['good']);
    });

    test('keeps a backup of unreadable data before overwriting it', () async {
      const corrupt = '{not json';
      SharedPreferences.setMockInitialValues({'todo.tasks.v1': corrupt});
      final repository = SharedPreferencesTodoRepository();

      await repository.upsert(_task('fresh'));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(SharedPreferencesTodoRepository.backupKey),
        corrupt,
      );
      expect((await repository.getAll()).single.id, 'fresh');
    });

    test('a failed write does not block later writes', () async {
      var fail = true;
      final repository = SharedPreferencesTodoRepository(
        preferencesLoader: () async {
          if (fail) throw StateError('disk full');
          return SharedPreferences.getInstance();
        },
      );

      await expectLater(repository.upsert(_task('a')), throwsStateError);
      fail = false;
      await repository.upsert(_task('b'));

      expect((await repository.getAll()).single.id, 'b');
    });
  });
}
