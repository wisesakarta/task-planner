import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/data/shared_preferences_todo_repository.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

TodoTask _task(String id, {String? title}) =>
    TodoTask.create(id: id, title: title ?? 'Task $id');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stores a batch in one write and replaces existing ids', () async {
    final repository = SharedPreferencesTodoRepository();
    await repository.upsert(_task('a', title: 'old'));

    await repository.upsertAll([
      _task('a', title: 'new'),
      _task('b'),
      _task('c'),
    ]);

    final tasks = await repository.getAll();
    expect(tasks.map((task) => task.id), ['a', 'b', 'c']);
    expect(tasks.first.title, 'new');
  });

  test('an empty batch is a no-op', () async {
    final repository = SharedPreferencesTodoRepository();
    await repository.upsertAll(const []);
    expect(await repository.getAll(), isEmpty);
  });

  test('every field survives a storage round trip', () async {
    final repository = SharedPreferencesTodoRepository();
    final task = TodoTask.create(
      id: 'rich',
      title: 'Rich',
      now: DateTime.utc(2026, 9, 30),
      notes: 'Notes',
      dueDate: DateTime(2026, 10, 2),
      reminderAt: DateTime(2026, 10, 1, 9),
      color: 0xFF2196F3,
      recurrence: const RecurrenceRule.weekdays(),
      subtasks: const [TodoSubtask(id: 's', title: 'Step', level: 1)],
    );

    await repository.upsert(task);

    expect((await repository.getAll()).single.toJson(), task.toJson());
  });

  test('a task saved in an older format is still loaded', () async {
    SharedPreferences.setMockInitialValues({
      'todo.tasks.v1':
          '[{"id":"old","title":"Existing","dueDate":"2026-09-30T00:00:00.000",'
          '"createdAt":"2026-09-30T02:00:00.000Z",'
          '"updatedAt":"2026-09-30T02:00:00.000Z","isDone":false,'
          '"syncState":"pending","deletedAt":null}]',
    });

    final tasks = await SharedPreferencesTodoRepository().getAll();

    expect(tasks.single.title, 'Existing');
    expect(tasks.single.dueDate, DateTime(2026, 9, 30));
  });
}
