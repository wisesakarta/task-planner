import 'dart:convert';

import 'package:todo_app/features/todo/model/todo_repository.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTodoRepository implements TodoRepository {
  SharedPreferencesTodoRepository({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _storageKey = 'todo.tasks.v1';

  /// Raw payload kept when the stored data had unreadable entries, so a later
  /// write never destroys the only copy.
  static const backupKey = 'todo.tasks.v1.corrupt_backup';

  final Future<SharedPreferences> Function() _preferencesLoader;

  // Serializes writes so concurrent upserts cannot overwrite each other's
  // read-modify-write cycle.
  Future<void> _writeQueue = Future.value();

  @override
  Future<List<TodoTask>> getAll() async {
    final preferences = await _preferencesLoader();
    // A notification button may have written from another isolate; read the
    // store, not this isolate's cache.
    await preferences.reload();
    return _read(preferences).tasks;
  }

  @override
  Future<void> upsert(TodoTask task) => upsertAll([task]);

  @override
  Future<void> upsertAll(Iterable<TodoTask> tasks) {
    final batch = List<TodoTask>.of(tasks);
    if (batch.isEmpty) return Future.value();

    final result = _writeQueue.then((_) => _upsertAll(batch));
    // Keep the queue alive after a failed write; the caller still sees the error.
    _writeQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _upsertAll(List<TodoTask> batch) async {
    final preferences = await _preferencesLoader();
    // A notification button may have written from another isolate; read the
    // store, not this isolate's cache.
    await preferences.reload();
    final snapshot = _read(preferences);

    if (snapshot.hasUnreadableData && !preferences.containsKey(backupKey)) {
      await preferences.setString(backupKey, snapshot.raw!);
    }

    final updatedTasks = [...snapshot.tasks];
    for (final task in batch) {
      final index = updatedTasks.indexWhere(
        (candidate) => candidate.id == task.id,
      );
      if (index == -1) {
        updatedTasks.add(task);
      } else {
        updatedTasks[index] = task;
      }
    }

    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updatedTasks.map((candidate) => candidate.toJson()).toList()),
    );
    if (!saved) throw StateError('Todo storage rejected the write.');
  }

  _Snapshot _read(SharedPreferences preferences) {
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const _Snapshot([], null, false);

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return _Snapshot(const [], raw, true);
    }
    if (decoded is! List<dynamic>) return _Snapshot(const [], raw, true);

    final tasks = <TodoTask>[];
    var hasUnreadableData = false;
    for (final entry in decoded) {
      try {
        tasks.add(TodoTask.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        hasUnreadableData = true;
      }
    }
    return _Snapshot(List.unmodifiable(tasks), raw, hasUnreadableData);
  }
}

class _Snapshot {
  const _Snapshot(this.tasks, this.raw, this.hasUnreadableData);

  final List<TodoTask> tasks;
  final String? raw;
  final bool hasUnreadableData;
}
