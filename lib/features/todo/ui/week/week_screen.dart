import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/week/day_section.dart';
import 'package:todo_app/features/todo/ui/week/inline_composer.dart';
import 'package:todo_app/features/todo/ui/week/task_drag.dart';
import 'package:todo_app/features/todo/ui/week/week_dates.dart';
import 'package:todo_app/features/todo/ui/week/week_top_bar.dart';

/// The home of the app: one week, seven stacked days, and Someday underneath.
///
/// It only draws. The tasks, the current week and every action come from the
/// caller, so the same screen works with a prototype's list or the real
/// controller.
class WeekScreen extends StatelessWidget {
  const WeekScreen({
    required this.weekStart,
    required this.today,
    required this.tasks,
    required this.onToggle,
    required this.onOpen,
    required this.onAdd,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSearch,
    required this.onMenu,
    this.onMonth,
    this.onMove,
    this.focusDay,
    this.visit = 0,
    this.sortCompletedDown = false,
    this.hideCompleted = false,
    super.key,
  });

  /// The first day shown (a local calendar day).
  final DateTime weekStart;
  final DateTime today;

  /// Every task; the screen picks the ones for each day and for Someday.
  final List<TodoTask> tasks;
  final void Function(TodoTask task, bool done) onToggle;
  final ValueChanged<TodoTask> onOpen;

  /// Adds a task on [date], or to Someday when [date] is null.
  final FutureOr<bool> Function(DateTime? date, String title) onAdd;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Goes back to the current week.
  final VoidCallback onToday;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  /// Opens the month view. The title does this while you are on the current
  /// week; on any other week it takes you back to the current one instead.
  final VoidCallback? onMonth;

  /// A task was carried to a new place (or moved by a screen-reader action).
  /// Without it, rows cannot be dragged.
  final TaskDropCallback? onMove;

  /// The day that opens on the top row (a day picked in the month view).
  /// Without it the week opens on today when today is in it, and on its
  /// first day otherwise. The days above stay a scroll away.
  final DateTime? focusDay;

  /// Change it to open the week afresh on its focus day. While it stays the
  /// same, the week keeps where it was scrolled, for instance when it comes
  /// back from the month view.
  final int visit;
  final bool sortCompletedDown;
  final bool hideCompleted;

  List<TodoTask> _forDay(DateTime? date) {
    var found = tasks.where((task) {
      if (task.isDeleted) return false;
      final due = task.dueDate;
      return date == null
          ? due == null
          : due != null && WeekDates.sameDay(due, date);
    }).toList();
    if (hideCompleted) found = found.where((task) => !task.isDone).toList();
    found = sortedByOrder(found);
    return sortCompletedDown ? sortDoneDown(found) : found;
  }

  @override
  Widget build(BuildContext context) {
    final days = WeekDates.days(weekStart);
    final title = DateFormat('MMM y').format(WeekDates.titleMonth(days));
    final onCurrentWeek = days.any((d) => WeekDates.sameDay(d, today));
    final motion = context.motion;
    final focus = days.indexWhere(
      (d) => WeekDates.sameDay(d, focusDay ?? today),
    );
    final sections = [
      for (final date in days) ...[
        DaySection(
          date: date,
          isToday: WeekDates.sameDay(date, today),
          tasks: _forDay(date),
          onToggle: onToggle,
          onOpen: onOpen,
          onAdd: (text) => onAdd(date, text),
        ),
        const SizedBox(height: TodoSize.dayGap),
      ],
      _Someday(
        tasks: _forDay(null),
        onToggle: onToggle,
        onOpen: onOpen,
        onAdd: (text) => onAdd(null, text),
      ),
    ];
    // Each day is a section and the gap after it.
    final split = focus < 0 ? 0 : 2 * focus;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              WeekTopBar(
                title: title,
                onSearch: onSearch,
                onMenu: onMenu,
                onPrevious: onPrevious,
                onNext: onNext,
                accentTitle: !onCurrentWeek,
                titleTapLabel: onCurrentWeek
                    ? 'open month view'
                    : 'back to this week',
                onTitleTap: onCurrentWeek ? onMonth : onToday,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion.medium,
                  switchInCurve: motion.ease,
                  child: _Draggable(
                    onMove: onMove,
                    key: ValueKey((weekStart, visit)),
                    // The focus day is the scroll view's centre: offset 0 puts
                    // it on the top row with no jump after the first frame,
                    // the days before it grow upwards, and adding a task
                    // above it never pushes it down.
                    //
                    // Not a lazy list: a week is a few dozen rows, and the row
                    // being carried must not be thrown away when it scrolls
                    // out of view.
                    child: LayoutBuilder(
                      builder: (context, constraints) => CustomScrollView(
                        key: PageStorageKey(('week', weekStart, visit)),
                        center: _focusKey,
                        // The centre sits one margin down, where the first
                        // day sits when the list is scrolled to the top.
                        anchor: constraints.maxHeight > TodoSize.margin
                            ? TodoSize.margin / constraints.maxHeight
                            : 0,
                        slivers: [
                          // The margin above the first day is part of what
                          // scrolls up, so the top of the week rests one
                          // margin down, like the focus day.
                          _sliver(
                            sections.sublist(0, split),
                            top: TodoSize.margin,
                          ),
                          _sliver(
                            sections.sublist(split),
                            key: _focusKey,
                            bottom:
                                TodoSize.margin +
                                MediaQuery.paddingOf(context).bottom +
                                48,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _focusKey = ValueKey('week-focus');

Widget _sliver(
  List<Widget> children, {
  Key? key,
  double top = 0,
  double bottom = 0,
}) => SliverPadding(
  key: key,
  padding: EdgeInsets.fromLTRB(TodoSize.margin, top, TodoSize.margin, bottom),
  sliver: SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  ),
);

/// Tasks with no day: a heading and the same ruled lines.
class _Someday extends StatelessWidget {
  const _Someday({
    required this.tasks,
    required this.onToggle,
    required this.onOpen,
    required this.onAdd,
  });

  final List<TodoTask> tasks;
  final void Function(TodoTask task, bool done) onToggle;
  final ValueChanged<TodoTask> onOpen;
  final FutureOr<bool> Function(String title) onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DropZone(
      date: null,
      tasks: tasks,
      headerHeight: _somedayHeader,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Container(
              height: _somedayHeader,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: p.rule, width: TodoSize.hairline),
                ),
              ),
              child: Text('Someday', style: context.type.heading),
            ),
          ),
          for (final task in tasks)
            TaskLine(
              key: ValueKey(task.id),
              task: task,
              date: null,
              shown: tasks,
              onToggle: onToggle,
              onOpen: onOpen,
            ),
          InlineComposer(
            key: const ValueKey('composer-someday'),
            semanticsLabel: 'Add a Someday task',
            onSubmit: onAdd,
          ),
        ],
      ),
    );
  }
}

const double _somedayHeader = 52;

/// Lets rows be carried, when the caller handles moves.
class _Draggable extends StatelessWidget {
  const _Draggable({required this.onMove, required this.child, super.key});

  final TaskDropCallback? onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      onMove == null ? child : TaskDragScope(onDrop: onMove!, child: child);
}
