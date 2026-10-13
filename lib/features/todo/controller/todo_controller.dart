import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/model/task_completion.dart';
import 'package:todo_app/features/todo/model/todo_repository.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_settings_store.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/reminders/reminder_planner.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

/// What the screens read and change. It owns the task list, the settings and
/// the week being shown, and is the only thing that talks to the repository.
///
/// Discrete actions (add, complete, delete) are written at once. Edits made
/// from the task card arrive on every keystroke, so those are collected and
/// written together after a short pause (or when [flush] is called).
class TodoController extends ChangeNotifier {
  TodoController({
    required this.repository,
    required this.settingsStore,
    DateTime Function()? clock,
    String Function()? newId,
    this.saveDelay = const Duration(milliseconds: 400),
    this.reminders = const NoopReminderService(),
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? _defaultId {
    _today = TodoTask.dateOnly(_clock());
    _weekStart = _startOfWeek(_today);
    _signals = reminders.signals.listen(_onSignal);
  }

  final TodoRepository repository;
  final TodoSettingsStore settingsStore;
  final ReminderService reminders;
  final Duration saveDelay;
  final DateTime Function() _clock;

  /// The controller's clock (injectable in tests).
  DateTime now() => _clock();
  final String Function() _newId;

  static String _defaultId() => newTaskId();

  final ValueNotifier<TodoSettings> settingsListenable = ValueNotifier(
    const TodoSettings(),
  );

  /// Whether the system lets the app show notifications (as far as we know).
  final ValueNotifier<ReminderPermission> reminderPermission = ValueNotifier(
    ReminderPermission.granted,
  );

  /// Set when a notification was tapped; the screen opens that task, then
  /// clears it.
  final ValueNotifier<String?> openRequest = ValueNotifier(null);

  late final StreamSubscription<ReminderSignal> _signals;
  bool _askedPermission = false;
  bool _warnedBlocked = false;

  List<TodoTask> _all = const [];
  final Map<String, TodoTask> _unsaved = {};
  Timer? _saveTimer;
  late DateTime _today;
  late DateTime _weekStart;
  bool _loading = true;
  bool _disposed = false;
  String? _problem;

  /// True until the first [load] finishes.
  bool get isLoading => _loading;

  /// A short, user-facing description of the last failure, or null.
  String? get problem => _problem;

  /// Every task that has not been deleted.
  List<TodoTask> get tasks =>
      List.unmodifiable(_all.where((t) => !t.isDeleted));

  TodoSettings get settings => settingsListenable.value;
  DateTime get today => _today;
  DateTime get weekStart => _weekStart;

  DateTime _startOfWeek(DateTime date) {
    final back = settings.weekStartsOn == DateTime.sunday
        ? date.weekday % 7
        : date.weekday - 1;
    return DateTime(date.year, date.month, date.day - back);
  }

  void clearProblem() {
    if (_problem == null) return;
    _problem = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ loading

  Future<void> load() async {
    try {
      settingsListenable.value = await settingsStore.load();
    } catch (_) {
      _problem = 'Could not read your settings.';
    }
    try {
      _all = await repository.getAll();
    } catch (_) {
      _problem = 'Could not read your tasks.';
    }
    _today = TodoTask.dateOnly(_clock());
    _weekStart = _startOfWeek(_today);
    _loading = false;
    await _rollOver();
    notifyListeners();
    await _replanReminders();
    await refreshReminderPermission();
    try {
      final launched = await reminders.takeLaunchTaskId();
      if (launched != null) openRequest.value = launched;
    } catch (_) {}
  }

  /// Reads the tasks again (a notification button changed them in the
  /// background) and re-plans the reminders.
  Future<void> reload() async {
    try {
      _all = await repository.getAll();
    } catch (_) {
      _problem = 'Could not read your tasks.';
    }
    if (!_disposed) notifyListeners();
    await _replanReminders();
  }

  /// Asks the platform whether notifications are allowed and remembers it.
  Future<void> refreshReminderPermission() async {
    try {
      reminderPermission.value = await reminders.permission();
      if (reminderPermission.value == ReminderPermission.granted) {
        _warnedBlocked = false;
      }
    } catch (_) {}
  }

  void _onSignal(ReminderSignal signal) {
    switch (signal.kind) {
      case ReminderSignalKind.open:
        if (signal.taskId != null) openRequest.value = signal.taskId;
      case ReminderSignalKind.dataChanged:
        unawaited(reload());
    }
  }

  // --------------------------------------------------------- reminders

  /// True when a notification may be shown; asks once if the system has not
  /// been asked yet, and says so (once) if it is switched off.
  Future<bool> _canNotify() async {
    var permission = await reminders.permission();
    if (permission != ReminderPermission.granted && !_askedPermission) {
      _askedPermission = true;
      permission = await reminders.requestPermission();
    }
    reminderPermission.value = permission;
    if (permission == ReminderPermission.granted) {
      _warnedBlocked = false;
      return true;
    }
    if (!_warnedBlocked) {
      _warnedBlocked = true;
      _problem =
          'Notifications are off for this app. Turn them on in your '
          "phone's settings to get reminders.";
      if (!_disposed) notifyListeners();
    }
    return false;
  }

  /// Schedules or cancels the reminder of each of [changed]. A reminder that
  /// cannot be scheduled never fails the task operation that caused it.
  Future<void> _syncReminders(Iterable<TodoTask> changed) async {
    if (!settings.notificationsEnabled) return;
    try {
      final now = _clock();
      for (final task in changed) {
        final request = planReminder(task, now);
        if (request == null) {
          await reminders.cancel(task.id);
        } else if (await _canNotify()) {
          await reminders.schedule(request);
        } else {
          return;
        }
      }
    } catch (_) {}
  }

  /// Makes the pending reminders match the tasks exactly.
  Future<void> _replanReminders() async {
    try {
      if (!settings.notificationsEnabled) {
        await reminders.replaceAll(const []);
        return;
      }
      final plan = planReminders(_all, _clock());
      if (plan.isNotEmpty && !await _canNotify()) return;
      await reminders.replaceAll(plan);
    } catch (_) {}
  }

  /// Call when the app returns to the foreground or the date may have
  /// changed. Moves "today" and, if the user was looking at the current week,
  /// the visible week with it.
  Future<void> refreshToday() async {
    final now = TodoTask.dateOnly(_clock());
    if (now == _today) return;
    final wasOnCurrentWeek = _weekStart == _startOfWeek(_today);
    _today = now;
    if (wasOnCurrentWeek) _weekStart = _startOfWeek(_today);
    await _rollOver();
    notifyListeners();
  }

  /// Carries open one-off tasks from earlier days over to today, if the
  /// setting is on. Repeating tasks are left alone: they have their own rhythm.
  Future<void> _rollOver() async {
    if (!settings.moveToNextDay) return;
    final moved = <TodoTask>[];
    for (final task in _all) {
      final due = task.dueDate;
      if (task.isDeleted ||
          task.isDone ||
          task.repeats ||
          due == null ||
          !due.isBefore(_today)) {
        continue;
      }
      moved.add(_touched(task.copyWith(dueDate: _today)));
    }
    if (moved.isEmpty) return;
    _replace(moved);
    await _write(moved);
  }

  // --------------------------------------------------------------- week

  void goToWeek(int offset) {
    _weekStart = DateTime(
      _weekStart.year,
      _weekStart.month,
      _weekStart.day + 7 * offset,
    );
    notifyListeners();
  }

  /// Shows the week that contains [date] (from the month view).
  void goToDate(DateTime date) {
    _weekStart = _startOfWeek(TodoTask.dateOnly(date));
    notifyListeners();
  }

  void goToCurrentWeek() {
    _weekStart = _startOfWeek(_today);
    notifyListeners();
  }

  // ------------------------------------------------------------ actions

  /// Adds a task on [date] (Someday when null). Returns whether it was saved.
  Future<bool> add(DateTime? date, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    final task = TodoTask.create(
      id: _newId(),
      title: trimmed,
      dueDate: date,
      now: _clock(),
    );
    _replace([task]);
    notifyListeners();
    return _write([task]);
  }

  /// Completes or reopens [task]. Completing a repeating task also creates
  /// its next occurrence; reopening it takes that occurrence away again
  /// (unless it has already been touched).
  Future<void> setDone(TodoTask task, bool done) async {
    final current = _byId(task.id) ?? task;
    final base = _carryOwned(task, current);
    await _commitDone(base, done);
  }

  /// Stages an edit from the task card.
  ///
  /// The card holds its own copy of the task, so fields that only the
  /// controller changes (the link to the next occurrence) are kept from the
  /// stored version.
  Future<void> update(TodoTask edited) async {
    final current = _byId(edited.id);
    if (current == null || current.isDeleted) return;
    final merged = _carryOwned(edited, current);

    if (merged.isDone != current.isDone) {
      await _commitDone(merged, merged.isDone);
      return;
    }
    final staged = _touched(merged);
    _replace([staged]);
    _unsaved[staged.id] = staged;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => unawaited(flush()));
    notifyListeners();
  }

  Future<void> delete(TodoTask task, RecurrenceScope scope) async {
    final current = _byId(task.id) ?? task;
    final doomed = <TodoTask>{current};
    final extra = <TodoTask>[];

    if (current.repeats ||
        current.spawnedTaskId != null ||
        _hasPredecessor(current)) {
      switch (scope) {
        case RecurrenceScope.onlyThis:
          // Only this one goes; the series carries on from the next day.
          if (!current.isDone) {
            final next = current.nextOccurrence(
              id: _newId(),
              today: _today,
              now: _clock(),
            );
            if (next != null) extra.add(next);
          }
        case RecurrenceScope.thisAndFuture:
          doomed.addAll(_openSuccessors(current));
        case RecurrenceScope.all:
          doomed.addAll(_openSuccessors(current));
          doomed.addAll(_predecessors(current));
      }
    }

    final now = _clock().toUtc();
    final changed = [
      for (final task in doomed)
        task.copyWith(
          deletedAt: now,
          updatedAt: now,
          syncState: TodoTaskSyncState.pending,
        ),
      ...extra,
    ];
    _unsaved.removeWhere((id, _) => doomed.any((task) => task.id == id));
    _replace(changed);
    notifyListeners();
    await _write(changed);
  }

  /// Moves [task] to [date] (Someday when null), between two neighbours.
  ///
  /// [afterId] and [beforeId] are the tasks that end up directly above and
  /// below it in what the person sees (either may be null at an end). The
  /// task only takes a new position number between theirs, so one move
  /// changes one task, which is what a device sync wants.
  Future<void> move(
    TodoTask task, {
    required DateTime? date,
    String? afterId,
    String? beforeId,
  }) async {
    final current = _byId(task.id);
    if (current == null || current.isDeleted) return;
    final day = date == null ? null : TodoTask.dateOnly(date);

    var others = sortedByOrder(
      _all.where(
        (t) =>
            !t.isDeleted &&
            t.id != current.id &&
            (day == null
                ? t.dueDate == null
                : t.dueDate != null && t.dueDate == day),
      ),
    );
    TodoTask? find(String? id) =>
        id == null ? null : others.where((t) => t.id == id).firstOrNull;

    final sameDay = current.dueDate == day;
    var prev = find(afterId);
    var next = find(beforeId);
    final changed = <TodoTask>[];

    // Dropped where it already is.
    if (sameDay &&
        (prev == null || prev.order < current.order) &&
        (next == null || current.order < next.order)) {
      return;
    }

    // Two neighbours with no room between them (or the same position):
    // space the whole list out again.
    if (prev != null &&
        next != null &&
        next.order >= prev.order &&
        next.order - prev.order < 1) {
      final spaced = [
        for (var i = 0; i < others.length; i++)
          _touched(others[i].copyWith(sortKey: (i + 1) * 1024.0)),
      ];
      changed.addAll(spaced);
      others = spaced;
      prev = find(afterId);
      next = find(beforeId);
    }

    final double key;
    if (prev != null && next != null && next.order > prev.order) {
      key = (prev.order + next.order) / 2;
    } else if (prev != null) {
      key = prev.order + 1024;
    } else if (next != null) {
      key = next.order - 1024;
    } else {
      key = _clock().millisecondsSinceEpoch.toDouble();
    }

    final moved = _touched(
      current.copyWith(dueDate: day, clearDueDate: day == null, sortKey: key),
    );
    changed.add(moved);
    _unsaved.remove(moved.id);
    _replace(changed);
    notifyListeners();
    await _write(changed);
  }

  Future<void> duplicate(TodoTask task) async {
    final copy = TodoTask.create(
      id: _newId(),
      title: task.title,
      notes: task.notes,
      dueDate: task.dueDate,
      reminderAt: task.reminderAt,
      color: task.color,
      recurrence: task.recurrence,
      subtasks: [
        for (final subtask in task.subtasks) subtask.copyWith(isDone: false),
      ],
      now: _clock(),
    );
    _replace([copy]);
    notifyListeners();
    await _write([copy]);
  }

  Future<void> updateSettings(TodoSettings next) async {
    final previous = settings;
    if (next == previous) return;
    settingsListenable.value = next;
    if (next.weekStartsOn != previous.weekStartsOn) {
      _weekStart = _startOfWeek(_weekStart);
    }
    if (next.moveToNextDay && !previous.moveToNextDay) await _rollOver();
    notifyListeners();
    try {
      await settingsStore.save(next);
    } catch (_) {
      _problem = 'Could not save your settings.';
      notifyListeners();
    }
    if (next.notificationsEnabled != previous.notificationsEnabled) {
      // Turning them on asks for permission now, in response to the user.
      await _replanReminders();
      await refreshReminderPermission();
    }
  }

  /// Writes any staged edits now.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (_unsaved.isEmpty) return;
    final batch = _unsaved.values.toList();
    _unsaved.clear();
    await _write(batch);
  }

  // ----------------------------------------------------------- internals

  TodoTask? _byId(String id) {
    for (final task in _all) {
      if (task.id == id) return task;
    }
    return null;
  }

  TodoTask _touched(TodoTask task) => task.copyWith(
    updatedAt: _clock().toUtc(),
    syncState: TodoTaskSyncState.pending,
  );

  /// [edited] with the fields only the controller owns taken from [current].
  TodoTask _carryOwned(TodoTask edited, TodoTask current) => edited.copyWith(
    spawnedTaskId: current.spawnedTaskId,
    clearSpawnedTaskId: current.spawnedTaskId == null,
    deletedAt: current.deletedAt,
    clearDeletedAt: current.deletedAt == null,
  );

  Future<void> _commitDone(TodoTask base, bool done) async {
    final changed = completionChanges(
      base: base,
      done: done,
      find: _byId,
      today: _today,
      now: _clock(),
      newId: _newId,
    );
    _unsaved.remove(base.id);
    _replace(changed);
    notifyListeners();
    await _write(changed);
  }

  bool _hasPredecessor(TodoTask task) =>
      _all.any((other) => other.spawnedTaskId == task.id && !other.isDeleted);

  /// Occurrences created after [task] that are still open.
  List<TodoTask> _openSuccessors(TodoTask task) {
    final found = <TodoTask>[];
    var nextId = task.spawnedTaskId;
    while (nextId != null) {
      final next = _byId(nextId);
      if (next == null || next.isDeleted) break;
      if (!next.isDone) found.add(next);
      nextId = next.spawnedTaskId;
    }
    return found;
  }

  /// Every earlier occurrence that led to [task].
  List<TodoTask> _predecessors(TodoTask task) {
    final found = <TodoTask>[];
    var current = task;
    while (true) {
      final before = _all
          .where(
            (other) => other.spawnedTaskId == current.id && !other.isDeleted,
          )
          .firstOrNull;
      if (before == null || found.contains(before)) break;
      found.add(before);
      current = before;
    }
    return found;
  }

  void _replace(List<TodoTask> changed) {
    final byId = {for (final task in changed) task.id: task};
    final next = [
      for (final task in _all) byId.remove(task.id) ?? task,
      ...byId.values,
    ];
    _all = next;
  }

  Future<bool> _write(List<TodoTask> batch) async {
    // Anything staged rides along, so a write never leaves an older staged
    // version behind to overwrite it later.
    final staged = _unsaved.values
        .where((task) => !batch.any((b) => b.id == task.id))
        .toList();
    _unsaved.clear();
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await repository.upsertAll([...staged, ...batch]);
      unawaited(_syncReminders([...staged, ...batch]));
      return true;
    } catch (_) {
      _problem = 'Could not save. Your last change is only on screen.';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    // Best effort: staged edits are written even though nobody is listening.
    if (_unsaved.isNotEmpty) {
      unawaited(
        repository.upsertAll(_unsaved.values.toList()).catchError((_) {}),
      );
      _unsaved.clear();
    }
    unawaited(_signals.cancel());
    reminderPermission.dispose();
    openRequest.dispose();
    settingsListenable.dispose();
    super.dispose();
  }
}
