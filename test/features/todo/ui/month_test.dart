import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/ui/month/month_rows.dart';
import 'package:todo_app/features/todo/ui/month/month_screen.dart';

import '../support/pump_todo.dart';

// Thursday 1 October 2026.
final _today = DateTime(2026, 10, 1);

TodoTask _task(
  String title,
  DateTime due, {
  int? color,
  bool done = false,
  bool deleted = false,
}) => TodoTask.create(
  id: title,
  title: title,
  dueDate: due,
  color: color,
  now: DateTime(2026, 9, 30),
).copyWith(isDone: done, deletedAt: deleted ? DateTime(2026, 9, 30) : null);

Widget _month({
  List<TodoTask> tasks = const [],
  DateTime? today,
  int weekStartsOn = DateTime.monday,
  ValueChanged<DateTime>? onSelectDay,
  ValueChanged<TodoTask>? onOpenTask,
}) => MonthScreen(
  today: today ?? _today,
  tasks: tasks,
  weekStartsOn: weekStartsOn,
  onSelectDay: onSelectDay ?? (_) {},
  onOpenTask: onOpenTask ?? (_) {},
);

void main() {
  useBundledFonts();

  group('buildMonthRows', () {
    List<MonthRow> rows({
      int startsOn = DateTime.monday,
      DateTime? from,
      DateTime? to,
    }) => buildMonthRows(
      from: from ?? DateTime(2026, 9),
      to: to ?? DateTime(2026, 10),
      weekStartsOn: startsOn,
    );

    List<int?> days(MonthRow row) => [for (final c in row.cells) c?.day];

    test('September 2026 (Monday first) starts on a Tuesday', () {
      final september = rows(to: DateTime(2026, 9));
      expect(september, hasLength(5));
      expect(days(september[0]), [null, 1, 2, 3, 4, 5, 6]);
      expect(days(september[1]), [7, 8, 9, 10, 11, 12, 13]);
      expect(days(september[4]), [28, 29, 30, null, null, null, null]);
    });

    test(
      'only the first row of a month starts it, in the column of the 1st',
      () {
        final september = rows(to: DateTime(2026, 9));
        expect(september.map((r) => r.startsMonth), [
          true,
          false,
          false,
          false,
          false,
        ]);
        expect(september.first.monthStart, DateTime(2026, 9));
        expect(september.first.labelColumn, 1);
      },
    );

    test(
      'a week that crosses a month is split: left half, then right half',
      () {
        final both = rows();
        final september = both.lastWhere(
          (r) => r.cells.any((c) => c?.month == 9 && c?.day == 30),
        );
        final october = both[both.indexOf(september) + 1];
        expect(days(september), [28, 29, 30, null, null, null, null]);
        expect(days(october), [null, null, null, 1, 2, 3, 4]);
        expect(october.startsMonth, isTrue);
        expect(october.labelColumn, 3);
      },
    );

    test('a Sunday-first week puts the 1st in another column', () {
      final october = rows(
        startsOn: DateTime.sunday,
        from: DateTime(2026, 10),
        to: DateTime(2026, 10),
      );
      // 1 October 2026 is a Thursday: Sunday-first makes that column 4.
      expect(october.first.labelColumn, 4);
      expect(days(october.first), [null, null, null, null, 1, 2, 3]);
      expect(days(october[1]), [4, 5, 6, 7, 8, 9, 10]);
    });

    test(
      'every day appears exactly once, in order, across years and leap days',
      () {
        final all = rows(from: DateTime(2027, 12), to: DateTime(2028, 3));
        final seen = [
          for (final r in all)
            for (final c in r.cells) ?c,
        ];
        var expected = DateTime(2027, 12);
        for (final day in seen) {
          expect(day, expected);
          expected = DateTime(expected.year, expected.month, expected.day + 1);
        }
        expect(seen.last, DateTime(2028, 3, 31));
        expect(seen.contains(DateTime(2028, 2, 29)), isTrue);
      },
    );

    test('a month that ends exactly on a week end has no empty row', () {
      // 28 Feb 2027 is a Sunday.
      final feb = rows(from: DateTime(2027, 2), to: DateTime(2027, 2));
      expect(feb, hasLength(4));
      expect(days(feb.last), [22, 23, 24, 25, 26, 27, 28]);
    });

    test('heights: 138 a row, 202 for the first row of a month', () {
      final september = rows(to: DateTime(2026, 9));
      expect(september.first.height, 202);
      expect(september[1].height, 138);
    });

    test('four pills fit under a day number', () {
      expect(MonthMetrics.pillCapacity, 4);
    });
  });

  group('MonthScreen', () {
    testWidgets('shows the year, two arrows, and one letter per weekday', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      expect(find.text('2026'), findsOneWidget);
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('S'), findsNWidgets(2));
    });

    testWidgets('a Sunday-first week begins with S', (tester) async {
      await pumpTodo(tester, _month(weekStartsOn: DateTime.sunday));
      final letters = tester.widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data != null &&
              w.data!.length == 1 &&
              'MTWFS'.contains(w.data!) &&
              w.style?.fontSize == 11,
        ),
      );
      expect(letters.first.data, 'S');
      expect(letters.map((t) => t.data).join(), 'SMTWTFS');
    });

    testWidgets('opens at the top of this month, named above its first week', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      expect(find.text('October'), findsOneWidget);
      // October 2026 starts on a Thursday: the name is centred on that column.
      final cell = (390 - 32) / 7;
      final thursdayCentre = 16 + cell * 3 + cell / 2;
      expect(
        tester.getCenter(find.text('October')).dx,
        closeTo(thursdayCentre, 1),
      );
    });

    testWidgets('the year follows the scroll', (tester) async {
      await pumpTodo(tester, _month());
      expect(find.text('2026'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, 6000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 6000));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsNothing);
      expect(find.text('2025'), findsOneWidget);
    });

    testWidgets('next and previous move a month at a time', (tester) async {
      await pumpTodo(tester, _month());
      expect(find.text('October'), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November'), findsOneWidget);
      expect(find.text('October'), findsNothing);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September'), findsOneWidget);
    });

    testWidgets('today is a number on a pale wash of the accent', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      final p = TodoThemes.paper.light;
      final circle = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('1').first,
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (circle.decoration! as BoxDecoration).color,
        Color.alphaBlend(p.accent.withValues(alpha: 0.18), p.paper),
      );
      expect(tester.widget<Text>(find.text('1').first).style!.color, p.ink);
    });

    testWidgets('a day number is a 28-point circle, weekends are quieter', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      final p = TodoThemes.paper.light;
      // October 2026: Fri 2, Sat 3, Sun 4.
      final friday = tester.widget<Text>(find.text('2').first).style!.color;
      final saturday = tester.widget<Text>(find.text('3').first).style!.color;
      expect(friday, p.ink);
      expect(saturday, p.textSecondary);
      final circle = tester.getSize(
        find
            .ancestor(
              of: find.text('2').first,
              matching: find.byType(Container),
            )
            .first,
      );
      expect(circle, const Size(28, 28));
    });

    testWidgets('a week row is 138 tall and the first row of a month 202', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      // The first October row (1–4) has the month label: 202. Next row: 138.
      final firstRow = find
          .ancestor(of: find.text('4'), matching: find.byType(LayoutBuilder))
          .first;
      expect(tester.getSize(firstRow).height, 202);
      final nextRow = find
          .ancestor(
            of: find.text('5').first,
            matching: find.byType(LayoutBuilder),
          )
          .first;
      expect(tester.getSize(nextRow).height, 138);
    });

    testWidgets('a partial row is ruled only where it has days', (
      tester,
    ) async {
      await pumpTodo(tester, _month());
      final p = TodoThemes.paper.light;
      // The October row holding 1–4 has four days, so four rules.
      final row = find
          .ancestor(of: find.text('4'), matching: find.byType(LayoutBuilder))
          .first;
      final rules = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: row, matching: find.byType(DecoratedBox)),
          )
          .where((box) {
            final d = box.decoration;
            return d is BoxDecoration &&
                d.border is Border &&
                (d.border! as Border).top.color == p.rule;
          });
      expect(rules, hasLength(4));
    });

    testWidgets('a day cell is (width − 32) ÷ 7 wide', (tester) async {
      await pumpTodo(tester, _month());
      final five = tester.getCenter(find.text('5').first).dx;
      final six = tester.getCenter(find.text('6').first).dx;
      expect(six - five, closeTo((390 - 32) / 7, 0.5));
    });

    testWidgets('tapping a day reports it', (tester) async {
      final handle = tester.ensureSemantics();
      DateTime? tapped;
      await pumpTodo(tester, _month(onSelectDay: (d) => tapped = d));

      await tester.tap(find.bySemanticsLabel(RegExp('Tuesday, 6 October')));
      expect(tapped, DateTime(2026, 10, 6));
      handle.dispose();
    });

    testWidgets('a day is spoken with its date, today and its task count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(
        tester,
        _month(
          tasks: [
            _task('A', DateTime(2026, 10, 1)),
            _task('B', DateTime(2026, 10, 1)),
          ],
        ),
      );
      expect(
        find.bySemanticsLabel('Thursday, 1 October, today, 2 tasks'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Friday, 2 October, no tasks'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('tasks in the month', () {
    testWidgets('appear as 18-point pills under the day number', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _month(tasks: [_task('Hello', DateTime(2026, 10, 2))]),
      );
      expect(find.text('Hello'), findsOneWidget);
      final pill = tester.getSize(
        find
            .ancestor(of: find.text('Hello'), matching: find.byType(Container))
            .first,
      );
      expect(pill.height, 18 + 3, reason: '18 tall plus the 3-point gap below');
      expect(
        tester.getTopLeft(find.text('Hello')).dy,
        greaterThan(tester.getBottomLeft(find.text('2').first).dy),
      );
    });

    testWidgets('an uncoloured pill is a whisper of ink, 12 point text', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _month(tasks: [_task('Hello', DateTime(2026, 10, 2))]),
      );
      final p = TodoThemes.paper.light;
      final pill = tester.widget<Container>(
        find
            .ancestor(of: find.text('Hello'), matching: find.byType(Container))
            .first,
      );
      expect((pill.decoration! as BoxDecoration).color, p.ink5);
      expect(tester.widget<Text>(find.text('Hello')).style!.fontSize, 12);
    });

    testWidgets('a coloured task fills its pill, text readable on it', (
      tester,
    ) async {
      final ocean = TodoTaskColors.swatches[4].argb;
      await pumpTodo(
        tester,
        _month(tasks: [_task('Plan', DateTime(2026, 10, 2), color: ocean)]),
      );
      final p = TodoThemes.paper.light;
      final style = TodoTaskColors.resolve(ocean, p);
      final pill = tester.widget<Container>(
        find
            .ancestor(of: find.text('Plan'), matching: find.byType(Container))
            .first,
      );
      expect((pill.decoration! as BoxDecoration).color, style.fill);
      expect(tester.widget<Text>(find.text('Plan')).style!.color, style.onFill);
    });

    testWidgets('a finished task is struck through and dimmed', (tester) async {
      await pumpTodo(
        tester,
        _month(tasks: [_task('Done', DateTime(2026, 10, 2), done: true)]),
      );
      expect(
        tester.widget<Text>(find.text('Done')).style!.decoration,
        TextDecoration.lineThrough,
      );
      final opacity = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.text('Done'),
              matching: find.byType(Opacity),
            ),
          )
          .first;
      expect(opacity.opacity, 0.5);
    });

    testWidgets('deleted tasks and tasks on other days are not drawn', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _month(
          tasks: [
            _task('Gone', DateTime(2026, 10, 2), deleted: true),
            _task('Elsewhere', DateTime(2026, 10, 9)),
            TodoTask.create(id: 's', title: 'Someday', now: _today),
          ],
        ),
      );
      expect(find.text('Gone'), findsNothing);
      expect(find.text('Someday'), findsNothing);
      expect(find.text('Elsewhere'), findsOneWidget);
    });

    testWidgets('tapping a pill opens the task, not the day', (tester) async {
      TodoTask? opened;
      DateTime? day;
      await pumpTodo(
        tester,
        _month(
          tasks: [_task('Hello', DateTime(2026, 10, 2))],
          onOpenTask: (t) => opened = t,
          onSelectDay: (d) => day = d,
        ),
      );
      await tester.tap(find.text('Hello'));
      expect(opened?.title, 'Hello');
      expect(day, isNull);
    });

    testWidgets('a crowded day shows three pills and "+N more"', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _month(
          tasks: [
            for (var i = 0; i < 9; i++) _task('Task $i', DateTime(2026, 10, 2)),
          ],
        ),
      );
      expect(find.textContaining('Task '), findsNWidgets(3));
      expect(find.text('+6 more'), findsOneWidget);
    });

    testWidgets('four tasks still fit, without "more"', (tester) async {
      await pumpTodo(
        tester,
        _month(
          tasks: [
            for (var i = 0; i < 4; i++) _task('Task $i', DateTime(2026, 10, 2)),
          ],
        ),
      );
      expect(find.textContaining('Task '), findsNWidgets(4));
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('a long title is cut to one line', (tester) async {
      await pumpTodo(
        tester,
        _month(
          tasks: [
            _task('A very long task title indeed', DateTime(2026, 10, 2)),
          ],
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('A very long'),
      );
      expect(paragraph.maxLines, 1);
      expect(paragraph.didExceedMaxLines, isTrue);
    });
  });

  group('every theme and size', () {
    for (final entry in allPalettes.entries) {
      testWidgets('reads in ${entry.key}', (tester) async {
        await pumpTodo(
          tester,
          _month(
            tasks: [
              for (final (i, s) in TodoTaskColors.swatches.indexed)
                _task('Task $i', DateTime(2026, 10, 2), color: s.argb),
            ],
          ),
          palette: entry.value,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final width in [320.0, 390.0, 768.0, 1200.0]) {
      testWidgets('fits $width wide', (tester) async {
        await pumpTodo(
          tester,
          _month(tasks: [_task('Hello', DateTime(2026, 10, 2))]),
          width: width,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives 200% text on the narrowest phone', (tester) async {
      await pumpTodo(
        tester,
        _month(tasks: [_task('Hello', DateTime(2026, 10, 2))]),
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
