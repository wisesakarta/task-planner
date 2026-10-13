import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

void main() {
  group('TodoTask', () {
    test('serializes stable sync fields without losing timestamps', () {
      final createdAt = DateTime.utc(2026, 9, 30, 9, 0);
      final task = TodoTask(
        id: 'task-1',
        title: 'Prepare sync contract',
        dueDate: DateTime(2026, 10, 2),
        createdAt: createdAt,
        updatedAt: createdAt,
        isDone: false,
        syncState: TodoTaskSyncState.pending,
      );

      final restored = TodoTask.fromJson(task.toJson());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.dueDate, DateTime(2026, 10, 2));
      expect(restored.createdAt, createdAt);
      expect(restored.syncState, TodoTaskSyncState.pending);
    });

    test('preserves a tombstone for future device synchronization', () {
      final now = DateTime.utc(2026, 9, 30, 9, 0);
      final task = TodoTask(
        id: 'task-1',
        title: 'Remove me',
        dueDate: DateTime(2026, 10, 2),
        createdAt: now,
        updatedAt: now,
        isDone: false,
        syncState: TodoTaskSyncState.pending,
      );

      final deleted = task.copyWith(
        deletedAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.deletedAt, now.add(const Duration(minutes: 1)));
    });
  });

  group('TodoTask order', () {
    final created = DateTime.utc(2026, 9, 30, 9, 0);

    test('a new task is ordered by its creation time', () {
      final task = TodoTask.create(id: 'a', title: 'A', now: created);
      expect(task.sortKey, created.millisecondsSinceEpoch.toDouble());
      expect(task.order, created.millisecondsSinceEpoch.toDouble());
    });

    test('a task saved before ordering existed falls back to createdAt', () {
      final json = TodoTask.create(id: 'a', title: 'A', now: created).toJson()
        ..remove('sortKey');
      final restored = TodoTask.fromJson(json);
      expect(restored.sortKey, isNull);
      expect(restored.order, created.millisecondsSinceEpoch.toDouble());
    });

    test('a moved task keeps its position through JSON', () {
      final moved = TodoTask.create(
        id: 'a',
        title: 'A',
        now: created,
      ).copyWith(sortKey: 1234.5);
      expect(moved.order, 1234.5);
      expect(TodoTask.fromJson(moved.toJson()).order, 1234.5);
    });

    test('copyWith without a sortKey keeps the current one', () {
      final task = TodoTask.create(
        id: 'a',
        title: 'A',
        now: created,
      ).copyWith(sortKey: 7);
      expect(task.copyWith(title: 'B').order, 7);
    });
  });
}
