import 'package:todo_app/features/todo/model/todo_task.dart';

class TodoDay {
  TodoDay({required this.name, required this.date, List<TodoTask>? tasks})
    : tasks = tasks ?? [];

  final String name;
  final DateTime date;
  final List<TodoTask> tasks;
}
