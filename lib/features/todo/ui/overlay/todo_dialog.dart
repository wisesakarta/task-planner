import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_motion.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// The face of every floating card: a 24-point radius, 24 points of padding,
/// and a colour that says what it is (the sheet tint for a task, the alert
/// tint for a confirmation, the paper for search).
class TodoDialogSurface extends StatelessWidget {
  const TodoDialogSurface({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.palette.sheet,
        borderRadius: BorderRadius.circular(TodoRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TodoSize.dialogPad),
        child: child,
      ),
    );
  }
}

/// Lets a popover opened from inside a floating card find that card, so it can
/// attach to it (full width, under the row it was opened from) instead of
/// floating over the middle of it.
class PanelBoundary extends InheritedWidget {
  const PanelBoundary({
    required this.boundaryKey,
    required super.child,
    super.key,
  });

  final GlobalKey boundaryKey;

  /// The screen rectangle of the card, or null if it is not laid out.
  Rect? get rect {
    final box = boundaryKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static PanelBoundary? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PanelBoundary>();

  @override
  bool updateShouldNotify(PanelBoundary old) => old.boundaryKey != boundaryKey;
}

/// Shows a floating card at the top of the screen.
///
/// It rises 40 points while fading in over 200 ms, on a 40% scrim; it is 12
/// points from the screen sides, at most 512 wide, and 64 points from the
/// top (or clear of the status bar). Tapping outside dismisses it. Content
/// taller than the space left (a keyboard is open) scrolls.
Future<T?> showTodoDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? color,
  bool barrierDismissible = true,
}) {
  final motion = TodoMotion.of(context);
  final palette = context.palette;

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: palette.scrim,
    transitionDuration: motion.medium,
    pageBuilder: (dialogContext, animation, secondary) =>
        _DialogLayout(color: color, builder: builder),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: motion.ease);
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, motion.dialogRise * (1 - curved.value)),
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}

class _DialogLayout extends StatefulWidget {
  const _DialogLayout({required this.builder, this.color});

  final WidgetBuilder builder;
  final Color? color;

  @override
  State<_DialogLayout> createState() => _DialogLayoutState();
}

class _DialogLayoutState extends State<_DialogLayout> {
  final _surfaceKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = math.max(TodoSize.dialogTop, media.padding.top + TodoSpace.l);
    final bottom =
        math.max(media.viewInsets.bottom, media.padding.bottom) +
        TodoSize.dialogSide;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TodoSize.dialogSide,
        top,
        TodoSize.dialogSide,
        bottom,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TodoSize.dialogMaxWidth),
          // Always as wide as the space allows (up to the maximum), never
          // shrunk to the content.
          child: SizedBox(
            width: double.infinity,
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
                child: PanelBoundary(
                  boundaryKey: _surfaceKey,
                  child: KeyedSubtree(
                    key: _surfaceKey,
                    child: TodoDialogSurface(
                      color: widget.color,
                      child: Builder(builder: widget.builder),
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
