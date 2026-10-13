import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/reminders/reminder_planner.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

// Wednesday 30 September 2026, 10:00.
final _now = DateTime(2026, 9, 30, 10);

TodoTask _task(
  String id, {
  DateTime? due,
  DateTime? reminder,
  bool done = false,
  bool deleted = false,
  RecurrenceRule? recurrence,
  String title = 'Buy milk',
}) => TodoTask.create(
  id: id,
  title: title,
  dueDate: due,
  reminderAt: reminder,
  recurrence: recurrence,
  now: _now,
).copyWith(isDone: done, deletedAt: deleted ? _now : null);

void main() {
  group('planReminder', () {
    test('a future reminder becomes a request with the task title', () {
      final task = _task(
        'a',
        due: DateTime(2026, 10, 2),
        reminder: DateTime(2026, 10, 2, 9),
      );
      final request = planReminder(task, _now)!;
      expect(request.taskId, 'a');
      expect(request.title, 'Buy milk');
      expect(request.at, DateTime(2026, 10, 2, 9));
      expect(request.body, 'Fri, 2 Oct');
    });

    test('a Someday task has no body line', () {
      final request = planReminder(
        _task('a', reminder: DateTime(2026, 10, 2, 9)),
        _now,
      )!;
      expect(request.body, isNull);
    });

    test('nothing for a task without a reminder', () {
      expect(
        planReminder(_task('a', due: DateTime(2026, 10, 2)), _now),
        isNull,
      );
    });

    test('nothing for a reminder in the past or right now', () {
      expect(
        planReminder(_task('a', reminder: DateTime(2026, 9, 30, 9)), _now),
        isNull,
      );
      expect(planReminder(_task('a', reminder: _now), _now), isNull);
    });

    test('nothing for finished or deleted tasks', () {
      final at = DateTime(2026, 10, 2, 9);
      expect(planReminder(_task('a', reminder: at, done: true), _now), isNull);
      expect(
        planReminder(_task('a', reminder: at, deleted: true), _now),
        isNull,
      );
    });
  });

  group('planReminders', () {
    test('keeps the ones that apply, soonest first', () {
      final plan = planReminders([
        _task('late', reminder: DateTime(2026, 10, 5, 9)),
        _task('past', reminder: DateTime(2026, 9, 1, 9)),
        _task('soon', reminder: DateTime(2026, 9, 30, 12)),
        _task('none'),
        _task('done', reminder: DateTime(2026, 10, 1, 9), done: true),
      ], _now);
      expect(plan.map((r) => r.taskId), ['soon', 'late']);
    });
  });

  group('reminderNotificationId', () {
    test('is stable, positive and fits 31 bits', () {
      final id = reminderNotificationId('abc-123');
      expect(reminderNotificationId('abc-123'), id);
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThan(1 << 31));
    });

    test('differs for different tasks', () {
      final ids = {
        for (var i = 0; i < 500; i++) reminderNotificationId('task-$i'),
      };
      expect(ids.length, 500);
    });

    test('has a known value (FNV-1a), so it never changes between runs', () {
      expect(reminderNotificationId(''), 0x811c9dc5 & 0x7fffffff);
      expect(reminderNotificationId('a'), 0xe40c292c & 0x7fffffff);
    });
  });

  group('applyReminderAction', () {
    int counter = 0;
    String newId() => 'n${counter++}';

    setUp(() => counter = 0);

    test('open changes nothing', () {
      final task = _task('a', reminder: DateTime(2026, 10, 2, 9));
      expect(
        applyReminderAction(
          action: ReminderAction.open,
          task: task,
          all: [task],
          now: _now,
          newId: newId,
        ),
        isEmpty,
      );
    });

    test('complete finishes the task', () {
      final task = _task('a', reminder: DateTime(2026, 10, 2, 9));
      final changed = applyReminderAction(
        action: ReminderAction.complete,
        task: task,
        all: [task],
        now: _now,
        newId: newId,
      );
      expect(changed, hasLength(1));
      expect(changed.single.isDone, isTrue);
      expect(changed.single.completedAt, isNotNull);
      expect(changed.single.syncState, TodoTaskSyncState.pending);
    });

    test('complete on a repeating task also creates the next one', () {
      final task = _task(
        'a',
        due: DateTime(2026, 9, 30),
        reminder: DateTime(2026, 9, 30, 12),
        recurrence: const RecurrenceRule.daily(),
      );
      final changed = applyReminderAction(
        action: ReminderAction.complete,
        task: task,
        all: [task],
        now: _now,
        newId: newId,
      );
      expect(changed, hasLength(2));
      expect(changed.first.id, 'n0');
      expect(changed.first.dueDate, DateTime(2026, 10, 1));
      expect(changed.first.reminderAt, DateTime(2026, 10, 1, 12));
      expect(changed.last.spawnedTaskId, 'n0');
    });

    test('"in an hour" moves the reminder to now + 1 hour', () {
      final task = _task('a', reminder: DateTime(2026, 9, 30, 9, 45));
      final changed = applyReminderAction(
        action: ReminderAction.inAnHour,
        task: task,
        all: [task],
        now: _now,
        newId: newId,
      );
      expect(changed.single.reminderAt, DateTime(2026, 9, 30, 11));
      expect(changed.single.isDone, isFalse);
    });

    test('"tomorrow" keeps the time of day and moves to the next day', () {
      final task = _task('a', reminder: DateTime(2026, 9, 30, 9, 45));
      final changed = applyReminderAction(
        action: ReminderAction.tomorrow,
        task: task,
        all: [task],
        now: _now,
        newId: newId,
      );
      expect(changed.single.reminderAt, DateTime(2026, 10, 1, 9, 45));
    });

    test('"tomorrow" at the end of a month and year rolls over', () {
      final task = _task('a', reminder: DateTime(2026, 12, 31, 8));
      final changed = applyReminderAction(
        action: ReminderAction.tomorrow,
        task: task,
        all: [task],
        now: DateTime(2026, 12, 31, 7),
        newId: newId,
      );
      expect(changed.single.reminderAt, DateTime(2027, 1, 1, 8));
    });

    test('moving a reminder marks the task as needing sync', () {
      final task = _task('a', reminder: DateTime(2026, 9, 30, 9, 45));
      final changed = applyReminderAction(
        action: ReminderAction.inAnHour,
        task: task,
        all: [task],
        now: _now,
        newId: newId,
      );
      expect(changed.single.syncState, TodoTaskSyncState.pending);
      expect(changed.single.updatedAt.isBefore(_now.toUtc()), isFalse);
    });
  });
}
