import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// The ring-and-tick check used on the task card and its subtasks.
///
/// Checking fills the ring and draws the tick with the one playful motion in
/// the app: a 300 ms overshoot that swells past the ring and settles back.
/// Unchecking is instant. The touch target is 48 points square.
class CheckToggle extends StatelessWidget {
  const CheckToggle({
    required this.done,
    required this.onChanged,
    required this.label,
    this.dimWhenDone = true,
    super.key,
  });

  final bool done;
  final ValueChanged<bool> onChanged;

  /// Spoken by screen readers (the title of what is being checked).
  final String label;

  /// Fade the glyph to 50% once checked, like a finished row.
  final bool dimWhenDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;

    void toggle() {
      HapticFeedback.lightImpact();
      onChanged(!done);
    }

    return Semantics(
      label: label,
      checked: done,
      onTap: toggle,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: SizedBox(
            width: TodoSize.minTap,
            height: TodoSize.minTap,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done ? 1 : 0),
                // Checking overshoots; unchecking snaps back at once.
                duration: done ? motion.check : Duration.zero,
                curve: motion.overshoot,
                builder: (context, t, _) => Opacity(
                  opacity: done && dimWhenDone ? 0.5 : 1,
                  child: CustomPaint(
                    size: const Size.square(TodoSize.icon),
                    painter: CheckGlyphPainter(
                      progress: t,
                      ink: p.ink,
                      paper: p.paper,
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

/// A ring with a tick inside. [progress] 0 is an empty ring, 1 a solid disc
/// with a paper tick; values past 1 (the overshoot) swell the disc slightly.
class CheckGlyphPainter extends CustomPainter {
  CheckGlyphPainter({
    required this.progress,
    required this.ink,
    required this.paper,
  });

  final double progress;
  final Color ink;
  final Color paper;

  static const _stroke = 1.68;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final fill = progress.clamp(0.0, 1.0);
    final swell = progress.clamp(0.0, 1.15);

    canvas.drawCircle(
      center,
      radius - _stroke / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = ink,
    );
    if (progress > 0) {
      canvas.drawCircle(center, radius * swell, Paint()..color = ink);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 + (swell - fill) * 0.5);
    canvas.translate(-center.dx, -center.dy);
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
        ..color = Color.lerp(ink, paper, fill)!,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CheckGlyphPainter old) =>
      old.progress != progress || old.ink != ink || old.paper != paper;
}
