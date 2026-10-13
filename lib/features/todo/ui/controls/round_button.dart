import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

enum RoundButtonVariant {
  /// Solid ink with a paper icon: previous / next.
  ink,

  /// A whisper of ink behind an ink icon: search, back, close.
  soft,

  /// The theme accent: the profile avatar.
  accent,
}

/// A circular button, 40 (or 32) points across inside a 48-point touch target.
/// Pressing shifts the fill tone in 100 ms; nothing scales or bounces.
class RoundButton extends StatefulWidget {
  const RoundButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.child,
    this.variant = RoundButtonVariant.ink,
    this.size = TodoSize.controlM,
    super.key,
  }) : assert(icon != null || child != null);

  /// Spoken by screen readers and shown as the tooltip.
  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Replaces the icon (the avatar's initial).
  final Widget? child;
  final RoundButtonVariant variant;

  /// [TodoSize.controlM] or [TodoSize.controlS].
  final double size;

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value && _enabled) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;

    final (fill, pressedFill, foreground) = switch (widget.variant) {
      RoundButtonVariant.ink => (p.ink, p.ink75, p.paper),
      RoundButtonVariant.soft => (p.ink5, p.ink15, p.ink),
      RoundButtonVariant.accent => (
        p.accent,
        Color.lerp(p.accent, p.ink, 0.2)!,
        p.onAccent,
      ),
    };
    final iconSize = widget.size >= TodoSize.controlM ? TodoSize.icon : 18.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: Tooltip(
          message: widget.label,
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
            child: SizedBox(
              width: TodoSize.minTap,
              height: TodoSize.minTap,
              child: Center(
                child: Opacity(
                  opacity: _enabled ? 1 : 0.4,
                  child: AnimatedContainer(
                    duration: motion.fast,
                    curve: motion.ease,
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: _pressed ? pressedFill : fill,
                      shape: BoxShape.circle,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: foreground, size: iconSize),
                      child: DefaultTextStyle(
                        style: context.type.button.copyWith(color: foreground),
                        child: Center(child: widget.child ?? Icon(widget.icon)),
                      ),
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
