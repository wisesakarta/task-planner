import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/ui/week/day_header.dart';
import 'package:todo_app/features/todo/ui/week/inline_composer.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/week/task_drag.dart';
import 'package:todo_app/features/todo/ui/week/task_row.dart';

/// Puts finished tasks after open ones, keeping each group's order.
List<TodoTask> sortDoneDown(List<TodoTask> tasks) => [
  ...tasks.where((task) => !task.isDone),
  ...tasks.where((task) => task.isDone),
];

/// One day: its header, its tasks, and one spare line to type a new one.
/// A day with no tasks is a header and one empty line.
class DaySection extends StatelessWidget {
  const DaySection({
    required this.date,
    required this.tasks,
    required this.onToggle,
    required this.onOpen,
    required this.onAdd,
    this.isToday = false,
    super.key,
  });

  final DateTime date;
  final List<TodoTask> tasks;
  final bool isToday;
  final void Function(TodoTask task, bool done) onToggle;
  final ValueChanged<TodoTask> onOpen;

  /// Saves a new task for this day; returns whether it worked.
  final FutureOr<bool> Function(String title) onAdd;

  @override
  Widget build(BuildContext context) {
    return DropZone(
      date: date,
      tasks: tasks,
      headerHeight: TodoSize.row,
      slackBelow: TodoSize.dayGap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayHeader(date: date, isToday: isToday),
          for (final task in tasks)
            TaskLine(
              key: ValueKey(task.id),
              task: task,
              date: date,
              shown: tasks,
              onToggle: onToggle,
              onOpen: onOpen,
            ),
          InlineComposer(
            key: ValueKey('composer-${date.toIso8601String()}'),
            semanticsLabel:
                'Add a task on ${DateFormat('EEEE, d MMMM').format(date)}',
            onSubmit: onAdd,
          ),
        ],
      ),
    );
  }
}

/// One task line of a day or of Someday: the row, which can be picked up and
/// moved, with "Move up / down / to the next day" for screen readers.
class TaskLine extends StatelessWidget {
  const TaskLine({
    required this.task,
    required this.date,
    required this.shown,
    required this.onToggle,
    required this.onOpen,
    super.key,
  });

  final TodoTask task;

  /// The day it is listed under; null in Someday.
  final DateTime? date;

  /// The tasks of that day as shown, to work out "up" and "down".
  final List<TodoTask> shown;
  final void Function(TodoTask task, bool done) onToggle;
  final ValueChanged<TodoTask> onOpen;

  @override
  Widget build(BuildContext context) {
    final drag = TaskDragScope.maybeOf(context);
    return DraggableRow(
      task: task,
      builder: (context, {required lifted}) => TaskRow(
        title: task.title,
        isDone: task.isDone,
        color: task.color,
        repeats: task.repeats,
        hasReminder: task.reminderAt != null,
        lifted: lifted,
        customActions: drag == null
            ? const {}
            : moveActions(
                task: task,
                date: date,
                shown: shown,
                onDrop: drag.onDrop,
              ),
        onToggle: (done) => onToggle(task, done),
        onTap: () => onOpen(task),
      ),
    );
  }
}
