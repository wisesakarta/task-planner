import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

import '../support/fakes.dart';

// Wednesday 30 September 2026, 10:00.
final _now = DateTime(2026, 9, 30, 10);
final _wed = DateTime(2026, 9, 30);
final _thu = DateTime(2026, 10, 1);

TodoTask _task(
  String id, {
  DateTime? day,
  double? key,
  RecurrenceRule? repeat,
  bool done = false,
}) => TodoTask.create(
  id: id,
  title: 'Task $id',
  dueDate: day,
  recurrence: repeat,
  now: _now,
).copyWith(sortKey: key, isDone: done);

class Rig {
  Rig(List<TodoTask> tasks)
    : repo = FakeTodoRepository(tasks),
      store = FakeSettingsStore();

  final FakeTodoRepository repo;
  final FakeSettingsStore store;

  late final TodoController controller = TodoController(
    repository: repo,
    settingsStore: store,
    clock: () => _now,
    newId: () => 'new',
    saveDelay: const Duration(milliseconds: 10),
  );

  Future<TodoController> loaded() async {
    await controller.load();
    return controller;
  }
}

/// Ids of the tasks on [day] in the order they are kept.
List<String> _ids(TodoController c, DateTime? day) => [
  for (final t in sortedByOrder(
    c.tasks.where((t) => day == null ? t.dueDate == null : t.dueDate == day),
  ))
    t.id,
];

void main() {
  group('move', () {
    test('to another day: the date changes, nothing else does', () async {
      final rig = Rig([_task('a', day: _wed, key: 1), _task('b', day: _thu)]);
      final c = await rig.loaded();

      await c.move(c.tasks.first, date: _thu, afterId: 'b');
      expect(_ids(c, _thu), ['b', 'a']);
      expect(_ids(c, _wed), isEmpty);
      expect(rig.repo.stored['a']!.dueDate, _thu);
      expect(rig.repo.stored['a']!.title, 'Task a');
    });

    test('between two neighbours takes a position between theirs', () async {
      final rig = Rig([
        _task('a', day: _wed, key: 100),
        _task('b', day: _wed, key: 200),
        _task('c', day: _wed, key: 300),
      ]);
      final c = await rig.loaded();

      await c.move(c.tasks.last, date: _wed, afterId: 'a', beforeId: 'b');
      expect(_ids(c, _wed), ['a', 'c', 'b']);
      expect(rig.repo.stored['c']!.order, 150);
      expect(rig.repo.writes.last, ['c'], reason: 'one move, one task');
    });

    test('to the top and to the bottom', () async {
      final rig = Rig([
        _task('a', day: _wed, key: 100),
        _task('b', day: _wed, key: 200),
        _task('c', day: _wed, key: 300),
      ]);
      final c = await rig.loaded();

      await c.move(c.tasks.last, date: _wed, beforeId: 'a');
      expect(_ids(c, _wed), ['c', 'a', 'b']);
      await c.move(c.tasks.first, date: _wed, afterId: 'b');
      expect(_ids(c, _wed), ['c', 'b', 'a']);
    });

    test('into an empty day', () async {
      final rig = Rig([_task('a', day: _wed, key: 1)]);
      final c = await rig.loaded();
      await c.move(c.tasks.single, date: _thu);
      expect(_ids(c, _thu), ['a']);
    });

    test('dropped where it already is changes nothing', () async {
      final rig = Rig([
        _task('a', day: _wed, key: 100),
        _task('b', day: _wed, key: 200),
        _task('c', day: _wed, key: 300),
      ]);
      final c = await rig.loaded();
      rig.repo.writes.clear();

      await c.move(c.tasks[1], date: _wed, afterId: 'a', beforeId: 'c');
      await c.move(c.tasks[1], date: _wed, afterId: 'a');
      expect(rig.repo.writes, isEmpty);
    });

    test('to Someday removes the day and ends a repeat', () async {
      final rig = Rig([
        _task('a', day: _wed, key: 1, repeat: const RecurrenceRule.daily()),
      ]);
      final c = await rig.loaded();

      await c.move(c.tasks.single, date: null);
      final stored = rig.repo.stored['a']!;
      expect(stored.dueDate, isNull);
      expect(stored.recurrence, isNull);
    });

    test('from Someday onto a day', () async {
      final rig = Rig([_task('a', key: 1)]);
      final c = await rig.loaded();
      await c.move(c.tasks.single, date: _wed);
      expect(rig.repo.stored['a']!.dueDate, _wed);
    });

    test('a move is marked for sync', () async {
      final rig = Rig([_task('a', day: _wed, key: 1)]);
      final c = await rig.loaded();
      await c.move(c.tasks.single, date: _thu);
      expect(rig.repo.stored['a']!.syncState, TodoTaskSyncState.pending);
    });

    test('tasks that share a position are spaced out first', () async {
      // Created in the same instant: equal positions, no room between them.
      final rig = Rig([
        _task('a', day: _wed, key: 5),
        _task('b', day: _wed, key: 5),
        _task('c', day: _thu, key: 9),
      ]);
      final c = await rig.loaded();

      await c.move(c.tasks.last, date: _wed, afterId: 'a', beforeId: 'b');
      expect(_ids(c, _wed), ['a', 'c', 'b']);
    });

    test('many drops into the same gap never run out of room', () async {
      final rig = Rig([
        _task('a', day: _wed, key: 1000),
        _task('b', day: _wed, key: 1001),
        for (var i = 0; i < 40; i++) _task('m$i', day: _thu, key: i + 1.0),
      ]);
      final c = await rig.loaded();

      final expected = ['a', 'b'];
      for (var i = 0; i < 40; i++) {
        final task = c.tasks.firstWhere((t) => t.id == 'm$i');
        await c.move(task, date: _wed, afterId: 'a', beforeId: expected[1]);
        expected.insert(1, 'm$i');
        expect(_ids(c, _wed), expected, reason: 'after drop $i');
      }
    });

    test(
      'with done tasks sorted down, dropping after the last open one',
      () async {
        final rig = Rig([
          _task('a', day: _wed, key: 10),
          _task('b', day: _wed, key: 20),
          _task('x', day: _wed, key: 1, done: true),
          _task('n', day: _thu, key: 1),
        ]);
        final c = await rig.loaded();

        // The screen shows a, b, then the done x; n is dropped between b and x.
        await c.move(c.tasks.last, date: _wed, afterId: 'b', beforeId: 'x');
        final open = _ids(c, _wed).where((id) => id != 'x').toList();
        expect(open, ['a', 'b', 'n']);
      },
    );

    test('an unknown task is ignored', () async {
      final rig = Rig([_task('a', day: _wed, key: 1)]);
      final c = await rig.loaded();
      rig.repo.writes.clear();
      await c.move(_task('ghost', day: _wed), date: _thu);
      expect(rig.repo.writes, isEmpty);
    });

    test('a failed write is reported, the move stays on screen', () async {
      final rig = Rig([_task('a', day: _wed, key: 1)]);
      final c = await rig.loaded();
      rig.repo.failWrites = true;
      await c.move(c.tasks.single, date: _thu);
      expect(c.problem, isNotNull);
      expect(_ids(c, _thu), ['a']);
    });
  });

  group('sortedByOrder', () {
    test('sorts by position and keeps the given order for ties', () {
      final sorted = sortedByOrder([
        _task('c', key: 3),
        _task('a', key: 1),
        _task('t1', key: 2),
        _task('t2', key: 2),
      ]);
      expect([for (final t in sorted) t.id], ['a', 't1', 't2', 'c']);
    });
  });
}
