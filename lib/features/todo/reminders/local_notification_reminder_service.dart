import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/features/todo/data/shared_preferences_settings_store.dart';
import 'package:todo_app/features/todo/data/shared_preferences_todo_repository.dart';
import 'package:todo_app/features/todo/model/task_completion.dart';
import 'package:todo_app/features/todo/reminders/reminder_planner.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';

/// The name under which the running app listens for "a notification button
/// changed your tasks" from the background isolate.
const reminderPortName = 'todo.reminders.changed';

const _channelId = 'reminders';
const _actionComplete = 'complete';
const _actionHour = 'hour';
const _actionTomorrow = 'tomorrow';

/// Reminders as Android (and iOS) local notifications.
///
/// Reminders are scheduled with *exact* alarms that also ring while the phone
/// dozes, when the app may use them (`USE_EXACT_ALARM`, see the manifest).
/// Inexact alarms were not good enough: on HiOS the battery manager froze the
/// app and the reminder never came. Without exact-alarm access the service
/// falls back to inexact ones. Each notification has three
/// buttons — Done, In 1 hour, Tomorrow (short, so all three fit) — that
/// work without opening the app.
class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _signals = StreamController<ReminderSignal>.broadcast();
  ReceivePort? _port;
  bool _launchTaken = false;

  @override
  Stream<ReminderSignal> get signals => _signals.stream;

  /// Sets up time zones and the plugin. Call once before using the service.
  ///
  /// [listenForBackgroundChanges] (the running app, not the background
  /// isolate) also listens for changes made by notification buttons.
  Future<void> init({bool listenForBackgroundChanges = false}) async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_reminder'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: reminderBackgroundHandler,
    );

    if (listenForBackgroundChanges) {
      IsolateNameServer.removePortNameMapping(reminderPortName);
      final port = ReceivePort();
      IsolateNameServer.registerPortWithName(port.sendPort, reminderPortName);
      port.listen(
        (_) =>
            _signals.add(const ReminderSignal(ReminderSignalKind.dataChanged)),
      );
      _port = port;
    }
  }

  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(reminderPortName);
    unawaited(_signals.close());
  }

  void _onResponse(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId == null) return;
    // Buttons run in the background and never reach here; a tap on the body does.
    _signals.add(ReminderSignal(ReminderSignalKind.open, taskId));
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<ReminderPermission> permission() async {
    final android = _android;
    if (android == null) return ReminderPermission.granted;
    return (await android.areNotificationsEnabled() ?? false)
        ? ReminderPermission.granted
        : ReminderPermission.denied;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    final android = _android;
    if (android == null) return ReminderPermission.granted;
    await android.requestNotificationsPermission();
    return permission();
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Task reminders',
      channelDescription: 'A reminder when a task is due.',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_reminder',
      category: AndroidNotificationCategory.reminder,
      actions: [
        AndroidNotificationAction(_actionComplete, 'Done'),
        AndroidNotificationAction(_actionHour, 'In 1 hour'),
        AndroidNotificationAction(_actionTomorrow, 'Tomorrow'),
      ],
    ),
  );

  /// Exact when the phone allows it, inexact otherwise.
  Future<AndroidScheduleMode> _scheduleMode() async =>
      (await _android?.canScheduleExactNotifications() ?? false)
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  @override
  Future<void> schedule(ReminderRequest request) async =>
      _schedule(request, await _scheduleMode());

  Future<void> _schedule(ReminderRequest request, AndroidScheduleMode mode) =>
      _plugin.zonedSchedule(
        id: reminderNotificationId(request.taskId),
        title: request.title,
        body: request.body,
        scheduledDate: tz.TZDateTime.from(request.at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
        payload: request.taskId,
      );

  @override
  Future<void> cancel(String taskId) =>
      _plugin.cancel(id: reminderNotificationId(taskId));

  @override
  Future<void> replaceAll(List<ReminderRequest> requests) async {
    // Only the pending ones: a reminder already on screen stays until dismissed.
    await _plugin.cancelAllPendingNotifications();
    final mode = await _scheduleMode();
    for (final request in requests) {
      await _schedule(request, mode);
    }
  }

  @override
  Future<String?> takeLaunchTaskId() async {
    if (_launchTaken) return null;
    _launchTaken = true;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}

/// Runs in a background isolate when a notification button is pressed, even if
/// the app is closed: changes the task in storage, re-plans its reminder, and
/// tells the app (if it is running) to read the tasks again.
@pragma('vm:entry-point')
Future<void> reminderBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final taskId = response.payload;
  final action = switch (response.actionId) {
    _actionComplete => ReminderAction.complete,
    _actionHour => ReminderAction.inAnHour,
    _actionTomorrow => ReminderAction.tomorrow,
    _ => null,
  };
  if (taskId == null || action == null) return;

  final repository = SharedPreferencesTodoRepository();
  final tasks = await repository.getAll();
  final task = tasks.where((t) => t.id == taskId && !t.isDeleted).firstOrNull;
  if (task == null) return;

  final now = DateTime.now();
  final changed = applyReminderAction(
    action: action,
    task: task,
    all: tasks,
    now: now,
    newId: newTaskId,
  );
  if (changed.isEmpty) return;
  await repository.upsertAll(changed);

  final settings = await SharedPreferencesSettingsStore().load();
  if (settings.notificationsEnabled) {
    final service = LocalNotificationReminderService();
    await service.init();
    for (final updated in changed) {
      final request = planReminder(updated, now);
      if (request == null) {
        await service.cancel(updated.id);
      } else {
        await service.schedule(request);
      }
    }
  }

  IsolateNameServer.lookupPortByName(reminderPortName)?.send('changed');
}
