import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';

/// A named swatch offered in the colour picker. The stored value on a task is
/// just the ARGB int, so custom colours work exactly like these.
@immutable
class TodoSwatch {
  const TodoSwatch(this.name, this.argb);

  final String name;
  final int argb;
}

/// A task colour as it should be drawn in a given theme.
@immutable
class TaskColorStyle {
  const TaskColorStyle({required this.fill, required this.onFill});

  /// The highlight behind the text.
  final Color fill;

  /// Text and icons on top of [fill]. Always ≥ 4.5:1 against it.
  final Color onFill;
}

abstract final class TodoTaskColors {
  /// The eight colours shown first in the picker (a 3 × 3 grid with "no
  /// colour").
  static const swatches = [
    TodoSwatch('Tomato', 0xFFE5484D),
    TodoSwatch('Lemon', 0xFFFFE066),
    TodoSwatch('Ink', 0xFF1C1B1A),
    TodoSwatch('Stone', 0xFFCFCFCF),
    TodoSwatch('Ocean', 0xFF3E63DD),
    TodoSwatch('Amber', 0xFFFFB020),
    TodoSwatch('Mint', 0xFF5EEAB0),
    TodoSwatch('Orchid', 0xFFC15EF0),
  ];

  /// More colours, revealed by the "+" dot.
  static const extendedSwatches = [
    TodoSwatch('Rose', 0xFFFF9EB5),
    TodoSwatch('Peach', 0xFFFFB38A),
    TodoSwatch('Sand', 0xFFE6D5B8),
    TodoSwatch('Lime', 0xFFC5E86C),
    TodoSwatch('Sky', 0xFF9AD6FF),
    TodoSwatch('Lavender', 0xFFC9B6FF),
    TodoSwatch('Forest', 0xFF2F7D5B),
    TodoSwatch('Plum', 0xFF7A2E6E),
  ];

  static Iterable<TodoSwatch> get all => [...swatches, ...extendedSwatches];

  /// The name of the swatch matching [argb], or "Custom colour".
  static String nameOf(int argb) {
    for (final swatch in all) {
      if (swatch.argb == argb) return swatch.name;
    }
    return 'Custom colour';
  }

  static const _minContrast = 4.5;

  /// How [argb] should be drawn in [palette].
  ///
  /// In light themes the colour is used as picked. In dark themes it is
  /// deepened so a bright highlight does not glare on a dark page. Either way
  /// the text colour is chosen for contrast, and the fill is nudged if no text
  /// colour reaches [_minContrast] against it.
  static TaskColorStyle resolve(int argb, TodoPalette palette) {
    var fill = Color(argb);
    if (palette.isDark) fill = _deepen(fill);

    final lightText = palette.isDark ? palette.ink : const Color(0xFFFFFFFF);
    final darkText = palette.isDark ? palette.paper : palette.ink;

    for (var step = 0; step < 40; step++) {
      final onFill = _bestText(fill, lightText, darkText);
      if (_contrast(fill, onFill) >= _minContrast) {
        return TaskColorStyle(fill: fill, onFill: onFill);
      }
      // No text colour is readable: move the fill towards the nearer extreme.
      final hsl = HSLColor.fromColor(fill);
      final lighten = hsl.lightness >= 0.5;
      fill = hsl
          .withLightness((hsl.lightness + (lighten ? 0.02 : -0.02)).clamp(0, 1))
          .toColor();
    }
    return TaskColorStyle(
      fill: fill,
      onFill: _bestText(fill, lightText, darkText),
    );
  }

  static Color _deepen(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(hsl.saturation * 0.75)
        .withLightness(hsl.lightness.clamp(0, 0.34))
        .toColor();
  }

  static Color _bestText(Color fill, Color a, Color b) =>
      _contrast(fill, a) >= _contrast(fill, b) ? a : b;

  static double _contrast(Color a, Color b) => contrastRatio(a, b);
}

/// WCAG 2 contrast ratio between two opaque colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
