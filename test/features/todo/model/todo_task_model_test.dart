import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

void main() {
  final created = DateTime.utc(2026, 9, 30, 9);

  TodoTask fullTask() => TodoTask(
    id: 't',
    title: 'Full',
    notes: 'Some notes',
    dueDate: DateTime(2026, 10, 2),
    reminderAt: DateTime(2026, 10, 1, 9, 30),
    color: 0xFFFFEB3B,
    recurrence: const RecurrenceRule.weekly(),
    subtasks: const [
      TodoSubtask(id: 'h', title: 'Launch', kind: TodoSubtaskKind.heading),
      TodoSubtask(id: 's1', title: 'One', isDone: true),
      TodoSubtask(id: 's2', title: 'Two', level: 1),
    ],
    createdAt: created,
    updatedAt: created,
    syncState: TodoTaskSyncState.pending,
  );

  group('serialization', () {
    test('round-trips every field', () {
      final task = fullTask();
      final restored = TodoTask.fromJson(task.toJson());

      expect(restored.toJson(), task.toJson());
      expect(restored.reminderAt, DateTime(2026, 10, 1, 9, 30));
      expect(restored.recurrence, const RecurrenceRule.weekly());
      expect(restored.color, 0xFFFFEB3B);
    });

    test('a task can be undated ("Someday")', () {
      final task = TodoTask.create(id: 'x', title: 'Someday');
      final restored = TodoTask.fromJson(task.toJson());

      expect(restored.dueDate, isNull);
      expect(restored.isSomeday, isTrue);
      expect(restored.isOverdue(DateTime(2030)), isFalse);
    });

    test('reads the very first format, which had only basic fields', () {
      final task = TodoTask.fromJson({
        'id': 'old',
        'title': 'Legacy',
        'dueDate': '2026-10-02T00:00:00.000',
        'createdAt': '2026-09-30T09:00:00.000Z',
        'updatedAt': '2026-09-30T09:00:00.000Z',
        'isDone': true,
        'syncState': 'synced',
      });

      expect(task.notes, '');
      expect(task.dueDate, DateTime(2026, 10, 2));
      expect(task.reminderAt, isNull);
      expect(task.color, isNull);
      expect(task.recurrence, isNull);
      expect(task.subtasks, isEmpty);
      expect(task.isDone, isTrue);
      expect(task.syncState, TodoTaskSyncState.synced);
    });

    test('migrates the second format (dueMinutes, enum repeat, priority)', () {
      final task = TodoTask.fromJson({
        'id': 'v2',
        'title': 'Second format',
        'dueDate': '2026-10-02T00:00:00.000',
        'dueMinutes': 570,
        'remind': true,
        'priority': 'high',
        'recurrence': 'weekdays',
        'tags': ['work'],
        'subtasks': [
          {'id': 's', 'title': 'Step', 'isDone': true},
        ],
        'createdAt': '2026-09-30T09:00:00.000Z',
        'updatedAt': '2026-09-30T09:00:00.000Z',
        'isDone': false,
        'syncState': 'pending',
      });

      expect(task.reminderAt, DateTime(2026, 10, 2, 9, 30));
      expect(task.recurrence, const RecurrenceRule.weekdays());
      expect(task.subtasks.single.isDone, isTrue);
      expect(task.subtasks.single.level, 0);
      expect(task.subtasks.single.kind, TodoSubtaskKind.item);
    });

    test('an old time without "remind" does not become a reminder', () {
      final task = TodoTask.fromJson({
        'id': 'v2',
        'title': 'No reminder',
        'dueDate': '2026-10-02T00:00:00.000',
        'dueMinutes': 570,
        'remind': false,
        'createdAt': '2026-09-30T09:00:00.000Z',
        'updatedAt': '2026-09-30T09:00:00.000Z',
        'syncState': 'pending',
      });

      expect(task.reminderAt, isNull);
    });
  });

  group('fields', () {
    test('a repeat rule is ignored without a due date', () {
      final task = TodoTask.create(
        id: 'x',
        title: 'No date',
        recurrence: const RecurrenceRule.daily(),
      );

      expect(task.recurrence, isNull);
    });

    test('a reminder does not need a due date', () {
      final reminder = DateTime(2026, 10, 3, 8);
      final task = TodoTask.create(
        id: 'x',
        title: 'Ping',
        reminderAt: reminder,
      );

      expect(task.reminderAt, reminder);
      expect(task.dueDate, isNull);
    });

    test('isOverdue compares calendar days and ignores done tasks', () {
      final task = fullTask(); // due 2026-10-02
      expect(task.isOverdue(DateTime(2026, 10, 2, 23, 59)), isFalse);
      expect(task.isOverdue(DateTime(2026, 10, 3)), isTrue);
      expect(
        task.copyWith(isDone: true).isOverdue(DateTime(2026, 10, 3)),
        isFalse,
      );
    });

    test('subtask counts ignore headings', () {
      expect(fullTask().totalSubtasks, 2);
      expect(fullTask().completedSubtasks, 1);
    });

    test('a heading can never be marked done', () {
      const heading = TodoSubtask(
        id: 'h',
        title: 'Launch',
        kind: TodoSubtaskKind.heading,
      );

      expect(heading.copyWith(isDone: true).isDone, isFalse);
      expect(
        TodoSubtask.fromJson({
          'id': 'h',
          'title': 'Launch',
          'kind': 'heading',
          'isDone': true,
        }).isDone,
        isFalse,
      );
    });
  });

  group('copyWith', () {
    test('can clear nullable fields and undo a delete', () {
      final deleted = fullTask().copyWith(
        deletedAt: created,
        completedAt: created,
        spawnedTaskId: 'next',
      );
      expect(deleted.isDeleted, isTrue);

      final restored = deleted.copyWith(
        clearDeletedAt: true,
        clearCompletedAt: true,
        clearSpawnedTaskId: true,
      );
      expect(restored.isDeleted, isFalse);
      expect(restored.completedAt, isNull);
      expect(restored.spawnedTaskId, isNull);
    });

    test('clearing the due date drops the repeat but keeps the reminder', () {
      final someday = fullTask().copyWith(clearDueDate: true);

      expect(someday.dueDate, isNull);
      expect(someday.recurrence, isNull);
      expect(someday.reminderAt, DateTime(2026, 10, 1, 9, 30));
    });

    test('colour, reminder and repeat can each be cleared', () {
      final cleared = fullTask().copyWith(
        clearColor: true,
        clearReminder: true,
        clearRecurrence: true,
      );

      expect(cleared.color, isNull);
      expect(cleared.reminderAt, isNull);
      expect(cleared.recurrence, isNull);
      expect(cleared.dueDate, DateTime(2026, 10, 2));
    });
  });

  group('nextOccurrence', () {
    test('creates the next task, keeping content and shifting the reminder', () {
      final next = fullTask().nextOccurrence(
        id: 'next',
        today: DateTime(2026, 10, 2),
        now: DateTime.utc(2026, 10, 2, 12),
      )!;

      expect(next.id, 'next');
      expect(next.title, 'Full');
      expect(next.notes, 'Some notes');
      expect(next.color, 0xFFFFEB3B);
      expect(next.dueDate, DateTime(2026, 10, 9));
      // Reminder was the day before the due date, at 09:30; it stays that way.
      expect(next.reminderAt, DateTime(2026, 10, 8, 9, 30));
      expect(next.recurrence, const RecurrenceRule.weekly());
      expect(next.isDone, isFalse);
      expect(next.syncState, TodoTaskSyncState.pending);
      expect(next.createdAt, DateTime.utc(2026, 10, 2, 12));
    });

    test(
      'starts with an unchecked checklist and keeps headings and levels',
      () {
        final next = fullTask().nextOccurrence(
          id: 'next',
          today: DateTime(2026, 10, 2),
          now: DateTime.utc(2026, 10, 2),
        )!;

        expect(next.subtasks.map((s) => s.title), ['Launch', 'One', 'Two']);
        expect(next.subtasks.every((s) => !s.isDone), isTrue);
        expect(next.subtasks.last.level, 1);
        expect(next.subtasks.first.isHeading, isTrue);
      },
    );

    test('a late completion schedules the next one after today', () {
      final next = fullTask().nextOccurrence(
        id: 'next',
        today: DateTime(2026, 10, 20),
        now: DateTime.utc(2026, 10, 20),
      )!;

      expect(next.dueDate, DateTime(2026, 10, 23));
    });

    test('is null for a task that does not repeat', () {
      expect(
        fullTask()
            .copyWith(clearRecurrence: true)
            .nextOccurrence(
              id: 'n',
              today: DateTime(2026, 10, 2),
              now: DateTime.utc(2026, 10, 2),
            ),
        isNull,
      );
    });

    test('is null once the rule has ended', () {
      final ended = fullTask().copyWith(
        recurrence: RecurrenceRule(
          unit: RecurrenceUnit.week,
          until: DateTime(2026, 10, 5),
        ),
      );

      expect(
        ended.nextOccurrence(
          id: 'n',
          today: DateTime(2026, 10, 2),
          now: DateTime.utc(2026, 10, 2),
        ),
        isNull,
      );
    });
  });
}
