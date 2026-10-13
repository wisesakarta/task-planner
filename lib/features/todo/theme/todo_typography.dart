import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';

/// The type scale: Inter Tight (bundled in `assets/fonts/inter_tight/`) and a
/// short list of sizes. The contrast is deliberately steep: headings
/// (title, dates, Someday, the card title) are extra bold, reading text is
/// medium, and secondary text regular. Sizes and weights were measured
/// against Tweek on the phone (cap height and stem width, see
/// `docs/tweek-study/09-fokus-hari-ini-dan-tipografi.md`).
///
/// Sizes are logical pixels and scale with the user's text-size setting.
@immutable
class TodoTypography {
  const TodoTypography(this.palette);

  final TodoPalette palette;

  TextStyle _interTight(
    double size,
    double lineHeight,
    FontWeight weight, {
    double letterSpacing = 0,
    Color? color,
  }) => TextStyle(
    fontFamily: 'InterTight',
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color ?? palette.ink,
  );

  /// The screen title: "Oct 2026".
  TextStyle get title =>
      _interTight(32, 40, FontWeight.w800, letterSpacing: -0.2);

  /// The date in a day header: "30 Sep".
  TextStyle get dayDate => _interTight(22, 28, FontWeight.w800);

  /// The weekday in a day header: "Wed". Same size as the date so the two
  /// share a baseline; medium, so it reads as a label next to it.
  TextStyle get dayName =>
      _interTight(22, 28, FontWeight.w500, color: palette.textSecondary);

  /// Dialog titles, names, the Someday heading.
  TextStyle get heading => _interTight(22, 28, FontWeight.w800);

  /// The task title on the task card.
  TextStyle get cardTitle => _interTight(24, 30, FontWeight.w800);

  /// A task in the week list, notes, and body copy.
  TextStyle get taskText => _interTight(17, 22, FontWeight.w500);

  /// A row in a settings group.
  TextStyle get rowLabel => _interTight(17, 22, FontWeight.w400);

  /// A section title in settings.
  TextStyle get sectionLabel =>
      _interTight(17, 22, FontWeight.w400, color: palette.textSecondary);

  /// An item in a popover menu.
  TextStyle get menuItem => _interTight(15, 22, FontWeight.w500);

  /// Text on a pill button.
  TextStyle get button => _interTight(17, 21, FontWeight.w700);

  /// Hints, values, small explanations.
  TextStyle get caption =>
      _interTight(14, 20, FontWeight.w400, color: palette.textSecondary);

  /// The date chip on the task card.
  TextStyle get small => _interTight(12, 18, FontWeight.w400);

  /// Numbers that should not jitter as they change (time, counts).
  TextStyle get tabular =>
      taskText.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The Material text theme mapped onto this scale, so stock widgets
  /// (text fields, snack bars) match.
  TextTheme get textTheme => TextTheme(
    displayLarge: title,
    headlineMedium: heading,
    titleLarge: heading,
    titleMedium: rowLabel,
    bodyLarge: rowLabel,
    bodyMedium: taskText,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: menuItem,
    labelSmall: small,
  );
}
