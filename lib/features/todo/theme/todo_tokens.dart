/// Spacing on a 4-point grid.
abstract final class TodoSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Corner radii: a small, fixed set.
abstract final class TodoRadius {
  /// Small buttons inside cards, the editor toolbar.
  static const double s = 6;

  /// Popovers and menus.
  static const double m = 12;

  /// Grouped cards and tiles.
  static const double l = 16;

  /// Floating cards, panels and dialogs.
  static const double xl = 24;

  /// Fully rounded: buttons, pills, highlights, circles.
  static const double pill = 256;
}

/// Fixed sizes. Everything on the week screen sits on these.
abstract final class TodoSize {
  /// Side margin of the week list and the top bar.
  static const double margin = 24;

  /// Height of a task row, a spare row, and a day header.
  static const double row = 42;

  /// Space between one day and the next.
  static const double dayGap = 24;

  /// The rule under a day header.
  static const double dayRule = 2;

  /// The 1 px line under every row.
  static const double hairline = 1;

  /// Round buttons, pills and segmented controls come in these heights.
  static const double controlS = 32;
  static const double controlM = 40;
  static const double controlL = 48;

  /// Icons on the task card and in rows.
  static const double icon = 22;
  static const double iconS = 16;

  /// Smallest tappable area.
  static const double minTap = 48;

  /// The floating card: never wider than this, this far from the top and
  /// from the screen sides.
  static const double dialogMaxWidth = 512;
  static const double dialogTop = 64;
  static const double dialogSide = 12;

  /// Padding inside floating cards and panels.
  static const double dialogPad = 24;

  /// How far a highlighted task's pill reaches past the text on each side.
  static const double pillPad = 6;
}
