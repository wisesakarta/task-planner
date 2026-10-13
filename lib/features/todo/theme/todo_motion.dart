import 'package:flutter/material.dart';

/// The motion language: very little of it.
///
/// Two base durations (100 and 200 ms) and one easing. Things that *change
/// state* (completing a task, picking a colour, switching a view) change at
/// once. Only things that *appear or leave* move: a dialog rises 40 px while
/// fading, a menu panel drops 8 px, a settings page slides 24 px sideways.
/// The one playful exception is the subtask check, which overshoots.
///
/// When the system asks for reduced motion every duration is zero.
@immutable
class TodoMotion {
  const TodoMotion({this.reduced = false});

  static const full = TodoMotion();
  static const none = TodoMotion(reduced: true);

  static TodoMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? none : full;

  final bool reduced;

  Duration _d(int milliseconds) =>
      reduced ? Duration.zero : Duration(milliseconds: milliseconds);

  /// Press feedback, background tint changes.
  Duration get fast => _d(100);

  /// Dialogs, panels, popovers, page slides, fades.
  Duration get medium => _d(200);

  /// The subtask check's overshoot.
  Duration get check => _d(300);

  Curve get ease => Curves.ease;

  /// The check's spring-like overshoot: `cubic-bezier(.68, -.55, .27, 1.55)`.
  Curve get overshoot => const Cubic(0.68, -0.55, 0.27, 1.55);

  /// How far a dialog rises while it fades in.
  double get dialogRise => reduced ? 0 : 40;

  /// How far a menu panel drops while it fades in.
  double get panelDrop => reduced ? 0 : 8;

  /// How far a settings page slides sideways.
  double get pageSlide => reduced ? 0 : 24;
}
