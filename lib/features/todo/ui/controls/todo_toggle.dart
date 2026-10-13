import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// An on/off switch: a 40 × 24 track and an 18-point knob.
///
/// Off, the track is the ink at 50% (≥ 3:1 against the paper, so the control
/// is findable); on, it is the ink at 90%. The knob is the paper colour.
class TodoToggle extends StatelessWidget {
  const TodoToggle({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Spoken by screen readers.
  final String label;

  static const width = 40.0;
  static const height = 24.0;
  static const knob = 18.0;

  void _toggle() {
    HapticFeedback.selectionClick();
    onChanged!(!value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      onTap: enabled ? _toggle : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _toggle : null,
          child: SizedBox(
            width: TodoSize.minTap,
            height: TodoSize.minTap,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: AnimatedContainer(
                  duration: motion.fast,
                  curve: motion.ease,
                  width: width,
                  height: height,
                  padding: const EdgeInsets.all((height - knob) / 2),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: value ? p.ink90 : p.ink50,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      color: p.paper,
                      shape: BoxShape.circle,
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
