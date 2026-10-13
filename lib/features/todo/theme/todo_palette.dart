import 'package:flutter/material.dart';

/// Every colour the Todo UI may use.
///
/// The palette is small on purpose: a **paper**, an **ink**, one **accent**,
/// and two tinted surfaces. Every grey is the ink at a fixed opacity (the
/// "ink ladder" below), so a new theme only has to supply those few colours
/// and dark mode is the same ladder with a light ink.
@immutable
class TodoPalette {
  const TodoPalette({
    required this.brightness,
    required this.paper,
    required this.ink,
    required this.accent,
    required this.accentInk,
    required this.onAccent,
    required this.sheet,
    required this.alert,
    required this.danger,
  });

  final Brightness brightness;

  /// The page.
  final Color paper;

  /// Text, icons, rules, and the source of every neutral.
  final Color ink;

  /// The theme colour: today, hover, the primary action. Seen as a graphic on
  /// [paper], so it keeps ≥ 3:1 against it.
  final Color accent;

  /// [accent] darkened (or lightened) until it reads as small text: ≥ 4.5:1.
  final Color accentInk;

  /// Text and icons drawn on [accent]: ≥ 4.5:1.
  final Color onAccent;

  /// Floating cards and panels (task card, search, menu).
  final Color sheet;

  /// Confirmation dialogs.
  final Color alert;

  /// Destructive text ("Log out"); readable on [paper], [sheet] and [alert].
  final Color danger;

  bool get isDark => brightness == Brightness.dark;

  // ── The ink ladder ──────────────────────────────────────────────────────

  Color _ink(double opacity) => ink.withValues(alpha: opacity);

  Color get ink5 => _ink(0.05);
  Color get ink10 => _ink(0.10);
  Color get ink15 => _ink(0.15);
  Color get ink20 => _ink(0.20);
  Color get ink25 => _ink(0.25);
  Color get ink40 => _ink(0.40);
  Color get ink50 => _ink(0.50);
  Color get ink65 => _ink(0.65);
  Color get ink75 => _ink(0.75);
  Color get ink90 => _ink(0.90);

  // ── Roles ───────────────────────────────────────────────────────────────

  /// The 1 px ruled line under every row.
  Color get rule => ink10;

  /// Secondary text (weekday names, section titles, values). ≥ 4.5:1 on the
  /// paper and on both tinted surfaces.
  Color get textSecondary => ink65;

  /// The soft fill behind secondary buttons, tiles and groups.
  Color get fill => ink5;

  /// Dimming behind floating cards.
  Color get scrim => const Color(0x66000000);

  static TodoPalette lerp(TodoPalette a, TodoPalette b, double t) {
    Color mix(Color x, Color y) => Color.lerp(x, y, t)!;
    return TodoPalette(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      paper: mix(a.paper, b.paper),
      ink: mix(a.ink, b.ink),
      accent: mix(a.accent, b.accent),
      accentInk: mix(a.accentInk, b.accentInk),
      onAccent: mix(a.onAccent, b.onAccent),
      sheet: mix(a.sheet, b.sheet),
      alert: mix(a.alert, b.alert),
      danger: mix(a.danger, b.danger),
    );
  }
}

/// A colour theme with a light and a dark variant.
@immutable
class TodoThemeFamily {
  const TodoThemeFamily({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  final String id;
  final String name;
  final TodoPalette light;
  final TodoPalette dark;

  TodoPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// The available colour themes. **Paper** is the default.
abstract final class TodoThemes {
  static const paper = TodoThemeFamily(
    id: 'paper',
    name: 'Paper',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFFFFFFF),
      ink: Color(0xFF0B0B0C),
      accent: Color(0xFFFF5000),
      accentInk: Color(0xFFB83700),
      onAccent: Color(0xFF0B0B0C),
      sheet: Color(0xFFFFE9DC),
      alert: Color(0xFFFFF3EA),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF0B0B0C),
      ink: Color(0xFFF5F5F6),
      accent: Color(0xFFFF7A3D),
      accentInk: Color(0xFFFF7A3D),
      onAccent: Color(0xFF0B0B0C),
      sheet: Color(0xFF2C201A),
      alert: Color(0xFF241A15),
      danger: Color(0xFFFF8A80),
    ),
  );

  static const mist = TodoThemeFamily(
    id: 'mist',
    name: 'Mist',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFF3F6FB),
      ink: Color(0xFF0F1A26),
      accent: Color(0xFF2A64F0),
      accentInk: Color(0xFF1F4FCC),
      onAccent: Color(0xFFFFFFFF),
      sheet: Color(0xFFDCE6FB),
      alert: Color(0xFFE9F0FD),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF0E141B),
      ink: Color(0xFFE8EEF4),
      accent: Color(0xFF6E9BFF),
      accentInk: Color(0xFF6E9BFF),
      onAccent: Color(0xFF0E141B),
      sheet: Color(0xFF1B2636),
      alert: Color(0xFF162030),
      danger: Color(0xFFFF8A80),
    ),
  );

  static const blush = TodoThemeFamily(
    id: 'blush',
    name: 'Blush',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFFFF4F2),
      ink: Color(0xFF2A1216),
      accent: Color(0xFFD6336C),
      accentInk: Color(0xFFB0245A),
      onAccent: Color(0xFFFFFFFF),
      sheet: Color(0xFFFFDDE1),
      alert: Color(0xFFFFEAEC),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF1A0F11),
      ink: Color(0xFFF8E9EA),
      accent: Color(0xFFFF7FA8),
      accentInk: Color(0xFFFF7FA8),
      onAccent: Color(0xFF1A0F11),
      sheet: Color(0xFF3A1F26),
      alert: Color(0xFF2E181D),
      danger: Color(0xFFFF8A80),
    ),
  );

  static const sage = TodoThemeFamily(
    id: 'sage',
    name: 'Sage',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFF4F8F2),
      ink: Color(0xFF122016),
      accent: Color(0xFF2E7D4F),
      accentInk: Color(0xFF1F6A40),
      onAccent: Color(0xFFFFFFFF),
      sheet: Color(0xFFDCEBD8),
      alert: Color(0xFFE9F3E6),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF0F1611),
      ink: Color(0xFFEAF2EA),
      accent: Color(0xFF6FD09A),
      accentInk: Color(0xFF6FD09A),
      onAccent: Color(0xFF0F1611),
      sheet: Color(0xFF1E3024),
      alert: Color(0xFF182619),
      danger: Color(0xFFFF8A80),
    ),
  );

  /// Warm cream paper with brown ink and a terracotta accent.
  static const sand = TodoThemeFamily(
    id: 'sand',
    name: 'Sand',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFF7F1E6),
      ink: Color(0xFF241B14),
      accent: Color(0xFFB4530F),
      accentInk: Color(0xFF96410A),
      onAccent: Color(0xFFFFFFFF),
      sheet: Color(0xFFEEE4D1),
      alert: Color(0xFFF1E8D8),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF17130F),
      ink: Color(0xFFF0E6D6),
      accent: Color(0xFFE39A54),
      accentInk: Color(0xFFE39A54),
      onAccent: Color(0xFF17130F),
      sheet: Color(0xFF2B2319),
      alert: Color(0xFF211B13),
      danger: Color(0xFFFF8A80),
    ),
  );

  /// Neutral greys with one cool teal accent.
  static const charcoal = TodoThemeFamily(
    id: 'charcoal',
    name: 'Charcoal',
    light: TodoPalette(
      brightness: Brightness.light,
      paper: Color(0xFFF4F4F2),
      ink: Color(0xFF161616),
      accent: Color(0xFF0E7490),
      accentInk: Color(0xFF0B6076),
      onAccent: Color(0xFFFFFFFF),
      sheet: Color(0xFFE4E4E1),
      alert: Color(0xFFEBEBE8),
      danger: Color(0xFFB3261E),
    ),
    dark: TodoPalette(
      brightness: Brightness.dark,
      paper: Color(0xFF121212),
      ink: Color(0xFFEDEDED),
      accent: Color(0xFF5CC8DA),
      accentInk: Color(0xFF5CC8DA),
      onAccent: Color(0xFF121212),
      sheet: Color(0xFF262626),
      alert: Color(0xFF1E1E1E),
      danger: Color(0xFFFF8A80),
    ),
  );

  static const all = [paper, mist, blush, sage, sand, charcoal];

  /// The family with [id], or [paper] for an unknown id.
  static TodoThemeFamily byId(String id) =>
      all.firstWhere((family) => family.id == id, orElse: () => paper);

  /// Picks the palette for the user's theme and appearance choice.
  /// [platformBrightness] is only consulted for [ThemeMode.system].
  static TodoPalette resolve({
    required String themeId,
    required ThemeMode mode,
    required Brightness platformBrightness,
  }) {
    final brightness = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    return byId(themeId).forBrightness(brightness);
  }
}
