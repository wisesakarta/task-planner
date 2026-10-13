import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

enum PillVariant {
  /// Solid ink: the one main action of a card ("Apply", "Ok").
  primary,

  /// A thin ink outline: the alternative ("Cancel").
  outlined,

  /// A whisper of ink: quiet actions ("Add calendar", "Create new").
  soft,
}

/// A 40-point pill button. Text is 17 bold; the shape is fully rounded.
class PillButton extends StatefulWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.expand = true,
    this.destructive = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final PillVariant variant;

  /// Fill the width (default) or wrap the label.
  final bool expand;

  /// Draws the label in the danger colour ("Log out", "Delete").
  final bool destructive;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value && _enabled) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;

    final (fill, pressedFill, foreground, border) = switch (widget.variant) {
      PillVariant.primary => (p.ink, p.ink75, p.paper, null),
      PillVariant.outlined => (
        Colors.transparent,
        p.ink5,
        p.ink,
        BorderSide(color: p.ink, width: 0.67),
      ),
      PillVariant.soft => (p.ink5, p.ink15, p.ink, null),
    };
    final textColor = widget.destructive ? p.danger : foreground;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                },
          child: Opacity(
            opacity: _enabled ? 1 : 0.4,
            child: AnimatedContainer(
              duration: motion.fast,
              curve: motion.ease,
              constraints: const BoxConstraints(
                minHeight: TodoSize.controlM,
                minWidth: TodoSize.controlM,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TodoSpace.xxl,
                vertical: TodoSpace.s,
              ),
              alignment: widget.expand ? Alignment.center : null,
              decoration: BoxDecoration(
                color: _pressed ? pressedFill : fill,
                borderRadius: BorderRadius.circular(22),
                border: border == null ? null : Border.fromBorderSide(border),
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: context.type.button.copyWith(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
