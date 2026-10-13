import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';

/// Kept as a common setup boundary for every Todo widget test. Inter Tight is
/// declared directly in `pubspec.yaml`; it has no runtime font fetching path.
void useBundledFonts() {}

/// The two variants every component must be checked in.
final allPalettes = <String, TodoPalette>{
  for (final family in TodoThemes.all) ...{
    '${family.id} light': family.light,
    '${family.id} dark': family.dark,
  },
};

/// Pumps [child] inside the Todo theme.
///
/// [textScale] lets tests check large-text layouts, [disableAnimations]
/// emulates the system "reduce motion" setting, and [width] sets the logical
/// screen width (phones are ~390).
Future<void> pumpTodo(
  WidgetTester tester,
  Widget child, {
  TodoPalette? palette,
  double textScale = 1,
  bool disableAnimations = false,
  double width = 390,
  double height = 844,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTodoTheme(palette ?? TodoThemes.paper.light),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: app!,
      ),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
