import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/task_completion.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

/// The reminder [task] should have at [now], or null when it should have none:
/// deleted and finished tasks, tasks without a reminder time, and reminder
/// times already past.
ReminderRequest? planReminder(TodoTask task, DateTime now) {
  final at = task.reminderAt;
  if (task.isDeleted || task.isDone || at == null || !at.isAfter(now)) {
    return null;
  }
  final due = task.dueDate;
  return ReminderRequest(
    taskId: task.id,
    title: task.title,
    body: due == null ? null : DateFormat('EEE, d MMM').format(due),
    at: at,
  );
}

/// Every reminder that should be pending at [now], soonest first.
List<ReminderRequest> planReminders(Iterable<TodoTask> tasks, DateTime now) {
  final plan = [for (final task in tasks) ?planReminder(task, now)]
    ..sort((a, b) => a.at.compareTo(b.at));
  return plan;
}

/// A stable positive 31-bit number for a task id (Android notification ids are
/// ints). `String.hashCode` differs between runs, so this is FNV-1a over the
/// UTF-8 bytes.
int reminderNotificationId(String taskId) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(taskId)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// The tasks that change when a notification's button is pressed on [task].
///
/// * complete — [completionChanges] (a repeating task gets its next one);
/// * in an hour — the reminder moves to `now + 1 h`;
/// * tomorrow — the reminder moves to tomorrow at the same time of day.
///
/// [ReminderAction.open] changes nothing.
List<TodoTask> applyReminderAction({
  required ReminderAction action,
  required TodoTask task,
  required Iterable<TodoTask> all,
  required DateTime now,
  required String Function() newId,
}) {
  TodoTask? find(String id) {
    for (final candidate in all) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  TodoTask moved(DateTime to) => task.copyWith(
    reminderAt: to,
    updatedAt: now.toUtc(),
    syncState: TodoTaskSyncState.pending,
  );

  switch (action) {
    case ReminderAction.open:
      return const [];
    case ReminderAction.complete:
      return completionChanges(
        base: task,
        done: true,
        find: find,
        today: TodoTask.dateOnly(now),
        now: now,
        newId: newId,
      );
    case ReminderAction.inAnHour:
      return [moved(now.add(const Duration(hours: 1)))];
    case ReminderAction.tomorrow:
      final time = task.reminderAt ?? now;
      return [
        moved(
          DateTime(now.year, now.month, now.day + 1, time.hour, time.minute),
        ),
      ];
  }
}
