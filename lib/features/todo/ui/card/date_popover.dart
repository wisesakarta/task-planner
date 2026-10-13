import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';
import 'package:todo_app/features/todo/ui/week/week_dates.dart';

/// What the user chose in the date popover. `date == null` means "Someday"
/// (no day). A null *result* from [showDatePopover] means it was dismissed.
class DateSelection {
  const DateSelection(this.date);

  final DateTime? date;
}

Future<DateSelection?> showDatePopover(
  BuildContext context, {
  required Rect anchor,
  required DateTime? selected,
  required DateTime today,
  int weekStartsOn = DateTime.monday,
}) {
  return showTodoPopover<DateSelection>(
    context,
    anchor: anchor,
    builder: (popoverContext) => DatePopover(
      selected: selected,
      today: today,
      weekStartsOn: weekStartsOn,
      onSelected: (selection) => Navigator.of(popoverContext).pop(selection),
    ),
  );
}

/// A month grid (‹ September 2026 ›), seven columns of 40-point days, the
/// chosen day in solid ink, today ringed in the accent, and a "Someday" pill
/// that removes the date.
class DatePopover extends StatefulWidget {
  const DatePopover({
    required this.selected,
    required this.today,
    required this.onSelected,
    this.weekStartsOn = DateTime.monday,
    super.key,
  });

  final DateTime? selected;
  final DateTime today;
  final int weekStartsOn;
  final ValueChanged<DateSelection> onSelected;

  @override
  State<DatePopover> createState() => _DatePopoverState();
}

class _DatePopoverState extends State<DatePopover> {
  late DateTime _month = DateTime(
    (widget.selected ?? widget.today).year,
    (widget.selected ?? widget.today).month,
  );

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// The cells of the grid: leading blanks, then the days of the month.
  List<DateTime?> get _cells {
    final first = DateTime(_month.year, _month.month);
    final lead = widget.weekStartsOn == DateTime.sunday
        ? first.weekday % 7
        : first.weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    return [
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= count; d++) DateTime(_month.year, _month.month, d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final headers = widget.weekStartsOn == DateTime.sunday
        ? const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final cells = _cells;
    final rows = (cells.length / 7).ceil();

    return PopoverSurface(
      width: 7 * 40.0 + TodoSpace.l * 2,
      padding: const EdgeInsets.all(TodoSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RoundButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous month',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM y').format(_month),
                    style: type.menuItem.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              RoundButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next month',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          Row(
            children: [
              for (final h in headers)
                SizedBox(
                  width: 40,
                  height: 28,
                  child: Center(child: Text(h, style: type.caption)),
                ),
            ],
          ),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  _DayCell(
                    date: row * 7 + col < cells.length
                        ? cells[row * 7 + col]
                        : null,
                    selected:
                        cells.length > row * 7 + col &&
                        cells[row * 7 + col] != null &&
                        widget.selected != null &&
                        WeekDates.sameDay(
                          cells[row * 7 + col]!,
                          widget.selected!,
                        ),
                    isToday:
                        cells.length > row * 7 + col &&
                        cells[row * 7 + col] != null &&
                        WeekDates.sameDay(cells[row * 7 + col]!, widget.today),
                    onTap: (date) => widget.onSelected(DateSelection(date)),
                  ),
              ],
            ),
          const SizedBox(height: TodoSpace.s),
          PillButton(
            label: 'Someday',
            variant: PillVariant.soft,
            onPressed: () => widget.onSelected(const DateSelection(null)),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime? date;
  final bool selected;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = date;
    if (d == null) return const SizedBox(width: 40, height: 40);

    return Semantics(
      button: true,
      selected: selected,
      label: [
        DateFormat('EEEE, d MMMM').format(d),
        if (isToday) 'today',
      ].join(', '),
      onTap: () => onTap(d),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(d);
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !selected
                      ? Border.all(color: p.accent, width: 2)
                      : null,
                ),
                child: Text(
                  '${d.day}',
                  style: context.type.menuItem.copyWith(
                    color: selected ? p.paper : p.ink,
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w400,
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
