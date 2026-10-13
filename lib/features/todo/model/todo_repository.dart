import 'package:todo_app/features/todo/model/todo_task.dart';

/// The only door between the app and wherever tasks live.
///
/// Today that is local storage. A sync adapter can implement or decorate this
/// interface later without any change to the UI or controller.
abstract interface class TodoRepository {
  /// Returns active tasks and deletion tombstones for a future sync adapter.
  Future<List<TodoTask>> getAll();

  /// Upserts one versioned task. A remote adapter can merge by [TodoTask.id].
  Future<void> upsert(TodoTask task);

  /// Upserts several tasks in a single write, so multi-task changes (such as a
  /// recurring task and its next occurrence) are stored together or not at all.
  Future<void> upsertAll(Iterable<TodoTask> tasks);
}
