import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/controller/todo_controller.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/card/task_card.dart';
import 'package:todo_app/features/todo/ui/menu/menu_panel.dart';
import 'package:todo_app/features/todo/ui/menu/search_card.dart';
import 'package:todo_app/features/todo/ui/month/month_screen.dart';
import 'package:todo_app/features/todo/reminders/system_settings.dart';
import 'package:todo_app/features/todo/ui/overlay/confirm_dialog.dart';
import 'package:todo_app/features/todo/ui/week/task_drag.dart';
import 'package:todo_app/features/todo/ui/week/week_screen.dart';

/// The home of the app: the week, wired to the [TodoController].
///
/// It also keeps the controller honest about time: staged edits are written
/// when the app leaves the foreground, and "today" moves on at midnight or
/// when the app is reopened on a new day.
class TodoHome extends StatefulWidget {
  const TodoHome({required this.controller, super.key});

  final TodoController controller;

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> with WidgetsBindingObserver {
  Timer? _midnight;

  /// Whether the month view is showing instead of the week.
  bool _monthOpen = false;

  /// A day picked in the month view; the week opens with it on the top row.
  DateTime? _focusDay;

  /// Counts trips to a week (the arrows, the title, a day in the month view)
  /// so each one lands on its focus day. Leaving the month view with Back
  /// keeps the count, and the week keeps where it was scrolled.
  int _visit = 0;

  TodoController get _c => widget.controller;

  void _goToWeek(VoidCallback go, {DateTime? focus}) {
    go();
    setState(() {
      _focusDay = focus;
      _visit++;
      _monthOpen = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armMidnight();
    _c.openRequest.addListener(_openRequested);
    // A notification may have launched the app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequested());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.openRequest.removeListener(_openRequested);
    _midnight?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_c.refreshToday());
        unawaited(_c.refreshReminderPermission());
        _armMidnight();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_c.flush());
    }
  }

  void _armMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      unawaited(_c.refreshToday());
      _armMidnight();
    });
  }

  /// A task was carried somewhere. A repeating task dropped on Someday stops
  /// repeating, so that needs a yes first.
  Future<void> _move(TodoTask task, TaskDrop drop) async {
    if (drop.date == null && task.repeats) {
      if (!await confirmChangeRecurrence(context)) return;
    }
    await _c.move(
      task,
      date: drop.date,
      afterId: drop.afterId,
      beforeId: drop.beforeId,
    );
  }

  /// A reminder was tapped: show that task's card.
  void _openRequested() {
    final id = _c.openRequest.value;
    if (id == null || !mounted) return;
    _c.openRequest.value = null;
    final task = _c.tasks.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    setState(() => _monthOpen = false);
    _open(task);
  }

  void _open(TodoTask task) {
    showTaskCard(
      context,
      task: _c.tasks.firstWhere((t) => t.id == task.id, orElse: () => task),
      today: _c.today,
      weekStartsOn: _c.settings.weekStartsOn,
      clock: _c.now,
      onChanged: (edited) => unawaited(_c.update(edited)),
      onDelete: (task, scope) => unawaited(_c.delete(task, scope)),
      onDuplicate: (task) => unawaited(_c.duplicate(task)),
    ).whenComplete(() => unawaited(_c.flush()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        if (_c.isLoading) return const SizedBox.expand();
        final settings = _c.settings;

        return PopScope(
          // Back from the month view returns to the week instead of leaving.
          canPop: !_monthOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _monthOpen) setState(() => _monthOpen = false);
          },
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: context.motion.medium,
                switchInCurve: context.motion.ease,
                child: _monthOpen
                    ? MonthScreen(
                        key: const ValueKey('month'),
                        today: _c.today,
                        tasks: _c.tasks,
                        weekStartsOn: settings.weekStartsOn,
                        onSelectDay: (day) =>
                            _goToWeek(() => _c.goToDate(day), focus: day),
                        onOpenTask: _open,
                      )
                    : WeekScreen(
                        key: const ValueKey('week'),
                        weekStart: _c.weekStart,
                        today: _c.today,
                        tasks: _c.tasks,
                        focusDay: _focusDay,
                        visit: _visit,
                        sortCompletedDown: settings.sortCompletedDown,
                        hideCompleted: settings.hideAfterComplete,
                        onToggle: (task, done) =>
                            unawaited(_c.setDone(task, done)),
                        onOpen: _open,
                        onAdd: _c.add,
                        onPrevious: () => _goToWeek(() => _c.goToWeek(-1)),
                        onNext: () => _goToWeek(() => _c.goToWeek(1)),
                        onToday: () => _goToWeek(_c.goToCurrentWeek),
                        onMonth: () => setState(() => _monthOpen = true),
                        onMove: _move,
                        onSearch: () => showSearchCard(
                          context,
                          tasks: _c.tasks,
                          onOpen: _open,
                        ),
                        onMenu: () {
                          unawaited(_c.refreshReminderPermission());
                          showMenuPanel(
                            context,
                            settings: _c.settingsListenable,
                            reminderPermission: _c.reminderPermission,
                            onOpenSystemSettings: () =>
                                unawaited(openNotificationSettings()),
                            onChanged: (next) =>
                                unawaited(_c.updateSettings(next)),
                          );
                        },
                      ),
              ),
              if (_c.problem != null)
                Positioned(
                  left: TodoSize.dialogSide,
                  right: TodoSize.dialogSide,
                  bottom:
                      TodoSize.dialogSide +
                      MediaQuery.paddingOf(context).bottom,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 512),
                      child: _ProblemBanner(
                        message: _c.problem!,
                        onDismiss: _c.clearProblem,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A short notice in the alert tint when something could not be saved.
class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: p.alert,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TodoRadius.m),
          side: BorderSide(color: p.ink, width: 0.67),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TodoSpace.l,
            TodoSpace.s,
            TodoSpace.s,
            TodoSpace.s,
          ),
          child: Row(
            children: [
              Expanded(child: Text(message, style: context.type.menuItem)),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size(TodoSize.minTap, TodoSize.minTap),
                  foregroundColor: p.ink,
                ),
                child: Text('Dismiss', style: context.type.menuItem),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
