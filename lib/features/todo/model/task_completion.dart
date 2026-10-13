import 'package:todo_app/features/todo/model/todo_task.dart';

/// The tasks that change when [base] is completed ([done] true) or reopened.
///
/// * Completing a repeating task also creates its next occurrence (once).
/// * Reopening a task takes back the next occurrence it created, if nobody has
///   touched that one yet.
///
/// The last element is always [base] itself, updated. [find] looks a task up
/// by id (for the occurrence a reopened task once created). This is pure so the
/// app and the notification's "Mark as completed" action share one rule.
List<TodoTask> completionChanges({
  required TodoTask base,
  required bool done,
  required TodoTask? Function(String id) find,
  required DateTime today,
  required DateTime now,
  required String Function() newId,
}) {
  final stamp = now.toUtc();
  var completed = done
      ? base.copyWith(isDone: true, completedAt: stamp)
      : base.copyWith(isDone: false, clearCompletedAt: true);
  completed = completed.copyWith(
    updatedAt: stamp,
    syncState: TodoTaskSyncState.pending,
  );
  final changed = <TodoTask>[];

  if (done && completed.repeats && completed.spawnedTaskId == null) {
    final next = completed.nextOccurrence(id: newId(), today: today, now: now);
    if (next != null) {
      completed = completed.copyWith(spawnedTaskId: next.id);
      changed.add(next);
    }
  } else if (!done && completed.spawnedTaskId != null) {
    final spawned = find(completed.spawnedTaskId!);
    if (spawned != null && !spawned.isDone && !spawned.isDeleted) {
      changed.add(
        spawned.copyWith(
          deletedAt: stamp,
          updatedAt: stamp,
          syncState: TodoTaskSyncState.pending,
        ),
      );
      completed = completed.copyWith(clearSpawnedTaskId: true);
    }
  }

  changed.add(completed);
  return changed;
}

int _idCounter = 0;

/// A new task id, unique on this device (microsecond clock plus a counter).
String newTaskId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
