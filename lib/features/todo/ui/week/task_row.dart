import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// One task on the ruled page.
///
/// A 42-point row with a 1-point line under it. The title sits in a pill that
/// is only *visible* when the task has a colour, but its 6-point side padding
/// is always there, so a title never shifts when it is coloured. A single line
/// with an ellipsis. A ring-and-tick toggle on the right. Done tasks are
/// struck through and dimmed to 50%, and their toggle fills in.
class TaskRow extends StatefulWidget {
  const TaskRow({
    required this.title,
    required this.isDone,
    required this.onToggle,
    required this.onTap,
    this.color,
    this.repeats = false,
    this.hasReminder = false,
    this.onLongPress,
    this.lifted = false,
    this.customActions = const {},
    super.key,
  });

  final String title;
  final bool isDone;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// True while the row is being carried: it loses its line and its press
  /// tint, because it is drawn on a panel of its own.
  final bool lifted;

  /// Extra screen-reader actions (for example "Move up").
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  /// ARGB highlight colour, or null.
  final int? color;
  final bool repeats;
  final bool hasReminder;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _pressed = false;
  bool _hovered = false;

  String get _spoken => [
    widget.title,
    if (widget.isDone) 'done',
    if (widget.repeats) 'repeats',
    if (widget.hasReminder) 'has a reminder',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final motion = context.motion;

    var textStyle = type.taskText;
    Color? fill;
    var iconColor = p.ink;
    final swatch = widget.color;
    if (swatch != null) {
      final style = TodoTaskColors.resolve(swatch, p);
      fill = style.fill;
      textStyle = textStyle.copyWith(color: style.onFill);
      iconColor = style.onFill;
    }
    if (widget.isDone) {
      textStyle = textStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: textStyle.color,
      );
    }

    final ruleColor = widget.lifted
        ? Colors.transparent
        : (_hovered ? p.accent.withValues(alpha: 0.4) : p.rule);

    return Semantics(
      container: true,
      label: _spoken,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      customSemanticsActions: widget.customActions,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: motion.fast,
            curve: motion.ease,
            height: TodoSize.row,
            decoration: BoxDecoration(
              color: _pressed && !widget.lifted ? p.ink5 : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: ruleColor, width: TodoSize.hairline),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: widget.isDone ? 0.5 : 1,
                    child: ExcludeSemantics(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Pill(
                          title: widget.title,
                          fill: fill,
                          style: textStyle,
                          iconColor: iconColor,
                          repeats: widget.repeats,
                          hasReminder: widget.hasReminder,
                        ),
                      ),
                    ),
                  ),
                ),
                _Toggle(
                  isDone: widget.isDone,
                  label: widget.title,
                  onChanged: widget.onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.title,
    required this.fill,
    required this.style,
    required this.iconColor,
    required this.repeats,
    required this.hasReminder,
  });

  final String title;
  final Color? fill;
  final TextStyle style;
  final Color iconColor;
  final bool repeats;
  final bool hasReminder;

  @override
  Widget build(BuildContext context) {
    Widget icon(IconData data) => Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(data, size: 12, color: iconColor),
    );

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: TodoSize.pillPad),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (repeats) icon(Icons.repeat_rounded),
          if (hasReminder) icon(Icons.notifications_none_rounded),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.isDone,
    required this.label,
    required this.onChanged,
  });

  final bool isDone;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    void toggle() {
      HapticFeedback.lightImpact();
      onChanged(!isDone);
    }

    return Semantics(
      label: label,
      checked: isDone,
      onTap: toggle,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: SizedBox(
            width: TodoSize.minTap,
            height: TodoSize.row,
            child: Opacity(
              opacity: isDone ? 0.5 : 1,
              // The ring sits on the right margin, under the end of the rule;
              // the rest of the 48-point target reaches out to its left.
              child: Align(
                alignment: Alignment.centerRight,
                child: CustomPaint(
                  size: const Size.square(TodoSize.icon),
                  painter: _CheckGlyph(
                    done: isDone,
                    ink: p.ink,
                    paper: p.paper,
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

/// A ring with a tick inside; filled solid when the task is done.
class _CheckGlyph extends CustomPainter {
  _CheckGlyph({required this.done, required this.ink, required this.paper});

  final bool done;
  final Color ink;
  final Color paper;

  static const _stroke = 1.68;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    if (done) {
      canvas.drawCircle(center, radius, Paint()..color = ink);
    } else {
      canvas.drawCircle(
        center,
        radius - _stroke / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..color = ink,
      );
    }

    final tick = Path()
      ..moveTo(size.width * 0.29, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.36);
    canvas.drawPath(
      tick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = done ? paper : ink,
    );
  }

  @override
  bool shouldRepaint(_CheckGlyph old) =>
      old.done != done || old.ink != ink || old.paper != paper;
}
