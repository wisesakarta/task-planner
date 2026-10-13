import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_task_colors.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

/// What the user chose in the colour popover. `argb == null` means "no
/// colour". A null *result* from [showColorPopover] means it was dismissed.
class ColorSelection {
  const ColorSelection(this.argb);

  final int? argb;
}

Future<ColorSelection?> showColorPopover(
  BuildContext context, {
  required Rect anchor,
  required int? selected,
}) {
  return showTodoPopover<ColorSelection>(
    context,
    anchor: anchor,
    builder: (popoverContext) => ColorPopover(
      selected: selected,
      onSelected: (selection) => Navigator.of(popoverContext).pop(selection),
    ),
  );
}

/// A grid of colour dots, five to a row: "no colour", eight colours, and a "+"
/// that reveals eight more. Each dot is a 24-point circle in a cell a fifth of
/// the panel wide; the chosen one is ringed in ink.
class ColorPopover extends StatefulWidget {
  const ColorPopover({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int? selected;
  final ValueChanged<ColorSelection> onSelected;

  @override
  State<ColorPopover> createState() => _ColorPopoverState();
}

class _ColorPopoverState extends State<ColorPopover> {
  late bool _extended = TodoTaskColors.extendedSwatches.any(
    (swatch) => swatch.argb == widget.selected,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = widget.selected;

    return PopoverSurface(
      width: _columns * 48.0 + TodoSpace.s * 2,
      fill: true,
      padding: const EdgeInsets.all(TodoSpace.s),
      child: LayoutBuilder(
        builder: (context, box) {
          final cell =
              (box.maxWidth.isFinite ? box.maxWidth : _columns * 48.0) /
              _columns;
          return Wrap(
            children: [
              _Dot(
                width: cell,
                label: 'No colour',
                selected: selected == null,
                fill: null,
                onTap: () => widget.onSelected(const ColorSelection(null)),
              ),
              for (final swatch in TodoTaskColors.swatches)
                _Dot(
                  width: cell,
                  label: swatch.name,
                  selected: selected == swatch.argb,
                  fill: TodoTaskColors.resolve(swatch.argb, p).fill,
                  onTap: () => widget.onSelected(ColorSelection(swatch.argb)),
                ),
              _PlusDot(
                width: cell,
                expanded: _extended,
                onTap: () => setState(() => _extended = !_extended),
              ),
              if (_extended)
                for (final swatch in TodoTaskColors.extendedSwatches)
                  _Dot(
                    width: cell,
                    label: swatch.name,
                    selected: selected == swatch.argb,
                    fill: TodoTaskColors.resolve(swatch.argb, p).fill,
                    onTap: () => widget.onSelected(ColorSelection(swatch.argb)),
                  ),
            ],
          );
        },
      ),
    );
  }

  static const _columns = 5;
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.width,
    required this.label,
    required this.selected,
    required this.fill,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;

  /// Null draws the "no colour" outline.
  final Color? fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: width,
            height: 44,
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
                    color: fill,
                    shape: BoxShape.circle,
                    border: fill == null
                        ? Border.all(color: p.ink25, width: 1.5)
                        : null,
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

class _PlusDot extends StatelessWidget {
  const _PlusDot({
    required this.width,
    required this.expanded,
    required this.onTap,
  });

  final double width;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: expanded ? 'Show fewer colours' : 'More colours',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: 44,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: p.ink5,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expanded ? Icons.remove_rounded : Icons.add_rounded,
                  size: 16,
                  color: p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
