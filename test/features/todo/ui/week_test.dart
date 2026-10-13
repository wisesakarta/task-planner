import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/week/day_header.dart';
import 'package:todo_app/features/todo/ui/week/day_section.dart';
import 'package:todo_app/features/todo/ui/week/inline_composer.dart';
import 'package:todo_app/features/todo/ui/week/task_row.dart';
import 'package:todo_app/features/todo/ui/week/week_dates.dart';
import 'package:todo_app/features/todo/ui/week/week_screen.dart';
import 'package:todo_app/features/todo/ui/week/week_top_bar.dart';

import '../support/pump_todo.dart';

// 2026-09-30 is a Wednesday.
final wednesday = DateTime(2026, 9, 30);
final weekStart = DateTime(2026, 9, 28);

TodoTask task(
  String id,
  String title, {
  DateTime? due,
  int? color,
  bool done = false,
  RecurrenceRule? recurrence,
  DateTime? reminderAt,
}) => TodoTask.create(
  id: id,
  title: title,
  dueDate: due,
  color: color,
  recurrence: recurrence,
  reminderAt: reminderAt,
).copyWith(isDone: done);

Color over(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

void main() {
  useBundledFonts();

  group('WeekDates', () {
    test('a Monday-start week begins on Monday', () {
      expect(WeekDates.startOfWeek(wednesday), DateTime(2026, 9, 28));
      expect(
        WeekDates.startOfWeek(DateTime(2026, 9, 28)),
        DateTime(2026, 9, 28),
      );
      expect(
        WeekDates.startOfWeek(DateTime(2026, 10, 4)),
        DateTime(2026, 9, 28),
      );
    });

    test('a Sunday-start week begins on Sunday', () {
      const sunday = DateTime.sunday;
      expect(
        WeekDates.startOfWeek(wednesday, weekStartsOn: sunday),
        DateTime(2026, 9, 27),
      );
      expect(
        WeekDates.startOfWeek(DateTime(2026, 10, 4), weekStartsOn: sunday),
        DateTime(2026, 10, 4),
      );
      expect(
        WeekDates.startOfWeek(DateTime(2026, 10, 3), weekStartsOn: sunday),
        DateTime(2026, 9, 27),
      );
    });

    test('weeks cross month and year ends', () {
      expect(
        WeekDates.startOfWeek(DateTime(2027, 1, 1)),
        DateTime(2026, 12, 28),
      );
      expect(WeekDates.days(DateTime(2026, 12, 28)).last, DateTime(2027, 1, 3));
    });

    test('seven consecutive days', () {
      final days = WeekDates.days(weekStart);
      expect(days, hasLength(7));
      for (var i = 1; i < 7; i++) {
        expect(
          days[i].difference(days[i - 1]).inHours,
          inInclusiveRange(23, 25),
        );
      }
    });

    test('addWeeks moves by whole weeks', () {
      expect(WeekDates.addWeeks(weekStart, 1), DateTime(2026, 10, 5));
      expect(WeekDates.addWeeks(weekStart, -1), DateTime(2026, 9, 21));
      expect(
        WeekDates.addWeeks(DateTime(2026, 12, 28), 1),
        DateTime(2027, 1, 4),
      );
    });

    test('the title month is the month of the week\'s middle day', () {
      expect(WeekDates.titleMonth(WeekDates.days(weekStart)).month, 10);
      expect(
        WeekDates.titleMonth(WeekDates.days(DateTime(2026, 9, 21))).month,
        9,
      );
    });

    test('sameDay ignores the time', () {
      expect(
        WeekDates.sameDay(DateTime(2026, 9, 30, 23), DateTime(2026, 9, 30)),
        isTrue,
      );
      expect(
        WeekDates.sameDay(DateTime(2026, 9, 30), DateTime(2026, 10, 1)),
        isFalse,
      );
    });
  });

  group('TaskRow', () {
    Widget row({
      String title = 'Buy milk',
      bool done = false,
      int? color,
      bool repeats = false,
      bool reminder = false,
      ValueChanged<bool>? onToggle,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TaskRow(
        title: title,
        isDone: done,
        color: color,
        repeats: repeats,
        hasReminder: reminder,
        onToggle: onToggle ?? (_) {},
        onTap: onTap ?? () {},
        onLongPress: onLongPress,
      ),
    );

    testWidgets('is 42 tall with a 1 point rule under it', (tester) async {
      await pumpTodo(tester, row());
      expect(tester.getSize(find.byType(TaskRow)).height, 42);

      final decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      final bottom = (decoration.border! as Border).bottom;
      expect(bottom.color, TodoThemes.paper.light.rule);
      expect(bottom.width, 1);
    });

    testWidgets('tapping the title opens; tapping the toggle toggles', (
      tester,
    ) async {
      var opened = 0;
      final toggles = <bool>[];
      await pumpTodo(tester, row(onTap: () => opened++, onToggle: toggles.add));

      await tester.tap(find.text('Buy milk'));
      expect(opened, 1);
      expect(toggles, isEmpty);

      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      expect(toggles, [true]);
      expect(opened, 1);
    });

    testWidgets('long press is reported', (tester) async {
      var pressed = 0;
      await pumpTodo(tester, row(onLongPress: () => pressed++));
      await tester.longPress(find.text('Buy milk'));
      expect(pressed, 1);
    });

    testWidgets('a plain and a coloured title start at the same x', (
      tester,
    ) async {
      await pumpTodo(tester, row());
      final plain = tester.getTopLeft(find.text('Buy milk')).dx;

      await pumpTodo(tester, row(color: 0xFFFFE066));
      final coloured = tester.getTopLeft(find.text('Buy milk')).dx;

      // 24 margin + the pill's always-present 6 points of padding.
      expect(plain, 30);
      expect(coloured, plain);
    });

    testWidgets('a coloured title sits in a full-height pill', (tester) async {
      const lemon = 0xFFFFE066;
      await pumpTodo(tester, row(color: lemon));

      final resolved = TodoTaskColors.resolve(lemon, TodoThemes.paper.light);
      final pill = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == resolved.fill,
          );
      expect(pill.constraints!.maxHeight, 22);
      expect(
        (pill.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(11),
      );
      expect(
        tester.widget<Text>(find.text('Buy milk')).style!.color,
        resolved.onFill,
      );
    });

    testWidgets('a plain title has no fill', (tester) async {
      await pumpTodo(tester, row());
      final fills = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null && d.color!.a > 0);
      expect(fills, isEmpty);
    });

    testWidgets('repeat and reminder show 12 point icons before the title', (
      tester,
    ) async {
      await pumpTodo(tester, row(repeats: true, reminder: true));

      for (final icon in [
        Icons.repeat_rounded,
        Icons.notifications_none_rounded,
      ]) {
        expect(tester.getSize(find.byIcon(icon)), const Size(12, 12));
        expect(
          tester.getTopLeft(find.byIcon(icon)).dx,
          lessThan(tester.getTopLeft(find.text('Buy milk')).dx),
        );
      }
      await pumpTodo(tester, row());
      expect(find.byIcon(Icons.repeat_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets('a long title is one line with an ellipsis', (tester) async {
      await pumpTodo(
        tester,
        row(
          title:
              'An extremely long task title that could never fit on a '
              'single line of a phone screen',
        ),
      );

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text).first);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.byType(TaskRow)).height, 42);
    });

    testWidgets('done is struck through, dimmed to 50%, with a filled toggle', (
      tester,
    ) async {
      await pumpTodo(tester, row(done: true));

      expect(
        tester.widget<Text>(find.text('Buy milk')).style!.decoration,
        TextDecoration.lineThrough,
      );
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity);
      expect(opacities.where((o) => o == 0.5), hasLength(2)); // title + toggle

      final paint = tester.renderObject(
        find
            .descendant(
              of: find.byType(TaskRow),
              matching: find.byType(CustomPaint),
            )
            .last,
      );
      expect(
        paint,
        paints..circle(
          color: TodoThemes.paper.light.ink,
          style: PaintingStyle.fill,
        ),
      );
    });

    testWidgets('open is a ring, not a disc', (tester) async {
      await pumpTodo(tester, row());

      final paint = tester.renderObject(
        find
            .descendant(
              of: find.byType(TaskRow),
              matching: find.byType(CustomPaint),
            )
            .last,
      );
      // A stroked ring in ink, never a filled disc.
      expect(
        paint,
        isNot(
          paints..circle(
            color: TodoThemes.paper.light.ink,
            style: PaintingStyle.fill,
          ),
        ),
      );
      expect(
        paint,
        paints
          ..circle(style: PaintingStyle.stroke)
          ..path(),
      );
    });

    testWidgets('the toggle target is at least 48 wide and the full row tall', (
      tester,
    ) async {
      await pumpTodo(tester, row());
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(TaskRow),
              matching: find.byType(SizedBox),
            )
            .last,
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, 41); // the row, less its 1 point rule
    });

    testWidgets('is read as one sentence, and the toggle as a checkbox', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, row(done: true, repeats: true, reminder: true));

      expect(
        find.bySemanticsLabel('Buy milk, done, repeats, has a reminder'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buy milk')),
        matchesSemantics(
          label: 'Buy milk',
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a touch tints the row for 100 ms', (tester) async {
      await pumpTodo(tester, row());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Buy milk')),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, TodoThemes.paper.light.ink5);
      await gesture.up();
    });

    testWidgets('hovering with a mouse draws the accent 40% rule', (
      tester,
    ) async {
      await pumpTodo(tester, row());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(TaskRow)));
      await tester.pump();

      final decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      expect(
        (decoration.border! as Border).bottom.color,
        TodoThemes.paper.light.accent.withValues(alpha: 0.4),
      );
      await mouse.removePointer();
    });

    for (final entry in allPalettes.entries) {
      testWidgets('renders every colour in ${entry.key}', (tester) async {
        await pumpTodo(
          tester,
          Column(
            children: [
              for (final swatch in TodoTaskColors.all)
                row(
                  title: swatch.name,
                  color: swatch.argb,
                  repeats: true,
                  reminder: true,
                ),
              row(title: 'Done', done: true, color: 0xFFFFE066),
            ],
          ),
          palette: entry.value,
          height: 1000,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives 200% text on the narrowest phone', (tester) async {
      await pumpTodo(
        tester,
        row(
          title: 'A long title at double size',
          color: 0xFFFFE066,
          repeats: true,
        ),
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DayHeader', () {
    Widget header({bool today = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DayHeader(date: wednesday, isToday: today),
    );

    testWidgets(
      'shows the date in bold at the left, the weekday at the right',
      (tester) async {
        await pumpTodo(tester, header());

        final date = tester.getRect(find.text('30 Sep'));
        final day = tester.getRect(find.text('Wed'));
        expect(date.left, 24);
        expect(day.right, 390 - 24);
        expect(
          tester.widget<Text>(find.text('30 Sep')).style!.fontWeight,
          FontWeight.w800,
        );
        expect(
          tester.widget<Text>(find.text('Wed')).style!.fontWeight,
          FontWeight.w500,
        );
      },
    );

    testWidgets('is 42 tall with a 2 point ink rule', (tester) async {
      await pumpTodo(tester, header());
      expect(tester.getSize(find.byType(DayHeader)).height, 42);

      final box = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).border != null,
          );
      final bottom =
          ((box.decoration! as BoxDecoration).border! as Border).bottom;
      expect(bottom.width, 2);
      expect(bottom.color, TodoThemes.paper.light.ink);
    });

    testWidgets('today uses the accent for the rule and readable accent text', (
      tester,
    ) async {
      final p = TodoThemes.paper.light;
      await pumpTodo(tester, header(today: true));

      final box = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).border != null,
          );
      expect(
        ((box.decoration! as BoxDecoration).border! as Border).bottom.color,
        p.accent,
      );
      expect(
        tester.widget<Text>(find.text('30 Sep')).style!.color,
        p.accentInk,
      );
      expect(tester.widget<Text>(find.text('Wed')).style!.color, p.accentInk);
    });

    testWidgets('other days use ink and secondary ink', (tester) async {
      final p = TodoThemes.paper.light;
      await pumpTodo(tester, header());
      expect(tester.widget<Text>(find.text('30 Sep')).style!.color, p.ink);
      expect(
        tester.widget<Text>(find.text('Wed')).style!.color,
        p.textSecondary,
      );
    });

    testWidgets('is a semantic header with the full date', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, header(today: true));
      expect(
        tester.getSemantics(find.byType(DayHeader)),
        matchesSemantics(
          label: 'Wednesday, 30 September, today',
          isHeader: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('fits at 200% text on the narrowest phone', (tester) async {
      await pumpTodo(tester, header(), textScale: 2, width: 320);
      expect(tester.takeException(), isNull);
    });
  });

  group('InlineComposer', () {
    Widget composer(
      FutureOr<bool> Function(String) onSubmit, {
      TextEditingController? controller,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InlineComposer(
        onSubmit: onSubmit,
        controller: controller,
        semanticsLabel: 'Add a task on Wednesday',
      ),
    );

    Future<void> typeAndSubmit(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    testWidgets('is one 42 point line', (tester) async {
      await pumpTodo(tester, composer((_) => true));
      expect(tester.getSize(find.byType(InlineComposer)).height, 42);
    });

    testWidgets('Enter submits the trimmed title and clears the line', (
      tester,
    ) async {
      final saved = <String>[];
      await pumpTodo(
        tester,
        composer((t) {
          saved.add(t);
          return true;
        }),
      );

      await typeAndSubmit(tester, '  Buy milk  ');

      expect(saved, ['Buy milk']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a blank line is ignored', (tester) async {
      final saved = <String>[];
      await pumpTodo(
        tester,
        composer((t) {
          saved.add(t);
          return true;
        }),
      );
      await typeAndSubmit(tester, '   ');
      expect(saved, isEmpty);
    });

    testWidgets('a failed save keeps what was typed', (tester) async {
      await pumpTodo(tester, composer((_) => false));
      await typeAndSubmit(tester, 'Will fail');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Will fail',
      );
    });

    testWidgets('an asynchronous save is awaited before clearing', (
      tester,
    ) async {
      final completer = Completer<bool>();
      await pumpTodo(tester, composer((_) => completer.future));
      await typeAndSubmit(tester, 'Slow');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Slow',
      );

      completer.complete(true);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('the line stays focused so the next task can be typed', (
      tester,
    ) async {
      final saved = <String>[];
      await pumpTodo(
        tester,
        composer((t) {
          saved.add(t);
          return true;
        }),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await typeAndSubmit(tester, 'One');
      await typeAndSubmit(tester, 'Two');
      await typeAndSubmit(tester, 'Three');

      expect(saved, ['One', 'Two', 'Three']);
      expect(tester.testTextInput.isVisible, isTrue);
      final focused = tester
          .widget<TextField>(find.byType(TextField))
          .focusNode!
          .hasFocus;
      expect(focused, isTrue);
    });

    testWidgets('stays flat while focused: no card, no shadow', (tester) async {
      await pumpTodo(tester, composer((_) => true));
      final before = tester.getRect(find.byType(InlineComposer));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
            true,
        isTrue,
      );
      final shadows = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty);
      expect(shadows, isEmpty);
      expect(tester.getRect(find.byType(InlineComposer)), before);
    });

    testWidgets('is announced as a text field', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, composer((_) => true));
      expect(find.bySemanticsLabel('Add a task on Wednesday'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('can use a controller from outside', (tester) async {
      final controller = TextEditingController(text: 'Draft');
      addTearDown(controller.dispose);
      await pumpTodo(tester, composer((_) => true, controller: controller));
      expect(find.text('Draft'), findsOneWidget);
    });
  });

  group('DaySection', () {
    Widget section(
      List<TodoTask> tasks, {
      bool today = false,
      void Function(TodoTask, bool)? onToggle,
      ValueChanged<TodoTask>? onOpen,
      FutureOr<bool> Function(String)? onAdd,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DaySection(
        date: wednesday,
        isToday: today,
        tasks: tasks,
        onToggle: onToggle ?? (_, _) {},
        onOpen: onOpen ?? (_) {},
        onAdd: onAdd ?? (_) => true,
      ),
    );

    testWidgets('an empty day is a header and one empty line', (tester) async {
      await pumpTodo(tester, section(const []));
      expect(tester.getSize(find.byType(DaySection)).height, 84);
      expect(find.byType(TaskRow), findsNothing);
    });

    testWidgets('each task adds one 42 point row, the spare line stays', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        section([
          task('a', 'One', due: wednesday),
          task('b', 'Two', due: wednesday),
        ]),
      );
      expect(tester.getSize(find.byType(DaySection)).height, 42 + 42 * 2 + 42);
      expect(find.byType(TaskRow), findsNWidgets(2));
    });

    testWidgets('keeps the given order', (tester) async {
      await pumpTodo(
        tester,
        section([
          task('a', 'First', due: wednesday),
          task('b', 'Second', due: wednesday),
        ]),
      );
      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy),
      );
    });

    testWidgets('passes taps and toggles with the right task', (tester) async {
      final opened = <String>[];
      final toggled = <String>[];
      final a = task('a', 'One', due: wednesday);
      await pumpTodo(
        tester,
        section(
          [a],
          onOpen: (t) => opened.add(t.id),
          onToggle: (t, done) => toggled.add('${t.id}:$done'),
        ),
      );

      await tester.tap(find.text('One'));
      await tester.tapAt(
        tester.getCenter(
          find
              .descendant(
                of: find.byType(TaskRow),
                matching: find.byType(CustomPaint),
              )
              .last,
        ),
      );
      expect(opened, ['a']);
      expect(toggled, ['a:true']);
    });

    testWidgets('typing on the spare line adds a task for the day', (
      tester,
    ) async {
      final saved = <String>[];
      await pumpTodo(
        tester,
        section(
          const [],
          onAdd: (t) {
            saved.add(t);
            return true;
          },
        ),
      );
      await tester.enterText(find.byType(TextField), 'New one');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(saved, ['New one']);
    });

    test('sortDoneDown keeps each group\'s order', () {
      final sorted = sortDoneDown([
        task('1', 'a', done: true),
        task('2', 'b'),
        task('3', 'c', done: true),
        task('4', 'd'),
      ]);
      expect(sorted.map((t) => t.id), ['2', '4', '1', '3']);
    });
  });

  group('WeekTopBar', () {
    Widget bar({
      VoidCallback? onSearch,
      VoidCallback? onMenu,
      VoidCallback? onPrevious,
      VoidCallback? onNext,
      VoidCallback? onTitleTap,
      String title = 'Oct 2026',
    }) => WeekTopBar(
      title: title,
      onSearch: onSearch ?? () {},
      onMenu: onMenu ?? () {},
      onPrevious: onPrevious ?? () {},
      onNext: onNext ?? () {},
      onTitleTap: onTitleTap,
    );

    testWidgets('shows the title large at the left', (tester) async {
      await pumpTodo(tester, bar());
      expect(tester.getTopLeft(find.text('Oct 2026')).dx, 16);
      expect(tester.widget<Text>(find.text('Oct 2026')).style!.fontSize, 32);
    });

    testWidgets(
      'has four labelled buttons, 40 point circles 16 from the edge',
      (tester) async {
        await pumpTodo(tester, bar());
        for (final label in ['Search', 'Menu', 'Previous week', 'Next week']) {
          expect(find.byTooltip(label), findsOneWidget, reason: label);
        }
        final next = tester.getRect(find.byTooltip('Next week'));
        expect(
          next.right,
          390 - 12,
        ); // 48 target; the 40 circle is 4 inside → 16
        expect(next.width, greaterThanOrEqualTo(48));
      },
    );

    testWidgets('each button reports its tap', (tester) async {
      final taps = <String>[];
      await pumpTodo(
        tester,
        bar(
          onSearch: () => taps.add('search'),
          onMenu: () => taps.add('menu'),
          onPrevious: () => taps.add('previous'),
          onNext: () => taps.add('next'),
        ),
      );
      for (final label in ['Search', 'Menu', 'Previous week', 'Next week']) {
        await tester.tap(find.byTooltip(label));
      }
      expect(taps, ['search', 'menu', 'previous', 'next']);
    });

    testWidgets('the title opens the month view only when wired', (
      tester,
    ) async {
      var opened = 0;
      await pumpTodo(tester, bar(onTitleTap: () => opened++));
      await tester.tap(find.text('Oct 2026'));
      expect(opened, 1);

      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Oct 2026, open month view'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a long title is cut with an ellipsis at 200% text', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        bar(title: 'September 2026'),
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('WeekScreen', () {
    Widget screen(
      List<TodoTask> tasks, {
      DateTime? start,
      bool sortDown = false,
      bool hideDone = false,
      FutureOr<bool> Function(DateTime?, String)? onAdd,
      void Function(TodoTask, bool)? onToggle,
      ValueChanged<TodoTask>? onOpen,
      VoidCallback? onPrevious,
      VoidCallback? onNext,
      VoidCallback? onToday,
      VoidCallback? onMonth,
      DateTime? today,
    }) => WeekScreen(
      weekStart: start ?? weekStart,
      today: today ?? wednesday,
      tasks: tasks,
      sortCompletedDown: sortDown,
      hideCompleted: hideDone,
      onToggle: onToggle ?? (_, _) {},
      onOpen: onOpen ?? (_) {},
      onAdd: onAdd ?? (_, _) => true,
      onPrevious: onPrevious ?? () {},
      onNext: onNext ?? () {},
      onToday: onToday ?? () {},
      onMonth: onMonth,
      onSearch: () {},
      onMenu: () {},
    );

    group('the top row', () {
      // Where a day's header sits when it is on the top row: one margin
      // below the top of the list, where Monday sits when scrolled to the top.
      double topRow(WidgetTester tester) =>
          tester.getTopLeft(find.byType(Scrollable).first).dy + TodoSize.margin;

      double headerTop(WidgetTester tester, String date) => tester
          .getTopLeft(
            find.ancestor(
              of: find.text(date),
              matching: find.byType(DayHeader),
            ),
          )
          .dy;

      testWidgets('is today on the current week', (tester) async {
        await pumpTodo(tester, screen(const []));
        expect(headerTop(tester, '30 Sep'), topRow(tester));
        expect(
          headerTop(tester, '29 Sep'),
          lessThan(topRow(tester)),
          reason: 'the days before today are above, out of view',
        );
      });

      testWidgets('lets you scroll up to the start of the week', (
        tester,
      ) async {
        await pumpTodo(tester, screen(const []));
        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, 2000),
          3000,
        );
        await tester.pumpAndSettle();
        expect(headerTop(tester, '28 Sep'), topRow(tester));
      });

      testWidgets('is the first day on any other week', (tester) async {
        await pumpTodo(tester, screen(const [], start: DateTime(2026, 10, 5)));
        expect(headerTop(tester, '5 Oct'), topRow(tester));
      });

      testWidgets('is a day picked in the month view', (tester) async {
        await pumpTodo(
          tester,
          WeekScreen(
            weekStart: DateTime(2026, 10, 12),
            today: wednesday,
            focusDay: DateTime(2026, 10, 15),
            tasks: const [],
            onToggle: (_, _) {},
            onOpen: (_) {},
            onAdd: (_, _) => true,
            onPrevious: () {},
            onNext: () {},
            onToday: () {},
            onSearch: () {},
            onMenu: () {},
          ),
        );
        expect(headerTop(tester, '15 Oct'), topRow(tester));
      });

      testWidgets('stays on today on a Sunday, with Someday below', (
        tester,
      ) async {
        await pumpTodo(tester, screen(const [], today: DateTime(2026, 10, 4)));
        expect(headerTop(tester, '4 Oct'), topRow(tester));
        expect(find.text('Someday'), findsOneWidget);
      });

      testWidgets('does not move when a task is added above it', (
        tester,
      ) async {
        await pumpTodo(tester, screen(const []));
        final before = headerTop(tester, '30 Sep');
        await pumpTodo(
          tester,
          screen([
            for (var i = 0; i < 4; i++)
              task('m$i', 'Monday $i', due: weekStart),
          ]),
        );
        expect(headerTop(tester, '30 Sep'), before);
      });

      testWidgets('a new visit lands on the focus day again; the same visit '
          'keeps the scroll', (tester) async {
        final bucket = PageStorageBucket();
        Widget at(int visit) => PageStorage(
          bucket: bucket,
          child: WeekScreen(
            weekStart: weekStart,
            today: wednesday,
            visit: visit,
            tasks: const [],
            onToggle: (_, _) {},
            onOpen: (_) {},
            onAdd: (_, _) => true,
            onPrevious: () {},
            onNext: () {},
            onToday: () {},
            onSearch: () {},
            onMenu: () {},
          ),
        );

        await pumpTodo(tester, at(0));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 120));
        await tester.pumpAndSettle();
        final scrolled = headerTop(tester, '30 Sep');
        expect(scrolled, greaterThan(topRow(tester)));

        // Away (the month view) and back, same visit: where it was.
        await pumpTodo(tester, const SizedBox());
        await pumpTodo(tester, at(0));
        expect(headerTop(tester, '30 Sep'), scrolled);

        // A new visit: today on top again.
        await pumpTodo(tester, at(1));
        expect(headerTop(tester, '30 Sep'), topRow(tester));
      });
    });

    group('the title', () {
      testWidgets('is ink on the current week and opens the month view', (
        tester,
      ) async {
        var month = 0;
        var today = 0;
        await pumpTodo(
          tester,
          screen(const [], onMonth: () => month++, onToday: () => today++),
          height: 1400,
        );

        final p = TodoThemes.paper.light;
        expect(tester.widget<Text>(find.text('Oct 2026')).style!.color, p.ink);
        await tester.tap(find.text('Oct 2026'));
        expect(month, 1);
        expect(today, 0);
      });

      testWidgets('is the accent on another week and returns to this one', (
        tester,
      ) async {
        var month = 0;
        var today = 0;
        await pumpTodo(
          tester,
          screen(
            const [],
            start: DateTime(2026, 10, 5),
            onMonth: () => month++,
            onToday: () => today++,
          ),
          height: 1400,
        );

        final p = TodoThemes.paper.light;
        expect(
          tester.widget<Text>(find.text('Oct 2026')).style!.color,
          p.accentInk,
        );
        await tester.tap(find.text('Oct 2026'));
        expect(today, 1);
        expect(month, 0);
      });

      testWidgets('says what tapping it does', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpTodo(tester, screen(const [], onMonth: () {}), height: 1400);
        expect(
          find.bySemanticsLabel('Oct 2026, open month view'),
          findsOneWidget,
        );
        await pumpTodo(
          tester,
          screen(const [], start: DateTime(2026, 10, 5), onMonth: () {}),
          height: 1400,
        );
        expect(
          find.bySemanticsLabel('Oct 2026, back to this week'),
          findsOneWidget,
        );
        handle.dispose();
      });

      testWidgets('is not a button on the current week without a month view', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpTodo(tester, screen(const []), height: 1400);
        expect(
          find.bySemanticsLabel('Oct 2026, open month view'),
          findsNothing,
        );
        handle.dispose();
      });
    });

    testWidgets('titles the week by its month and lists seven days', (
      tester,
    ) async {
      await pumpTodo(tester, screen(const []), height: 1400);

      expect(find.text('Oct 2026'), findsOneWidget);
      for (final label in [
        '28 Sep',
        '29 Sep',
        '30 Sep',
        '1 Oct',
        '2 Oct',
        '3 Oct',
        '4 Oct',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Someday'), findsOneWidget);
    });

    testWidgets('days are 24 apart: header, one empty line, then the gap', (
      tester,
    ) async {
      await pumpTodo(tester, screen(const []), height: 1400);
      final first = tester.getTopLeft(find.text('28 Sep')).dy;
      final second = tester.getTopLeft(find.text('29 Sep')).dy;
      expect(second - first, 42 + 42 + 24);
    });

    testWidgets('only today gets the accent rule', (tester) async {
      await pumpTodo(tester, screen(const []), height: 1400);
      final accent = TodoThemes.paper.light.accent;
      final rules = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(DayHeader),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration).border! as Border)
          .map((b) => b.bottom.color);
      expect(rules.where((c) => c == accent), hasLength(1));
      expect(rules, hasLength(7));
    });

    testWidgets('puts each task on its own day', (tester) async {
      await pumpTodo(
        tester,
        screen([
          task('a', 'On Monday', due: DateTime(2026, 9, 28)),
          task('b', 'On Wednesday', due: wednesday),
          task('c', 'On Sunday', due: DateTime(2026, 10, 4)),
          task('d', 'Next week', due: DateTime(2026, 10, 6)),
        ]),
        height: 1400,
      );

      expect(find.text('On Monday'), findsOneWidget);
      expect(find.text('On Wednesday'), findsOneWidget);
      expect(find.text('On Sunday'), findsOneWidget);
      expect(find.text('Next week'), findsNothing);
      expect(
        tester.getTopLeft(find.text('On Monday')).dy,
        lessThan(tester.getTopLeft(find.text('On Wednesday')).dy),
      );
    });

    testWidgets('tasks without a date live in Someday', (tester) async {
      await pumpTodo(
        tester,
        screen([task('s', 'Learn piano'), task('d', 'Dated', due: wednesday)]),
        height: 1400,
      );
      expect(
        tester.getTopLeft(find.text('Learn piano')).dy,
        greaterThan(tester.getTopLeft(find.text('Someday')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Dated')).dy,
        lessThan(tester.getTopLeft(find.text('Someday')).dy),
      );
    });

    testWidgets('deleted tasks are not shown', (tester) async {
      final deleted = task(
        'x',
        'Gone',
        due: wednesday,
      ).copyWith(deletedAt: DateTime.utc(2026, 9, 30));
      await pumpTodo(tester, screen([deleted]), height: 1400);
      expect(find.text('Gone'), findsNothing);
    });

    testWidgets('can hide completed tasks', (tester) async {
      final tasks = [
        task('a', 'Open', due: wednesday),
        task('b', 'Finished', due: wednesday, done: true),
      ];
      await pumpTodo(tester, screen(tasks, hideDone: true), height: 1400);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Finished'), findsNothing);
    });

    testWidgets('can sort completed tasks down', (tester) async {
      final tasks = [
        task('a', 'Finished', due: wednesday, done: true),
        task('b', 'Open', due: wednesday),
      ];
      await pumpTodo(tester, screen(tasks), height: 1400);
      expect(
        tester.getTopLeft(find.text('Finished')).dy,
        lessThan(tester.getTopLeft(find.text('Open')).dy),
      );

      await pumpTodo(tester, screen(tasks, sortDown: true), height: 1400);
      expect(
        tester.getTopLeft(find.text('Open')).dy,
        lessThan(tester.getTopLeft(find.text('Finished')).dy),
      );
    });

    testWidgets('adding on a day passes the date; on Someday passes null', (
      tester,
    ) async {
      final added = <(DateTime?, String)>[];
      await pumpTodo(
        tester,
        screen(
          const [],
          onAdd: (d, t) {
            added.add((d, t));
            return true;
          },
        ),
        height: 1400,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(2), 'For Wednesday');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.enterText(fields.last, 'Someday thing');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(added[0], (DateTime(2026, 9, 30), 'For Wednesday'));
      expect(added[1], (null, 'Someday thing'));
    });

    testWidgets('previous and next report taps', (tester) async {
      var previous = 0;
      var next = 0;
      await pumpTodo(
        tester,
        screen(const [], onPrevious: () => previous++, onNext: () => next++),
      );
      await tester.tap(find.byTooltip('Previous week'));
      await tester.tap(find.byTooltip('Next week'));
      expect((previous, next), (1, 1));
    });

    testWidgets('changing the week cross-fades to the new one', (tester) async {
      await pumpTodo(tester, screen(const []), height: 1400);
      expect(find.text('28 Sep'), findsOneWidget);

      await pumpTodo(
        tester,
        screen(const [], start: DateTime(2026, 10, 5)),
        height: 1400,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Both weeks are on screen mid-fade.
      expect(find.text('28 Sep'), findsOneWidget);
      expect(find.text('5 Oct'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('28 Sep'), findsNothing);
      expect(find.text('5 Oct'), findsOneWidget);
    });

    testWidgets('reduced motion changes the week at once', (tester) async {
      await pumpTodo(
        tester,
        screen(const []),
        height: 1400,
        disableAnimations: true,
      );
      await pumpTodo(
        tester,
        screen(const [], start: DateTime(2026, 10, 5)),
        height: 1400,
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('28 Sep'), findsNothing);
    });

    testWidgets('a tablet keeps the content column at most 640 wide', (
      tester,
    ) async {
      await pumpTodo(tester, screen(const []), width: 1000, height: 1400);
      final header = tester.getRect(find.byType(DayHeader).first);
      expect(header.width, 640 - 48);
      expect(tester.getCenter(find.byType(DayHeader).first).dx, 500);
    });

    testWidgets('every task colour draws on the week in every theme', (
      tester,
    ) async {
      for (final entry in allPalettes.entries) {
        await pumpTodo(
          tester,
          screen([
            for (var i = 0; i < TodoTaskColors.swatches.length; i++)
              task(
                'c$i',
                TodoTaskColors.swatches[i].name,
                due: wednesday,
                color: TodoTaskColors.swatches[i].argb,
              ),
            task(
              'r',
              'Repeats',
              due: wednesday,
              recurrence: const RecurrenceRule.daily(),
            ),
            task(
              'n',
              'Remind',
              due: wednesday,
              reminderAt: DateTime(2026, 9, 30, 9),
            ),
          ]),
          palette: entry.value,
          height: 2000,
        );
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('survives 200% text on the narrowest phone', (tester) async {
      await pumpTodo(
        tester,
        screen([
          task(
            'a',
            'A title at double size',
            due: wednesday,
            color: 0xFFFFE066,
          ),
        ]),
        textScale: 2,
        width: 320,
        height: 2000,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
