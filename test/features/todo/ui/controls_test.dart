import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/controls/segmented_control.dart';
import 'package:todo_app/features/todo/ui/controls/todo_toggle.dart';

import '../support/pump_todo.dart';

Color over(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

/// The circle drawn by a [RoundButton].
BoxDecoration circleOf(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.shape == BoxShape.circle);

/// The colour the button's icon is drawn in (inherited through IconTheme).
Color? iconColorOf(WidgetTester tester) => tester
    .widget<IconTheme>(
      find
          .descendant(
            of: find.byType(RoundButton),
            matching: find.byType(IconTheme),
          )
          .first,
    )
    .data
    .color;

void main() {
  useBundledFonts();

  group('RoundButton', () {
    Widget button({
      VoidCallback? onPressed,
      RoundButtonVariant variant = RoundButtonVariant.ink,
      double size = 40,
      Widget? child,
    }) => Center(
      child: RoundButton(
        icon: child == null ? Icons.chevron_right_rounded : null,
        label: 'Next week',
        onPressed: onPressed,
        variant: variant,
        size: size,
        child: child,
      ),
    );

    testWidgets('tapping calls back', (tester) async {
      var taps = 0;
      await pumpTodo(tester, button(onPressed: () => taps++));
      await tester.tap(find.byType(RoundButton));
      expect(taps, 1);
    });

    testWidgets('disabled does nothing and says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, button());
      await tester.tap(find.byType(RoundButton));
      expect(
        tester.getSemantics(find.byType(RoundButton)),
        matchesSemantics(
          label: 'Next week',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('the circle is 40 (or 32) inside a 48 target', (tester) async {
      await pumpTodo(tester, button(onPressed: () {}));
      final target = tester.getSize(find.byType(RoundButton));
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(40, 40),
      );

      await pumpTodo(tester, button(onPressed: () {}, size: 32));
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(32, 32),
      );
      expect(tester.getSize(find.byType(RoundButton)).width, 48);
    });

    testWidgets('has a tooltip', (tester) async {
      await pumpTodo(tester, button(onPressed: () {}));
      expect(find.byTooltip('Next week'), findsOneWidget);
    });

    testWidgets('each variant draws the documented fill and icon', (
      tester,
    ) async {
      final p = TodoThemes.paper.light;
      Future<void> check(
        RoundButtonVariant variant,
        Color fill,
        Color icon,
      ) async {
        await pumpTodo(tester, button(onPressed: () {}, variant: variant));
        expect(circleOf(tester).color, fill);
        expect(iconColorOf(tester), icon);
      }

      await check(RoundButtonVariant.ink, p.ink, p.paper);
      await check(RoundButtonVariant.soft, p.ink5, p.ink);
      await check(RoundButtonVariant.accent, p.accent, p.onAccent);
    });

    for (final entry in allPalettes.entries) {
      testWidgets('icons are readable on every variant in ${entry.key}', (
        tester,
      ) async {
        final p = entry.value;
        expect(contrastRatio(p.paper, p.ink), greaterThanOrEqualTo(7));
        expect(
          contrastRatio(p.ink, over(p.ink5, p.paper)),
          greaterThanOrEqualTo(7),
        );
        expect(contrastRatio(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
        await pumpTodo(tester, button(onPressed: () {}), palette: p);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pressing shifts the fill in 100 ms and back', (tester) async {
      final p = TodoThemes.paper.light;
      await pumpTodo(tester, button(onPressed: () {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(RoundButton)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(circleOf(tester).color, p.ink75);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 120));
      expect(circleOf(tester).color, p.ink);
    });

    testWidgets('can hold an initial instead of an icon', (tester) async {
      await pumpTodo(
        tester,
        button(
          onPressed: () {},
          variant: RoundButtonVariant.accent,
          child: const Text('K'),
        ),
      );
      expect(find.text('K'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('PillButton', () {
    Widget pill({
      VoidCallback? onPressed,
      PillVariant variant = PillVariant.primary,
      bool expand = true,
      bool destructive = false,
      String label = 'Apply',
    }) => Center(
      child: PillButton(
        label: label,
        onPressed: onPressed,
        variant: variant,
        expand: expand,
        destructive: destructive,
      ),
    );

    testWidgets('tapping calls back', (tester) async {
      var taps = 0;
      await pumpTodo(tester, pill(onPressed: () => taps++));
      await tester.tap(find.text('Apply'));
      expect(taps, 1);
    });

    testWidgets('is at least 40 tall and fills the width by default', (
      tester,
    ) async {
      await pumpTodo(tester, pill(onPressed: () {}));
      final size = tester.getSize(find.byType(PillButton));
      expect(size.height, greaterThanOrEqualTo(40));
      expect(size.width, 390);
    });

    testWidgets('can wrap its label instead', (tester) async {
      await pumpTodo(tester, pill(onPressed: () {}, expand: false));
      expect(tester.getSize(find.byType(PillButton)).width, lessThan(200));
    });

    testWidgets('each variant draws its own face', (tester) async {
      final p = TodoThemes.paper.light;
      BoxDecoration face() =>
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;
      Color? text() => tester.widget<Text>(find.text('Apply')).style!.color;

      await pumpTodo(tester, pill(onPressed: () {}));
      expect(face().color, p.ink);
      expect(text(), p.paper);

      await pumpTodo(
        tester,
        pill(onPressed: () {}, variant: PillVariant.outlined),
      );
      expect(face().color, Colors.transparent);
      expect((face().border! as Border).top.color, p.ink);
      expect((face().border! as Border).top.width, 0.67);
      expect(text(), p.ink);

      await pumpTodo(tester, pill(onPressed: () {}, variant: PillVariant.soft));
      expect(face().color, p.ink5);
      expect(text(), p.ink);
    });

    testWidgets('destructive draws the label in danger', (tester) async {
      await pumpTodo(
        tester,
        pill(onPressed: () {}, variant: PillVariant.soft, destructive: true),
      );
      expect(
        tester.widget<Text>(find.text('Apply')).style!.color,
        TodoThemes.paper.light.danger,
      );
    });

    for (final entry in allPalettes.entries) {
      testWidgets('every variant is readable in ${entry.key}', (tester) async {
        final p = entry.value;
        // primary: paper on ink; outlined and soft: ink on paper / ink5.
        expect(contrastRatio(p.paper, p.ink), greaterThanOrEqualTo(7));
        expect(contrastRatio(p.ink, p.paper), greaterThanOrEqualTo(7));
        expect(
          contrastRatio(p.ink, over(p.ink5, p.paper)),
          greaterThanOrEqualTo(7),
        );
        expect(
          contrastRatio(p.danger, over(p.ink5, p.paper)),
          greaterThanOrEqualTo(4.5),
        );
        await pumpTodo(tester, pill(onPressed: () {}), palette: p);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('disabled is announced and inert', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, pill());
      expect(
        tester.getSemantics(find.byType(PillButton)),
        matchesSemantics(
          label: 'Apply',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a long label wraps at 200% text', (tester) async {
      await pumpTodo(
        tester,
        pill(
          onPressed: () {},
          label: 'Apply these changes to every future occurrence',
        ),
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pressing shifts the fill', (tester) async {
      await pumpTodo(tester, pill(onPressed: () {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PillButton)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration!
                as BoxDecoration)
            .color,
        TodoThemes.paper.light.ink75,
      );
      await gesture.up();
    });
  });

  group('TodoToggle', () {
    Widget toggle(bool value, ValueChanged<bool>? onChanged) => Center(
      child: TodoToggle(value: value, onChanged: onChanged, label: 'Hide'),
    );

    testWidgets('tapping reports the opposite value', (tester) async {
      final changes = <bool>[];
      await pumpTodo(tester, toggle(false, changes.add));
      await tester.tap(find.byType(TodoToggle));
      expect(changes, [true]);

      await pumpTodo(tester, toggle(true, changes.add));
      await tester.tap(find.byType(TodoToggle));
      expect(changes, [true, false]);
    });

    testWidgets('is a 40 by 24 track in a 48 target', (tester) async {
      await pumpTodo(tester, toggle(false, (_) {}));
      expect(tester.getSize(find.byType(TodoToggle)), const Size(48, 48));
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(40, 24),
      );
    });

    testWidgets('the knob sits left when off and right when on', (
      tester,
    ) async {
      double knobDx() {
        final knob = find
            .descendant(
              of: find.byType(AnimatedContainer),
              matching: find.byType(Container),
            )
            .last;
        return tester.getCenter(knob).dx -
            tester.getCenter(find.byType(AnimatedContainer)).dx;
      }

      await pumpTodo(tester, toggle(false, (_) {}));
      expect(knobDx(), lessThan(0));
      await pumpTodo(tester, toggle(true, (_) {}));
      expect(knobDx(), greaterThan(0));
    });

    testWidgets('track is ink 90% on and ink 50% off', (tester) async {
      final p = TodoThemes.paper.light;
      Color? track() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color;

      await pumpTodo(tester, toggle(true, (_) {}));
      expect(track(), p.ink90);
      await pumpTodo(tester, toggle(false, (_) {}));
      expect(track(), p.ink50);
    });

    for (final entry in allPalettes.entries) {
      test('both tracks are visible against the paper in ${entry.key}', () {
        final p = entry.value;
        expect(
          contrastRatio(over(p.ink50, p.paper), p.paper),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrastRatio(over(p.ink90, p.paper), p.paper),
          greaterThanOrEqualTo(3),
        );
      });
    }

    testWidgets('is announced as a toggle with its state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, toggle(true, (_) {}));
      expect(
        tester.getSemantics(find.byType(TodoToggle)),
        matchesSemantics(
          label: 'Hide',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled ignores taps', (tester) async {
      await pumpTodo(tester, toggle(false, null));
      await tester.tap(find.byType(TodoToggle));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion moves the knob in one frame', (tester) async {
      double knobDx() {
        final knob = find
            .descendant(
              of: find.byType(AnimatedContainer),
              matching: find.byType(Container),
            )
            .last;
        return tester.getCenter(knob).dx -
            tester.getCenter(find.byType(AnimatedContainer)).dx;
      }

      await pumpTodo(tester, toggle(false, (_) {}), disableAnimations: true);
      await pumpTodo(
        tester,
        toggle(true, (_) {}),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      expect(knobDx(), greaterThan(0));
    });
  });

  group('SegmentedControl', () {
    const options = [
      SegmentedOption(value: 'system', label: 'System', icon: Icons.contrast),
      SegmentedOption(value: 'light', label: 'Light', icon: Icons.light_mode),
      SegmentedOption(value: 'dark', label: 'Dark', icon: Icons.dark_mode),
    ];

    Widget control(String value, ValueChanged<String> onChanged) => Center(
      child: SegmentedControl<String>(
        options: options,
        value: value,
        onChanged: onChanged,
      ),
    );

    testWidgets('choosing another segment reports it', (tester) async {
      final chosen = <String>[];
      await pumpTodo(tester, control('light', chosen.add));
      await tester.tap(find.text('Dark'));
      expect(chosen, ['dark']);
    });

    testWidgets('choosing the current segment does nothing', (tester) async {
      final chosen = <String>[];
      await pumpTodo(tester, control('light', chosen.add));
      await tester.tap(find.text('Light'));
      expect(chosen, isEmpty);
    });

    testWidgets('the strip is ink and the chosen segment is the sheet', (
      tester,
    ) async {
      final p = TodoThemes.paper.light;
      await pumpTodo(tester, control('light', (_) {}));

      final strip = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == p.ink);
      expect(strip.borderRadius, BorderRadius.circular(12));

      Color? fillOf(String label) =>
          (tester
                      .widget<AnimatedContainer>(
                        find.ancestor(
                          of: find.text(label),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(fillOf('Light'), p.sheet);
      expect(fillOf('Dark'), Colors.transparent);
      expect(tester.widget<Text>(find.text('Light')).style!.color, p.ink);
      expect(tester.widget<Text>(find.text('Dark')).style!.color, p.paper);
    });

    for (final entry in allPalettes.entries) {
      test('both segment states are readable in ${entry.key}', () {
        final p = entry.value;
        expect(contrastRatio(p.ink, p.sheet), greaterThanOrEqualTo(7));
        expect(contrastRatio(p.paper, p.ink), greaterThanOrEqualTo(7));
      });
    }

    testWidgets('each segment is a labelled, selectable button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTodo(tester, control('light', (_) {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Light')),
        matchesSemantics(
          label: 'Light',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Dark')),
        matchesSemantics(
          label: 'Dark',
          isButton: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('works without icons and at 200% text', (tester) async {
      await pumpTodo(
        tester,
        Center(
          child: SegmentedControl<int>(
            options: const [
              SegmentedOption(value: 3, label: '3'),
              SegmentedOption(value: 6, label: '6'),
            ],
            value: 3,
            onChanged: (_) {},
          ),
        ),
        textScale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('segments are at least 38 tall', (tester) async {
      await pumpTodo(tester, control('light', (_) {}));
      final size = tester.getSize(
        find.ancestor(
          of: find.text('Light'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(size.height, greaterThanOrEqualTo(38));
    });
  });

  group('concentric corners', () {
    testWidgets('a segment is the strip radius minus its 3-point inset', (
      tester,
    ) async {
      await pumpTodo(
        tester,
        SegmentedControl<int>(
          options: const [
            SegmentedOption(value: 1, label: 'One'),
            SegmentedOption(value: 2, label: 'Two'),
          ],
          value: 1,
          onChanged: (_) {},
        ),
      );
      double radius(Finder f) =>
          ((tester.widget<DecoratedBox>(f).decoration as BoxDecoration)
                  .borderRadius!
                  .resolve(TextDirection.ltr))
              .topLeft
              .x;
      final decorated = find.descendant(
        of: find.byType(SegmentedControl<int>),
        matching: find.byType(DecoratedBox),
      );
      final outer = radius(decorated.first);
      final segment = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(SegmentedControl<int>),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .first;
      final inner =
          ((segment.decoration! as BoxDecoration).borderRadius!.resolve(
            TextDirection.ltr,
          )).topLeft.x;
      expect(outer, 12);
      expect(inner + 3, outer);
    });
  });
}
