import 'dart:async';

import 'package:todo_app/features/todo/model/todo_repository.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_settings_store.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

/// An in-memory [TodoRepository] that records every write.
class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository([Iterable<TodoTask> initial = const []])
    : stored = {for (final task in initial) task.id: task};

  final Map<String, TodoTask> stored;

  /// One entry per `upsertAll` call: the ids written.
  final List<List<String>> writes = [];

  /// Make the next writes fail.
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<List<TodoTask>> getAll() async {
    if (failReads) throw StateError('read failed');
    return stored.values.toList();
  }

  @override
  Future<void> upsert(TodoTask task) => upsertAll([task]);

  @override
  Future<void> upsertAll(Iterable<TodoTask> tasks) async {
    if (failWrites) throw StateError('write failed');
    final batch = tasks.toList();
    writes.add([for (final task in batch) task.id]);
    for (final task in batch) {
      stored[task.id] = task;
    }
  }
}

class FakeSettingsStore implements TodoSettingsStore {
  FakeSettingsStore([this.settings = const TodoSettings()]);

  TodoSettings settings;
  int saves = 0;
  bool failSaves = false;

  @override
  Future<TodoSettings> load() async => settings;

  @override
  Future<void> save(TodoSettings next) async {
    if (failSaves) throw StateError('save failed');
    saves++;
    settings = next;
  }
}

/// Records reminder calls; permission and failures can be controlled.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.granted = true, this.canRequest = true});

  /// Whether notifications are currently allowed.
  bool granted;

  /// Whether asking the user would grant permission.
  bool canRequest;

  /// Make scheduling throw.
  bool failing = false;

  final pending = <String, ReminderRequest>{};
  final calls = <String>[];
  String? launchTaskId;
  int permissionRequests = 0;

  final _signals = StreamController<ReminderSignal>.broadcast();

  void emit(ReminderSignal signal) => _signals.add(signal);

  @override
  Stream<ReminderSignal> get signals => _signals.stream;

  @override
  Future<ReminderPermission> permission() async =>
      granted ? ReminderPermission.granted : ReminderPermission.denied;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    if (canRequest) granted = true;
    return permission();
  }

  @override
  Future<void> schedule(ReminderRequest request) async {
    if (failing) throw StateError('cannot schedule');
    calls.add('schedule ${request.taskId}');
    pending[request.taskId] = request;
  }

  @override
  Future<void> cancel(String taskId) async {
    if (failing) throw StateError('cannot cancel');
    calls.add('cancel $taskId');
    pending.remove(taskId);
  }

  @override
  Future<void> replaceAll(List<ReminderRequest> requests) async {
    if (failing) throw StateError('cannot replace');
    calls.add('replaceAll ${requests.length}');
    pending
      ..clear()
      ..addEntries(requests.map((r) => MapEntry(r.taskId, r)));
  }

  @override
  Future<String?> takeLaunchTaskId() async {
    final id = launchTaskId;
    launchTaskId = null;
    return id;
  }
}
