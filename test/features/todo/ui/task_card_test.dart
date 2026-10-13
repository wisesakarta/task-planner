import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/ui/card/task_card.dart';
import 'package:todo_app/features/todo/ui/controls/check_toggle.dart';

import '../support/pump_todo.dart';

final _today = DateTime(2026, 9, 30);

TodoTask _task({
  String title = 'Buy milk',
  String notes = '',
  DateTime? due,
  bool someday = false,
  RecurrenceRule? recurrence,
  DateTime? reminder,
  int? color,
  List<TodoSubtask> subtasks = const [],
  bool done = false,
}) => TodoTask.create(
  id: 't1',
  title: title,
  notes: notes,
  dueDate: someday ? null : (due ?? DateTime(2026, 10, 2)),
  recurrence: recurrence,
  reminderAt: reminder,
  color: color,
  subtasks: subtasks,
).copyWith(isDone: done);

/// Hosts a button that opens the card, and records everything it reports.
class CardHarness {
  CardHarness(this.task);

  TodoTask task;
  final changes = <TodoTask>[];
  final deletes = <(TodoTask, RecurrenceScope)>[];
  final duplicates = <TodoTask>[];
  int _ids = 0;

  Widget get widget => Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => showTaskCard(
          context,
          task: task,
          today: _today,
          // Early on the 30th, so 2 Oct reminders are ahead.
          clock: () => DateTime(2026, 9, 30, 8),
          onChanged: (t) {
            task = t;
            changes.add(t);
          },
          onDelete: (t, scope) => deletes.add((t, scope)),
          onDuplicate: duplicates.add,
        ),
        child: const Text('Open'),
      ),
    ),
  );

  String nextId() => 'id${_ids++}';
}

Future<CardHarness> pumpCard(
  WidgetTester tester,
  TodoTask task, {
  double width = 390,
  double textScale = 1,
}) async {
  final harness = CardHarness(task);
  await pumpTodo(tester, harness.widget, width: width, textScale: textScale);
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return harness;
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

/// Focuses the subtask called [title] and opens its options menu.
Future<void> openSubtaskMenu(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
  await tester.tap(find.byTooltip('Subtask options'));
  await tester.pumpAndSettle();
}

Future<void> tapAction(WidgetTester tester, String tooltipStart) async {
  await tester.tap(find.byTooltip(tooltipStart));
  await settle(tester);
}

void main() {
  useBundledFonts();

  group('layout', () {
    testWidgets('shows the day, title, notes hint and the five actions', (
      tester,
    ) async {
      await pumpCard(tester, _task());

      expect(find.text('Fri, 2 Oct'), findsOneWidget);
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Add some extra notes here…'), findsOneWidget);
      expect(find.text('Add subtask…'), findsOneWidget);
      for (final tip in [
        'Delete task',
        'Repeat',
        'Colour',
        'Reminder',
        'More',
      ]) {
        expect(find.byTooltip(tip), findsOneWidget, reason: tip);
      }
    });

    testWidgets('the day chip is never cut short on a phone', (tester) async {
      await pumpCard(tester, _task(), width: 360);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Fri, 2 Oct'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.getSize(find.text('Fri, 2 Oct')).width, greaterThan(55));
    });

    testWidgets('a Someday task says so', (tester) async {
      await pumpCard(tester, _task(someday: true));
      expect(find.text('Someday'), findsOneWidget);
    });

    testWidgets('existing notes and subtasks are shown', (tester) async {
      await pumpCard(
        tester,
        _task(
          notes: 'Semi-skimmed',
          subtasks: const [
            TodoSubtask(id: 'a', title: 'Oat milk'),
            TodoSubtask(
              id: 'b',
              title: 'Section',
              kind: TodoSubtaskKind.heading,
            ),
            TodoSubtask(id: 'c', title: 'Almond', level: 1, isDone: true),
          ],
        ),
      );

      expect(find.text('Semi-skimmed'), findsOneWidget);
      expect(find.text('Oat milk'), findsOneWidget);
      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Almond'), findsOneWidget);
    });

    testWidgets('a level-1 subtask is indented by 24', (tester) async {
      await pumpCard(
        tester,
        _task(
          subtasks: const [
            TodoSubtask(id: 'a', title: 'Top'),
            TodoSubtask(id: 'b', title: 'Nested', level: 1),
          ],
        ),
      );
      final top = tester.getTopLeft(find.text('Top')).dx;
      final nested = tester.getTopLeft(find.text('Nested')).dx;
      expect(nested - top, 24);
    });

    testWidgets('every action is a 48-point-tall target', (tester) async {
      await pumpCard(tester, _task());
      for (final tip in [
        'Delete task',
        'Repeat',
        'Colour',
        'Reminder',
        'More',
      ]) {
        expect(tester.getSize(find.byTooltip(tip)).height, 48, reason: tip);
      }
    });

    for (final width in [320.0, 360.0, 390.0, 900.0]) {
      testWidgets('fits without overflow at $width wide', (tester) async {
        await pumpCard(
          tester,
          _task(
            title: 'A rather long title that has to wrap onto more lines',
            recurrence: const RecurrenceRule.weekdays(),
            reminder: DateTime(2026, 10, 2, 9),
            color: TodoTaskColors.swatches.first.argb,
            subtasks: const [
              TodoSubtask(id: 'a', title: 'One'),
              TodoSubtask(id: 'b', title: 'Two', level: 1),
            ],
          ),
          width: width,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fits at 200% text size', (tester) async {
      await pumpCard(
        tester,
        _task(
          subtasks: const [TodoSubtask(id: 'a', title: 'One')],
        ),
        width: 360,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('actions in use turn solid ink', (tester) async {
      await pumpCard(
        tester,
        _task(
          recurrence: const RecurrenceRule.daily(),
          reminder: DateTime(2026, 10, 2, 9),
        ),
      );
      expect(find.byTooltip('Repeat: Every day'), findsOneWidget);
      expect(find.byTooltip('Reminder: 2 Oct, 09:00'), findsOneWidget);
    });
  });

  group('title, notes and done', () {
    testWidgets('typing in the title saves as you go', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.enterText(find.text('Buy milk'), 'Buy oat milk');
      expect(h.task.title, 'Buy oat milk');
    });

    testWidgets('a blank title is never saved', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.enterText(find.text('Buy milk'), '   ');
      expect(h.changes, isEmpty);
      expect(h.task.title, 'Buy milk');
    });

    testWidgets('typing notes saves as you go', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Add some extra notes here…',
        ),
        'Skimmed',
      );
      expect(h.task.notes, 'Skimmed');
    });

    testWidgets('the done toggle marks and unmarks the task', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.bySemanticsLabel('Mark as done').hitTestable());
      await settle(tester);
      expect(h.task.isDone, isTrue);
      expect(h.task.completedAt, isNotNull);

      await tester.tap(find.bySemanticsLabel('Mark as not done').hitTestable());
      await settle(tester);
      expect(h.task.isDone, isFalse);
      expect(h.task.completedAt, isNull);
    });
  });

  group('day', () {
    testWidgets('the chip opens the calendar and moves the task', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.text('Fri, 2 Oct'));
      await settle(tester);
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.text('20'));
      await settle(tester);
      expect(h.task.dueDate, DateTime(2026, 10, 20));
      expect(find.text('Tue, 20 Oct'), findsOneWidget);
    });

    testWidgets('Someday removes the day', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.text('Fri, 2 Oct'));
      await settle(tester);
      await tester.tap(find.text('Someday'));
      await settle(tester);
      expect(h.task.dueDate, isNull);
      expect(find.text('Someday'), findsOneWidget);
    });

    testWidgets('Someday on a repeating task asks first', (tester) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.daily()),
      );

      await tester.tap(find.text('Fri, 2 Oct'));
      await settle(tester);
      await tester.tap(find.text('Someday'));
      await settle(tester);
      expect(find.text('Change recurrence?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(h.task.dueDate, DateTime(2026, 10, 2));
      expect(h.task.repeats, isTrue);

      await tester.tap(find.text('Fri, 2 Oct'));
      await settle(tester);
      await tester.tap(find.text('Someday'));
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(h.task.dueDate, isNull);
      expect(h.task.repeats, isFalse);
    });

    testWidgets('choosing a popover away leaves the day alone', (tester) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.text('Fri, 2 Oct'));
      await settle(tester);
      await tester.tapAt(const Offset(5, 843));
      await settle(tester);
      expect(h.changes, isEmpty);
      expect(find.text('Buy milk'), findsOneWidget, reason: 'card stays open');
    });
  });

  group('repeat', () {
    testWidgets('setting a repeat on a plain task needs no question', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'Repeat');
      await tester.tap(find.text('Weekly'));
      await settle(tester);

      expect(h.task.recurrence, const RecurrenceRule.weekly());
      expect(find.text('Change recurrence?'), findsNothing);
      expect(find.byTooltip('Repeat: Every week'), findsOneWidget);
    });

    testWidgets('a Someday task lands on today when given a repeat', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task(someday: true));

      await tapAction(tester, 'Repeat');
      await tester.tap(find.text('Daily'));
      await settle(tester);

      expect(h.task.dueDate, _today);
      expect(h.task.recurrence, const RecurrenceRule.daily());
      expect(find.text('Wed, 30 Sep'), findsOneWidget);
    });

    testWidgets('changing an existing repeat asks, and Cancel keeps it', (
      tester,
    ) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.daily()),
      );

      await tapAction(tester, 'Repeat: Every day');
      await tester.tap(find.text('Monthly'));
      await settle(tester);
      expect(find.text('Change recurrence?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(h.task.recurrence, const RecurrenceRule.daily());
    });

    testWidgets('confirming applies the new repeat', (tester) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.daily()),
      );

      await tapAction(tester, 'Repeat: Every day');
      await tester.tap(find.text('Monthly'));
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(h.task.recurrence, const RecurrenceRule.monthly());
    });

    testWidgets('Never (after confirming) ends the repeat', (tester) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.daily()),
      );

      await tapAction(tester, 'Repeat: Every day');
      await tester.tap(find.text('Never'));
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);
      expect(h.task.recurrence, isNull);
    });

    testWidgets('picking the rule it already has changes nothing', (
      tester,
    ) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.daily()),
      );

      await tapAction(tester, 'Repeat: Every day');
      await tester.tap(find.text('Daily'));
      await settle(tester);
      expect(find.text('Change recurrence?'), findsNothing);
      expect(h.changes, isEmpty);
    });
  });

  group('colour', () {
    testWidgets('sets and clears the task colour', (tester) async {
      final h = await pumpCard(tester, _task());
      final semantics = tester.ensureSemantics();
      final ocean = TodoTaskColors.swatches.firstWhere(
        (s) => s.name == 'Ocean',
      );

      await tapAction(tester, 'Colour');
      await tester.tap(find.bySemanticsLabel('Ocean'));
      await settle(tester);
      expect(h.task.color, ocean.argb);
      expect(find.byTooltip('Colour: Ocean'), findsOneWidget);

      await tapAction(tester, 'Colour: Ocean');
      await tester.tap(find.bySemanticsLabel('No colour'));
      await settle(tester);
      expect(h.task.color, isNull);
      semantics.dispose();
    });
  });

  group('reminder', () {
    testWidgets('proposes the task\'s day at the next five-minute mark', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'Reminder');
      await tester.tap(find.text('Set reminder'));
      await settle(tester);
      expect(h.task.reminderAt, DateTime(2026, 10, 2, 8, 5));
    });

    testWidgets('a Someday task proposes today', (tester) async {
      await pumpCard(tester, _task(someday: true));

      await tapAction(tester, 'Reminder');
      expect(find.text('30 Sep 2026'), findsOneWidget);
    });

    testWidgets('can be removed', (tester) async {
      final h = await pumpCard(
        tester,
        _task(reminder: DateTime(2026, 10, 2, 9)),
      );

      await tapAction(tester, 'Reminder: 2 Oct, 09:00');
      await tester.tap(find.text('Remove reminder'));
      await settle(tester);
      expect(h.task.reminderAt, isNull);
    });
  });

  group('more', () {
    testWidgets('Tomorrow and Next week move the task', (tester) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'More');
      await tester.tap(find.text('Tomorrow'));
      await settle(tester);
      expect(h.task.dueDate, DateTime(2026, 10, 1));

      await tapAction(tester, 'More');
      await tester.tap(find.text('Next week'));
      await settle(tester);
      expect(h.task.dueDate, DateTime(2026, 10, 7));
    });

    testWidgets('Tomorrow keeps the edits made before it', (tester) async {
      // Tweek drops them (docs/tweek-study/09); we must not.
      final h = await pumpCard(tester, _task());
      await tester.enterText(find.byType(EditableText).first, 'Renamed');
      await tester.pump();

      await tapAction(tester, 'More');
      await tester.tap(find.text('Tomorrow'));
      await settle(tester);

      expect(h.task.dueDate, DateTime(2026, 10, 1));
      expect(h.task.title, 'Renamed');
    });

    testWidgets('Move to Someday clears the day', (tester) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'More');
      await tester.tap(find.text('Move to Someday'));
      await settle(tester);
      expect(h.task.dueDate, isNull);
    });

    testWidgets('Duplicate reports the task and closes the card', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'More');
      await tester.tap(find.text('Duplicate'));
      await settle(tester);
      expect(h.duplicates, hasLength(1));
      expect(h.duplicates.single.title, 'Buy milk');
      expect(find.text('Add subtask…'), findsNothing);
    });
  });

  group('delete', () {
    testWidgets('a plain task is deleted at once and the card closes', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tapAction(tester, 'Delete task');
      expect(h.deletes, hasLength(1));
      expect(h.deletes.single.$2, RecurrenceScope.onlyThis);
      expect(find.text('Add subtask…'), findsNothing);
    });

    testWidgets('a repeating task asks which items to delete', (tester) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.weekly()),
      );

      await tapAction(tester, 'Delete task');
      expect(find.text('Delete repeating task?'), findsOneWidget);
      expect(h.deletes, isEmpty);

      await tester.tap(find.text('This and all future items'));
      await tester.pump();
      await tester.tap(find.text('Ok'));
      await settle(tester);
      expect(h.deletes.single.$2, RecurrenceScope.thisAndFuture);
      expect(find.text('Add subtask…'), findsNothing);
    });

    testWidgets('cancelling keeps the task and the card', (tester) async {
      final h = await pumpCard(
        tester,
        _task(recurrence: const RecurrenceRule.weekly()),
      );

      await tapAction(tester, 'Delete task');
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(h.deletes, isEmpty);
      expect(find.text('Add subtask…'), findsOneWidget);
    });
  });

  group('subtasks', () {
    testWidgets('typing in "Add subtask…" and pressing Enter adds one', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.text('Add subtask…'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText).last, 'Oat milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(h.task.subtasks.map((s) => s.title), ['Oat milk']);
      expect(h.task.subtasks.single.isDone, isFalse);
      // The field is empty again and still focused, ready for the next one.
      final add = tester.widget<EditableText>(find.byType(EditableText).last);
      expect(add.controller.text, isEmpty);
      expect(add.focusNode.hasFocus, isTrue);
    });

    testWidgets('leaving the field with text in it still adds it', (
      tester,
    ) async {
      final h = await pumpCard(tester, _task());

      await tester.tap(find.text('Add subtask…'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText).last, 'Bread');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);

      expect(h.task.subtasks.map((s) => s.title), ['Bread']);
    });

    testWidgets('checking a subtask marks it done', (tester) async {
      final h = await pumpCard(
        tester,
        _task(
          subtasks: const [TodoSubtask(id: 'a', title: 'Oat milk')],
        ),
      );

      await tester.tap(find.byType(CheckToggle).last);
      await settle(tester);
      expect(h.task.subtasks.single.isDone, isTrue);
      expect(h.task.completedSubtasks, 1);
    });

    testWidgets('Enter in a subtask adds the next one below it, focused', (
      tester,
    ) async {
      final h = await pumpCard(
        tester,
        _task(
          subtasks: const [
            TodoSubtask(id: 'a', title: 'First'),
            TodoSubtask(id: 'b', title: 'Third'),
          ],
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);

      expect(h.task.subtasks, hasLength(3));
      expect(h.task.subtasks[0].title, 'First');
      expect(h.task.subtasks[1].title, '');
      expect(h.task.subtasks[2].title, 'Third');

      await tester.enterText(find.byType(EditableText).at(3), 'Second');
      expect(h.task.subtasks[1].title, 'Second');
    });

    testWidgets('an emptied subtask is removed when you leave it', (
      tester,
    ) async {
      final h = await pumpCard(
        tester,
        _task(
          subtasks: const [TodoSubtask(id: 'a', title: 'Oat milk')],
        ),
      );

      await tester.tap(find.text('Oat milk'));
      await tester.pump();
      await tester.enterText(find.text('Oat milk'), '');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);

      expect(h.task.subtasks, isEmpty);
    });

    testWidgets('its options button opens a menu: indent, heading, delete', (
      tester,
    ) async {
      final h = await pumpCard(
        tester,
        _task(
          subtasks: const [TodoSubtask(id: 'a', title: 'Oat milk')],
        ),
      );

      await openSubtaskMenu(tester, 'Oat milk');
      expect(find.text('Indent'), findsOneWidget);
      expect(find.text('Outdent'), findsNothing);
      expect(find.text('Make it a heading'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Indent'));
      await settle(tester);
      expect(h.task.subtasks.single.level, 1);

      await openSubtaskMenu(tester, 'Oat milk');
      expect(find.text('Outdent'), findsOneWidget);
      await tester.tap(find.text('Make it a heading'));
      await settle(tester);
      expect(h.task.subtasks.single.isHeading, isTrue);
      expect(
        h.task.subtasks.single.level,
        0,
        reason: 'a heading is never indented',
      );

      await openSubtaskMenu(tester, 'Oat milk');
      expect(find.text('Make it a task'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      expect(h.task.subtasks, isEmpty);
    });

    testWidgets('a heading has no check', (tester) async {
      await pumpCard(
        tester,
        _task(
          subtasks: const [
            TodoSubtask(
              id: 'a',
              title: 'Aisle 1',
              kind: TodoSubtaskKind.heading,
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Aisle 1'), findsNothing);
    });
  });
}
