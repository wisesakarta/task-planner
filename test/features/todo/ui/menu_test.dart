import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/ui/controls/segmented_control.dart';
import 'package:todo_app/features/todo/ui/menu/menu_panel.dart';
import 'package:todo_app/features/todo/ui/menu/search_card.dart';

import '../support/pump_todo.dart';

class PanelHarness {
  final settings = ValueNotifier(const TodoSettings());
  final permission = ValueNotifier(ReminderPermission.granted);
  final changes = <TodoSettings>[];
  int settingsOpened = 0;

  Widget get widget => Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => showMenuPanel(
          context,
          settings: settings,
          reminderPermission: permission,
          onOpenSystemSettings: () => settingsOpened++,
          onChanged: (next) {
            changes.add(next);
            settings.value = next; // what the real controller does
          },
        ),
        child: const Text('Open'),
      ),
    ),
  );
}

Future<PanelHarness> openPanel(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  bool disableAnimations = false,
  TodoPalette? palette,
}) async {
  final h = PanelHarness();
  await pumpTodo(
    tester,
    h.widget,
    width: width,
    textScale: textScale,
    disableAnimations: disableAnimations,
    palette: palette,
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return h;
}

Future<void> go(WidgetTester tester, String tile) async {
  await tester.tap(find.text(tile));
  await tester.pumpAndSettle();
}

void main() {
  useBundledFonts();

  group('menu panel', () {
    testWidgets('opens on a home with four tiles', (tester) async {
      await openPanel(tester);

      for (final tile in ['Appearance', 'Calendar', 'Notifications', 'About']) {
        expect(find.text(tile), findsOneWidget);
      }
    });

    testWidgets('tiles are at least 84 tall and 48 wide targets', (
      tester,
    ) async {
      await openPanel(tester);
      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('Appearance'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(84));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('is a 24-radius sheet under the top bar at the right', (
      tester,
    ) async {
      await openPanel(tester);
      final panel = find
          .ancestor(
            of: find.text('Appearance'),
            matching: find.byType(DecoratedBox),
          )
          .last;
      final decoration =
          tester.widget<DecoratedBox>(panel).decoration as BoxDecoration;
      expect(decoration.color, TodoThemes.paper.light.sheet);
      expect(decoration.borderRadius, BorderRadius.circular(24));

      final rect = tester.getRect(panel);
      expect(rect.right, 390 - 12);
      expect(rect.top, greaterThan(48));
    });

    testWidgets('drops in 8 points while fading', (tester) async {
      final h = PanelHarness();
      await pumpTodo(tester, h.widget);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final start = tester.getTopLeft(find.text('Appearance')).dy;
      await tester.pumpAndSettle();
      final end = tester.getTopLeft(find.text('Appearance')).dy;
      expect(end - start, closeTo(8, 1.5));
    });

    testWidgets('tapping outside closes it', (tester) async {
      await openPanel(tester);
      await tester.tapAt(const Offset(10, 800));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsNothing);
    });

    testWidgets('a page has a back button and a header', (tester) async {
      await openPanel(tester);
      await go(tester, 'Calendar');

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('back transition does not composite the outgoing page', (
      tester,
    ) async {
      await openPanel(tester);
      await go(tester, 'Calendar');

      await tester.tap(find.byTooltip('Back'));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Week starts on'), findsNothing);
    });

    testWidgets('pages slide sideways by 24 while fading', (tester) async {
      await openPanel(tester);
      await tester.tap(find.text('Appearance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final segment = find.text('System');
      final startX = tester.getTopLeft(segment).dx;
      await tester.pumpAndSettle();
      final endX = tester.getTopLeft(segment).dx;
      expect(startX - endX, closeTo(24, 3));
    });

    testWidgets('reduced motion goes straight there', (tester) async {
      await openPanel(tester, disableAnimations: true);
      await tester.tap(find.text('Appearance'));
      await tester.pump();
      await tester.pump();
      expect(find.text('System'), findsOneWidget);
    });

    group('Appearance', () {
      testWidgets('switches light, dark and system', (tester) async {
        final h = await openPanel(tester);
        await go(tester, 'Appearance');

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(h.changes.last.themeMode, ThemeMode.dark);

        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();
        expect(h.changes.last.themeMode, ThemeMode.light);

        await tester.tap(find.text('System'));
        await tester.pumpAndSettle();
        expect(h.changes.last.themeMode, ThemeMode.system);
      });

      testWidgets('lists every theme and marks the current one', (
        tester,
      ) async {
        await openPanel(tester);
        await go(tester, 'Appearance');
        final semantics = tester.ensureSemantics();

        for (final family in TodoThemes.all) {
          expect(find.text(family.name), findsOneWidget);
        }
        final paper = tester.getSemantics(find.bySemanticsLabel('Paper'));
        expect(paper.flagsCollection.isSelected.toString(), contains('isTrue'));
        semantics.dispose();
      });

      testWidgets('choosing a theme reports it', (tester) async {
        final h = await openPanel(tester);
        await go(tester, 'Appearance');

        await tester.tap(find.text('Sage'));
        await tester.pumpAndSettle();
        expect(h.changes.last.themeId, 'sage');
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      });
    });

    group('Calendar', () {
      testWidgets('week start', (tester) async {
        final h = await openPanel(tester);
        await go(tester, 'Calendar');

        await tester.tap(find.text('Sunday'));
        await tester.pumpAndSettle();
        expect(h.changes.last.weekStartsOn, DateTime.sunday);
        await tester.tap(find.text('Monday'));
        await tester.pumpAndSettle();
        expect(h.changes.last.weekStartsOn, DateTime.monday);
      });

      for (final entry in {
        'Carry over unfinished': (TodoSettings s) => s.moveToNextDay,
        'Finished tasks last': (TodoSettings s) => s.sortCompletedDown,
        'Hide finished tasks': (TodoSettings s) => s.hideAfterComplete,
      }.entries) {
        testWidgets('${entry.key} toggles', (tester) async {
          final h = await openPanel(tester);
          await go(tester, 'Calendar');
          final before = entry.value(h.settings.value);

          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(entry.value(h.settings.value), !before);

          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(entry.value(h.settings.value), before);
        });
      }

      testWidgets('shows the live value when settings change elsewhere', (
        tester,
      ) async {
        final h = await openPanel(tester);
        await go(tester, 'Calendar');

        h.settings.value = h.settings.value.copyWith(hideAfterComplete: true);
        await tester.pump();
        final semantics = tester.ensureSemantics();
        final toggle = tester.getSemantics(
          find.bySemanticsLabel('Hide finished tasks').last,
        );
        expect(toggle.flagsCollection.isToggled.toString(), contains('isTrue'));
        semantics.dispose();
      });
    });

    testWidgets('the home is the four tiles and nothing else', (tester) async {
      await openPanel(tester);
      // No logo, name or blurb above them: every element does something.
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.textContaining('device'), findsNothing);
    });

    testWidgets('the Monday/Sunday control sits straight on the sheet', (
      tester,
    ) async {
      await openPanel(tester);
      await go(tester, 'Calendar');
      final control = find.byType(SegmentedControl<int>);
      expect(control, findsOneWidget);
      // Not inside a tinted, rounded group: that drew a second box around it.
      final tinted = find.ancestor(
        of: control,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color ==
                  TodoThemes.paper.light.ink5,
        ),
      );
      expect(tinted, findsNothing);
    });

    testWidgets('segments centre their icon and label', (tester) async {
      await openPanel(tester);
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      for (final label in ['System', 'Light', 'Dark']) {
        final segment = tester.getRect(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        expect(
          tester.getCenter(find.text(label)).dx,
          closeTo(segment.center.dx, 1),
          reason: label,
        );
      }
    });

    testWidgets(
      'a segmented control is a 12-radius track around 9-radius segments',
      (tester) async {
        await openPanel(tester);
        await go(tester, 'Calendar');
        final control = find.byType(SegmentedControl<int>);
        final track =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: control,
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(track.borderRadius, BorderRadius.circular(12));
      },
    );

    group('Notifications', () {
      testWidgets('has one toggle, on by default, that switches reminders', (
        tester,
      ) async {
        final h = await openPanel(tester);
        await go(tester, 'Notifications');

        expect(find.text('Reminders'), findsOneWidget);
        expect(h.settings.value.notificationsEnabled, isTrue);

        await tester.tap(find.text('Reminders'));
        await tester.pumpAndSettle();
        expect(h.settings.value.notificationsEnabled, isFalse);
        await tester.tap(find.text('Reminders'));
        await tester.pumpAndSettle();
        expect(h.settings.value.notificationsEnabled, isTrue);
      });

      testWidgets('says nothing while the system allows notifications', (
        tester,
      ) async {
        await openPanel(tester);
        await go(tester, 'Notifications');
        expect(
          find.textContaining('blocking notifications from this app'),
          findsNothing,
        );
      });

      testWidgets('says so when the system blocks them, and follows changes', (
        tester,
      ) async {
        final h = await openPanel(tester);
        await go(tester, 'Notifications');

        h.permission.value = ReminderPermission.denied;
        await tester.pump();
        expect(
          find.textContaining('blocking notifications from this app'),
          findsOneWidget,
        );

        h.permission.value = ReminderPermission.granted;
        await tester.pump();
        expect(
          find.textContaining('blocking notifications from this app'),
          findsNothing,
        );
      });

      testWidgets('the warning has a button that opens the phone settings', (
        tester,
      ) async {
        final h = await openPanel(tester);
        await go(tester, 'Notifications');
        h.permission.value = ReminderPermission.denied;
        await tester.pump();

        await tester.tap(find.text('Open phone settings'));
        expect(h.settingsOpened, 1);
      });

      testWidgets('the warning is not shown when reminders are off anyway', (
        tester,
      ) async {
        final h = await openPanel(tester);
        h.permission.value = ReminderPermission.denied;
        h.settings.value = h.settings.value.copyWith(
          notificationsEnabled: false,
        );
        await go(tester, 'Notifications');
        expect(
          find.textContaining('blocking notifications from this app'),
          findsNothing,
        );
      });

      testWidgets('fits 320 wide at 200% text', (tester) async {
        final h = await openPanel(tester, width: 320, textScale: 2);
        h.permission.value = ReminderPermission.denied;
        await go(tester, 'Notifications');
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('About says the data stays on the device', (tester) async {
      await openPanel(tester);
      await go(tester, 'About');
      expect(find.textContaining('saved on this device'), findsOneWidget);
    });

    for (final width in [320.0, 390.0, 900.0]) {
      testWidgets('every page fits at $width wide and 200% text', (
        tester,
      ) async {
        await openPanel(tester, width: width, textScale: 2);
        expect(tester.takeException(), isNull);
        for (final tile in ['Appearance', 'Calendar', 'About']) {
          await go(tester, tile);
          expect(tester.takeException(), isNull, reason: tile);
          await tester.tap(find.byTooltip('Back'));
          await tester.pumpAndSettle();
        }
      });
    }

    for (final entry in allPalettes.entries) {
      testWidgets('reads in ${entry.key}', (tester) async {
        await openPanel(tester, palette: entry.value);
        await go(tester, 'Calendar');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('search card', () {
    final today = DateTime(2026, 9, 30);
    final tasks = [
      TodoTask.create(
        id: '1',
        title: 'Buy oat milk',
        dueDate: DateTime(2026, 10, 2),
        color: TodoTaskColors.swatches[4].argb,
        now: today,
      ),
      TodoTask.create(
        id: '2',
        title: 'Call the bank',
        dueDate: today,
        now: today,
      ),
      TodoTask.create(
        id: '3',
        title: 'Plan trip',
        notes: 'Look at oat-free snacks',
        now: today,
      ),
      TodoTask.create(
        id: '4',
        title: 'Old milk chore',
        dueDate: DateTime(2026, 9, 1),
        now: today,
      ).copyWith(isDone: true),
    ];

    Future<List<TodoTask>> pumpSearch(WidgetTester tester) async {
      final opened = <TodoTask>[];
      await pumpTodo(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () =>
                  showSearchCard(context, tasks: tasks, onOpen: opened.add),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('starts with a hint, the field focused, and eight dots', (
      tester,
    ) async {
      await pumpSearch(tester);

      expect(find.text('Search'), findsOneWidget);
      expect(
        find.text('Find a task by its title, notes or checklist.'),
        findsOneWidget,
      );
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
      final semantics = tester.ensureSemantics();
      for (final swatch in TodoTaskColors.swatches) {
        expect(find.bySemanticsLabel('Only ${swatch.name}'), findsOneWidget);
      }
      semantics.dispose();
    });

    testWidgets('typing lists matches, open ones first', (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(EditableText), 'milk');
      await tester.pump();
      expect(find.text('Buy oat milk'), findsOneWidget);
      expect(find.text('Old milk chore'), findsOneWidget);
      expect(find.text('Call the bank'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Buy oat milk')).dy,
        lessThan(tester.getTopLeft(find.text('Old milk chore')).dy),
      );
      expect(find.text('Fri, 2 Oct 2026'), findsOneWidget);
    });

    testWidgets('finds words in notes', (tester) async {
      await pumpSearch(tester);
      await tester.enterText(find.byType(EditableText), 'snacks');
      await tester.pump();
      expect(find.text('Plan trip'), findsOneWidget);
      expect(find.text('Someday'), findsOneWidget);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await pumpSearch(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();
      expect(find.text('Nothing found.'), findsOneWidget);
    });

    testWidgets('a colour dot filters, and tapping it again clears it', (
      tester,
    ) async {
      await pumpSearch(tester);
      final semantics = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('Only Ocean'));
      await tester.pump();
      expect(find.text('Buy oat milk'), findsOneWidget);
      expect(find.text('Call the bank'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Only Ocean'));
      await tester.pump();
      expect(
        find.text('Find a task by its title, notes or checklist.'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('choosing a result closes the card and opens the task', (
      tester,
    ) async {
      final opened = await pumpSearch(tester);
      await tester.enterText(find.byType(EditableText), 'bank');
      await tester.pump();

      await tester.tap(find.text('Call the bank'));
      await tester.pumpAndSettle();
      expect(opened.single.id, '2');
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('sits on the paper colour', (tester) async {
      await pumpSearch(tester);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(Material).last,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        TodoThemes.paper.light.paper,
      );
    });
  });
}
