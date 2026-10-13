import 'package:todo_app/features/todo/model/todo_settings.dart';

/// Where [TodoSettings] live. Deliberately separate from [TodoRepository]:
/// settings belong to this device and must never be synced.
abstract interface class TodoSettingsStore {
  /// Returns the saved settings, or defaults when nothing usable is stored.
  Future<TodoSettings> load();

  Future<void> save(TodoSettings settings);
}
