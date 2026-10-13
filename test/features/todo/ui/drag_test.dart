import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/ui/week/task_drag.dart';
import 'package:todo_app/features/todo/ui/week/task_row.dart';
import 'package:todo_app/features/todo/ui/week/week_screen.dart';

import '../support/pump_todo.dart';

final _wed = DateTime(2026, 9, 30);
final _monday = DateTime(2026, 9, 28);
final _tuesday = DateTime(2026, 9, 29);

TodoTask _task(String id, DateTime? day, double key) => TodoTask.create(
  id: id,
  title: 'Task $id',
  dueDate: day,
  now: DateTime(2026, 9, 1),
).copyWith(sortKey: key);

final _tasks = [
  _task('a1', _monday, 1),
  _task('a2', _monday, 2),
  _task('b1', _tuesday, 1),
  _task('s1', null, 1),
];

class _Moves {
  final List<(TodoTask, TaskDrop)> list = [];
  void call(TodoTask task, TaskDrop drop) => list.add((task, drop));
}

Future<_Moves> _pump(
  WidgetTester tester, {
  bool draggable = true,
  List<TodoTask>? tasks,
}) async {
  final moves = _Moves();
  await pumpTodo(
    tester,
    WeekScreen(
      weekStart: _monday,
      today: _wed,
      // Opens on Monday; the drags start from its tasks.
      focusDay: _monday,
      tasks: tasks ?? _tasks,
      onToggle: (_, _) {},
      onOpen: (_) {},
      onAdd: (_, _) => true,
      onPrevious: () {},
      onNext: () {},
      onToday: () {},
      onSearch: () {},
      onMenu: () {},
      onMove: draggable ? moves.call : null,
    ),
    height: 1600,
  );
  return moves;
}

/// Presses on [from], holds, moves to [to] in steps and lets go.
Future<void> _drag(
  WidgetTester tester,
  Offset from,
  Offset to, {
  Duration hold = const Duration(milliseconds: 200),
  bool release = true,
}) async {
  final gesture = await tester.startGesture(from);
  await tester.pump(hold);
  for (var i = 1; i <= 6; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 6)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (release) {
    await gesture.up();
    await tester.pumpAndSettle();
  }
}

Offset _title(WidgetTester tester, String id) =>
    tester.getCenter(find.text('Task $id'));

bool _lineShown() => find
    .byWidgetPredicate((w) => w.runtimeType.toString() == '_InsertionLine')
    .evaluate()
    .isNotEmpty;

void main() {
  useBundledFonts();

  group('carrying a task', () {
    testWidgets('onto another day, after its last task', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a1'),
        _title(tester, 'b1') + const Offset(0, 30),
      );
      expect(moves.list, hasLength(1));
      final (task, drop) = moves.list.single;
      expect(task.id, 'a1');
      expect(drop.date, _tuesday);
      expect(drop.afterId, 'b1');
      expect(drop.beforeId, isNull);
    });

    testWidgets('above the first task of a day', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a1'),
        _title(tester, 'b1') + const Offset(0, -15),
      );
      final drop = moves.list.single.$2;
      expect(drop.date, _tuesday);
      expect(drop.afterId, isNull);
      expect(drop.beforeId, 'b1');
    });

    testWidgets('within a day, below the next task', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a1'),
        _title(tester, 'a2') + const Offset(0, 15),
      );
      final (task, drop) = moves.list.single;
      expect(task.id, 'a1');
      expect(drop.date, _monday);
      expect(drop.afterId, 'a2');
      expect(drop.beforeId, isNull);
    });

    testWidgets('within a day, above the first task', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a2'),
        _title(tester, 'a1') + const Offset(0, -15),
      );
      final drop = moves.list.single.$2;
      expect(drop.afterId, isNull);
      expect(drop.beforeId, 'a1');
    });

    testWidgets('onto an empty day', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a1'),
        tester.getCenter(find.text('1 Oct')) + const Offset(0, 50),
      );
      final drop = moves.list.single.$2;
      expect(drop.date, DateTime(2026, 10, 1));
      expect(drop.afterId, isNull);
      expect(drop.beforeId, isNull);
    });

    testWidgets('onto Someday', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 'a1'),
        _title(tester, 's1') + const Offset(0, 30),
      );
      final drop = moves.list.single.$2;
      expect(drop.date, isNull);
      expect(drop.afterId, 's1');
    });

    testWidgets('from Someday onto a day', (tester) async {
      final moves = await _pump(tester);
      await _drag(
        tester,
        _title(tester, 's1'),
        _title(tester, 'b1') + const Offset(0, 30),
      );
      final (task, drop) = moves.list.single;
      expect(task.id, 's1');
      expect(drop.date, _tuesday);
    });

    testWidgets('the gap between two days counts as the day above', (
      tester,
    ) async {
      final moves = await _pump(tester);
      // Under Tuesday's last line, in the 24-point space before Wednesday.
      final tuesdayComposer = tester.getCenter(find.text('Task b1')).dy + 63;
      await _drag(
        tester,
        _title(tester, 'a1'),
        Offset(195, tuesdayComposer + 12),
      );
      expect(moves.list.single.$2.date, _tuesday);
    });

    testWidgets('shows where it will land while carrying, then not', (
      tester,
    ) async {
      await _pump(tester);
      expect(_lineShown(), isFalse);
      final gesture = await tester.startGesture(_title(tester, 'a1'));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(_title(tester, 'b1'));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 5));
      await tester.pump();
      expect(_lineShown(), isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_lineShown(), isFalse);
    });

    testWidgets('the row being carried is dimmed where it was', (tester) async {
      await _pump(tester);
      final gesture = await tester.startGesture(_title(tester, 'a1'));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      // The original (dimmed) and the copy under the finger.
      expect(find.text('Task a1'), findsNWidgets(2));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Task a1'), findsOneWidget);
    });

    testWidgets('holding near the bottom edge scrolls the list', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        WeekScreen(
          weekStart: _monday,
          today: _wed,
          focusDay: _monday,
          tasks: _tasks,
          onToggle: (_, _) {},
          onOpen: (_) {},
          onAdd: (_, _) => true,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onSearch: () {},
          onMenu: () {},
          onMove: _Moves().call,
        ),
        height: 600,
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, 0);

      final gesture = await tester.startGesture(_title(tester, 'a1'));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(const Offset(195, 560));
      await tester.pump(const Duration(milliseconds: 16));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(scrollable.position.pixels, greaterThan(50));

      await gesture.moveTo(const Offset(195, 70));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(scrollable.position.pixels, 0, reason: 'and back up at the top');
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('letting go above the list moves nothing', (tester) async {
      final moves = await _pump(tester);
      await _drag(tester, _title(tester, 'a1'), const Offset(195, 20));
      expect(moves.list, isEmpty);
    });

    testWidgets('a quick swipe scrolls instead of picking the row up', (
      tester,
    ) async {
      final moves = await _pump(tester, tasks: [..._tasks]);
      await tester.fling(
        find.text('Task a1'),
        const Offset(0, -100),
        1000,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(moves.list, isEmpty);
    });

    testWidgets('a tap still opens the task', (tester) async {
      var opened = '';
      final moves = _Moves();
      await pumpTodo(
        tester,
        WeekScreen(
          weekStart: _monday,
          today: _wed,
          focusDay: _monday,
          tasks: _tasks,
          onToggle: (_, _) {},
          onOpen: (t) => opened = t.id,
          onAdd: (_, _) => true,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onSearch: () {},
          onMenu: () {},
          onMove: moves.call,
        ),
        height: 1600,
      );
      await tester.tap(find.text('Task a1'));
      await tester.pump();
      expect(opened, 'a1');
    });

    testWidgets('without a move handler, rows cannot be carried', (
      tester,
    ) async {
      await _pump(tester, draggable: false);
      final gesture = await tester.startGesture(_title(tester, 'a1'));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      expect(find.text('Task a1'), findsOneWidget);
      await gesture.up();
    });

    testWidgets('tasks are listed in their saved order', (tester) async {
      await _pump(
        tester,
        tasks: [_task('late', _monday, 9), _task('early', _monday, 1)],
      );
      expect(
        tester.getTopLeft(find.text('Task early')).dy,
        lessThan(tester.getTopLeft(find.text('Task late')).dy),
      );
    });
  });

  group('moveActions (for screen readers)', () {
    final shown = [
      _task('x', _monday, 1),
      _task('y', _monday, 2),
      _task('z', _monday, 3),
    ];
    final drops = <TaskDrop>[];

    Map<String, VoidCallback> actions(int at, {DateTime? date}) => {
      for (final entry in moveActions(
        task: shown[at],
        date: date ?? _monday,
        shown: shown,
        onDrop: (_, drop) => drops.add(drop),
      ).entries)
        entry.key.label!: entry.value,
    };

    setUp(drops.clear);

    test('the first task can only move down or to another day', () {
      expect(
        actions(0).keys,
        unorderedEquals([
          'Move down',
          'Move to the next day',
          'Move to the previous day',
        ]),
      );
    });

    test('the last task can move up', () {
      expect(actions(2).keys, contains('Move up'));
      expect(actions(2).keys, isNot(contains('Move down')));
    });

    test('move up goes above the task above', () {
      actions(2)['Move up']!();
      expect(drops.single.afterId, 'x');
      expect(drops.single.beforeId, 'y');
    });

    test('move down goes below the task below', () {
      actions(0)['Move down']!();
      expect(drops.single.afterId, 'y');
      expect(drops.single.beforeId, 'z');
    });

    test('the next and previous day', () {
      actions(1)['Move to the next day']!();
      actions(1)['Move to the previous day']!();
      expect(drops[0].date, _tuesday);
      expect(drops[1].date, DateTime(2026, 9, 27));
    });

    test('Someday has no days to move to', () {
      final someday = moveActions(
        task: shown[1],
        date: null,
        shown: shown,
        onDrop: (_, _) {},
      );
      expect([for (final a in someday.keys) a.label], ['Move up', 'Move down']);
    });
  });

  testWidgets('rows announce the move actions', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final data = tester.getSemantics(find.byType(TaskRow).first);
    expect(data.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    handle.dispose();
  });
}
