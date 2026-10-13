import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/theme/todo_motion.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

import '../support/pump_todo.dart';

/// A translucent [foreground] drawn over an opaque [background].
Color over(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

void main() {
  useBundledFonts();

  group('contrast (WCAG 2)', () {
    for (final entry in allPalettes.entries) {
      final p = entry.value;
      final surfaces = {'paper': p.paper, 'sheet': p.sheet, 'alert': p.alert};

      group(entry.key, () {
        test('ink reads on every surface', () {
          for (final s in surfaces.entries) {
            expect(
              contrastRatio(p.ink, s.value),
              greaterThanOrEqualTo(7),
              reason: s.key,
            );
          }
        });

        test('secondary text (ink 65%) meets AA on every surface', () {
          for (final s in surfaces.entries) {
            expect(
              contrastRatio(over(p.textSecondary, s.value), s.value),
              greaterThanOrEqualTo(4.5),
              reason: s.key,
            );
          }
        });

        test('a completed task (ink at 50%) stays legible (≥ 3:1)', () {
          final done = over(p.ink.withValues(alpha: 0.5), p.paper);
          expect(contrastRatio(done, p.paper), greaterThanOrEqualTo(3));
        });

        test('accent text reads on every surface', () {
          for (final s in surfaces.entries) {
            expect(
              contrastRatio(p.accentInk, s.value),
              greaterThanOrEqualTo(4.5),
              reason: s.key,
            );
          }
        });

        test('the accent is visible as a graphic on the paper', () {
          expect(contrastRatio(p.accent, p.paper), greaterThanOrEqualTo(3));
        });

        test('content on the accent is readable', () {
          expect(
            contrastRatio(p.onAccent, p.accent),
            greaterThanOrEqualTo(4.5),
          );
        });

        test('the danger colour reads on every surface', () {
          for (final s in surfaces.entries) {
            expect(
              contrastRatio(p.danger, s.value),
              greaterThanOrEqualTo(4.5),
              reason: s.key,
            );
          }
        });

        test('the ruled line is visible but quiet', () {
          final line = over(p.rule, p.paper);
          final ratio = contrastRatio(line, p.paper);
          expect(ratio, greaterThan(1.1));
          expect(ratio, lessThan(2));
        });

        test('the floating surfaces differ from the paper', () {
          expect(p.sheet, isNot(p.paper));
          expect(p.alert, isNot(p.paper));
        });
      });
    }
  });

  group('the ink ladder', () {
    test('uses exactly the documented opacities', () {
      final p = TodoThemes.paper.light;
      double a(Color c) => c.a;
      expect(a(p.ink5), closeTo(0.05, 0.005));
      expect(a(p.ink10), closeTo(0.10, 0.005));
      expect(a(p.ink15), closeTo(0.15, 0.005));
      expect(a(p.ink20), closeTo(0.20, 0.005));
      expect(a(p.ink25), closeTo(0.25, 0.005));
      expect(a(p.ink40), closeTo(0.40, 0.005));
      expect(a(p.ink50), closeTo(0.50, 0.005));
      expect(a(p.ink65), closeTo(0.65, 0.005));
      expect(a(p.ink75), closeTo(0.75, 0.005));
      expect(a(p.ink90), closeTo(0.90, 0.005));
    });

    test('every step is the ink colour, only more transparent', () {
      for (final p in allPalettes.values) {
        for (final step in [p.ink5, p.ink25, p.ink65, p.ink90]) {
          expect(step.r, closeTo(p.ink.r, 0.005));
          expect(step.g, closeTo(p.ink.g, 0.005));
          expect(step.b, closeTo(p.ink.b, 0.005));
        }
      }
    });

    test('roles map onto the ladder', () {
      final p = TodoThemes.paper.light;
      expect(p.rule, p.ink10);
      expect(p.textSecondary, p.ink65);
      expect(p.fill, p.ink5);
    });
  });

  group('themes', () {
    test('have unique ids and a light and a dark variant', () {
      final ids = TodoThemes.all.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final family in TodoThemes.all) {
        expect(family.light.brightness, Brightness.light, reason: family.id);
        expect(family.dark.brightness, Brightness.dark, reason: family.id);
      }
    });

    test('an unknown id falls back to Paper', () {
      expect(TodoThemes.byId('nope'), TodoThemes.paper);
    });

    test('Paper is white with an orange accent', () {
      expect(TodoThemes.paper.light.paper, const Color(0xFFFFFFFF));
      expect(TodoThemes.paper.light.accent, const Color(0xFFFF5000));
    });

    test('resolve follows the platform only in system mode', () {
      TodoPalette pick(ThemeMode mode, Brightness platform) =>
          TodoThemes.resolve(
            themeId: 'mist',
            mode: mode,
            platformBrightness: platform,
          );

      expect(pick(ThemeMode.system, Brightness.dark), TodoThemes.mist.dark);
      expect(pick(ThemeMode.system, Brightness.light), TodoThemes.mist.light);
      expect(pick(ThemeMode.light, Brightness.dark), TodoThemes.mist.light);
      expect(pick(ThemeMode.dark, Brightness.light), TodoThemes.mist.dark);
    });

    test('lerp blends and lands on the endpoints', () {
      final a = TodoThemes.paper.light;
      final b = TodoThemes.paper.dark;
      expect(TodoPalette.lerp(a, b, 0).paper, a.paper);
      expect(TodoPalette.lerp(a, b, 1).ink, b.ink);
      expect(
        TodoPalette.lerp(a, b, 0.5).paper,
        Color.lerp(a.paper, b.paper, 0.5),
      );
    });
  });

  group('task colours', () {
    test('eight preset swatches plus eight extended, all unique', () {
      expect(TodoTaskColors.swatches, hasLength(8));
      expect(TodoTaskColors.extendedSwatches, hasLength(8));
      final names = TodoTaskColors.all.map((s) => s.name).toSet();
      final values = TodoTaskColors.all.map((s) => s.argb).toSet();
      expect(names.length, 16);
      expect(values.length, 16);
    });

    for (final entry in allPalettes.entries) {
      test('every swatch has readable text in ${entry.key}', () {
        for (final swatch in TodoTaskColors.all) {
          final style = TodoTaskColors.resolve(swatch.argb, entry.value);
          expect(
            contrastRatio(style.onFill, style.fill),
            greaterThanOrEqualTo(4.5),
            reason: swatch.name,
          );
        }
      });
    }

    test('any custom colour is readable, even mid-tones', () {
      final random = Random(11);
      for (final p in [TodoThemes.paper.light, TodoThemes.paper.dark]) {
        for (var i = 0; i < 300; i++) {
          final argb = 0xFF000000 | random.nextInt(0xFFFFFF);
          final style = TodoTaskColors.resolve(argb, p);
          expect(
            contrastRatio(style.onFill, style.fill),
            greaterThanOrEqualTo(4.5),
            reason: argb.toRadixString(16),
          );
        }
      }
    });

    test('dark themes deepen a bright swatch', () {
      final light = TodoTaskColors.resolve(0xFFFFE066, TodoThemes.paper.light);
      final dark = TodoTaskColors.resolve(0xFFFFE066, TodoThemes.paper.dark);
      expect(
        dark.fill.computeLuminance(),
        lessThan(light.fill.computeLuminance()),
      );
    });

    test('nameOf finds swatches and labels custom colours', () {
      expect(TodoTaskColors.nameOf(0xFFFFE066), 'Lemon');
      expect(TodoTaskColors.nameOf(0xFF7A2E6E), 'Plum');
      expect(TodoTaskColors.nameOf(0xFF123456), 'Custom colour');
    });
  });

  group('theme wiring', () {
    for (final entry in allPalettes.entries) {
      test('maps ${entry.key} onto the Material colour scheme', () {
        final p = entry.value;
        final theme = buildTodoTheme(p);

        expect(theme.brightness, p.brightness);
        expect(theme.scaffoldBackgroundColor, p.paper);
        expect(theme.colorScheme.primary, p.accent);
        expect(theme.colorScheme.onSurface, p.ink);
        expect(theme.extension<TodoTheme>()!.palette, p);
      });
    }

    testWidgets('exposes the system through the context', (tester) async {
      late BuildContext captured;
      await pumpTodo(
        tester,
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        palette: TodoThemes.mist.dark,
      );

      expect(captured.palette, TodoThemes.mist.dark);
      expect(captured.type.palette, TodoThemes.mist.dark);
      expect(captured.type.taskText.color, TodoThemes.mist.dark.ink);
    });

    testWidgets('switching theme animates instead of jumping', (tester) async {
      Widget app(TodoPalette p) => MaterialApp(
        theme: buildTodoTheme(p),
        home: Builder(
          builder: (context) =>
              Scaffold(body: ColoredBox(color: context.palette.paper)),
        ),
      );

      await tester.pumpWidget(app(TodoThemes.paper.light));
      await tester.pumpWidget(app(TodoThemes.paper.dark));
      await tester.pump(const Duration(milliseconds: 100));

      final mid = tester.widget<ColoredBox>(find.byType(ColoredBox).last).color;
      expect(mid, isNot(TodoThemes.paper.light.paper));
      expect(mid, isNot(TodoThemes.paper.dark.paper));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
        TodoThemes.paper.dark.paper,
      );
    });
  });

  group('typography', () {
    for (final entry in allPalettes.entries) {
      testWidgets('every style uses bundled Inter Tight in ${entry.key}', (
        tester,
      ) async {
        await pumpTodo(
          tester,
          Builder(
            builder: (context) {
              final t = context.type;
              final styles = [
                t.title,
                t.dayDate,
                t.dayName,
                t.heading,
                t.cardTitle,
                t.taskText,
                t.rowLabel,
                t.sectionLabel,
                t.menuItem,
                t.button,
                t.caption,
                t.small,
                t.tabular,
              ];
              for (final style in styles) {
                expect(style.fontFamily, 'InterTight');
              }
              return Column(
                children: [
                  for (final style in styles)
                    Text('Wednesday 30', style: style),
                ],
              );
            },
          ),
          palette: entry.value,
        );
        expect(tester.takeException(), isNull);
      });
    }

    test('the scale has the documented sizes and line heights', () {
      final t = TodoTheme(TodoThemes.paper.light).typography;
      void check(TextStyle style, double size, double lineHeight) {
        expect(style.fontSize, size);
        expect(style.fontSize! * style.height!, closeTo(lineHeight, 0.01));
      }

      // Measured against Tweek on the phone (docs/tweek-study/09).
      check(t.title, 32, 40);
      expect(t.title.fontWeight, FontWeight.w800);
      check(t.dayDate, 22, 28);
      check(t.dayName, 22, 28);
      expect(t.dayDate.fontWeight, FontWeight.w800);
      expect(t.dayName.fontWeight, FontWeight.w500);
      check(t.taskText, 17, 22);
      expect(t.taskText.fontWeight, FontWeight.w500);
      check(t.heading, 22, 28);
      check(t.cardTitle, 24, 30);
      expect(t.cardTitle.fontWeight, FontWeight.w800);
      check(t.rowLabel, 17, 22);
      check(t.menuItem, 15, 22);
      check(t.caption, 14, 20);
      check(t.small, 12, 18);
    });

    test('only the four bundled weights are used', () {
      final t = TodoTheme(TodoThemes.paper.light).typography;
      final weights = {
        for (final s in [
          t.title,
          t.dayDate,
          t.dayName,
          t.heading,
          t.cardTitle,
          t.taskText,
          t.rowLabel,
          t.sectionLabel,
          t.menuItem,
          t.button,
          t.caption,
          t.small,
        ])
          s.fontWeight,
      };
      expect(weights, {
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w700,
        FontWeight.w800,
      });
    });

    test('secondary text uses the secondary ink', () {
      final p = TodoThemes.paper.light;
      final t = TodoTheme(p).typography;
      expect(t.dayName.color, p.textSecondary);
      expect(t.caption.color, p.textSecondary);
      expect(t.sectionLabel.color, p.textSecondary);
      expect(t.dayDate.color, p.ink);
    });
  });

  group('motion', () {
    test('two base durations and a longer one for the check', () {
      const m = TodoMotion.full;
      expect(m.fast, const Duration(milliseconds: 100));
      expect(m.medium, const Duration(milliseconds: 200));
      expect(m.check, const Duration(milliseconds: 300));
      expect(m.dialogRise, 40);
      expect(m.panelDrop, 8);
      expect(m.pageSlide, 24);
    });

    test('the overshoot curve leaves and exceeds its range', () {
      const m = TodoMotion.full;
      expect(m.overshoot.transform(0.15), lessThan(0)); // pulls back first
      expect(
        [0.6, 0.7, 0.8].map(m.overshoot.transform).reduce(max),
        greaterThan(1),
      ); // then overshoots
      expect(m.overshoot.transform(1), closeTo(1, 0.001));
    });

    test('reduced motion zeroes every duration and distance', () {
      const m = TodoMotion.none;
      for (final d in [m.fast, m.medium, m.check]) {
        expect(d, Duration.zero);
      }
      expect(m.dialogRise, 0);
      expect(m.panelDrop, 0);
      expect(m.pageSlide, 0);
    });

    testWidgets('follows the system reduce-motion setting', (tester) async {
      late TodoMotion motion;
      Widget probe() => Builder(
        builder: (context) {
          motion = context.motion;
          return const SizedBox();
        },
      );

      await pumpTodo(tester, probe());
      expect(motion.reduced, isFalse);
      await pumpTodo(tester, probe(), disableAnimations: true);
      expect(motion.reduced, isTrue);
    });
  });

  group('tokens', () {
    test('spacing follows a 4-point grid', () {
      for (final v in [
        TodoSpace.xs,
        TodoSpace.s,
        TodoSpace.m,
        TodoSpace.l,
        TodoSpace.xl,
        TodoSpace.xxl,
        TodoSpace.xxxl,
        TodoSpace.huge,
      ]) {
        expect(v % 4, 0);
      }
    });

    test('the week rhythm is fixed', () {
      expect(TodoSize.margin, 24);
      expect(TodoSize.row, 42);
      expect(TodoSize.dayGap, 24);
      expect(TodoSize.dayRule, 2);
      expect(
        [TodoSize.controlS, TodoSize.controlM, TodoSize.controlL],
        [32, 40, 48],
      );
      expect(TodoSize.minTap, greaterThanOrEqualTo(48));
    });

    test('radii are a short fixed set', () {
      expect(
        [
          TodoRadius.s,
          TodoRadius.m,
          TodoRadius.l,
          TodoRadius.xl,
          TodoRadius.pill,
        ],
        [6, 12, 16, 24, 256],
      );
    });
  });
}
