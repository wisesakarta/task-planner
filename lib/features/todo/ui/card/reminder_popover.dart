import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

/// What the user chose in the reminder popover. `at == null` means "remove
/// the reminder". A null *result* from [showReminderPopover] means dismissed.
class ReminderSelection {
  const ReminderSelection(this.at);

  final DateTime? at;
}

Future<ReminderSelection?> showReminderPopover(
  BuildContext context, {
  required Rect anchor,
  required DateTime? current,
  required DateTime fallbackDate,
  DateTime? now,
}) {
  return showTodoPopover<ReminderSelection>(
    context,
    anchor: anchor,
    builder: (popoverContext) => ReminderPopover(
      current: current,
      fallbackDate: fallbackDate,
      now: now,
      onSelected: (selection) => Navigator.of(popoverContext).pop(selection),
    ),
  );
}

/// A day (‹ 30 Sep 2026 ›), an hour and a minute (each with steppers), and a
/// "Set reminder" pill. When a reminder already exists there is also a
/// "Remove reminder" pill.
///
/// A new reminder starts at the next five-minute mark from now, as Tweek
/// starts at the current time. A time that has passed cannot be set: it
/// would never ring, and accepting it silently is how a reminder goes missing.
class ReminderPopover extends StatefulWidget {
  const ReminderPopover({
    required this.current,
    required this.fallbackDate,
    required this.onSelected,
    this.now,
    super.key,
  });

  /// The existing reminder, if any.
  final DateTime? current;

  /// The day shown when there is no reminder yet (the task's day, or today
  /// when the task's day has passed).
  final DateTime fallbackDate;
  final ValueChanged<ReminderSelection> onSelected;

  /// The current time; [DateTime.now] when null.
  final DateTime? now;

  @override
  State<ReminderPopover> createState() => _ReminderPopoverState();
}

class _ReminderPopoverState extends State<ReminderPopover> {
  static const _minuteStep = 5;

  late final DateTime _now = widget.now ?? DateTime.now();
  late final DateTime _today = _dayOf(_now);

  /// The first five-minute mark after now: 17:16 and 17:15 both give 17:20.
  late final DateTime _soon = DateTime(
    _now.year,
    _now.month,
    _now.day,
    _now.hour,
    (_now.minute ~/ _minuteStep + 1) * _minuteStep,
  );

  late DateTime _day = _dayOf(widget.current ?? _defaultStart);
  late int _hour = (widget.current ?? _defaultStart).hour;
  late int _minute = (widget.current ?? _defaultStart).minute;

  /// The next five-minute mark, moved to the task's day when that day is
  /// still ahead.
  DateTime get _defaultStart {
    final fallback = _dayOf(widget.fallbackDate);
    if (!fallback.isAfter(_dayOf(_soon))) return _soon;
    return DateTime(
      fallback.year,
      fallback.month,
      fallback.day,
      _soon.hour,
      _soon.minute,
    );
  }

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  DateTime get _chosen =>
      DateTime(_day.year, _day.month, _day.day, _hour, _minute);

  bool get _passed => !_chosen.isAfter(_now);

  void _shiftDay(int delta) =>
      setState(() => _day = DateTime(_day.year, _day.month, _day.day + delta));

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return PopoverSurface(
      width: 260,
      padding: const EdgeInsets.all(TodoSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RoundButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous day',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                // Days before today can never ring.
                onPressed: _day.isAfter(_today) ? () => _shiftDay(-1) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('d MMM y').format(_day),
                    style: type.menuItem.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              RoundButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next day',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: () => _shiftDay(1),
              ),
            ],
          ),
          const SizedBox(height: TodoSpace.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeStepper(
                label: 'Hour',
                value: _hour,
                onUp: () => setState(() => _hour = (_hour + 1) % 24),
                onDown: () => setState(() => _hour = (_hour + 23) % 24),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TodoSpace.m),
                child: Text(':', style: type.cardTitle),
              ),
              _TimeStepper(
                label: 'Minute',
                value: _minute,
                onUp: () =>
                    setState(() => _minute = (_minute + _minuteStep) % 60),
                onDown: () =>
                    setState(() => _minute = (_minute + 60 - _minuteStep) % 60),
              ),
            ],
          ),
          const SizedBox(height: TodoSpace.s),
          if (_passed)
            Padding(
              padding: const EdgeInsets.only(bottom: TodoSpace.s),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  'This time has passed',
                  textAlign: TextAlign.center,
                  style: type.caption,
                ),
              ),
            ),
          PillButton(
            label: 'Set reminder',
            onPressed: _passed
                ? null
                : () => widget.onSelected(ReminderSelection(_chosen)),
          ),
          if (widget.current != null) ...[
            const SizedBox(height: TodoSpace.s),
            PillButton(
              label: 'Remove reminder',
              variant: PillVariant.outlined,
              onPressed: () => widget.onSelected(const ReminderSelection(null)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A two-digit value with a chevron above and below it.
class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.value,
    required this.onUp,
    required this.onDown,
  });

  final String label;
  final int value;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = value.toString().padLeft(2, '0');

    return Semantics(
      label: label,
      value: digits,
      increasedValue: label == 'Hour'
          ? ((value + 1) % 24).toString().padLeft(2, '0')
          : ((value + 5) % 60).toString().padLeft(2, '0'),
      decreasedValue: label == 'Hour'
          ? ((value + 23) % 24).toString().padLeft(2, '0')
          : ((value + 55) % 60).toString().padLeft(2, '0'),
      onIncrease: onUp,
      onDecrease: onDown,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RepeatWhileHeld(
              onRepeat: onUp,
              child: RoundButton(
                icon: Icons.keyboard_arrow_up_rounded,
                label: 'Increase ${label.toLowerCase()}',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: onUp,
              ),
            ),
            Container(
              width: 56,
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.ink15)),
              ),
              child: Text(
                digits,
                textAlign: TextAlign.center,
                style: context.type.cardTitle.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _RepeatWhileHeld(
              onRepeat: onDown,
              child: RoundButton(
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Decrease ${label.toLowerCase()}',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: onDown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps stepping while a stepper button is held, so 04 to 17 is one press
/// rather than thirteen taps. A short tap still steps once, through the
/// button. Raw pointer events rather than a long-press recognizer: the
/// button's tooltip would win that gesture.
class _RepeatWhileHeld extends StatefulWidget {
  const _RepeatWhileHeld({required this.onRepeat, required this.child});

  final VoidCallback onRepeat;
  final Widget child;

  @override
  State<_RepeatWhileHeld> createState() => _RepeatWhileHeldState();
}

class _RepeatWhileHeldState extends State<_RepeatWhileHeld> {
  static const _delay = Duration(milliseconds: 400);
  static const _interval = Duration(milliseconds: 90);

  Timer? _timer;

  void _down(PointerDownEvent _) {
    _stop();
    _timer = Timer(_delay, () {
      widget.onRepeat();
      _timer = Timer.periodic(_interval, (_) => widget.onRepeat());
    });
  }

  void _stop([PointerEvent? _]) {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _stop,
    onPointerCancel: _stop,
    child: widget.child,
  );
}
