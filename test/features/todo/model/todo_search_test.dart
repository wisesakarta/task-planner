import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/todo_search.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';

TodoTask _t(
  String title, {
  String notes = '',
  DateTime? due,
  int? color,
  bool done = false,
  bool deleted = false,
  List<String> subtasks = const [],
}) => TodoTask.create(
  id: title,
  title: title,
  notes: notes,
  dueDate: due,
  color: color,
  subtasks: [for (final s in subtasks) TodoSubtask(id: s, title: s)],
  now: DateTime(2026, 9, 30),
).copyWith(isDone: done, deletedAt: deleted ? DateTime(2026, 9, 30) : null);

void main() {
  group('searchTasks', () {
    test('no query and no colour finds nothing', () {
      expect(searchTasks([_t('Milk')]), isEmpty);
      expect(searchTasks([_t('Milk')], query: '   '), isEmpty);
    });

    test('matches the title, ignoring case', () {
      final found = searchTasks([
        _t('Buy Milk'),
        _t('Call mum'),
      ], query: 'milk');
      expect(found.map((t) => t.title), ['Buy Milk']);
    });

    test('matches notes and subtasks too', () {
      final found = searchTasks([
        _t('One', notes: 'remember the oat drink'),
        _t('Two', subtasks: ['oat bars']),
        _t('Three'),
      ], query: 'oat');
      expect(found.map((t) => t.title).toSet(), {'One', 'Two'});
    });

    test('every word must appear, in any order', () {
      final found = searchTasks([
        _t('Buy oat milk'),
        _t('Buy bread'),
      ], query: 'milk buy');
      expect(found.map((t) => t.title), ['Buy oat milk']);
    });

    test('a colour alone lists the tasks with it', () {
      final found = searchTasks([
        _t('A', color: 1),
        _t('B', color: 2),
        _t('C'),
      ], color: 2);
      expect(found.map((t) => t.title), ['B']);
    });

    test('a colour narrows a text search', () {
      final found = searchTasks(
        [_t('Milk', color: 1), _t('Milkshake', color: 2)],
        query: 'milk',
        color: 2,
      );
      expect(found.map((t) => t.title), ['Milkshake']);
    });

    test('deleted tasks never match', () {
      expect(searchTasks([_t('Milk', deleted: true)], query: 'milk'), isEmpty);
    });

    test(
      'open tasks come first, then by day with Someday last, then title',
      () {
        final found = searchTasks([
          _t('x done', due: DateTime(2026, 9, 1), done: true),
          _t('x someday'),
          _t('x later', due: DateTime(2026, 10, 5)),
          _t('x b', due: DateTime(2026, 10, 1)),
          _t('x a', due: DateTime(2026, 10, 1)),
        ], query: 'x');
        expect(found.map((t) => t.title), [
          'x a',
          'x b',
          'x later',
          'x someday',
          'x done',
        ]);
      },
    );
  });
}
