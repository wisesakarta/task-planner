import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/model/todo_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesSettingsStore implements TodoSettingsStore {
  SharedPreferencesSettingsStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _settingsKey = 'todo.settings.v1';

  /// Written by the first version, which only stored the theme mode.
  static const _legacyThemeModeKey = 'todo.settings.themeMode';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<TodoSettings> load() async {
    final preferences = await _preferencesLoader();
    // A notification button may have written from another isolate; read the
    // store, not this isolate's cache.
    await preferences.reload();
    final raw = preferences.getString(_settingsKey);

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return TodoSettings.fromJson(decoded);
        }
      } on FormatException {
        // Fall through to defaults; the next save replaces the bad value.
      }
      return const TodoSettings();
    }

    final legacyName = preferences.getString(_legacyThemeModeKey);
    return TodoSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == legacyName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  @override
  Future<void> save(TodoSettings settings) async {
    final preferences = await _preferencesLoader();
    // A notification button may have written from another isolate; read the
    // store, not this isolate's cache.
    await preferences.reload();
    final saved = await preferences.setString(
      _settingsKey,
      jsonEncode(settings.toJson()),
    );
    if (!saved) throw StateError('Settings storage rejected the write.');
  }
}
