import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// Drawn above the label when set.
  final IconData? icon;
}

/// A solid-ink strip with the chosen segment lifted out in the sheet colour.
/// Radius 12, 3-point inset, segments radius 9; the fill changes in 100 ms.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  }) : assert(options.length >= 2);

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(TodoRadius.m),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  Expanded(
                    child: _Segment<T>(
                      option: option,
                      selected: option.value == value,
                      onTap: () {
                        if (option.value == value) return;
                        HapticFeedback.selectionClick();
                        onChanged(option.value);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SegmentedOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final foreground = selected ? p.ink : p.paper;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: option.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: motion.fast,
            curve: motion.ease,
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.all(TodoSpace.s),
            decoration: BoxDecoration(
              color: selected ? p.sheet : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: TodoSize.icon, color: foreground),
                  const SizedBox(height: TodoSpace.xs),
                ],
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: context.type.menuItem.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
