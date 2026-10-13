import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

import '../support/pump_todo.dart';

Widget dialogOpener({
  Color? color,
  bool dismissible = true,
  double contentHeight = 120,
  void Function(Object?)? onResult,
}) => Builder(
  builder: (context) => Center(
    child: TextButton(
      onPressed: () async {
        final result = await showTodoDialog<String>(
          context,
          color: color,
          barrierDismissible: dismissible,
          builder: (dialogContext) => SizedBox(
            height: contentHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Card body'),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop('done'),
                  child: const Text('Close card'),
                ),
              ],
            ),
          ),
        );
        onResult?.call(result);
      },
      child: const Text('Open'),
    ),
  ),
);

Finder get _card => find.byType(TodoDialogSurface);

void main() {
  useBundledFonts();

  group('showTodoDialog', () {
    testWidgets('is a card 12 from the sides and 64 from the top', (
      tester,
    ) async {
      await pumpTodo(tester, dialogOpener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final rect = tester.getRect(_card);
      expect(rect.left, 12);
      expect(rect.right, 390 - 12);
      expect(rect.top, 64);
    });

    testWidgets('is at most 512 wide on a tablet', (tester) async {
      await pumpTodo(tester, dialogOpener(), width: 1000, height: 800);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.getSize(_card).width, 512);
      expect(tester.getCenter(_card).dx, 500);
    });

    testWidgets('has a 24 radius, 24 padding and the sheet colour', (
      tester,
    ) async {
      await pumpTodo(tester, dialogOpener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final box = tester.widget<DecoratedBox>(
        find.descendant(of: _card, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, TodoThemes.paper.light.sheet);
      expect(decoration.borderRadius, BorderRadius.circular(24));

      final cardTop = tester.getTopLeft(_card);
      final bodyTop = tester.getTopLeft(find.text('Card body'));
      expect(bodyTop.dx - cardTop.dx, 24);
      expect(bodyTop.dy - cardTop.dy, closeTo(24, 6));
    });

    testWidgets('a different colour can be given (alert)', (tester) async {
      final alert = TodoThemes.paper.light.alert;
      await pumpTodo(tester, dialogOpener(color: alert));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final box = tester.widget<DecoratedBox>(
        find.descendant(of: _card, matching: find.byType(DecoratedBox)).first,
      );
      expect((box.decoration as BoxDecoration).color, alert);
    });

    testWidgets('rises 40 points while fading in over 200 ms', (tester) async {
      await pumpTodo(tester, dialogOpener());
      await tester.tap(find.text('Open'));
      await tester.pump(); // route pushed
      await tester.pump(const Duration(milliseconds: 1));

      final start = tester.getTopLeft(_card).dy;
      expect(start, closeTo(64 + 40, 2));

      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getTopLeft(_card).dy;
      expect(mid, greaterThan(64));
      expect(mid, lessThan(start));

      double opacity() => tester
          .widgetList<FadeTransition>(
            find.ancestor(of: _card, matching: find.byType(FadeTransition)),
          )
          .map((f) => f.opacity.value)
          .reduce((a, b) => a < b ? a : b);
      expect(opacity(), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_card).dy, 64);
      expect(opacity(), 1);
    });

    testWidgets('reduced motion shows it at rest at once', (tester) async {
      await pumpTodo(tester, dialogOpener(), disableAnimations: true);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      expect(tester.getTopLeft(_card).dy, 64);
    });

    testWidgets('dims the page behind it with the 40% scrim', (tester) async {
      await pumpTodo(tester, dialogOpener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, TodoThemes.paper.light.scrim);
    });

    testWidgets('tapping outside dismisses it with no result', (tester) async {
      Object? result = 'unset';
      await pumpTodo(tester, dialogOpener(onResult: (r) => result = r));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(195, 780));
      await tester.pumpAndSettle();

      expect(_card, findsNothing);
      expect(result, isNull);
    });

    testWidgets('can refuse to be dismissed by tapping outside', (
      tester,
    ) async {
      await pumpTodo(tester, dialogOpener(dismissible: false));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(195, 780));
      await tester.pumpAndSettle();

      expect(_card, findsOneWidget);
    });

    testWidgets('hands a value back when closed from inside', (tester) async {
      Object? result;
      await pumpTodo(tester, dialogOpener(onResult: (r) => result = r));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close card'));
      await tester.pumpAndSettle();

      expect(result, 'done');
      expect(_card, findsNothing);
    });

    testWidgets('content taller than the screen scrolls, no overflow', (
      tester,
    ) async {
      await pumpTodo(tester, dialogOpener(contentHeight: 2000), height: 500);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
      );
    });

    testWidgets('stays clear of an open keyboard', (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      addTearDown(tester.view.resetViewInsets);
      await pumpTodo(tester, dialogOpener(contentHeight: 300), height: 800);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The card scrolls inside the room left above the keyboard.
      expect(
        tester.getRect(find.byType(SingleChildScrollView).last).bottom,
        lessThanOrEqualTo(800 - 400),
      );
    });

    for (final entry in allPalettes.entries) {
      testWidgets('body text is readable in ${entry.key}', (tester) async {
        await pumpTodo(tester, dialogOpener(), palette: entry.value);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('showTodoPopover', () {
    Widget popoverOpener({
      Alignment alignment = Alignment.center,
      void Function(Object?)? onResult,
      double width = 200,
    }) => Align(
      alignment: alignment,
      child: Builder(
        builder: (buttonContext) => TextButton(
          onPressed: () async {
            final result = await showTodoPopover<String>(
              buttonContext,
              anchor: anchorRectOf(buttonContext),
              builder: (context) => PopoverSurface(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopoverMenuItem(
                      label: 'Never',
                      reserveCheck: true,
                      selected: true,
                      onTap: () => Navigator.of(context).pop('never'),
                    ),
                    const PopoverDivider(),
                    PopoverMenuItem(
                      label: 'Daily',
                      onTap: () => Navigator.of(context).pop('daily'),
                    ),
                    PopoverMenuItem(
                      label: 'Custom',
                      chevron: true,
                      onTap: () => Navigator.of(context).pop('custom'),
                    ),
                  ],
                ),
              ),
            );
            onResult?.call(result);
          },
          child: const Text('Anchor'),
        ),
      ),
    );

    final surface = find.byType(PopoverSurface);

    testWidgets('hangs 12 below its anchor, centred on it', (tester) async {
      await pumpTodo(tester, popoverOpener());
      final anchor = tester.getRect(find.text('Anchor'));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      final rect = tester.getRect(surface);
      expect(
        rect.top,
        closeTo(tester.getRect(find.byType(TextButton)).bottom + 12, 1),
      );
      expect(rect.center.dx, closeTo(anchor.center.dx, 1));
    });

    testWidgets('stays 12 inside the screen at the left edge', (tester) async {
      await pumpTodo(tester, popoverOpener(alignment: Alignment.topLeft));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      expect(tester.getRect(surface).left, 12);
    });

    testWidgets('stays 12 inside the screen at the right edge', (tester) async {
      await pumpTodo(tester, popoverOpener(alignment: Alignment.topRight));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      expect(tester.getRect(surface).right, 390 - 12);
    });

    testWidgets('flips above the anchor when there is no room below', (
      tester,
    ) async {
      await pumpTodo(tester, popoverOpener(alignment: Alignment.bottomCenter));
      final anchor = tester.getRect(find.byType(TextButton));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      expect(tester.getRect(surface).bottom, closeTo(anchor.top - 12, 1));
    });

    testWidgets('is a shade darker than the sheet, radius 16, no outline', (
      tester,
    ) async {
      final p = TodoThemes.paper.light;
      await pumpTodo(tester, popoverOpener());
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: surface,
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      // A shade darker than the card it opens from, so no outline is needed.
      expect(decoration.color, Color.alphaBlend(p.ink5, p.sheet));
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.border, isNull);
    });

    testWidgets('fades in over 200 ms', (tester) async {
      await pumpTodo(tester, popoverOpener());
      await tester.tap(find.text('Anchor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final opacity = tester
          .widgetList<FadeTransition>(
            find.ancestor(of: surface, matching: find.byType(FadeTransition)),
          )
          .map((f) => f.opacity.value)
          .reduce((a, b) => a < b ? a : b);
      expect(opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('choosing an item returns its value and closes', (
      tester,
    ) async {
      Object? result;
      await pumpTodo(tester, popoverOpener(onResult: (r) => result = r));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(result, 'daily');
      expect(surface, findsNothing);
    });

    testWidgets('tapping outside closes it with no value', (tester) async {
      Object? result = 'unset';
      await pumpTodo(tester, popoverOpener(onResult: (r) => result = r));
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(surface, findsNothing);
      expect(result, isNull);
    });

    testWidgets('closing a popover leaves the card under it open', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showTodoDialog<void>(
                context,
                builder: (dialogContext) => Builder(
                  builder: (buttonContext) => TextButton(
                    onPressed: () => showTodoPopover<void>(
                      buttonContext,
                      anchor: anchorRectOf(buttonContext),
                      builder: (_) =>
                          const PopoverSurface(width: 160, child: Text('Menu')),
                    ),
                    child: const Text('Repeat'),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget);

      await tester.tapAt(const Offset(195, 838));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsNothing);
      expect(find.text('Repeat'), findsOneWidget);
      expect(_card, findsOneWidget);
    });

    testWidgets('the current choice shows a check and is selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, popoverOpener());
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Never')),
        matchesSemantics(
          label: 'Never',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('items are 36 tall; a chevron marks a sub-page', (
      tester,
    ) async {
      await pumpTodo(tester, popoverOpener());
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      final item = find.ancestor(
        of: find.text('Daily'),
        matching: find.byType(ConstrainedBox),
      );
      expect(tester.getSize(item.first).height, greaterThanOrEqualTo(36));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('the divider is a 1 point ink 15% line', (tester) async {
      await pumpTodo(tester, popoverOpener());
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      final line = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(PopoverDivider),
              matching: find.byType(ColoredBox),
            ),
          )
          .first;
      expect(line.color, TodoThemes.paper.light.ink15);
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(PopoverDivider),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .height,
        1,
      );
    });

    for (final entry in allPalettes.entries) {
      testWidgets('renders in ${entry.key}', (tester) async {
        await pumpTodo(tester, popoverOpener(), palette: entry.value);
        await tester.tap(find.text('Anchor'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives 200% text on the narrowest phone', (tester) async {
      await pumpTodo(
        tester,
        popoverOpener(width: 240),
        textScale: 2,
        width: 320,
      );
      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
