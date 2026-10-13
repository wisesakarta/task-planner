import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/model/todo_subtask.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/card/color_popover.dart';
import 'package:todo_app/features/todo/ui/card/date_popover.dart';
import 'package:todo_app/features/todo/ui/card/more_menu.dart';
import 'package:todo_app/features/todo/ui/card/reminder_popover.dart';
import 'package:todo_app/features/todo/ui/card/repeat_menu.dart';
import 'package:todo_app/features/todo/ui/controls/check_toggle.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/overlay/confirm_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

/// Opens the task card for [task].
///
/// Every edit is reported through [onChanged] as it happens (there is no save
/// button). [onDelete] and [onDuplicate] close the card.
Future<void> showTaskCard(
  BuildContext context, {
  required TodoTask task,
  required DateTime today,
  required ValueChanged<TodoTask> onChanged,
  required void Function(TodoTask task, RecurrenceScope scope) onDelete,
  required ValueChanged<TodoTask> onDuplicate,
  int weekStartsOn = DateTime.monday,
  DateTime Function() clock = DateTime.now,
}) {
  return showTodoDialog<void>(
    context,
    builder: (dialogContext) => TaskCard(
      task: task,
      today: today,
      weekStartsOn: weekStartsOn,
      clock: clock,
      onChanged: onChanged,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

int _idCounter = 0;

String _newSubtaskId() =>
    's${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

/// The floating card for one task: its day, five actions, a title with a done
/// toggle, notes, and a checklist. Nothing in it needs saving.
class TaskCard extends StatefulWidget {
  const TaskCard({
    required this.task,
    required this.today,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
    required this.onClose,
    this.weekStartsOn = DateTime.monday,
    this.newId = _newSubtaskId,
    this.clock = DateTime.now,
    super.key,
  });

  final TodoTask task;
  final DateTime today;
  final int weekStartsOn;

  /// The current time, for the reminder picker.
  final DateTime Function() clock;
  final ValueChanged<TodoTask> onChanged;
  final void Function(TodoTask task, RecurrenceScope scope) onDelete;
  final ValueChanged<TodoTask> onDuplicate;
  final VoidCallback onClose;

  /// Makes ids for new checklist entries.
  final String Function() newId;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late TodoTask _task = widget.task;
  late final TextEditingController _title = TextEditingController(
    text: widget.task.title,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.task.notes,
  );

  /// Ids of subtasks created in this session, so they open focused.
  final Set<String> _fresh = {};

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _apply(TodoTask next) {
    setState(() => _task = next);
    widget.onChanged(next);
  }

  // --- title, notes, done -------------------------------------------------

  void _onTitle(String value) {
    // A task cannot be saved without a name; keep the last good one.
    if (value.trim().isEmpty) return;
    _apply(_task.copyWith(title: value.trim()));
  }

  void _onNotes(String value) => _apply(_task.copyWith(notes: value));

  void _onDone(bool done) => _apply(
    done
        ? _task.copyWith(isDone: true, completedAt: DateTime.now())
        : _task.copyWith(isDone: false, clearCompletedAt: true),
  );

  // --- day ----------------------------------------------------------------

  /// Ending a repeat (by giving the task no day) needs a yes first.
  Future<bool> _confirmLeavingRepeat() async =>
      !_task.repeats || await confirmChangeRecurrence(context);

  Future<void> _setDay(DateTime? date) async {
    if (date == null) {
      if (_task.isSomeday) return;
      if (!await _confirmLeavingRepeat() || !mounted) return;
      _apply(_task.copyWith(clearDueDate: true));
    } else {
      _apply(_task.copyWith(dueDate: date));
    }
  }

  Future<void> _pickDay(Rect anchor) async {
    final selection = await showDatePopover(
      context,
      anchor: anchor,
      selected: _task.dueDate,
      today: widget.today,
      weekStartsOn: widget.weekStartsOn,
    );
    if (selection != null && mounted) await _setDay(selection.date);
  }

  DateTime _daysFromToday(int days) =>
      DateTime(widget.today.year, widget.today.month, widget.today.day + days);

  // --- the five actions ---------------------------------------------------

  Future<void> _delete() async {
    var scope = RecurrenceScope.onlyThis;
    if (_task.repeats) {
      final chosen = await confirmDeleteRecurring(context);
      if (chosen == null || !mounted) return;
      scope = chosen;
    }
    widget.onDelete(_task, scope);
    widget.onClose();
  }

  Future<void> _repeat(Rect anchor) async {
    final selection = await showRepeatMenu(
      context,
      anchor: anchor,
      current: _task.recurrence,
    );
    if (selection == null || !mounted) return;
    final rule = selection.rule;
    if (rule == _task.recurrence) return;
    // Changing an existing repeat ends its cycle: ask first.
    if (_task.repeats && !await confirmChangeRecurrence(context)) return;
    if (!mounted) return;
    _apply(
      rule == null
          ? _task.copyWith(clearRecurrence: true)
          // A repeat needs a day: a Someday task lands on today.
          : _task.copyWith(
              recurrence: rule,
              dueDate: _task.dueDate ?? widget.today,
            ),
    );
  }

  Future<void> _colour(Rect anchor) async {
    final selection = await showColorPopover(
      context,
      anchor: anchor,
      selected: _task.color,
    );
    if (selection == null || !mounted) return;
    final argb = selection.argb;
    _apply(
      argb == null
          ? _task.copyWith(clearColor: true)
          : _task.copyWith(color: argb),
    );
  }

  Future<void> _reminder(Rect anchor) async {
    final selection = await showReminderPopover(
      context,
      anchor: anchor,
      current: _task.reminderAt,
      fallbackDate: _task.dueDate ?? widget.today,
      now: widget.clock(),
    );
    if (selection == null || !mounted) return;
    final at = selection.at;
    _apply(
      at == null
          ? _task.copyWith(clearReminder: true)
          : _task.copyWith(reminderAt: at),
    );
  }

  Future<void> _more(Rect anchor) async {
    final action = await showMoreMenu(context, anchor: anchor);
    if (action == null || !mounted) return;
    switch (action) {
      case MoreAction.tomorrow:
        await _setDay(_daysFromToday(1));
      case MoreAction.nextWeek:
        await _setDay(_daysFromToday(7));
      case MoreAction.someday:
        await _setDay(null);
      case MoreAction.duplicate:
        widget.onDuplicate(_task);
        widget.onClose();
    }
  }

  // --- checklist ----------------------------------------------------------

  void _setSubtasks(List<TodoSubtask> next) =>
      _apply(_task.copyWith(subtasks: next));

  void _addSubtask(String title, {int? after}) {
    final entry = TodoSubtask(
      id: widget.newId(),
      title: title,
      level: after == null ? 0 : _task.subtasks[after].level,
    );
    final list = [..._task.subtasks];
    list.insert(after == null ? list.length : after + 1, entry);
    if (after != null) _fresh.add(entry.id);
    _setSubtasks(list);
  }

  void _editSubtask(String id, TodoSubtask Function(TodoSubtask s) edit) {
    _setSubtasks([for (final s in _task.subtasks) s.id == id ? edit(s) : s]);
  }

  void _removeSubtask(String id) => _setSubtasks([
    for (final s in _task.subtasks)
      if (s.id != id) s,
  ]);

  Future<void> _subtaskMenu(TodoSubtask subtask, Rect anchor) async {
    final action = await showTodoPopover<_SubtaskAction>(
      context,
      anchor: anchor,
      attached: false,
      builder: (popoverContext) => PopoverSurface(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in _SubtaskAction.values)
              if (a.appliesTo(subtask))
                PopoverMenuItem(
                  label: a.labelFor(subtask),
                  onTap: () => Navigator.of(popoverContext).pop(a),
                ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _SubtaskAction.indent:
        _editSubtask(subtask.id, (s) => s.copyWith(level: 1));
      case _SubtaskAction.outdent:
        _editSubtask(subtask.id, (s) => s.copyWith(level: 0));
      case _SubtaskAction.toggleHeading:
        _setSubtasks([
          for (final s in _task.subtasks)
            s.id == subtask.id
                ? TodoSubtask(
                    id: s.id,
                    title: s.title,
                    isDone: false,
                    level: s.isHeading ? s.level : 0,
                    kind: s.isHeading
                        ? TodoSubtaskKind.item
                        : TodoSubtaskKind.heading,
                  )
                : s,
        ]);
      case _SubtaskAction.delete:
        _removeSubtask(subtask.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final task = _task;
    final date = task.dueDate;
    final swatch = task.color == null
        ? null
        : TodoTaskColors.resolve(task.color!, p);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (chipContext) => _DateChip(
                    label: date == null
                        ? 'Someday'
                        : DateFormat('EEE, d MMM').format(date),
                    onTap: () => _pickDay(anchorRectOf(chipContext)),
                  ),
                ),
              ),
            ),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete task',
              onTap: (_) => _delete(),
            ),
            _ActionButton(
              icon: Icons.repeat_rounded,
              label: task.repeats
                  ? 'Repeat: ${task.recurrence!.summary()}'
                  : 'Repeat',
              active: task.repeats,
              onTap: _repeat,
            ),
            _ActionButton(
              label: swatch == null
                  ? 'Colour'
                  : 'Colour: ${TodoTaskColors.nameOf(task.color!)}',
              dot: swatch?.fill,
              icon: Icons.circle_outlined,
              onTap: _colour,
            ),
            _ActionButton(
              icon: task.reminderAt == null
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_outlined,
              label: task.reminderAt == null
                  ? 'Reminder'
                  : 'Reminder: ${DateFormat('d MMM, HH:mm').format(task.reminderAt!)}',
              active: task.reminderAt != null,
              onTap: _reminder,
            ),
            _ActionButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: _more,
            ),
          ],
        ),
        const SizedBox(height: TodoSpace.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _UnderlinedField(
                controller: _title,
                style: type.cardTitle.copyWith(
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
                hint: 'Task title',
                semanticsLabel: 'Task title',
                onChanged: _onTitle,
                maxLines: null,
              ),
            ),
            CheckToggle(
              done: task.isDone,
              label: task.isDone ? 'Mark as not done' : 'Mark as done',
              onChanged: _onDone,
              dimWhenDone: false,
            ),
          ],
        ),
        const SizedBox(height: TodoSpace.m),
        Semantics(
          textField: true,
          label: 'Notes',
          child: TextField(
            controller: _notes,
            onChanged: _onNotes,
            minLines: 2,
            maxLines: null,
            style: type.taskText,
            cursorColor: p.ink,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              hintText: 'Add some extra notes here…',
              hintStyle: type.taskText.copyWith(color: p.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: TodoSpace.s),
        for (var i = 0; i < task.subtasks.length; i++)
          _SubtaskRow(
            key: ValueKey(task.subtasks[i].id),
            subtask: task.subtasks[i],
            autofocus: _fresh.remove(task.subtasks[i].id),
            onTitle: (value) => _editSubtask(
              task.subtasks[i].id,
              (s) => s.copyWith(title: value),
            ),
            onToggle: (done) => _editSubtask(
              task.subtasks[i].id,
              (s) => s.copyWith(isDone: done),
            ),
            onSubmit: () => _addSubtask('', after: i),
            onEmptyBlur: () => _removeSubtask(task.subtasks[i].id),
            onMenu: (anchor) => _subtaskMenu(task.subtasks[i], anchor),
          ),
        _AddSubtaskField(onAdd: _addSubtask),
      ],
    );
  }
}

enum _SubtaskAction {
  indent,
  outdent,
  toggleHeading,
  delete;

  bool appliesTo(TodoSubtask s) => switch (this) {
    indent => !s.isHeading && s.level == 0,
    outdent => !s.isHeading && s.level == 1,
    toggleHeading || delete => true,
  };

  String labelFor(TodoSubtask s) => switch (this) {
    indent => 'Indent',
    outdent => 'Outdent',
    toggleHeading => s.isHeading ? 'Make it a task' : 'Make it a heading',
    delete => 'Delete',
  };
}

/// "Wed, 30 Sep": tapping it picks another day.
class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: 'Day: $label',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TodoSize.minTap),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Container(
                height: TodoSize.controlS,
                padding: const EdgeInsets.symmetric(horizontal: TodoSpace.m),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.ink5,
                  borderRadius: BorderRadius.circular(TodoRadius.pill),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.menuItem,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the five icons on the card: a 36 × 48 slot holding a 32-point
/// circle that turns solid ink while the setting is in use.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.dot,
  });

  final IconData icon;
  final String label;
  final ValueChanged<Rect> onTap;
  final bool active;

  /// A colour to show as a filled dot instead of the icon.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Builder(
      builder: (slotContext) => Semantics(
        button: true,
        selected: active || dot != null,
        label: label,
        onTap: () => onTap(anchorRectOf(slotContext)),
        child: ExcludeSemantics(
          child: Tooltip(
            message: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(anchorRectOf(slotContext));
              },
              child: SizedBox(
                width: 36,
                height: TodoSize.minTap,
                child: Center(
                  child: AnimatedContainer(
                    duration: context.motion.fast,
                    width: TodoSize.controlS,
                    height: TodoSize.controlS,
                    decoration: BoxDecoration(
                      color: active ? p.ink : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: dot != null
                        ? Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            size: TodoSize.icon,
                            color: active ? p.paper : p.ink,
                          ),
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

/// A borderless text field with a line under it that darkens on focus.
class _UnderlinedField extends StatefulWidget {
  const _UnderlinedField({
    required this.controller,
    required this.style,
    required this.hint,
    required this.semanticsLabel,
    required this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final TextStyle style;
  final String hint;
  final String semanticsLabel;
  final ValueChanged<String> onChanged;
  final int? maxLines;

  @override
  State<_UnderlinedField> createState() => _UnderlinedFieldState();
}

class _UnderlinedFieldState extends State<_UnderlinedField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      textField: true,
      label: widget.semanticsLabel,
      child: AnimatedContainer(
        duration: context.motion.fast,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _focus.hasFocus ? p.ink : p.ink15,
              width: TodoSize.hairline,
            ),
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          style: widget.style,
          cursorColor: p.ink,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          onEditingComplete: _focus.unfocus,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            hintText: widget.hint,
            hintStyle: widget.style.copyWith(color: p.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// One entry of the checklist. Enter adds the next one below; emptying an
/// entry and leaving it removes it; a long press opens its menu.
class _SubtaskRow extends StatefulWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.autofocus,
    required this.onTitle,
    required this.onToggle,
    required this.onSubmit,
    required this.onEmptyBlur,
    required this.onMenu,
    super.key,
  });

  final TodoSubtask subtask;
  final bool autofocus;
  final ValueChanged<String> onTitle;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSubmit;
  final VoidCallback onEmptyBlur;
  final ValueChanged<Rect> onMenu;

  @override
  State<_SubtaskRow> createState() => _SubtaskRowState();
}

class _SubtaskRowState extends State<_SubtaskRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.subtask.title,
  );
  final FocusNode _focus = FocusNode();
  bool _hadFocus = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
    if (_focus.hasFocus) {
      _hadFocus = true;
    } else if (_hadFocus && _controller.text.trim().isEmpty && mounted) {
      // Defer: removing the row while its focus is settling would rebuild
      // this subtree mid-change.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEmptyBlur();
      });
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final s = widget.subtask;
    final style = s.isHeading
        ? type.taskText.copyWith(fontWeight: FontWeight.w700)
        : type.taskText.copyWith(
            decoration: s.isDone ? TextDecoration.lineThrough : null,
          );

    return Builder(
      builder: (rowContext) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => widget.onMenu(anchorRectOf(rowContext)),
        child: Padding(
          padding: EdgeInsets.only(left: s.level * TodoSpace.xxl),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: s.isHeading ? 'Heading' : 'Subtask',
                  onLongPress: () => widget.onMenu(anchorRectOf(rowContext)),
                  child: Opacity(
                    opacity: s.isDone ? 0.5 : 1,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      style: style,
                      cursorColor: p.ink,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: widget.onTitle,
                      onEditingComplete: () {
                        if (_controller.text.trim().isEmpty) {
                          _focus.unfocus();
                        } else {
                          widget.onSubmit();
                        }
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              ),
              // Long-pressing a text field selects a word, so the menu has a
              // button of its own, shown while the entry is being edited.
              if (_focused)
                TextFieldTapRegion(
                  child: RoundButton(
                    icon: Icons.more_horiz_rounded,
                    label: 'Subtask options',
                    variant: RoundButtonVariant.soft,
                    size: TodoSize.controlS,
                    onPressed: () => widget.onMenu(anchorRectOf(rowContext)),
                  ),
                ),
              if (!s.isHeading)
                CheckToggle(
                  done: s.isDone,
                  label: s.title.isEmpty
                      ? 'Subtask'
                      : (s.isDone ? '${s.title}, done' : s.title),
                  onChanged: widget.onToggle,
                )
              else
                const SizedBox(width: TodoSize.minTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Add subtask…" at the foot of the checklist. Enter (or leaving the field)
/// adds what was typed and the field stays ready for the next.
class _AddSubtaskField extends StatefulWidget {
  const _AddSubtaskField({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddSubtaskField> createState() => _AddSubtaskFieldState();
}

class _AddSubtaskFieldState extends State<_AddSubtaskField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onAdd(text);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return Semantics(
      textField: true,
      label: 'Add subtask',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: type.taskText,
              cursorColor: p.ink,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onEditingComplete: () {
                _commit();
                _focus.requestFocus();
              },
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintText: 'Add subtask…',
                hintStyle: type.taskText.copyWith(color: p.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: TodoSize.minTap),
        ],
      ),
    );
  }
}
