import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/controls/segmented_control.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

/// What the user chose in the repeat menu. `rule == null` means "Never".
/// A null *result* from [showRepeatMenu] means the menu was dismissed.
class RepeatSelection {
  const RepeatSelection(this.rule);

  final RecurrenceRule? rule;
}

class RepeatPreset {
  const RepeatPreset(this.label, this.rule);

  final String label;
  final RecurrenceRule rule;
}

/// The presets, in menu order.
const repeatPresets = [
  RepeatPreset('Daily', RecurrenceRule.daily()),
  RepeatPreset('Weekly', RecurrenceRule.weekly()),
  RepeatPreset('Weekdays', RecurrenceRule.weekdays()),
  RepeatPreset('Biweekly', RecurrenceRule.weekly(2)),
  RepeatPreset('Monthly', RecurrenceRule.monthly()),
  RepeatPreset('Annually', RecurrenceRule.yearly()),
];

/// Opens the repeat menu under [anchor]: Never, the presets, and Custom.
Future<RepeatSelection?> showRepeatMenu(
  BuildContext context, {
  required Rect anchor,
  required RecurrenceRule? current,
}) {
  return showTodoPopover<RepeatSelection>(
    context,
    anchor: anchor,
    builder: (popoverContext) => RepeatMenu(
      current: current,
      onSelected: (selection) => Navigator.of(popoverContext).pop(selection),
    ),
  );
}

class RepeatMenu extends StatefulWidget {
  const RepeatMenu({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final RecurrenceRule? current;
  final ValueChanged<RepeatSelection> onSelected;

  @override
  State<RepeatMenu> createState() => _RepeatMenuState();
}

class _RepeatMenuState extends State<RepeatMenu> {
  bool _custom = false;

  bool get _isCustom =>
      widget.current != null &&
      !repeatPresets.any((preset) => preset.rule == widget.current);

  @override
  Widget build(BuildContext context) {
    if (_custom) {
      return CustomRepeatPanel(
        initial: widget.current,
        onBack: () => setState(() => _custom = false),
        onApply: (rule) => widget.onSelected(RepeatSelection(rule)),
      );
    }

    return PopoverSurface(
      width: 240,
      fill: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopoverMenuItem(
            reserveCheck: true,
            label: 'Never',
            selected: widget.current == null,
            onTap: () => widget.onSelected(const RepeatSelection(null)),
          ),
          const PopoverDivider(),
          for (final preset in repeatPresets)
            PopoverMenuItem(
              reserveCheck: true,
              label: preset.label,
              selected: widget.current == preset.rule,
              onTap: () => widget.onSelected(RepeatSelection(preset.rule)),
            ),
          PopoverMenuItem(
            reserveCheck: true,
            label: 'Custom',
            selected: _isCustom,
            chevron: true,
            onTap: () => setState(() => _custom = true),
          ),
        ],
      ),
    );
  }
}

enum _Unit {
  day('Day', RecurrenceUnit.day),
  week('Week', RecurrenceUnit.week),
  month('Month', RecurrenceUnit.month),
  year('Year', RecurrenceUnit.year);

  const _Unit(this.label, this.unit);

  final String label;
  final RecurrenceUnit unit;
}

/// "Every [−] 2 [+]" and a unit, with the sentence it makes.
class CustomRepeatPanel extends StatefulWidget {
  const CustomRepeatPanel({
    required this.initial,
    required this.onBack,
    required this.onApply,
    super.key,
  });

  final RecurrenceRule? initial;
  final VoidCallback onBack;
  final ValueChanged<RecurrenceRule> onApply;

  @override
  State<CustomRepeatPanel> createState() => _CustomRepeatPanelState();
}

class _CustomRepeatPanelState extends State<CustomRepeatPanel> {
  late int _interval = widget.initial?.interval ?? 1;
  late _Unit _unit = _Unit.values.firstWhere(
    (u) => u.unit == (widget.initial?.unit ?? RecurrenceUnit.week),
  );

  RecurrenceRule get _rule =>
      RecurrenceRule(unit: _unit.unit, interval: _interval);

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return PopoverSurface(
      width: 296,
      padding: const EdgeInsets.all(TodoSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RoundButton(
                icon: Icons.chevron_left_rounded,
                label: 'Back to repeat options',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Center(child: Text('Repeat', style: type.menuItem)),
              ),
              const SizedBox(width: TodoSize.minTap),
            ],
          ),
          const SizedBox(height: TodoSpace.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Every', style: type.taskText),
              const SizedBox(width: TodoSpace.s),
              RoundButton(
                icon: Icons.remove_rounded,
                label: 'Decrease interval',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: _interval > 1
                    ? () => setState(
                        () => _interval = (_interval - 1).clamp(1, 99),
                      )
                    : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_interval',
                  textAlign: TextAlign.center,
                  style: type.cardTitle.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              RoundButton(
                icon: Icons.add_rounded,
                label: 'Increase interval',
                variant: RoundButtonVariant.soft,
                size: TodoSize.controlS,
                onPressed: _interval < 99
                    ? () => setState(
                        () => _interval = (_interval + 1).clamp(1, 99),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: TodoSpace.s),
          SegmentedControl<_Unit>(
            options: [
              for (final unit in _Unit.values)
                SegmentedOption(value: unit, label: unit.label),
            ],
            value: _unit,
            onChanged: (unit) => setState(() => _unit = unit),
          ),
          const SizedBox(height: TodoSpace.m),
          Center(child: Text(_rule.summary(), style: type.caption)),
          const SizedBox(height: TodoSpace.m),
          PillButton(label: 'Apply', onPressed: () => widget.onApply(_rule)),
        ],
      ),
    );
  }
}
