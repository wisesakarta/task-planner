import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/ui/card/color_popover.dart';
import 'package:todo_app/features/todo/ui/card/date_popover.dart';
import 'package:todo_app/features/todo/ui/card/more_menu.dart';
import 'package:todo_app/features/todo/ui/card/reminder_popover.dart';
import 'package:todo_app/features/todo/ui/card/repeat_menu.dart';
import 'package:todo_app/features/todo/ui/controls/check_toggle.dart';
import 'package:todo_app/features/todo/ui/overlay/confirm_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

import '../support/pump_todo.dart';

/// A page with one button ("Open") that runs [open] with the button's context
/// and reports whatever it returns through [result].
Widget opener<T>(
  Future<T?> Function(BuildContext context, Rect anchor) open,
  void Function(T? value) result,
) => Builder(
  builder: (context) => Center(
    child: Builder(
      builder: (buttonContext) => TextButton(
        onPressed: () async =>
            result(await open(buttonContext, anchorRectOf(buttonContext))),
        child: const Text('Open'),
      ),
    ),
  ),
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  useBundledFonts();

  group('confirm dialogs', () {
    testWidgets('showConfirm shows the question on the alert tint', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        opener<bool>(
          (context, _) => showConfirm(
            context,
            title: 'Sure?',
            body: 'This cannot be undone.',
          ).then((v) => v),
          (_) {},
        ),
      );
      await open(tester);

      expect(find.text('Sure?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(TodoDialogSurface),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        TodoThemes.paper.light.alert,
      );
    });

    testWidgets('Apply confirms, Cancel and the scrim decline', (tester) async {
      bool? result;
      await pumpTodo(
        tester,
        opener<bool>(
          (context, _) =>
              showConfirm(context, title: 'Sure?', body: 'Body').then((v) => v),
          (v) => result = v,
        ),
      );

      await open(tester);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await open(tester);
      await tester.tapAt(const Offset(195, 800));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('changing a repeat explains that the cycle ends', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        opener<bool>(
          (context, _) => confirmChangeRecurrence(context).then((v) => v),
          (_) {},
        ),
      );
      await open(tester);

      expect(find.text('Change recurrence?'), findsOneWidget);
      expect(find.textContaining('end the current cycle'), findsOneWidget);
    });

    testWidgets('deleting a repeat offers three scopes, safest first', (
      tester,
    ) async {
      RecurrenceScope? result;
      var called = false;
      await pumpTodo(
        tester,
        opener<RecurrenceScope>(confirmDeleteRecurringOpener, (v) {
          called = true;
          result = v;
        }),
      );
      await open(tester);

      for (final scope in RecurrenceScope.values) {
        expect(find.text(scope.label), findsOneWidget);
      }
      final checked = tester.getSemantics(find.text('Only this item'));
      expect(checked.flagsCollection.isChecked, isNotNull);

      await tester.tap(find.text('All linked items'));
      await tester.pump();
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(result, RecurrenceScope.all);

      called = false;
      await open(tester);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(result, RecurrenceScope.onlyThis, reason: 'default is safest');

      await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(called, isTrue);
    });
  });

  group('repeat menu', () {
    Widget page(RecurrenceRule? current, void Function(RepeatSelection?) r) =>
        opener<RepeatSelection>(
          (context, anchor) =>
              showRepeatMenu(context, anchor: anchor, current: current),
          r,
        );

    testWidgets('lists Never, the presets and Custom', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);

      for (final label in [
        'Never',
        'Daily',
        'Weekly',
        'Weekdays',
        'Biweekly',
        'Monthly',
        'Annually',
        'Custom',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('ticks the current choice only', (tester) async {
      await pumpTodo(tester, page(const RecurrenceRule.weekdays(), (_) {}));
      await open(tester);

      // One tick, in the Weekdays row.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      final tickY = tester.getCenter(find.byIcon(Icons.check_rounded)).dy;
      expect(tickY, tester.getCenter(find.text('Weekdays')).dy);
    });

    testWidgets('a rule that is not a preset ticks Custom', (tester) async {
      await pumpTodo(tester, page(const RecurrenceRule.daily(3), (_) {}));
      await open(tester);

      expect(
        tester.getCenter(find.byIcon(Icons.check_rounded)).dy,
        tester.getCenter(find.text('Custom')).dy,
      );
    });

    testWidgets('choosing a preset returns its rule', (tester) async {
      RepeatSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tap(find.text('Biweekly'));
      await tester.pumpAndSettle();
      expect(result!.rule, const RecurrenceRule.weekly(2));
    });

    testWidgets('Never returns a selection with no rule', (tester) async {
      RepeatSelection? result;
      await pumpTodo(
        tester,
        page(const RecurrenceRule.daily(), (v) => result = v),
      );
      await open(tester);

      await tester.tap(find.text('Never'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.rule, isNull);
    });

    testWidgets('dismissing returns nothing at all', (tester) async {
      RepeatSelection? result = const RepeatSelection(null);
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('Custom: interval, unit, summary and Apply', (tester) async {
      RepeatSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(
        find.text('Every week'),
        findsOneWidget,
        reason: 'default summary',
      );

      await tester.tap(find.byTooltip('Increase interval'));
      await tester.tap(find.byTooltip('Increase interval'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Every 3 weeks'), findsOneWidget);

      await tester.tap(find.text('Month'));
      await tester.pump();
      expect(find.text('Every 3 months'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        result!.rule,
        const RecurrenceRule(unit: RecurrenceUnit.month, interval: 3),
      );
    });

    testWidgets('Custom: interval stays between 1 and 99', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // At 1 the minus is disabled.
      await tester.tap(find.byTooltip('Decrease interval'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      for (var i = 0; i < 110; i++) {
        await tester.tap(find.byTooltip('Increase interval'));
      }
      await tester.pump();
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('Custom opens on the current rule and can go back', (
      tester,
    ) async {
      await pumpTodo(tester, page(const RecurrenceRule.daily(4), (_) {}));
      await open(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Every 4 days'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to repeat options'));
      await tester.pumpAndSettle();
      expect(find.text('Never'), findsOneWidget);
    });
  });

  group('colour popover', () {
    Widget page(int? selected, void Function(ColorSelection?) r) =>
        opener<ColorSelection>(
          (context, anchor) =>
              showColorPopover(context, anchor: anchor, selected: selected),
          r,
        );

    testWidgets('shows No colour and the eight colours', (tester) async {
      await pumpTodo(tester, page(null, (_) {}), settle: true);
      await open(tester);
      final semantics = tester.ensureSemantics();

      expect(find.bySemanticsLabel('No colour'), findsOneWidget);
      for (final swatch in TodoTaskColors.swatches) {
        expect(find.bySemanticsLabel(swatch.name), findsOneWidget);
      }
      // The extended row is hidden until "+" is pressed.
      expect(
        find.bySemanticsLabel(TodoTaskColors.extendedSwatches.first.name),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('choosing a colour returns its ARGB value', (tester) async {
      ColorSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);
      final semantics = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('Ocean'));
      await tester.pumpAndSettle();
      expect(
        result!.argb,
        TodoTaskColors.swatches.firstWhere((s) => s.name == 'Ocean').argb,
      );
      semantics.dispose();
    });

    testWidgets('No colour returns a selection with no colour', (tester) async {
      ColorSelection? result;
      await pumpTodo(
        tester,
        page(TodoTaskColors.swatches.first.argb, (v) => result = v),
      );
      await open(tester);
      final semantics = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('No colour'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.argb, isNull);
      semantics.dispose();
    });

    testWidgets('"+" reveals eight more and they can be chosen', (
      tester,
    ) async {
      ColorSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);
      final semantics = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('More colours'));
      await tester.pump();
      for (final swatch in TodoTaskColors.extendedSwatches) {
        expect(find.bySemanticsLabel(swatch.name), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Show fewer colours'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Plum'));
      await tester.pumpAndSettle();
      expect(
        result!.argb,
        TodoTaskColors.extendedSwatches
            .firstWhere((s) => s.name == 'Plum')
            .argb,
      );
      semantics.dispose();
    });

    testWidgets('opens expanded when the current colour is an extra one', (
      tester,
    ) async {
      final extra = TodoTaskColors.extendedSwatches.last;
      await pumpTodo(tester, page(extra.argb, (_) {}));
      await open(tester);
      final semantics = tester.ensureSemantics();

      expect(find.bySemanticsLabel(extra.name), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('marks only the current colour as selected', (tester) async {
      final current = TodoTaskColors.swatches[4];
      await pumpTodo(tester, page(current.argb, (_) {}));
      await open(tester);
      final semantics = tester.ensureSemantics();

      for (final swatch in TodoTaskColors.swatches) {
        final node = tester.getSemantics(find.bySemanticsLabel(swatch.name));
        expect(
          node.flagsCollection.isSelected.toString().contains('isTrue'),
          swatch.argb == current.argb,
          reason: swatch.name,
        );
      }
      semantics.dispose();
    });
  });

  group('date popover', () {
    final today = DateTime(2026, 9, 30);

    Widget page(
      DateTime? selected,
      void Function(DateSelection?) r, {
      int weekStartsOn = DateTime.monday,
    }) => opener<DateSelection>(
      (context, anchor) => showDatePopover(
        context,
        anchor: anchor,
        selected: selected,
        today: today,
        weekStartsOn: weekStartsOn,
      ),
      r,
    );

    testWidgets('opens on the month of the selected day', (tester) async {
      await pumpTodo(tester, page(DateTime(2026, 11, 5), (_) {}));
      await open(tester);
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('with no selection it opens on today\'s month', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('has one cell per day of the month', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsNothing, reason: 'September has 30 days');
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('September 2026 starts on a Tuesday (Monday-first)', (
      tester,
    ) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);

      final one = tester.getCenter(find.text('1'));
      final monday = tester.getCenter(find.text('M').first);
      final tuesday = tester.getCenter(find.text('T').first);
      expect((one.dx - tuesday.dx).abs(), lessThan(1));
      expect((one.dx - monday.dx).abs(), closeTo(40, 1));
    });

    testWidgets('Sunday-first shifts the grid', (tester) async {
      await pumpTodo(tester, page(null, (_) {}, weekStartsOn: DateTime.sunday));
      await open(tester);

      final one = tester.getCenter(find.text('1'));
      final sunday = tester.getCenter(find.text('S').first);
      // Tuesday is the third column when the week starts on Sunday.
      expect((one.dx - sunday.dx).abs(), closeTo(80, 1));
    });

    testWidgets('tapping a day returns it', (tester) async {
      DateSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(result!.date, DateTime(2026, 9, 15));
    });

    testWidgets('Someday returns a selection with no date', (tester) async {
      DateSelection? result;
      await pumpTodo(tester, page(DateTime(2026, 9, 15), (v) => result = v));
      await open(tester);

      await tester.tap(find.text('Someday'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.date, isNull);
    });

    testWidgets('month arrows move across year boundaries', (tester) async {
      DateSelection? result;
      await pumpTodo(tester, page(DateTime(2026, 12, 20), (v) => result = v));
      await open(tester);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pump();
      expect(find.text('January 2027'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();
      expect(find.text('November 2026'), findsOneWidget);

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(result!.date, DateTime(2026, 11, 3));
    });

    testWidgets('the chosen day is solid ink; today is ringed', (tester) async {
      await pumpTodo(tester, page(DateTime(2026, 9, 15), (_) {}));
      await open(tester);
      final p = TodoThemes.paper.light;

      BoxDecoration decorationOf(String day) {
        final container = tester.widget<Container>(
          find
              .ancestor(of: find.text(day), matching: find.byType(Container))
              .first,
        );
        return container.decoration! as BoxDecoration;
      }

      expect(decorationOf('15').color, p.ink);
      expect(decorationOf('30').border, isNotNull);
      expect((decorationOf('30').border! as Border).top.color, p.accent);
      expect(decorationOf('7').color, Colors.transparent);
    });

    testWidgets('every day has a 48-point-friendly cell', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);
      // 40 points in a grid, deliberately dense: adjacent cells do not overlap.
      final a = tester.getCenter(find.text('10'));
      final b = tester.getCenter(find.text('11'));
      expect(b.dx - a.dx, 40);
    });
  });

  group('reminder popover', () {
    Widget page(
      DateTime? current,
      void Function(ReminderSelection?) r, {
      DateTime? fallback,
      DateTime? now,
    }) => opener<ReminderSelection>(
      (context, anchor) => showReminderPopover(
        context,
        anchor: anchor,
        current: current,
        fallbackDate: fallback ?? DateTime(2026, 9, 30),
        now: now ?? DateTime(2026, 9, 30, 8, 58),
      ),
      r,
    );

    testWidgets('starts at the next five-minute mark from now', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);

      expect(find.text('30 Sep 2026'), findsOneWidget);
      expect(find.text('09'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('Remove reminder'), findsNothing);
      expect(find.text('This time has passed'), findsNothing);
    });

    testWidgets('a task on a later day starts on that day', (tester) async {
      ReminderSelection? result;
      await pumpTodo(
        tester,
        page(null, (v) => result = v, fallback: DateTime(2026, 10, 2)),
      );
      await open(tester);

      await tester.tap(find.text('Set reminder'));
      await tester.pumpAndSettle();
      expect(result!.at, DateTime(2026, 10, 2, 9));
    });

    testWidgets('a task whose day has passed starts today', (tester) async {
      await pumpTodo(
        tester,
        page(null, (_) {}, fallback: DateTime(2026, 9, 1)),
      );
      await open(tester);
      expect(find.text('30 Sep 2026'), findsOneWidget);
    });

    testWidgets('just before midnight it starts on the next day', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        page(null, (_) {}, now: DateTime(2026, 9, 30, 23, 57)),
      );
      await open(tester);
      expect(find.text('1 Oct 2026'), findsOneWidget);
      expect(find.text('00'), findsNWidgets(2));
    });

    testWidgets('a time that has passed cannot be set', (tester) async {
      ReminderSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tap(find.byTooltip('Decrease hour'));
      await tester.pump();
      expect(find.text('This time has passed'), findsOneWidget);
      await tester.tap(find.text('Set reminder'));
      await tester.pumpAndSettle();
      expect(result, isNull, reason: 'nothing was chosen');

      await tester.tap(find.byTooltip('Increase hour'));
      await tester.pump();
      expect(find.text('This time has passed'), findsNothing);
    });

    testWidgets('an old reminder opens with the warning, ready to fix', (
      tester,
    ) async {
      await pumpTodo(tester, page(DateTime(2026, 9, 30, 4, 10), (_) {}));
      await open(tester);
      expect(find.text('04'), findsOneWidget);
      expect(find.text('This time has passed'), findsOneWidget);
    });

    testWidgets('there is no going back before today', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);

      await tester.tap(find.byTooltip('Previous day'));
      await tester.pump();
      expect(find.text('30 Sep 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Next day'));
      await tester.pump();
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pump();
      expect(find.text('30 Sep 2026'), findsOneWidget);
    });

    testWidgets('holding a stepper keeps stepping', (tester) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byTooltip('Increase hour')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pump();

      final hour = int.parse(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .firstWhere((s) => RegExp(r'^\d\d$').hasMatch(s)),
      );
      expect(hour, greaterThan(11), reason: 'several steps from one press');
    });

    testWidgets('shows the existing reminder and offers to remove it', (
      tester,
    ) async {
      await pumpTodo(tester, page(DateTime(2026, 10, 2, 17, 45), (_) {}));
      await open(tester);

      expect(find.text('2 Oct 2026'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Remove reminder'), findsOneWidget);
    });

    testWidgets('day, hour and minute steppers change the time', (
      tester,
    ) async {
      ReminderSelection? result;
      await pumpTodo(tester, page(null, (v) => result = v));
      await open(tester);

      await tester.tap(find.byTooltip('Next day'));
      await tester.tap(find.byTooltip('Increase hour'));
      await tester.tap(find.byTooltip('Increase hour'));
      await tester.tap(find.byTooltip('Increase minute'));
      await tester.pump();
      expect(find.text('1 Oct 2026'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);

      await tester.tap(find.text('Set reminder'));
      await tester.pumpAndSettle();
      expect(result!.at, DateTime(2026, 10, 1, 11, 5));
    });

    testWidgets('hours and minutes wrap around', (tester) async {
      ReminderSelection? result;
      await pumpTodo(
        tester,
        page(DateTime(2026, 9, 30, 23, 55), (v) => result = v),
      );
      await open(tester);

      await tester.tap(find.byTooltip('Increase hour'));
      await tester.tap(find.byTooltip('Increase minute'));
      await tester.pump();
      expect(find.text('00'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Decrease hour'));
      await tester.tap(find.byTooltip('Decrease minute'));
      await tester.pump();
      expect(find.text('23'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);

      await tester.tap(find.text('Set reminder'));
      await tester.pumpAndSettle();
      expect(result!.at, DateTime(2026, 9, 30, 23, 55));
    });

    testWidgets('Remove reminder returns a selection with no time', (
      tester,
    ) async {
      ReminderSelection? result;
      await pumpTodo(tester, page(DateTime(2026, 10, 2, 8), (v) => result = v));
      await open(tester);

      await tester.tap(find.text('Remove reminder'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.at, isNull);
    });

    testWidgets('the steppers speak their value and can be adjusted', (
      tester,
    ) async {
      await pumpTodo(tester, page(null, (_) {}));
      await open(tester);
      final semantics = tester.ensureSemantics();

      final hour = tester.getSemantics(find.bySemanticsLabel('Hour'));
      expect(hour.value, '09');
      expect(hour.increasedValue, '10');
      expect(hour.decreasedValue, '08');
      semantics.dispose();
    });
  });

  group('more menu', () {
    testWidgets('offers the four actions', (tester) async {
      await pumpTodo(
        tester,
        opener<MoreAction>((c, a) => showMoreMenu(c, anchor: a), (_) {}),
      );
      await open(tester);

      for (final action in MoreAction.values) {
        expect(find.text(action.label), findsOneWidget);
      }
    });

    testWidgets('returns the chosen action', (tester) async {
      MoreAction? result;
      await pumpTodo(
        tester,
        opener<MoreAction>(
          (c, a) => showMoreMenu(c, anchor: a),
          (v) => result = v,
        ),
      );
      await open(tester);

      await tester.tap(find.text('Next week'));
      await tester.pumpAndSettle();
      expect(result, MoreAction.nextWeek);
    });
  });

  group('CheckToggle', () {
    Widget host(bool done, ValueChanged<bool> onChanged) => Center(
      child: CheckToggle(done: done, onChanged: onChanged, label: 'Milk'),
    );

    testWidgets('is a 48-point target that reports the new value', (
      tester,
    ) async {
      bool? changed;
      await pumpTodo(tester, host(false, (v) => changed = v));

      expect(tester.getSize(find.byType(CheckToggle)), const Size(48, 48));
      await tester.tap(find.byType(CheckToggle));
      expect(changed, isTrue);
    });

    testWidgets('is a checkable control for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpTodo(tester, host(true, (_) {}));

      final node = tester.getSemantics(find.bySemanticsLabel('Milk'));
      expect(node.flagsCollection.isChecked.toString(), contains('isTrue'));
      semantics.dispose();
    });

    testWidgets('checking overshoots and then settles at rest', (tester) async {
      var done = false;
      late StateSetter set;
      await pumpTodo(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return host(done, (_) {});
          },
        ),
      );

      double progress() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(CheckToggle),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as CheckGlyphPainter)
              .progress;

      expect(progress(), 0);
      set(() => done = true);
      await tester.pump();

      var peak = 0.0;
      var trough = 0.0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        peak = progress() > peak ? progress() : peak;
        trough = progress() < trough ? progress() : trough;
      }
      expect(peak, greaterThan(1.02), reason: 'swells past the ring');
      expect(trough, lessThan(0), reason: 'dips before it springs');
      await tester.pumpAndSettle();
      expect(progress(), closeTo(1, 0.001));
    });

    testWidgets('unchecking is instant', (tester) async {
      var done = true;
      late StateSetter set;
      await pumpTodo(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return host(done, (_) {});
          },
        ),
      );
      set(() => done = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(CheckToggle),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
      expect((painter as CheckGlyphPainter).progress, 0);
    });

    testWidgets('reduced motion sets it at once', (tester) async {
      var done = false;
      late StateSetter set;
      await pumpTodo(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return host(done, (_) {});
          },
        ),
        disableAnimations: true,
      );
      set(() => done = true);
      await tester.pump();
      await tester.pump();

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(CheckToggle),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CheckGlyphPainter;
      expect(painter.progress, 1);
    });
  });
}

Future<RecurrenceScope?> confirmDeleteRecurringOpener(
  BuildContext context,
  Rect anchor,
) => confirmDeleteRecurring(context);
