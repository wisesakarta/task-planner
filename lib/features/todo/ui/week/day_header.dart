import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// The head of a day: the date in bold on the left, the weekday in regular on
/// the right, and a 2-point rule underneath. Today's date, weekday and rule
/// take the theme accent. 42 points tall, rule included.
class DayHeader extends StatelessWidget {
  const DayHeader({required this.date, this.isToday = false, super.key});

  final DateTime date;
  final bool isToday;

  String get _spoken => [
    DateFormat('EEEE, d MMMM').format(date),
    if (isToday) 'today',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final accent = isToday;

    return Semantics(
      header: true,
      label: _spoken,
      child: ExcludeSemantics(
        child: Container(
          height: TodoSize.row,
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: accent ? p.accent : p.ink,
                width: TodoSize.dayRule,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // With very large text on a narrow phone both give way, the
            // weekday first, instead of running off the edge.
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  DateFormat('d MMM').format(date),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: type.dayDate.copyWith(
                    color: accent ? p.accentInk : p.ink,
                  ),
                ),
              ),
              const SizedBox(width: TodoSpace.s),
              Flexible(
                child: Text(
                  DateFormat('EEE').format(date),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: type.dayName.copyWith(
                    color: accent ? p.accentInk : p.textSecondary,
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
