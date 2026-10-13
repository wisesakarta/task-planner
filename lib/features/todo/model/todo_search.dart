import 'package:todo_app/features/todo/model/todo_task.dart';

/// Finds tasks by text and/or colour.
///
/// [query] is matched (case-insensitively, every word must appear) against the
/// title, the notes and the checklist. [color] keeps only tasks with that
/// highlight. Deleted tasks never match. With neither a query nor a colour the
/// result is empty: search is for looking something up, not for browsing.
///
/// Open tasks come first, then finished ones; within each, by day (Someday
/// last) and then by title.
List<TodoTask> searchTasks(
  Iterable<TodoTask> tasks, {
  String query = '',
  int? color,
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty && color == null) return const [];

  bool matches(TodoTask task) {
    if (task.isDeleted) return false;
    if (color != null && task.color != color) return false;
    if (words.isEmpty) return true;
    final haystack = [
      task.title,
      task.notes,
      for (final subtask in task.subtasks) subtask.title,
    ].join('\n').toLowerCase();
    return words.every(haystack.contains);
  }

  final found = tasks.where(matches).toList();
  found.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd != null) return 1;
    if (ad != null && bd == null) return -1;
    if (ad != null && bd != null) {
      final byDay = ad.compareTo(bd);
      if (byDay != 0) return byDay;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return found;
}
