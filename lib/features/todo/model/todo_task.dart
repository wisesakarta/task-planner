import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';

enum TodoTaskSyncState { pending, synced, conflict }

class TodoTask {
  const TodoTask({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.notes = '',
    this.dueDate,
    this.reminderAt,
    this.color,
    this.recurrence,
    this.subtasks = const [],
    this.isDone = false,
    this.completedAt,
    this.spawnedTaskId,
    this.deletedAt,
    this.sortKey,
  });

  factory TodoTask.create({
    required String id,
    required String title,
    DateTime? now,
    String notes = '',
    DateTime? dueDate,
    DateTime? reminderAt,
    int? color,
    RecurrenceRule? recurrence,
    List<TodoSubtask> subtasks = const [],
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return TodoTask(
      id: id,
      title: title,
      notes: notes,
      dueDate: dueDate == null ? null : dateOnly(dueDate),
      reminderAt: reminderAt,
      color: color,
      recurrence: dueDate == null ? null : recurrence,
      subtasks: subtasks,
      sortKey: timestamp.millisecondsSinceEpoch.toDouble(),
      createdAt: timestamp,
      updatedAt: timestamp,
      syncState: TodoTaskSyncState.pending,
    );
  }

  /// Reads current data and every earlier format:
  ///
  /// * v1 had no notes, colour, reminder, subtasks or repeat;
  /// * v2 stored the reminder as `dueMinutes` + `remind`, repeat as an enum
  ///   name, and had `priority` / `tags`, which are no longer used.
  factory TodoTask.fromJson(Map<String, dynamic> json) {
    final dueDateText = json['dueDate'] as String?;
    final dueDate = dueDateText == null
        ? null
        : dateOnly(DateTime.parse(dueDateText));
    final reminderText = json['reminderAt'] as String?;
    final completedAt = json['completedAt'] as String?;
    final deletedAt = json['deletedAt'] as String?;
    final syncStateName = json['syncState'] as String?;

    DateTime? reminderAt;
    if (reminderText != null) {
      reminderAt = DateTime.parse(reminderText).toLocal();
    } else {
      final minutes = json['dueMinutes'];
      if (dueDate != null &&
          minutes is int &&
          (json['remind'] as bool? ?? false)) {
        reminderAt = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          0,
          minutes,
        );
      }
    }

    return TodoTask(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueDate: dueDate,
      reminderAt: reminderAt,
      color: json['color'] as int?,
      recurrence: dueDate == null
          ? null
          : RecurrenceRule.fromJson(json['recurrence']),
      subtasks: (json['subtasks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TodoSubtask.fromJson)
          .toList(growable: false),
      isDone: json['isDone'] as bool? ?? false,
      completedAt: completedAt == null
          ? null
          : DateTime.parse(completedAt).toUtc(),
      spawnedTaskId: json['spawnedTaskId'] as String?,
      sortKey: (json['sortKey'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      syncState: TodoTaskSyncState.values.firstWhere(
        (state) => state.name == syncStateName,
        orElse: () => TodoTaskSyncState.pending,
      ),
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt).toUtc(),
    );
  }

  final String id;
  final String title;
  final String notes;

  /// Local calendar day (time stripped), or null for a "Someday" task.
  final DateTime? dueDate;

  /// When to notify, in local time. Independent of [dueDate]: a reminder may
  /// fire on a different day than the one the task is planned for.
  final DateTime? reminderAt;

  /// Highlight colour as ARGB, or null for none.
  final int? color;

  /// Null when the task does not repeat. Only meaningful with a [dueDate].
  final RecurrenceRule? recurrence;
  final List<TodoSubtask> subtasks;
  final bool isDone;
  final DateTime? completedAt;

  /// Id of the next occurrence created when this recurring task was completed.
  final String? spawnedTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TodoTaskSyncState syncState;
  final DateTime? deletedAt;

  /// Where the task sits among the tasks of its day (or of Someday): smaller
  /// comes first. Null means "by creation time". Moving a task sets it to a
  /// number between its new neighbours, so no other task has to change
  /// (which keeps syncing cheap).
  final double? sortKey;

  /// [sortKey], or the creation time when the task was never moved.
  double get order => sortKey ?? createdAt.millisecondsSinceEpoch.toDouble();

  bool get isDeleted => deletedAt != null;
  bool get isSomeday => dueDate == null;
  bool get repeats => recurrence != null;

  int get totalSubtasks => subtasks.where((s) => !s.isHeading).length;
  int get completedSubtasks =>
      subtasks.where((s) => !s.isHeading && s.isDone).length;

  bool isOverdue(DateTime now) {
    final date = dueDate;
    if (isDone || date == null) return false;
    return date.isBefore(dateOnly(now));
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// A null argument keeps the current value; use the `clear*` flags to reset
  /// a nullable field. Repeat only makes sense with a due date, so it is
  /// dropped automatically when the date is cleared.
  TodoTask copyWith({
    String? title,
    String? notes,
    DateTime? dueDate,
    DateTime? reminderAt,
    int? color,
    RecurrenceRule? recurrence,
    List<TodoSubtask>? subtasks,
    bool? isDone,
    DateTime? completedAt,
    String? spawnedTaskId,
    DateTime? updatedAt,
    TodoTaskSyncState? syncState,
    DateTime? deletedAt,
    double? sortKey,
    bool clearDueDate = false,
    bool clearReminder = false,
    bool clearColor = false,
    bool clearRecurrence = false,
    bool clearCompletedAt = false,
    bool clearSpawnedTaskId = false,
    bool clearDeletedAt = false,
  }) {
    final nextDueDate = clearDueDate
        ? null
        : (dueDate == null ? this.dueDate : dateOnly(dueDate));

    return TodoTask(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: nextDueDate,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      color: clearColor ? null : (color ?? this.color),
      recurrence: nextDueDate == null || clearRecurrence
          ? null
          : (recurrence ?? this.recurrence),
      subtasks: subtasks ?? this.subtasks,
      isDone: isDone ?? this.isDone,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      spawnedTaskId: clearSpawnedTaskId
          ? null
          : (spawnedTaskId ?? this.spawnedTaskId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      sortKey: sortKey ?? this.sortKey,
    );
  }

  /// The next occurrence of a repeating task that is being completed on
  /// [today], or null if the task does not repeat or the rule has ended.
  ///
  /// The copy keeps the title, notes, colour and rule, starts with a fresh
  /// (unchecked) checklist, and moves the reminder by the same number of days
  /// as the due date, keeping its time of day.
  TodoTask? nextOccurrence({
    required String id,
    required DateTime today,
    required DateTime now,
  }) {
    final rule = recurrence;
    final due = dueDate;
    if (rule == null || due == null) return null;

    final nextDue = rule.nextDue(due, today);
    if (nextDue == null) return null;

    final shiftDays = DateTime.utc(
      nextDue.year,
      nextDue.month,
      nextDue.day,
    ).difference(DateTime.utc(due.year, due.month, due.day)).inDays;
    final reminder = reminderAt;
    final timestamp = now.toUtc();

    return TodoTask(
      id: id,
      title: title,
      notes: notes,
      dueDate: nextDue,
      reminderAt: reminder == null
          ? null
          : DateTime(
              reminder.year,
              reminder.month,
              reminder.day + shiftDays,
              reminder.hour,
              reminder.minute,
            ),
      color: color,
      recurrence: rule,
      subtasks: [
        for (final subtask in subtasks) subtask.copyWith(isDone: false),
      ],
      createdAt: timestamp,
      updatedAt: timestamp,
      syncState: TodoTaskSyncState.pending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'dueDate': dueDate?.toIso8601String(),
    'reminderAt': reminderAt?.toUtc().toIso8601String(),
    'color': color,
    'recurrence': recurrence?.toJson(),
    'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
    'isDone': isDone,
    'completedAt': completedAt?.toIso8601String(),
    'spawnedTaskId': spawnedTaskId,
    'sortKey': sortKey,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'syncState': syncState.name,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// [tasks] in the order the user keeps them: by [TodoTask.order], and in the
/// order given when two share a position.
List<TodoTask> sortedByOrder(Iterable<TodoTask> tasks) {
  final indexed = tasks.toList().asMap().entries.toList()
    ..sort((a, b) {
      final byOrder = a.value.order.compareTo(b.value.order);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
  return [for (final entry in indexed) entry.value];
}
