import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/app/todo_app.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/data/shared_preferences_settings_store.dart';
import 'package:todo_app/features/todo/data/shared_preferences_todo_repository.dart';
import 'package:todo_app/features/todo/reminders/local_notification_reminder_service.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TodoController(
    repository: SharedPreferencesTodoRepository(),
    settingsStore: SharedPreferencesSettingsStore(),
    reminders: await _createReminders(),
  );
  // Load before the first frame so the saved theme is there from the start.
  await controller.load();

  runApp(TodoApp(controller: controller));
}

/// Notifications where the platform has them; otherwise reminders are simply
/// not shown (a failure here must never stop the app from opening).
Future<ReminderService> _createReminders() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const NoopReminderService();
  }
  try {
    final service = LocalNotificationReminderService();
    await service.init(listenForBackgroundChanges: true);
    return service;
  } catch (_) {
    return const NoopReminderService();
  }
}
