import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/data/shared_preferences_settings_store.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts with sensible defaults', () async {
    final settings = await SharedPreferencesSettingsStore().load();

    expect(settings, const TodoSettings());
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.moveToNextDay, isFalse);
    expect(settings.sortCompletedDown, isTrue);
    expect(settings.hideAfterComplete, isFalse);
    expect(settings.weekStartsOn, DateTime.monday);
  });

  test('persists every setting', () async {
    const chosen = TodoSettings(
      themeMode: ThemeMode.dark,
      themeId: 'night',
      moveToNextDay: true,
      sortCompletedDown: false,
      hideAfterComplete: true,
      weekStartsOn: DateTime.sunday,
    );

    await SharedPreferencesSettingsStore().save(chosen);

    expect(await SharedPreferencesSettingsStore().load(), chosen);
  });

  test('keeps the theme mode chosen in the first version', () async {
    SharedPreferences.setMockInitialValues({'todo.settings.themeMode': 'dark'});

    final settings = await SharedPreferencesSettingsStore().load();

    expect(settings.themeMode, ThemeMode.dark);
  });

  test('falls back to defaults for corrupt or unknown data', () async {
    SharedPreferences.setMockInitialValues({'todo.settings.v1': '{not json'});
    expect(await SharedPreferencesSettingsStore().load(), const TodoSettings());

    SharedPreferences.setMockInitialValues({'todo.settings.v1': '[1,2]'});
    expect(await SharedPreferencesSettingsStore().load(), const TodoSettings());

    SharedPreferences.setMockInitialValues({
      'todo.settings.v1':
          '{"themeMode":"sepia","weekStartsOn":3,"hideAfterComplete":true}',
    });
    final settings = await SharedPreferencesSettingsStore().load();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.weekStartsOn, DateTime.monday);
    expect(settings.hideAfterComplete, isTrue);
  });

  test('copyWith changes only what is given', () {
    const base = TodoSettings();
    final changed = base.copyWith(moveToNextDay: true);

    expect(changed.moveToNextDay, isTrue);
    expect(changed.sortCompletedDown, base.sortCompletedDown);
    expect(changed, isNot(base));
  });
}
