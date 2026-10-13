import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/ui/card/color_popover.dart';
import 'package:todo_app/features/todo/ui/card/date_popover.dart';
import 'package:todo_app/features/todo/ui/card/more_menu.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';
import 'package:todo_app/features/todo/ui/week/task_row.dart';

import '../support/pump_todo.dart';

/// A floating card (like the task card) with one button that opens [open].
Widget _card(Future<void> Function(BuildContext button, Rect anchor) open) =>
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showTodoDialog<void>(
            context,
            builder: (dialogContext) => Builder(
              builder: (button) => Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => open(button, anchorRectOf(button)),
                  child: const Text('Button'),
                ),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );

Future<void> _openCard(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Button'));
  await tester.pumpAndSettle();
}

Finder get _surface => find.byType(PopoverSurface);

void main() {
  useBundledFonts();

  group('a popover opened from a card becomes an attached panel', () {
    testWidgets('as wide as the card minus 12 each side, 8 under the button', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _card((button, anchor) => showMoreMenu(button, anchor: anchor)),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(TodoDialogSurface));
      final button = tester.getRect(find.text('Button'));
      await tester.tap(find.text('Button'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(_surface);
      expect(panel.left, card.left + 12);
      expect(panel.right, card.right - 12);
      expect(panel.top, greaterThan(button.bottom));
    });

    testWidgets('has no outline and is a shade darker than the card', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        _card((button, anchor) => showMoreMenu(button, anchor: anchor)),
      );
      await _openCard(tester);
      final p = TodoThemesPalette.paperLight;
      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: _surface,
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.border, isNull);
      expect(decoration.color, Color.alphaBlend(p.ink5, p.sheet));
    });

    testWidgets(
      'a fixed-width panel (calendar) is only as tall as its content',
      (tester) async {
        await pumpTodo(
          tester,
          _card(
            (button, anchor) => showDatePopover(
              button,
              anchor: anchor,
              selected: DateTime(2026, 9, 30),
              today: DateTime(2026, 9, 30),
            ),
          ),
        );
        await _openCard(tester);
        final panel = tester.getRect(_surface);
        expect(panel.height, lessThan(420));
        // The calendar itself stays centred in the wider panel.
        expect(
          tester.getCenter(find.text('September 2026')).dx,
          closeTo(panel.center.dx, 1),
        );
      },
    );

    testWidgets('outside a card it stays a small floating menu', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () =>
                  showMoreMenu(context, anchor: anchorRectOf(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getSize(_surface).width, 240);
    });
  });

  group('the "…" menu', () {
    testWidgets(
      'has no empty gutter: text starts 16 in, an icon ends each row',
      (tester) async {
        await pumpTodo(
          tester,
          _card((button, anchor) => showMoreMenu(button, anchor: anchor)),
        );
        await _openCard(tester);

        final panel = tester.getRect(_surface);
        expect(
          tester.getTopLeft(find.text('Tomorrow')).dx - panel.left,
          closeTo(16, 1),
        );
        for (final action in MoreAction.values) {
          expect(
            find.byIcon(action.icon),
            findsOneWidget,
            reason: action.label,
          );
          expect(
            panel.right - tester.getRect(find.byIcon(action.icon)).right,
            closeTo(12, 1),
            reason: action.label,
          );
        }
      },
    );

    testWidgets('picking an item returns it', (tester) async {
      MoreAction? picked;
      await pumpTodo(
        tester,
        _card((button, anchor) async {
          picked = await showMoreMenu(button, anchor: anchor);
        }),
      );
      await _openCard(tester);
      await tester.tap(find.text('Next week'));
      await tester.pumpAndSettle();
      expect(picked, MoreAction.nextWeek);
    });
  });

  group('the colour panel', () {
    testWidgets('is a grid of five dots to a row', (tester) async {
      await pumpTodo(
        tester,
        _card(
          (button, anchor) =>
              showColorPopover(button, anchor: anchor, selected: null),
        ),
      );
      await _openCard(tester);

      final dots = find.descendant(
        of: _surface,
        matching: find.byType(GestureDetector),
      );
      // "No colour", eight colours and the "+" fill two rows of five.
      expect(dots, findsNWidgets(10));
      final tops = {
        for (final e in dots.evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dy.round(),
      };
      expect(tops.length, 2);
    });

    testWidgets('picking none returns a null colour', (tester) async {
      ColorSelection? picked;
      await pumpTodo(
        tester,
        _card((button, anchor) async {
          picked = await showColorPopover(
            button,
            anchor: anchor,
            selected: 0xFFE53935,
          );
        }),
      );
      await _openCard(tester);
      await tester.tap(find.bySemanticsLabel('No colour'));
      await tester.pumpAndSettle();
      expect(picked?.argb, isNull);
      expect(picked, isNotNull);
    });
  });

  group('a task row', () {
    testWidgets(
      'puts its ring on the right margin, under the end of the rule',
      (tester) async {
        await pumpTodo(
          tester,
          TaskRow(
            title: 'Buy milk',
            isDone: false,
            onToggle: (_) {},
            onTap: () {},
          ),
        );
        final row = tester.getRect(find.byType(TaskRow));
        final ring = tester.getRect(find.byType(CustomPaint).last);
        expect(ring.right, closeTo(row.right, 1));
        // The touch target is still 48 wide.
        expect(
          tester
              .getSize(
                find
                    .descendant(
                      of: find.byType(TaskRow),
                      matching: find.byType(SizedBox),
                    )
                    .last,
              )
              .width,
          greaterThanOrEqualTo(48),
        );
      },
    );
  });
}

// Kept so the file reads without importing the whole theme barrel.
abstract final class TodoThemesPalette {
  static TodoPalette get paperLight => TodoThemes.paper.light;
}
