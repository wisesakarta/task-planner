import 'dart:async';

/// Whether the app may show notifications.
enum ReminderPermission { granted, denied }

/// What a notification asks the app to do.
enum ReminderAction {
  /// The notification itself was tapped: open the task.
  open,

  /// "Mark as completed".
  complete,

  /// "Remind me in an hour".
  inAnHour,

  /// "Remind me tomorrow" (same time of day).
  tomorrow,
}

/// One reminder to be shown at [at] (local time).
class ReminderRequest {
  const ReminderRequest({
    required this.taskId,
    required this.title,
    required this.at,
    this.body,
  });

  final String taskId;
  final String title;
  final String? body;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is ReminderRequest &&
      other.taskId == taskId &&
      other.title == title &&
      other.body == body &&
      other.at == at;

  @override
  int get hashCode => Object.hash(taskId, title, body, at);

  @override
  String toString() => 'ReminderRequest($taskId, "$title", $at)';
}

/// Something the notification system tells the app.
enum ReminderSignalKind {
  /// The user tapped a reminder: show [ReminderSignal.taskId].
  open,

  /// A notification button changed tasks while the app was not looking (from a
  /// background isolate): read them again.
  dataChanged,
}

class ReminderSignal {
  const ReminderSignal(this.kind, [this.taskId]);

  final ReminderSignalKind kind;
  final String? taskId;
}

/// The door between the app and the platform's notifications.
///
/// Every method may fail (no permission, unsupported platform); the caller
/// treats a failure as "no reminder", never as a failed task operation.
abstract interface class ReminderService {
  Stream<ReminderSignal> get signals;

  /// Whether notifications are currently allowed.
  Future<ReminderPermission> permission();

  /// Asks the user (once per install, on platforms that only ask once).
  Future<ReminderPermission> requestPermission();

  /// Shows [request] at its time, replacing any earlier one for that task.
  Future<void> schedule(ReminderRequest request);

  /// Removes the reminder for [taskId], if there is one.
  Future<void> cancel(String taskId);

  /// Makes [requests] exactly the pending reminders: everything else is
  /// cancelled.
  Future<void> replaceAll(List<ReminderRequest> requests);

  /// The id of the task whose notification launched the app from closed, once;
  /// null afterwards or when the app was opened normally.
  Future<String?> takeLaunchTaskId();
}

/// For tests and platforms without notifications: does nothing, allows
/// everything.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Stream<ReminderSignal> get signals => const Stream.empty();

  @override
  Future<ReminderPermission> permission() async => ReminderPermission.granted;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.granted;

  @override
  Future<void> schedule(ReminderRequest request) async {}

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> replaceAll(List<ReminderRequest> requests) async {}

  @override
  Future<String?> takeLaunchTaskId() async => null;
}
