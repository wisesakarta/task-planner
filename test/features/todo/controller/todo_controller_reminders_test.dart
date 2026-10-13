import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

import '../support/fakes.dart';

// Wednesday 30 September 2026, 10:00.
final _now = DateTime(2026, 9, 30, 10);
final _later = DateTime(2026, 10, 2, 9);

TodoTask _task(String id, {DateTime? reminder, bool done = false}) =>
    TodoTask.create(
      id: id,
      title: 'Task $id',
      dueDate: DateTime(2026, 10, 2),
      reminderAt: reminder,
      now: _now,
    ).copyWith(isDone: done);

class Rig {
  Rig({
    List<TodoTask> tasks = const [],
    TodoSettings settings = const TodoSettings(),
    bool granted = true,
    bool canRequest = true,
  }) : repo = FakeTodoRepository(tasks),
       store = FakeSettingsStore(settings),
       service = FakeReminderService(granted: granted, canRequest: canRequest);

  final FakeTodoRepository repo;
  final FakeSettingsStore store;
  final FakeReminderService service;
  int _ids = 0;

  late final TodoController controller = TodoController(
    repository: repo,
    settingsStore: store,
    reminders: service,
    clock: () => _now,
    newId: () => 'new${_ids++}',
    saveDelay: const Duration(milliseconds: 10),
  );

  Future<TodoController> loaded() async {
    await controller.load();
    return controller;
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  group('on load', () {
    test('every future reminder is scheduled, exactly', () async {
      final rig = Rig(
        tasks: [
          _task('a', reminder: _later),
          _task('b', reminder: DateTime(2026, 9, 1, 9)), // past
          _task('c'),
          _task('d', reminder: _later, done: true),
        ],
      );
      await rig.loaded();
      expect(rig.service.pending.keys, ['a']);
      expect(rig.service.calls, contains('replaceAll 1'));
    });

    test(
      'with nothing to remind, the user is not asked for permission',
      () async {
        final rig = Rig(tasks: [_task('a')], granted: false);
        await rig.loaded();
        expect(rig.service.permissionRequests, 0);
        expect(rig.controller.problem, isNull);
      },
    );

    test('with reminders to show, permission is asked once', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)], granted: false);
      await rig.loaded();
      expect(rig.service.permissionRequests, 1);
      expect(rig.service.pending.keys, ['a']);
    });

    test('a refusal is explained once and nothing is scheduled', () async {
      final rig = Rig(
        tasks: [_task('a', reminder: _later)],
        granted: false,
        canRequest: false,
      );
      await rig.loaded();
      expect(rig.service.pending, isEmpty);
      expect(rig.controller.problem, contains('Notifications are off'));
      expect(
        rig.controller.reminderPermission.value,
        ReminderPermission.denied,
      );

      rig.controller.clearProblem();
      await rig.controller.update(
        rig.controller.tasks.single.copyWith(reminderAt: _later),
      );
      await rig.controller.flush();
      await settle();
      expect(rig.controller.problem, isNull, reason: 'not nagged again');
      expect(rig.service.permissionRequests, 1, reason: 'asked only once');
    });

    test(
      'a notification that launched the app asks the screen to open it',
      () async {
        final rig = Rig(tasks: [_task('a')]);
        rig.service.launchTaskId = 'a';
        await rig.loaded();
        expect(rig.controller.openRequest.value, 'a');
      },
    );
  });

  group('while using the app', () {
    test('setting a reminder on a task schedules it', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.update(c.tasks.single.copyWith(reminderAt: _later));
      await c.flush();
      await settle();
      expect(rig.service.pending['a']!.at, _later);
      expect(rig.service.pending['a']!.title, 'Task a');
    });

    test('removing the reminder cancels it', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();
      expect(rig.service.pending, isNotEmpty);

      await c.update(c.tasks.single.copyWith(clearReminder: true));
      await c.flush();
      await settle();
      expect(rig.service.pending, isEmpty);
    });

    test('changing the time replaces the old reminder', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();

      final moved = DateTime(2026, 10, 3, 18);
      await c.update(c.tasks.single.copyWith(reminderAt: moved));
      await c.flush();
      await settle();
      expect(rig.service.pending['a']!.at, moved);
      expect(rig.service.pending, hasLength(1));
    });

    test('completing a task cancels its reminder', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();

      await c.setDone(c.tasks.single, true);
      await settle();
      expect(rig.service.pending, isEmpty);
    });

    test('reopening a task brings its reminder back', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();
      await c.setDone(c.tasks.single, true);
      await settle();

      await c.setDone(c.tasks.single, false);
      await settle();
      expect(rig.service.pending.keys, ['a']);
    });

    test('deleting a task cancels its reminder', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();

      await c.delete(c.tasks.single, RecurrenceScope.onlyThis);
      await settle();
      expect(rig.service.pending, isEmpty);
    });

    test('a reminder time already past is not scheduled', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();

      await c.update(
        c.tasks.single.copyWith(reminderAt: DateTime(2026, 9, 29, 9)),
      );
      await c.flush();
      await settle();
      expect(rig.service.pending, isEmpty);
    });

    test('a duplicate gets its own reminder', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();

      await c.duplicate(c.tasks.single);
      await settle();
      expect(rig.service.pending.keys.toSet(), {'a', 'new0'});
    });

    test('a scheduling failure never fails the task operation', () async {
      final rig = Rig(tasks: [_task('a', reminder: _later)]);
      final c = await rig.loaded();
      rig.service.failing = true;

      expect(await c.add(DateTime(2026, 10, 3), 'New'), isTrue);
      await c.setDone(c.tasks.first, true);
      await c.delete(c.tasks.last, RecurrenceScope.onlyThis);
      await settle();
      expect(c.problem, isNull);
      expect(rig.repo.stored['a']!.isDone, isTrue);
    });
  });

  group('the Notifications setting', () {
    test(
      'off: nothing is scheduled and what was pending is cancelled',
      () async {
        final rig = Rig(tasks: [_task('a', reminder: _later)]);
        final c = await rig.loaded();
        expect(rig.service.pending, isNotEmpty);

        await c.updateSettings(
          c.settings.copyWith(notificationsEnabled: false),
        );
        expect(rig.service.pending, isEmpty);

        await c.update(c.tasks.single.copyWith(reminderAt: _later));
        await c.flush();
        await settle();
        expect(rig.service.pending, isEmpty, reason: 'still off');
      },
    );

    test('on again: everything is scheduled again', () async {
      final rig = Rig(
        tasks: [_task('a', reminder: _later)],
        settings: const TodoSettings(notificationsEnabled: false),
      );
      final c = await rig.loaded();
      expect(rig.service.pending, isEmpty);

      await c.updateSettings(c.settings.copyWith(notificationsEnabled: true));
      expect(rig.service.pending.keys, ['a']);
      expect(rig.store.settings.notificationsEnabled, isTrue);
    });

    test('turning it on asks for permission in response to the user', () async {
      final rig = Rig(
        tasks: [_task('a', reminder: _later)],
        settings: const TodoSettings(notificationsEnabled: false),
        granted: false,
      );
      final c = await rig.loaded();
      expect(rig.service.permissionRequests, 0);

      await c.updateSettings(c.settings.copyWith(notificationsEnabled: true));
      expect(rig.service.permissionRequests, 1);
      expect(rig.service.pending.keys, ['a']);
    });

    test('it is on by default and survives a round trip', () {
      expect(const TodoSettings().notificationsEnabled, isTrue);
      final json = const TodoSettings(notificationsEnabled: false).toJson();
      expect(TodoSettings.fromJson(json).notificationsEnabled, isFalse);
      expect(TodoSettings.fromJson(const {}).notificationsEnabled, isTrue);
    });
  });

  group('signals from notifications', () {
    test('a tap opens the task', () async {
      final rig = Rig(tasks: [_task('a')]);
      final c = await rig.loaded();
      rig.service.emit(const ReminderSignal(ReminderSignalKind.open, 'a'));
      await settle();
      expect(c.openRequest.value, 'a');
    });

    test(
      'a background change (a button) is read back and re-planned',
      () async {
        final rig = Rig(tasks: [_task('a', reminder: _later)]);
        final c = await rig.loaded();
        expect(c.tasks.single.isDone, isFalse);

        // What the background isolate does: persist, then tell the app.
        rig.repo.stored['a'] = rig.repo.stored['a']!.copyWith(isDone: true);
        rig.service.emit(const ReminderSignal(ReminderSignalKind.dataChanged));
        await settle();

        expect(c.tasks.single.isDone, isTrue);
        expect(
          rig.service.pending,
          isEmpty,
          reason: 'a finished task has none',
        );
      },
    );

    test(
      'the permission can be re-read (after the user changed it elsewhere)',
      () async {
        final rig = Rig(granted: false, canRequest: false);
        final c = await rig.loaded();
        expect(c.reminderPermission.value, ReminderPermission.denied);

        rig.service.granted = true;
        await c.refreshReminderPermission();
        expect(c.reminderPermission.value, ReminderPermission.granted);
      },
    );
  });
}
