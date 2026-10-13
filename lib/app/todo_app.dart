import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/app_info.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/ui/todo_home.dart';

/// The root of the app: applies the chosen theme and shows the week.
///
/// Changing theme or light/dark takes effect at once, with no cross-fade:
/// things that change state change instantly.
class TodoApp extends StatelessWidget {
  const TodoApp({required this.controller, super.key});

  final TodoController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.settingsListenable,
      builder: (context, _) {
        final settings = controller.settings;
        final family = TodoThemes.byId(settings.themeId);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: appName,
          theme: buildTodoTheme(family.light),
          darkTheme: buildTodoTheme(family.dark),
          themeMode: settings.themeMode,
          themeAnimationDuration: Duration.zero,
          builder: (context, app) {
            final p = context.palette;
            final darkIcons = p.brightness == Brightness.light;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: darkIcons
                    ? Brightness.dark
                    : Brightness.light,
                statusBarBrightness: darkIcons
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: p.paper,
                systemNavigationBarIconBrightness: darkIcons
                    ? Brightness.dark
                    : Brightness.light,
              ),
              child: app!,
            );
          },
          home: Scaffold(body: TodoHome(controller: controller)),
        );
      },
    );
  }
}
