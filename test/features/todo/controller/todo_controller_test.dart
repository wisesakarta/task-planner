import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

import '../support/fakes.dart';

// Wednesday 30 September 2026; its week starts Monday the 28th.
final _now = DateTime(2026, 9, 30, 10);
final _today = DateTime(2026, 9, 30);

TodoTask _task(
  String id, {
  DateTime? due,
  bool someday = false,
  RecurrenceRule? recurrence,
  String? spawned,
  bool done = false,
}) => TodoTask.create(
  id: id,
  title: 'Task $id',
  dueDate: someday ? null : (due ?? _today),
  recurrence: recurrence,
  now: _now,
).copyWith(isDone: done, spawnedTaskId: spawned);

class Rig {
  Rig({
    List<TodoTask> tasks = const [],
    TodoSettings settings = const TodoSettings(),
    DateTime? now,
    this.saveDelay = const Duration(milliseconds: 400),
  }) : clock = now ?? _now,
       repo = FakeTodoRepository(tasks),
       store = FakeSettingsStore(settings);

  DateTime clock;
  final Duration saveDelay;
  final FakeTodoRepository repo;
  final FakeSettingsStore store;
  int _id = 0;

  late final TodoController controller = TodoController(
    repository: repo,
    settingsStore: store,
    clock: () => clock,
    newId: () => 'new${_id++}',
    saveDelay: saveDelay,
  );

  Future<TodoController> loaded() async {
    await controller.load();
    return controller;
  }

  TodoTask stored(String id) => repo.stored[id]!;
}

void main() {
  group('loading', () {
    test('reads tasks and settings, and starts on the current week', () async {
      final rig = Rig(
        tasks: [_task('a')],
        settings: const TodoSettings(themeId: 'mist'),
      );
      expect(rig.controller.isLoading, isTrue);

      final c = await rig.loaded();
      expect(c.isLoading, isFalse);
      expect(c.tasks.map((t) => t.id), ['a']);
      expect(c.settings.themeId, 'mist');
      expect(c.today, _today);
      expect(c.weekStart, DateTime(2026, 9, 28));
    });

    test('a Sunday-first setting starts the week on Sunday', () async {
      final rig = Rig(
        settings: const TodoSettings(weekStartsOn: DateTime.sunday),
      );
      final c = await rig.loaded();
      expect(c.weekStart, DateTime(2026, 9, 27));
    });

    test('a read failure is reported and the app still opens', () async {
      final rig = Rig()..repo.failReads = true;
      final c = await rig.loaded();
      expect(c.isLoading, isFalse);
      expect(c.problem, contains('read your tasks'));
      c.clearProblem();
      expect(c.problem, isNull);
    });

    test('deleted tasks are kept for sync but never listed', () async {
      final gone = _task('gone').copyWith(deletedAt: _now);
      final c = await (Rig(tasks: [_task('a'), gone])).loaded();
      expect(c.tasks.map((t) => t.id), ['a']);
    });
  });

  group('week navigation', () {
    test('moves by whole weeks and returns to the current one', () async {
      final c = await Rig().loaded();

      c.goToWeek(1);
      expect(c.weekStart, DateTime(2026, 10, 5));
      c.goToWeek(-3);
      expect(c.weekStart, DateTime(2026, 9, 14));
      c.goToCurrentWeek();
      expect(c.weekStart, DateTime(2026, 9, 28));
    });

    test('notifies listeners', () async {
      final c = await Rig().loaded();
      var calls = 0;
      c.addListener(() => calls++);
      c.goToWeek(1);
      expect(calls, 1);
    });

    test('changing the first day of the week re-aligns the view', () async {
      final c = await Rig().loaded();
      await c.updateSettings(
        c.settings.copyWith(weekStartsOn: DateTime.sunday),
      );
      expect(c.weekStart, DateTime(2026, 9, 27));
    });

    test(
      'a new day moves the view along if it was on the current week',
      () async {
        final rig = Rig();
        final c = await rig.loaded();

        rig.clock = DateTime(2026, 10, 5, 8); // next Monday
        await c.refreshToday();
        expect(c.today, DateTime(2026, 10, 5));
        expect(c.weekStart, DateTime(2026, 10, 5));
      },
    );

    test('a new day leaves a browsed week where it is', () async {
      final rig = Rig();
      final c = await rig.loaded();
      c.goToWeek(4);

      rig.clock = DateTime(2026, 10, 1);
      await c.refreshToday();
      expect(c.today, DateTime(2026, 10, 1));
      expect(c.weekStart, DateTime(2026, 10, 26));
    });
  });

  group('add', () {
    test('creates a task on the day and writes it', () async {
      final rig = Rig();
      final c = await rig.loaded();

      final ok = await c.add(DateTime(2026, 10, 2), '  Buy milk  ');
      expect(ok, isTrue);
      expect(c.tasks.single.title, 'Buy milk');
      expect(c.tasks.single.dueDate, DateTime(2026, 10, 2));
      expect(rig.stored('new0').title, 'Buy milk');
    });

    test('a null day means Someday', () async {
      final c = await Rig().loaded();
      await c.add(null, 'Someday thing');
      expect(c.tasks.single.isSomeday, isTrue);
    });

    test('blank titles are refused', () async {
      final rig = Rig();
      final c = await rig.loaded();
      expect(await c.add(_today, '   '), isFalse);
      expect(c.tasks, isEmpty);
      expect(rig.repo.writes, isEmpty);
    });

    test(
      'a failed write reports false and a message, keeping the task on screen',
      () async {
        final rig = Rig();
        final c = await rig.loaded();
        rig.repo.failWrites = true;

        expect(await c.add(_today, 'Milk'), isFalse);
        expect(c.problem, contains('Could not save'));
        expect(c.tasks, hasLength(1));
      },
    );

    test('notifies listeners', () async {
      final c = await Rig().loaded();
      var calls = 0;
      c.addListener(() => calls++);
      await c.add(_today, 'Milk');
      expect(calls, greaterThan(0));
    });
  });

  group('completing', () {
    test('a plain task is marked done with a time', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, true);
      expect(c.tasks.single.isDone, isTrue);
      expect(rig.stored('a').completedAt, isNotNull);
      expect(rig.repo.writes.last, ['a']);
    });

    test('it can be reopened', () async {
      final rig = Rig(tasks: [_task('a', done: true)]);
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, false);
      expect(rig.stored('a').isDone, isFalse);
      expect(rig.stored('a').completedAt, isNull);
    });

    test(
      'completing a repeating task creates the next one, in one write',
      () async {
        final rig = Rig(
          tasks: [_task('a', recurrence: const RecurrenceRule.daily())],
        );
        final c = await rig.loaded();

        await c.setDone(c.tasks.single, true);

        expect(c.tasks, hasLength(2));
        final next = rig.stored('new0');
        expect(next.dueDate, DateTime(2026, 10, 1));
        expect(next.isDone, isFalse);
        expect(rig.stored('a').spawnedTaskId, 'new0');
        expect(rig.repo.writes.last.toSet(), {'a', 'new0'});
      },
    );

    test('completing a repeat twice does not spawn twice', () async {
      final rig = Rig(
        tasks: [_task('a', recurrence: const RecurrenceRule.daily())],
      );
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, true);
      await c.setDone(c.tasks.firstWhere((t) => t.id == 'a'), false);
      await c.setDone(c.tasks.firstWhere((t) => t.id == 'a'), true);

      expect(c.tasks.where((t) => !t.isDone), hasLength(1));
    });

    test('reopening takes the untouched next occurrence away again', () async {
      final rig = Rig(
        tasks: [_task('a', recurrence: const RecurrenceRule.daily())],
      );
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, true);
      await c.setDone(c.tasks.firstWhere((t) => t.id == 'a'), false);

      expect(c.tasks.map((t) => t.id), ['a']);
      expect(rig.stored('new0').isDeleted, isTrue);
      expect(rig.stored('a').spawnedTaskId, isNull);
    });

    test(
      'reopening keeps a next occurrence that was already finished',
      () async {
        final rig = Rig(
          tasks: [
            _task(
              'a',
              done: true,
              spawned: 'b',
              recurrence: const RecurrenceRule.daily(),
            ),
            _task('b', done: true, due: DateTime(2026, 10, 1)),
          ],
        );
        final c = await rig.loaded();

        await c.setDone(c.tasks.firstWhere((t) => t.id == 'a'), false);
        expect(rig.stored('b').isDeleted, isFalse);
      },
    );

    test('a repeat that has ended creates nothing', () async {
      final rig = Rig(
        tasks: [
          _task(
            'a',
            recurrence: RecurrenceRule(
              unit: RecurrenceUnit.day,
              interval: 1,
              until: _today,
            ),
          ),
        ],
      );
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, true);
      expect(c.tasks, hasLength(1));
    });
  });

  group('editing from the card', () {
    test('edits are written once, after a pause', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();
      final base = c.tasks.single;

      await c.update(base.copyWith(title: 'B'));
      await c.update(base.copyWith(title: 'Bu'));
      await c.update(base.copyWith(title: 'Buy'));
      expect(c.tasks.single.title, 'Buy', reason: 'on screen at once');
      expect(rig.repo.writes, isEmpty, reason: 'not written yet');

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(rig.repo.writes, hasLength(1));
      expect(rig.stored('a').title, 'Buy');
    });

    test('flush writes straight away', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.update(c.tasks.single.copyWith(notes: 'Semi-skimmed'));
      await c.flush();
      expect(rig.stored('a').notes, 'Semi-skimmed');
      expect(rig.repo.writes, hasLength(1));
    });

    test('flush with nothing staged writes nothing', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();
      await c.flush();
      expect(rig.repo.writes, isEmpty);
    });

    test('a later discrete action carries staged edits with it', () async {
      final rig = Rig(tasks: [_task('a'), _task('b')]);
      final c = await rig.loaded();

      await c.update(c.tasks.first.copyWith(title: 'Renamed'));
      await c.setDone(c.tasks.last, true);

      expect(rig.repo.writes, hasLength(1));
      expect(rig.stored('a').title, 'Renamed');
      expect(rig.stored('b').isDone, isTrue);
    });

    test('editing marks the task as pending sync and bumps its time', () async {
      final rig = Rig(tasks: [_task('a')]);
      rig.clock = DateTime(2026, 9, 30, 12);
      final c = await rig.loaded();
      final before = c.tasks.single.updatedAt;

      await c.update(c.tasks.single.copyWith(notes: 'x'));
      await c.flush();
      expect(rig.stored('a').updatedAt.isAfter(before), isTrue);
      expect(rig.stored('a').syncState, TodoTaskSyncState.pending);
    });

    test('a done change from the card completes the task properly', () async {
      final rig = Rig(
        tasks: [_task('a', recurrence: const RecurrenceRule.weekly())],
      );
      final c = await rig.loaded();

      await c.update(c.tasks.single.copyWith(isDone: true));
      expect(c.tasks, hasLength(2));
      expect(rig.stored('a').spawnedTaskId, 'new0');
    });

    test(
      'a stale copy from the card cannot drop the link to the next task',
      () async {
        final rig = Rig(
          tasks: [_task('a', recurrence: const RecurrenceRule.weekly())],
        );
        final c = await rig.loaded();
        final stale = c.tasks.single; // what an open card still holds

        await c.setDone(stale, true);
        await c.update(stale.copyWith(isDone: true, notes: 'late note'));
        await c.flush();

        expect(rig.stored('a').spawnedTaskId, 'new0');
        expect(rig.stored('a').notes, 'late note');
      },
    );

    test('editing a task that no longer exists does nothing', () async {
      final rig = Rig();
      final c = await rig.loaded();
      await c.update(_task('ghost'));
      expect(c.tasks, isEmpty);
    });

    test('disposing writes what is still staged', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.update(c.tasks.single.copyWith(title: 'Last words'));
      c.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(rig.stored('a').title, 'Last words');
    });
  });

  group('deleting', () {
    test('a plain task becomes a tombstone', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.delete(c.tasks.single, RecurrenceScope.onlyThis);
      expect(c.tasks, isEmpty);
      expect(rig.stored('a').isDeleted, isTrue);
      expect(rig.stored('a').syncState, TodoTaskSyncState.pending);
    });

    test('deleting drops staged edits for it', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.update(c.tasks.single.copyWith(title: 'Edited'));
      await c.delete(c.tasks.single, RecurrenceScope.onlyThis);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(rig.stored('a').isDeleted, isTrue);
    });

    test('"only this" on a repeating task lets the series carry on', () async {
      final rig = Rig(
        tasks: [_task('a', recurrence: const RecurrenceRule.daily())],
      );
      final c = await rig.loaded();

      await c.delete(c.tasks.single, RecurrenceScope.onlyThis);
      expect(c.tasks.map((t) => t.id), ['new0']);
      expect(c.tasks.single.dueDate, DateTime(2026, 10, 1));
      expect(c.tasks.single.repeats, isTrue);
    });

    test('"this and future" ends the series', () async {
      final rig = Rig(
        tasks: [_task('a', recurrence: const RecurrenceRule.daily())],
      );
      final c = await rig.loaded();

      await c.delete(c.tasks.single, RecurrenceScope.thisAndFuture);
      expect(c.tasks, isEmpty);
    });

    test('"this and future" keeps the finished history', () async {
      final rig = Rig(
        tasks: [
          _task(
            'old',
            done: true,
            spawned: 'a',
            due: DateTime(2026, 9, 29),
            recurrence: const RecurrenceRule.daily(),
          ),
          _task('a', recurrence: const RecurrenceRule.daily()),
        ],
      );
      final c = await rig.loaded();

      await c.delete(
        c.tasks.firstWhere((t) => t.id == 'a'),
        RecurrenceScope.thisAndFuture,
      );
      expect(c.tasks.map((t) => t.id), ['old']);
    });

    test('"all" removes the whole chain, before and after', () async {
      final rig = Rig(
        tasks: [
          _task(
            'one',
            done: true,
            spawned: 'two',
            due: DateTime(2026, 9, 28),
            recurrence: const RecurrenceRule.daily(),
          ),
          _task(
            'two',
            done: true,
            spawned: 'three',
            due: DateTime(2026, 9, 29),
            recurrence: const RecurrenceRule.daily(),
          ),
          _task(
            'three',
            spawned: 'four',
            recurrence: const RecurrenceRule.daily(),
          ),
          _task(
            'four',
            due: DateTime(2026, 10, 1),
            recurrence: const RecurrenceRule.daily(),
          ),
          _task('other'),
        ],
      );
      final c = await rig.loaded();

      await c.delete(
        c.tasks.firstWhere((t) => t.id == 'three'),
        RecurrenceScope.all,
      );
      expect(c.tasks.map((t) => t.id), ['other']);
    });

    test('a failed delete is reported', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();
      rig.repo.failWrites = true;

      await c.delete(c.tasks.single, RecurrenceScope.onlyThis);
      expect(c.problem, isNotNull);
    });
  });

  group('duplicate', () {
    test('copies everything but the identity, unfinished', () async {
      final original = _task('a', recurrence: const RecurrenceRule.weekly())
          .copyWith(
            notes: 'note',
            color: 0xFF112233,
            reminderAt: DateTime(2026, 9, 30, 9),
            isDone: true,
          );
      final rig = Rig(tasks: [original]);
      final c = await rig.loaded();

      await c.duplicate(c.tasks.single);
      final copy = rig.stored('new0');
      expect(copy.title, original.title);
      expect(copy.notes, 'note');
      expect(copy.color, 0xFF112233);
      expect(copy.dueDate, original.dueDate);
      expect(copy.recurrence, original.recurrence);
      expect(copy.reminderAt, original.reminderAt);
      expect(copy.isDone, isFalse);
      expect(copy.spawnedTaskId, isNull);
      expect(c.tasks, hasLength(2));
    });
  });

  group('carry over', () {
    final yesterday = DateTime(2026, 9, 29);

    test('is off by default', () async {
      final rig = Rig(tasks: [_task('a', due: yesterday)]);
      final c = await rig.loaded();
      expect(c.tasks.single.dueDate, yesterday);
    });

    test('moves open one-off tasks from earlier days to today', () async {
      final rig = Rig(
        tasks: [
          _task('open', due: yesterday),
          _task('done', due: yesterday, done: true),
          _task(
            'repeat',
            due: yesterday,
            recurrence: const RecurrenceRule.daily(),
          ),
          _task('someday', someday: true),
          _task('future', due: DateTime(2026, 10, 3)),
        ],
        settings: const TodoSettings(moveToNextDay: true),
      );
      final c = await rig.loaded();
      TodoTask by(String id) => c.tasks.firstWhere((t) => t.id == id);

      expect(by('open').dueDate, _today);
      expect(by('done').dueDate, yesterday);
      expect(by('repeat').dueDate, yesterday);
      expect(by('someday').dueDate, isNull);
      expect(by('future').dueDate, DateTime(2026, 10, 3));
      expect(rig.stored('open').dueDate, _today, reason: 'persisted');
    });

    test('turning it on applies it at once', () async {
      final rig = Rig(tasks: [_task('a', due: yesterday)]);
      final c = await rig.loaded();

      await c.updateSettings(c.settings.copyWith(moveToNextDay: true));
      expect(c.tasks.single.dueDate, _today);
    });

    test('a new day rolls tasks over again', () async {
      final rig = Rig(
        tasks: [_task('a')],
        settings: const TodoSettings(moveToNextDay: true),
      );
      final c = await rig.loaded();

      rig.clock = DateTime(2026, 10, 1, 7);
      await c.refreshToday();
      expect(c.tasks.single.dueDate, DateTime(2026, 10, 1));
    });
  });

  group('settings', () {
    test('are applied at once and saved', () async {
      final rig = Rig();
      final c = await rig.loaded();
      var seen = 0;
      c.settingsListenable.addListener(() => seen++);

      await c.updateSettings(c.settings.copyWith(themeId: 'sage'));
      expect(c.settings.themeId, 'sage');
      expect(rig.store.settings.themeId, 'sage');
      expect(seen, 1);
    });

    test('an unchanged value is not saved again', () async {
      final rig = Rig();
      final c = await rig.loaded();
      await c.updateSettings(c.settings);
      expect(rig.store.saves, 0);
    });

    test('a failed save is reported but the setting still applies', () async {
      final rig = Rig()..store.failSaves = true;
      final c = await rig.loaded();

      await c.updateSettings(c.settings.copyWith(themeId: 'sage'));
      expect(c.settings.themeId, 'sage');
      expect(c.problem, contains('settings'));
    });
  });
}
