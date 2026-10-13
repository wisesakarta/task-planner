import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/todo_search.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';

/// Opens the search card. Choosing a result closes it and calls [onOpen].
Future<void> showSearchCard(
  BuildContext context, {
  required List<TodoTask> tasks,
  required ValueChanged<TodoTask> onOpen,
}) {
  return showTodoDialog<void>(
    context,
    color: context.palette.paper,
    builder: (dialogContext) => SearchCard(
      tasks: tasks,
      onOpen: (task) {
        Navigator.of(dialogContext).pop();
        onOpen(task);
      },
    ),
  );
}

/// A white card with a title, a search field, a row of colour dots to filter
/// by, and the matches underneath.
class SearchCard extends StatefulWidget {
  const SearchCard({required this.tasks, required this.onOpen, super.key});

  final List<TodoTask> tasks;
  final ValueChanged<TodoTask> onOpen;

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  final TextEditingController _query = TextEditingController();
  int? _color;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final results = searchTasks(
      widget.tasks,
      query: _query.text,
      color: _color,
    );
    final searching = _query.text.trim().isNotEmpty || _color != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('Search', style: type.heading)),
        const SizedBox(height: TodoSpace.m),
        Semantics(
          textField: true,
          label: 'Search tasks',
          child: Container(
            height: TodoSize.controlL,
            padding: const EdgeInsets.symmetric(horizontal: TodoSpace.l),
            decoration: BoxDecoration(
              color: p.ink5,
              borderRadius: BorderRadius.circular(TodoRadius.m),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: TodoSize.icon, color: p.ink65),
                const SizedBox(width: TodoSpace.s),
                Expanded(
                  child: TextField(
                    controller: _query,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: type.taskText,
                    cursorColor: p.ink,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search tasks',
                      hintStyle: type.taskText.copyWith(color: p.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TodoSpace.s),
        Wrap(
          children: [
            for (final swatch in TodoTaskColors.swatches)
              _FilterDot(
                swatch: swatch,
                selected: _color == swatch.argb,
                onTap: () => setState(
                  () => _color = _color == swatch.argb ? null : swatch.argb,
                ),
              ),
          ],
        ),
        const SizedBox(height: TodoSpace.s),
        if (!searching)
          _Note('Find a task by its title, notes or checklist.')
        else if (results.isEmpty)
          _Note('Nothing found.')
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final task in results)
                  _ResultRow(task: task, onTap: () => widget.onOpen(task)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TodoSpace.m),
    child: Text(text, style: context.type.caption),
  );
}

class _FilterDot extends StatelessWidget {
  const _FilterDot({
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final TodoSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Only ${swatch.name}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: AnimatedContainer(
                duration: context.motion.fast,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? p.ink : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: TodoTaskColors.resolve(swatch.argb, p).fill,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.task, required this.onTap});

  final TodoTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final due = task.dueDate;
    final day = due == null
        ? 'Someday'
        : DateFormat('EEE, d MMM y').format(due);

    return Semantics(
      button: true,
      label: '${task.title}, $day${task.isDone ? ', done' : ''}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: TodoSize.minTap),
            padding: const EdgeInsets.symmetric(vertical: TodoSpace.s),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: p.rule, width: TodoSize.hairline),
              ),
            ),
            child: Row(
              children: [
                if (task.color != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: TodoTaskColors.resolve(task.color!, p).fill,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: TodoSpace.s),
                ],
                Expanded(
                  child: Opacity(
                    opacity: task.isDone ? 0.5 : 1,
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.taskText.copyWith(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TodoSpace.m),
                Text(day, style: type.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
