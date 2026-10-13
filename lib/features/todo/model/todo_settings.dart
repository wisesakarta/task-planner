import 'package:flutter/material.dart';

/// Device-local preferences. Never synced between devices.
class TodoSettings {
  const TodoSettings({
    this.themeMode = ThemeMode.system,
    this.themeId = defaultThemeId,
    this.moveToNextDay = false,
    this.sortCompletedDown = true,
    this.hideAfterComplete = false,
    this.weekStartsOn = DateTime.monday,
    this.notificationsEnabled = true,
  }) : assert(
         weekStartsOn == DateTime.monday || weekStartsOn == DateTime.sunday,
       );

  static const defaultThemeId = 'paper';

  factory TodoSettings.fromJson(Map<String, dynamic> json) {
    final weekStart = json['weekStartsOn'];
    return TodoSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      themeId: json['themeId'] as String? ?? defaultThemeId,
      moveToNextDay: json['moveToNextDay'] as bool? ?? false,
      sortCompletedDown: json['sortCompletedDown'] as bool? ?? true,
      hideAfterComplete: json['hideAfterComplete'] as bool? ?? false,
      weekStartsOn: weekStart == DateTime.sunday
          ? DateTime.sunday
          : DateTime.monday,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  final ThemeMode themeMode;

  /// Which colour theme (paper, night, …) is applied on top of [themeMode].
  final String themeId;

  /// Roll unfinished tasks from past days over to today.
  final bool moveToNextDay;

  /// Show completed tasks below the open ones within a day.
  final bool sortCompletedDown;

  /// Hide a task from its day as soon as it is completed.
  final bool hideAfterComplete;

  /// [DateTime.monday] or [DateTime.sunday].
  final int weekStartsOn;

  /// Show a notification when a task's reminder time arrives.
  final bool notificationsEnabled;

  TodoSettings copyWith({
    ThemeMode? themeMode,
    String? themeId,
    bool? moveToNextDay,
    bool? sortCompletedDown,
    bool? hideAfterComplete,
    int? weekStartsOn,
    bool? notificationsEnabled,
  }) {
    return TodoSettings(
      themeMode: themeMode ?? this.themeMode,
      themeId: themeId ?? this.themeId,
      moveToNextDay: moveToNextDay ?? this.moveToNextDay,
      sortCompletedDown: sortCompletedDown ?? this.sortCompletedDown,
      hideAfterComplete: hideAfterComplete ?? this.hideAfterComplete,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'themeId': themeId,
    'moveToNextDay': moveToNextDay,
    'sortCompletedDown': sortCompletedDown,
    'hideAfterComplete': hideAfterComplete,
    'weekStartsOn': weekStartsOn,
    'notificationsEnabled': notificationsEnabled,
  };

  @override
  bool operator ==(Object other) =>
      other is TodoSettings &&
      other.themeMode == themeMode &&
      other.themeId == themeId &&
      other.moveToNextDay == moveToNextDay &&
      other.sortCompletedDown == sortCompletedDown &&
      other.hideAfterComplete == hideAfterComplete &&
      other.weekStartsOn == weekStartsOn &&
      other.notificationsEnabled == notificationsEnabled;

  @override
  int get hashCode => Object.hash(
    themeMode,
    themeId,
    moveToNextDay,
    sortCompletedDown,
    hideAfterComplete,
    weekStartsOn,
    notificationsEnabled,
  );
}
