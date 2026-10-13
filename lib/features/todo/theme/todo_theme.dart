import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_motion.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/theme/todo_typography.dart';

/// The Todo design system, attached to the Flutter [ThemeData] so any widget
/// can read it with `context.palette`, `context.type` and `context.motion`.
@immutable
class TodoTheme extends ThemeExtension<TodoTheme> {
  TodoTheme(this.palette) : typography = TodoTypography(palette);

  final TodoPalette palette;

  // Not called `type`: ThemeExtension already uses that name as its lookup key.
  final TodoTypography typography;

  @override
  TodoTheme copyWith({TodoPalette? palette}) =>
      TodoTheme(palette ?? this.palette);

  @override
  TodoTheme lerp(ThemeExtension<TodoTheme>? other, double t) {
    if (other is! TodoTheme) return this;
    return TodoTheme(TodoPalette.lerp(palette, other.palette, t));
  }
}

extension TodoThemeContext on BuildContext {
  TodoTheme get todo => Theme.of(this).extension<TodoTheme>()!;

  TodoPalette get palette => todo.palette;

  TodoTypography get type => todo.typography;

  TodoMotion get motion => TodoMotion.of(this);
}

/// Builds the Flutter theme for a palette.
ThemeData buildTodoTheme(TodoPalette palette) {
  final type = TodoTypography(palette);
  final scheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    error: palette.danger,
    onError: palette.paper,
    surface: palette.paper,
    onSurface: palette.ink,
    onSurfaceVariant: palette.textSecondary,
    surfaceContainerHighest: palette.fill,
    outline: palette.ink25,
    outlineVariant: palette.rule,
    scrim: palette.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.paper,
    canvasColor: palette.paper,
    dividerColor: palette.rule,
    textTheme: type.textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.ink,
      selectionColor: palette.accent.withValues(alpha: 0.3),
      selectionHandleColor: palette.accent,
    ),
    dividerTheme: DividerThemeData(
      color: palette.rule,
      thickness: TodoSize.hairline,
      space: TodoSize.hairline,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.ink,
      contentTextStyle: type.taskText.copyWith(color: palette.paper),
      actionTextColor: palette.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TodoRadius.l),
      ),
    ),
    extensions: [TodoTheme(palette)],
  );
}
