import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/month/month_rows.dart';
import 'package:todo_app/features/todo/ui/week/week_dates.dart';

/// The Month view: every month in one long vertical scroll.
///
/// The top bar shows the year and two arrows that move a month at a time;
/// under it, one letter per weekday. Each row is one week (split where a month
/// ends), each cell a day: the number (today's on a pale wash of the accent),
/// then that day's tasks as one-line pills. Tapping a day opens its
/// week; tapping a task opens it.
///
/// It only draws; the tasks and what a tap does come from the caller.
class MonthScreen extends StatefulWidget {
  const MonthScreen({
    required this.today,
    required this.tasks,
    required this.onSelectDay,
    required this.onOpenTask,
    this.weekStartsOn = DateTime.monday,
    this.monthsBefore = 24,
    this.monthsAfter = 36,
    super.key,
  });

  final DateTime today;
  final List<TodoTask> tasks;

  /// A day was tapped: show its week.
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<TodoTask> onOpenTask;
  final int weekStartsOn;

  /// How many months the scroll reaches before and after this month.
  final int monthsBefore;
  final int monthsAfter;

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  late List<MonthRow> _rows;
  late List<double> _offsets; // _offsets[i] = top of row i
  late final ScrollController _controller;
  final ValueNotifier<int> _year = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _build();
    _controller = ScrollController(initialScrollOffset: _initialOffset())
      ..addListener(_onScroll);
    _year.value = _yearAt(_controller.initialScrollOffset);
  }

  @override
  void didUpdateWidget(MonthScreen old) {
    super.didUpdateWidget(old);
    if (old.weekStartsOn != widget.weekStartsOn ||
        old.today != widget.today ||
        old.monthsBefore != widget.monthsBefore ||
        old.monthsAfter != widget.monthsAfter) {
      _build();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _year.dispose();
    super.dispose();
  }

  void _build() {
    final today = widget.today;
    _rows = buildMonthRows(
      from: DateTime(today.year, today.month - widget.monthsBefore),
      to: DateTime(today.year, today.month + widget.monthsAfter),
      weekStartsOn: widget.weekStartsOn,
    );
    var top = 0.0;
    _offsets = [
      for (final row in _rows)
        () {
          final at = top;
          top += row.height;
          return at;
        }(),
    ];
  }

  /// Index of the row that contains [day].
  int _rowOf(DateTime day) {
    for (var i = 0; i < _rows.length; i++) {
      if (_rows[i].cells.any((c) => c != null && WeekDates.sameDay(c, day))) {
        return i;
      }
    }
    return 0;
  }

  /// Opens at the top of this month, so its name and first week lead the screen.
  double _initialOffset() {
    final row = _rowOf(widget.today);
    // Back up to the first row of the month.
    var start = row;
    while (start > 0 && !_rows[start].startsMonth) {
      start--;
    }
    return _offsets[start];
  }

  int _rowAt(double offset) {
    var low = 0;
    var high = _rows.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_offsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  int _yearAt(double offset) => _rows[_rowAt(offset)].firstDay.year;

  void _onScroll() {
    final year = _yearAt(_controller.offset);
    if (year != _year.value) _year.value = year;
  }

  /// Scrolls to the start of the previous (−1) or next (+1) month.
  void _moveMonth(int direction) {
    final here = _controller.offset;
    final starts = [
      for (var i = 0; i < _rows.length; i++)
        if (_rows[i].startsMonth) _offsets[i],
    ];
    double? target;
    if (direction > 0) {
      target = starts.cast<double?>().firstWhere(
        (o) => o! > here + 1,
        orElse: () => null,
      );
    } else {
      target = starts.cast<double?>().lastWhere(
        (o) => o! < here - 1,
        orElse: () => null,
      );
    }
    if (target == null) return;
    final motion = context.motion;
    _controller.animateTo(
      target.clamp(0, _controller.position.maxScrollExtent),
      duration: motion.medium,
      curve: motion.ease,
    );
  }

  List<TodoTask> _tasksOn(DateTime day) => [
    for (final task in widget.tasks)
      if (!task.isDeleted &&
          task.dueDate != null &&
          WeekDates.sameDay(task.dueDate!, day))
        task,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _year,
                builder: (context, year, _) => _MonthTopBar(
                  year: year,
                  onPrevious: () => _moveMonth(-1),
                  onNext: () => _moveMonth(1),
                ),
              ),
              _WeekdayHeader(weekStartsOn: widget.weekStartsOn),
              Divider(height: 1, thickness: 1, color: p.rule),
              Expanded(
                child: ListView.builder(
                  controller: _controller,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  itemCount: _rows.length,
                  itemExtentBuilder: (index, _) => _rows[index].height,
                  itemBuilder: (context, index) => _MonthRowView(
                    row: _rows[index],
                    today: widget.today,
                    tasksOn: _tasksOn,
                    onSelectDay: widget.onSelectDay,
                    onOpenTask: widget.onOpenTask,
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

class _MonthTopBar extends StatelessWidget {
  const _MonthTopBar({
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: 'Month view, $year',
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('$year', maxLines: 1, style: context.type.title),
                ),
              ),
            ),
          ),
          RoundButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous month',
            onPressed: onPrevious,
          ),
          RoundButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next month',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// One letter per weekday above the grid; Saturday and Sunday are quieter.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStartsOn});

  final int weekStartsOn;

  static const _letters = {
    DateTime.monday: 'M',
    DateTime.tuesday: 'T',
    DateTime.wednesday: 'W',
    DateTime.thursday: 'T',
    DateTime.friday: 'F',
    DateTime.saturday: 'S',
    DateTime.sunday: 'S',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MonthMetrics.margin,
        TodoSpace.s,
        MonthMetrics.margin,
        TodoSpace.s,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final weekday = (weekStartsOn - 1 + i) % 7 + 1;
                  final weekend =
                      weekday == DateTime.saturday ||
                      weekday == DateTime.sunday;
                  return Semantics(
                    label: DateFormat('EEEE').format(
                      // 2026-09-28 is a Monday.
                      DateTime(2026, 9, 27 + weekday),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        _letters[weekday]!,
                        textAlign: TextAlign.center,
                        style: type.small.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: weekend ? p.textSecondary : p.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthRowView extends StatelessWidget {
  const _MonthRowView({
    required this.row,
    required this.today,
    required this.tasksOn,
    required this.onSelectDay,
    required this.onOpenTask,
  });

  final MonthRow row;
  final DateTime today;
  final List<TodoTask> Function(DateTime day) tasksOn;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<TodoTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MonthMetrics.margin),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 7;

          return Column(
            children: [
              if (row.startsMonth)
                SizedBox(
                  height: MonthMetrics.labelHeight,
                  child: Stack(
                    children: [
                      // Centred on the column of the 1st, however wide the name
                      // is (it is wider than one column): so it is placed by its
                      // centre, not boxed into the column.
                      Positioned(
                        left: row.labelColumn * cell + cell / 2,
                        top: 0,
                        bottom: 0,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0),
                          child: Center(
                            child: Semantics(
                              header: true,
                              child: Text(
                                DateFormat('MMMM').format(row.monthStart!),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: context.type.heading.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    for (final day in row.cells)
                      SizedBox(
                        width: cell,
                        // The line above a day belongs to the day: a partial
                        // row at a month's edge is only ruled where it has days.
                        child: day == null
                            ? null
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: p.rule,
                                      width: TodoSize.hairline,
                                    ),
                                  ),
                                ),
                                child: _DayCell(
                                  day: day,
                                  isToday: WeekDates.sameDay(day, today),
                                  tasks: tasksOn(day),
                                  onTap: () => onSelectDay(day),
                                  onOpenTask: onOpenTask,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.tasks,
    required this.onTap,
    required this.onOpenTask,
  });

  final DateTime day;
  final bool isToday;
  final List<TodoTask> tasks;
  final VoidCallback onTap;
  final ValueChanged<TodoTask> onOpenTask;

  String get _spoken {
    final date = DateFormat('EEEE, d MMMM').format(day);
    final count = tasks.isEmpty
        ? 'no tasks'
        : '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}';
    return [date, if (isToday) 'today', count].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final capacity = MonthMetrics.pillCapacity;
    final overflow = tasks.length > capacity;
    final shown = overflow ? tasks.take(capacity - 1).toList() : tasks;

    return Semantics(
      container: true,
      button: true,
      label: _spoken,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.only(top: MonthMetrics.numberTop),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Center(
                  child: Container(
                    width: MonthMetrics.numberSize,
                    height: MonthMetrics.numberSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // Today is a pale wash of the accent, not a solid disc.
                      color: isToday
                          ? Color.alphaBlend(
                              p.accent.withValues(alpha: 0.18),
                              p.paper,
                            )
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: type.small.copyWith(
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isToday
                            ? p.ink
                            : (weekend ? p.textSecondary : p.ink),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MonthMetrics.numberGap),
              for (final task in shown)
                _TaskPill(task: task, onTap: () => onOpenTask(task)),
              if (overflow)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      '+${tasks.length - shown.length} more',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: type.small.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: p.textSecondary,
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

/// One task in a day cell: a 16-point pill, one line, in the task's colour (or
/// a whisper of ink when it has none). A finished task is struck through and
/// dimmed.
class _TaskPill extends StatelessWidget {
  const _TaskPill({required this.task, required this.onTap});

  final TodoTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = task.color;
    final style = color == null ? null : TodoTaskColors.resolve(color, p);

    return Semantics(
      button: true,
      label: task.isDone ? '${task.title}, done' : task.title,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: MonthMetrics.pillHeight,
            margin: const EdgeInsets.only(bottom: MonthMetrics.pillGap),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: style?.fill ?? p.ink5,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Opacity(
              opacity: task.isDone ? 0.5 : 1,
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: context.type.small.copyWith(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: style?.onFill ?? p.ink,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
