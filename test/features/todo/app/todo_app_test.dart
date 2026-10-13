import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/app/todo_app.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';
import 'package:todo_app/features/todo/ui/card/task_card.dart';
import 'package:todo_app/features/todo/ui/month/month_screen.dart';
import 'package:todo_app/features/todo/ui/week/day_header.dart';

import '../support/fakes.dart';
import '../support/pump_todo.dart';

final _now = DateTime(2026, 9, 30, 10); // a Wednesday
final _today = DateTime(2026, 9, 30);

TodoTask _task(
  String title, {
  DateTime? due,
  bool someday = false,
  RecurrenceRule? recurrence,
  bool done = false,
}) => TodoTask.create(
  id: 'id-$title',
  title: title,
  dueDate: someday ? null : (due ?? _today),
  recurrence: recurrence,
  now: _now,
).copyWith(isDone: done);

class App {
  App(List<TodoTask> tasks, {TodoSettings settings = const TodoSettings()})
    : repo = FakeTodoRepository(tasks),
      store = FakeSettingsStore(settings);

  final FakeTodoRepository repo;
  final FakeSettingsStore store;
  final reminders = FakeReminderService();
  late TodoController controller;
  int _ids = 0;

  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    bool semantics = false,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    controller = TodoController(
      repository: repo,
      settingsStore: store,
      reminders: reminders,
      clock: () => _now,
      newId: () => 'gen${_ids++}',
      saveDelay: const Duration(milliseconds: 50),
    );
    await controller.load();
    await tester.pumpWidget(TodoApp(controller: controller));
    await tester.pumpAndSettle();
  }
}

/// The toggle of the task called [title].
Finder toggleOf(String title) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.label == title &&
      w.properties.checked != null,
);

Finder composerFor(String day) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == 'Add a task on $day',
  ),
  matching: find.byType(EditableText),
);

/// The first text field inside the open task card (the title).
final cardField = find
    .descendant(of: find.byType(TaskCard), matching: find.byType(EditableText))
    .first;

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

void main() {
  useBundledFonts();

  group('the week', () {
    testWidgets('shows the month, seven days and the saved tasks', (
      tester,
    ) async {
      final app = App([
        _task('Buy milk'),
        _task('Book dentist', due: DateTime(2026, 10, 2)),
        _task('Read a book', someday: true),
      ]);
      await app.pump(tester);

      expect(find.text('Oct 2026'), findsOneWidget);
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Book dentist'), findsOneWidget);
      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(day), findsOneWidget, reason: day);
      }
      await tester.scrollUntilVisible(
        find.text('Read a book'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Someday'), findsOneWidget);
      expect(find.text('Read a book'), findsOneWidget);
    });

    testWidgets('next and previous week change what is shown', (tester) async {
      final app = App([
        _task('This week'),
        _task('Next week task', due: DateTime(2026, 10, 7)),
      ]);
      await app.pump(tester);

      await tester.tap(find.byTooltip('Next week'));
      await settle(tester);
      expect(find.text('Next week task'), findsOneWidget);
      expect(find.text('This week'), findsNothing);

      await tester.tap(find.byTooltip('Previous week'));
      await settle(tester);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('tapping the title returns to the current week', (
      tester,
    ) async {
      final app = App([_task('This week')]);
      await app.pump(tester);

      await tester.tap(find.byTooltip('Next week'));
      await tester.tap(find.byTooltip('Next week'));
      await settle(tester);
      expect(find.text('This week'), findsNothing);

      await tester.tap(find.text('Oct 2026').first);
      await settle(tester);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('the first day of the week follows the setting', (
      tester,
    ) async {
      final app = App(
        [],
        settings: const TodoSettings(weekStartsOn: DateTime.sunday),
      );
      await app.pump(tester);

      final sun = tester.getTopLeft(find.text('Sun')).dy;
      final mon = tester.getTopLeft(find.text('Mon')).dy;
      expect(sun, lessThan(mon));
    });

    testWidgets('hides finished tasks when asked, and sorts them down', (
      tester,
    ) async {
      final app = App([
        _task('Finished', done: true),
        _task('Open'),
      ], settings: const TodoSettings(sortCompletedDown: true));
      await app.pump(tester);
      expect(
        tester.getTopLeft(find.text('Open')).dy,
        lessThan(tester.getTopLeft(find.text('Finished')).dy),
      );

      await app.controller.updateSettings(
        app.controller.settings.copyWith(hideAfterComplete: true),
      );
      await settle(tester);
      expect(find.text('Finished'), findsNothing);
    });
  });

  group('adding', () {
    testWidgets('type on a day, press Enter, and it is saved', (tester) async {
      final app = App([]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      await tester.tap(composerFor('Wednesday, 30 September'));
      await tester.pump();
      await tester.enterText(
        composerFor('Wednesday, 30 September'),
        'Buy milk',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(find.text('Buy milk'), findsOneWidget);
      expect(app.repo.stored['gen0']!.title, 'Buy milk');
      expect(app.repo.stored['gen0']!.dueDate, _today);
      semantics.dispose();
    });

    testWidgets('the field stays ready for the next task', (tester) async {
      final app = App([]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      await tester.tap(composerFor('Friday, 2 October'));
      await tester.pump();
      for (final title in ['One', 'Two', 'Three']) {
        await tester.enterText(composerFor('Friday, 2 October'), title);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      expect(app.controller.tasks.map((t) => t.title), ['One', 'Two', 'Three']);
      expect(
        tester
            .widget<EditableText>(composerFor('Friday, 2 October'))
            .focusNode
            .hasFocus,
        isTrue,
      );
      semantics.dispose();
    });

    testWidgets('Someday has its own composer', (tester) async {
      final app = App([]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      final field = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Add a Someday task',
        ),
        matching: find.byType(EditableText),
      );
      await tester.scrollUntilVisible(
        field,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'Learn to juggle');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(app.repo.stored['gen0']!.dueDate, isNull);
      semantics.dispose();
    });

    testWidgets('a failed save keeps the text and shows a notice', (
      tester,
    ) async {
      final app = App([]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);
      app.repo.failWrites = true;

      await tester.tap(composerFor('Wednesday, 30 September'));
      await tester.pump();
      await tester.enterText(composerFor('Wednesday, 30 September'), 'Milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(composerFor('Wednesday, 30 September'))
            .controller
            .text,
        'Milk',
        reason: 'what was typed is not lost',
      );

      await tester.tap(find.text('Dismiss'));
      await settle(tester);
      expect(find.textContaining('Could not save'), findsNothing);
      semantics.dispose();
    });
  });

  group('completing', () {
    testWidgets('tapping the ring completes and persists', (tester) async {
      final app = App([_task('Buy milk')]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      await tester.tap(toggleOf('Buy milk'));
      await settle(tester);
      expect(app.repo.stored['id-Buy milk']!.isDone, isTrue);

      await tester.tap(toggleOf('Buy milk'));
      await settle(tester);
      expect(app.repo.stored['id-Buy milk']!.isDone, isFalse);
      semantics.dispose();
    });

    testWidgets('a repeating task gets its next occurrence on the next day', (
      tester,
    ) async {
      final app = App([
        _task('Water plants', recurrence: const RecurrenceRule.daily()),
      ]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      await tester.tap(toggleOf('Water plants'));
      await settle(tester);

      expect(find.text('Water plants'), findsNWidgets(2));
      expect(app.repo.stored['gen0']!.dueDate, DateTime(2026, 10, 1));
      semantics.dispose();
    });
  });

  group('the task card', () {
    testWidgets('tapping a task opens it', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);

      await tester.tap(find.text('Buy milk'));
      await settle(tester);
      expect(find.text('Add subtask…'), findsOneWidget);
      expect(find.text('Wed, 30 Sep'), findsOneWidget);
    });

    testWidgets('edits appear on the week and are saved', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);

      await tester.tap(find.text('Buy milk'));
      await settle(tester);
      await tester.enterText(cardField, 'Buy oat milk');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(app.repo.stored['id-Buy milk']!.title, 'Buy oat milk');

      await tester.tapAt(const Offset(195, 830));
      await settle(tester);
      expect(find.text('Buy oat milk'), findsOneWidget);
    });

    testWidgets('colour and repeat show up on the row', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);

      await tester.tap(find.byTooltip('Repeat'));
      await settle(tester);
      await tester.tap(find.text('Daily'));
      await settle(tester);
      expect(app.controller.tasks.single.repeats, isTrue);

      await tester.tapAt(const Offset(195, 830));
      await settle(tester);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });

    testWidgets('deleting removes it from the week', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);

      await tester.tap(find.byTooltip('Delete task'));
      await settle(tester);
      expect(find.text('Buy milk'), findsNothing);
      expect(app.repo.stored['id-Buy milk']!.isDeleted, isTrue);
    });

    testWidgets('duplicating adds a second one', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Duplicate'));
      await settle(tester);
      expect(find.text('Buy milk'), findsNWidgets(2));
    });

    testWidgets('moving to Someday moves the row down the page', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);

      await tester.tap(find.text('Buy milk'));
      await settle(tester);
      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Move to Someday'));
      await settle(tester);
      await tester.tapAt(const Offset(195, 830));
      await settle(tester);

      expect(app.controller.tasks.single.isSomeday, isTrue);
      await tester.scrollUntilVisible(
        find.text('Buy milk'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.getTopLeft(find.text('Buy milk')).dy,
        greaterThan(tester.getTopLeft(find.text('Someday')).dy),
        reason: 'the task now sits under the Someday heading',
      );
    });

    testWidgets('closing the card writes staged edits at once', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);

      await tester.enterText(cardField, 'Renamed');
      await tester.tapAt(const Offset(195, 830));
      await settle(tester);
      expect(app.repo.stored['id-Buy milk']!.title, 'Renamed');
    });
  });

  group('month view', () {
    testWidgets('the title opens it; tapping a day opens that week', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);

      await tester.tap(find.text('Oct 2026'));
      await settle(tester);
      expect(find.byType(MonthScreen), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Buy milk'), findsOneWidget, reason: 'as a pill');

      await tester.tap(find.byTooltip('Next month'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('Monday, 5 October')));
      await settle(tester);

      expect(find.byType(MonthScreen), findsNothing);
      expect(find.text('5 Oct'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('back returns to the week instead of leaving', (tester) async {
      final app = App([]);
      await app.pump(tester);

      await tester.tap(find.text('Oct 2026'));
      await settle(tester);
      expect(find.byType(MonthScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(MonthScreen), findsNothing);
      expect(find.text('30 Sep'), findsOneWidget);
    });

    group('which day is on the top row', () {
      double headerTop(WidgetTester tester, String date) => tester
          .getTopLeft(
            find.ancestor(
              of: find.text(date),
              matching: find.byType(DayHeader),
            ),
          )
          .dy;
      double topRow(WidgetTester tester) =>
          tester.getTopLeft(find.byType(Scrollable).first).dy + TodoSize.margin;

      testWidgets('today, when the app opens', (tester) async {
        await App([]).pump(tester);
        expect(headerTop(tester, '30 Sep'), topRow(tester));
      });

      testWidgets('the day picked in the month', (tester) async {
        final semantics = tester.ensureSemantics();
        await App([]).pump(tester);

        await tester.tap(find.text('Oct 2026'));
        await settle(tester);
        await tester.tap(find.byTooltip('Next month'));
        await settle(tester);
        await tester.tap(find.bySemanticsLabel(RegExp('Thursday, 15 October')));
        await settle(tester);

        expect(headerTop(tester, '15 Oct'), topRow(tester));
        semantics.dispose();
      });

      testWidgets('where it was, after Back from the month', (tester) async {
        await App([]).pump(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 100));
        await settle(tester);
        final scrolled = headerTop(tester, '30 Sep');
        expect(scrolled, greaterThan(topRow(tester)));

        await tester.tap(find.text('Oct 2026'));
        await settle(tester);
        await tester.binding.handlePopRoute();
        await settle(tester);

        expect(headerTop(tester, '30 Sep'), scrolled);
      });

      testWidgets('today again, after a trip to another week', (tester) async {
        await App([]).pump(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 100));
        await settle(tester);

        await tester.tap(find.byTooltip('Next week'));
        await settle(tester);
        expect(headerTop(tester, '5 Oct'), topRow(tester));
        await tester.tap(find.byTooltip('Previous week'));
        await settle(tester);

        expect(headerTop(tester, '30 Sep'), topRow(tester));
      });
    });

    testWidgets('a task opens from the month', (tester) async {
      final app = App([_task('Buy milk', due: DateTime(2026, 9, 2))]);
      await app.pump(tester);

      await tester.tap(find.text('Oct 2026'));
      await settle(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);
      expect(find.byType(TaskCard), findsOneWidget);
    });

    testWidgets('the month follows the week-start setting', (tester) async {
      final app = App(
        [],
        settings: const TodoSettings(weekStartsOn: DateTime.sunday),
      );
      await app.pump(tester);
      await tester.tap(find.textContaining('2026'));
      await settle(tester);
      // Sunday first: the letters begin with S.
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
      expect(letters.map((t) => t.data).join(), 'SMTWTFS');
    });
  });

  group('the title', () {
    testWidgets('turns to the accent on another week and returns home', (
      tester,
    ) async {
      final app = App([_task('This week')]);
      await app.pump(tester);
      final p = TodoThemes.paper.light;
      Color? titleColor() =>
          tester.widget<Text>(find.textContaining('2026').first).style!.color;

      expect(titleColor(), p.ink);

      await tester.tap(find.byTooltip('Next week'));
      await settle(tester);
      await tester.tap(find.byTooltip('Next week'));
      await settle(tester);
      expect(find.text('This week'), findsNothing);
      expect(titleColor(), p.accentInk);

      await tester.tap(find.textContaining('2026').first);
      await settle(tester);
      expect(find.text('This week'), findsOneWidget);
      expect(titleColor(), p.ink);
      expect(find.byType(MonthScreen), findsNothing);
    });
  });

  group('reminders', () {
    testWidgets('a tapped notification opens that task', (tester) async {
      final app = App([_task('Buy milk'), _task('Call bank')]);
      await app.pump(tester);
      expect(find.byType(TaskCard), findsNothing);

      app.reminders.emit(
        const ReminderSignal(ReminderSignalKind.open, 'id-Call bank'),
      );
      await settle(tester);
      expect(find.byType(TaskCard), findsOneWidget);
      expect(
        tester.widget<EditableText>(cardField).controller.text,
        'Call bank',
      );
      expect(app.controller.openRequest.value, isNull, reason: 'consumed');
    });

    testWidgets('a notification that launched the app opens its task', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      app.reminders.launchTaskId = 'id-Buy milk';
      await app.pump(tester);
      expect(find.byType(TaskCard), findsOneWidget);
    });

    testWidgets('a request for a task that is gone does nothing', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      app.reminders.emit(const ReminderSignal(ReminderSignalKind.open, 'nope'));
      await settle(tester);
      expect(find.byType(TaskCard), findsNothing);
    });

    testWidgets('setting a reminder in the card schedules a notification', (
      tester,
    ) async {
      final app = App([_task('Buy milk', due: DateTime(2026, 10, 2))]);
      await app.pump(tester);
      await tester.tap(find.text('Buy milk'));
      await settle(tester);

      await tester.tap(find.byTooltip('Reminder'));
      await settle(tester);
      await tester.tap(find.text('Set reminder'));
      await settle(tester);
      await tester.tapAt(const Offset(195, 830));
      await settle(tester);

      expect(app.reminders.pending.keys, ['id-Buy milk']);
      expect(app.reminders.pending['id-Buy milk']!.title, 'Buy milk');
    });

    testWidgets('the Notifications page switches them off and on', (
      tester,
    ) async {
      final reminder = _now.add(const Duration(days: 2));
      final app = App([_task('Buy milk').copyWith(reminderAt: reminder)]);
      await app.pump(tester);
      expect(app.reminders.pending, isNotEmpty);

      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      await tester.tap(find.text('Notifications'));
      await settle(tester);
      await tester.tap(find.text('Reminders'));
      await settle(tester);

      expect(app.store.settings.notificationsEnabled, isFalse);
      expect(app.reminders.pending, isEmpty);

      await tester.tap(find.text('Reminders'));
      await settle(tester);
      expect(app.reminders.pending, isNotEmpty);
    });
  });

  group('moving tasks', () {
    Future<void> carry(WidgetTester tester, String title, Offset to) async {
      final from = tester.getCenter(find.text(title));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 200));
      for (var i = 1; i <= 6; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('carrying a task to another day changes its day and saves', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester, height: 1600);

      await carry(tester, 'Buy milk', tester.getCenter(find.text('Fri')));
      await app.controller.flush();

      final saved = app.repo.stored['id-Buy milk']!;
      expect(saved.dueDate, DateTime(2026, 10, 2));
      expect(saved.title, 'Buy milk');
    });

    testWidgets('reordering within a day is kept after a restart', (
      tester,
    ) async {
      final first = _task('First').copyWith(sortKey: 1);
      final second = _task('Second').copyWith(sortKey: 2);
      final app = App([first, second]);
      await app.pump(tester, height: 1600);

      await carry(
        tester,
        'Second',
        tester.getCenter(find.text('First')) + const Offset(0, -15),
      );
      await app.controller.flush();

      final reloaded = TodoController(
        repository: app.repo,
        settingsStore: app.store,
        clock: () => _now,
      );
      await reloaded.load();
      final today = sortedByOrder(
        reloaded.tasks.where((t) => t.dueDate == _today),
      );
      expect([for (final t in today) t.title], ['Second', 'First']);
    });

    testWidgets('a repeating task dropped on Someday asks first', (
      tester,
    ) async {
      final app = App([
        _task('Water plants', recurrence: const RecurrenceRule.daily()),
        _task('Read a book', someday: true),
      ]);
      await app.pump(tester, height: 1600);

      final someday = tester.getCenter(find.text('Read a book'));
      await carry(tester, 'Water plants', someday);
      expect(find.text('Change recurrence?'), findsOneWidget);
      expect(app.repo.stored['id-Water plants']!.dueDate, _today);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.repo.stored['id-Water plants']!.dueDate, _today);
      expect(app.repo.stored['id-Water plants']!.repeats, isTrue);

      await carry(tester, 'Water plants', someday);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(app.repo.stored['id-Water plants']!.dueDate, isNull);
      expect(app.repo.stored['id-Water plants']!.repeats, isFalse);
    });

    testWidgets('a plain task dropped on Someday just moves', (tester) async {
      final app = App([_task('Buy milk'), _task('Read a book', someday: true)]);
      await app.pump(tester, height: 1600);

      await carry(
        tester,
        'Buy milk',
        tester.getCenter(find.text('Read a book')),
      );
      expect(find.text('Change recurrence?'), findsNothing);
      expect(app.repo.stored['id-Buy milk']!.dueDate, isNull);
    });
  });

  group('search', () {
    testWidgets('finds a task and opens it', (tester) async {
      final app = App([
        _task('Buy milk'),
        _task('Book dentist', due: DateTime(2026, 11, 20)),
      ]);
      await app.pump(tester);

      await tester.tap(find.byTooltip('Search'));
      await settle(tester);
      await tester.enterText(find.byType(EditableText).last, 'dentist');
      await tester.pump();
      await tester.tap(find.text('Book dentist'));
      await settle(tester);

      expect(find.text('Add subtask…'), findsOneWidget);
      expect(find.text('Fri, 20 Nov'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('choosing Dark re-themes the app at once and is saved', (
      tester,
    ) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      Color paper() => Theme.of(
        tester.element(find.byType(Scaffold)),
      ).scaffoldBackgroundColor;
      expect(paper(), TodoThemes.paper.light.paper);

      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      await tester.tap(find.text('Appearance'));
      await settle(tester);
      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(paper(), TodoThemes.paper.dark.paper);
      expect(app.store.settings.themeMode, ThemeMode.dark);
    });

    testWidgets('choosing another theme applies its palette', (tester) async {
      final app = App([]);
      await app.pump(tester);
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      await tester.tap(find.text('Appearance'));
      await settle(tester);

      await tester.tap(find.text('Blush'));
      await tester.pump();
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.scaffoldBackgroundColor, TodoThemes.blush.light.paper);
    });

    testWidgets('a saved dark theme is used from the first frame', (
      tester,
    ) async {
      final app = App(
        [],
        settings: const TodoSettings(
          themeMode: ThemeMode.dark,
          themeId: 'sage',
        ),
      );
      await app.pump(tester);
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.scaffoldBackgroundColor, TodoThemes.sage.dark.paper);
    });

    testWidgets('turning on "Hide finished tasks" hides them', (tester) async {
      final app = App([_task('Finished', done: true), _task('Open')]);
      await app.pump(tester);

      await tester.tap(find.byTooltip('Menu'));
      await settle(tester);
      await tester.tap(find.text('Calendar'));
      await settle(tester);
      await tester.tap(find.text('Hide finished tasks'));
      await settle(tester);
      await tester.tapAt(const Offset(10, 800));
      await settle(tester);

      expect(find.text('Finished'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('going to the background writes staged edits', (tester) async {
      final app = App([_task('Buy milk')]);
      await app.pump(tester);
      // A long delay so only the lifecycle change can have written it.
      app.controller = TodoController(
        repository: app.repo,
        settingsStore: app.store,
        clock: () => _now,
        saveDelay: const Duration(hours: 1),
      );
      await app.controller.load();
      await tester.pumpWidget(TodoApp(controller: app.controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy milk'));
      await settle(tester);
      await tester.enterText(cardField, 'Edited');
      await tester.pump();
      expect(app.repo.stored['id-Buy milk']!.title, 'Buy milk');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(app.repo.stored['id-Buy milk']!.title, 'Edited');
    });

    testWidgets('data survives a restart', (tester) async {
      final app = App([]);
      final semantics = tester.ensureSemantics();
      await app.pump(tester);
      await tester.tap(composerFor('Thursday, 1 October'));
      await tester.pump();
      await tester.enterText(composerFor('Thursday, 1 October'), 'Remember me');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      await tester.pumpWidget(const SizedBox());
      await app.pump(tester); // a fresh controller over the same storage
      expect(find.text('Remember me'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('layout', () {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1200, 800),
    ]) {
      testWidgets(
        'fits a ${size.width.toInt()}×${size.height.toInt()} screen',
        (tester) async {
          final app = App([
            _task(
              'A rather long task title that will need to be cut short here',
            ),
            _task('Short', recurrence: const RecurrenceRule.daily()),
            _task('Later', due: DateTime(2026, 10, 3)),
          ]);
          await app.pump(tester, width: size.width, height: size.height);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
