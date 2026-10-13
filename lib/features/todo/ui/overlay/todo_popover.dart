import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/theme/todo_motion.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';

/// The screen rectangle of the widget behind [context]; a popover hangs from it.
Rect anchorRectOf(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Tells a [PopoverSurface] that it is an attached panel (as wide as the card
/// it hangs from) rather than a small floating menu.
class _PanelMode extends InheritedWidget {
  const _PanelMode({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PanelMode>() != null;

  @override
  bool updateShouldNotify(_PanelMode old) => false;
}

/// The face of a popover or panel: a surface a shade darker than the card it
/// opens from (so it reads without an outline), with a 16-point radius.
///
/// [width] is the width its content wants. Opened as a panel under a task
/// card, the surface spans the card and the content stays centred at that
/// width, unless [fill] is set, which lets a list of rows use the whole width.
class PopoverSurface extends StatelessWidget {
  const PopoverSurface({
    required this.child,
    this.width,
    this.color,
    this.fill = false,
    this.padding = const EdgeInsets.symmetric(vertical: TodoSpace.s),
    super.key,
  });

  final Widget child;
  final double? width;
  final Color? color;
  final bool fill;
  final EdgeInsets padding;

  /// The surface colour on top of a card of the sheet tint.
  static Color tint(BuildContext context) =>
      Color.alphaBlend(context.palette.ink5, context.palette.sheet);

  @override
  Widget build(BuildContext context) {
    final panel = _PanelMode.of(context);

    return Container(
      width: panel ? double.infinity : width,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tint(context),
        borderRadius: BorderRadius.circular(TodoRadius.l),
      ),
      child: panel && !fill && width != null
          ? Align(
              heightFactor: 1,
              alignment: Alignment.topCenter,
              child: SizedBox(width: width! - padding.horizontal, child: child),
            )
          : child,
    );
  }
}

/// Opens [builder] as a popover under [anchor] (above it if there is no room).
///
/// It fades in over 200 ms, sits 12 points from the anchor, is centred on it,
/// and stays 12 points inside the screen. Tapping anywhere else dismisses only
/// the popover; whatever is below (a task card) stays open.
///
/// Opened from inside a task card it becomes an attached panel (as wide as the
/// card, directly under the row of buttons); pass `attached: false` to keep a
/// small floating menu there too.
Future<T?> showTodoPopover<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  bool attached = true,
}) {
  final motion = TodoMotion.of(context);
  final card = attached ? PanelBoundary.maybeOf(context)?.rect : null;

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: motion.medium,
    pageBuilder: (popoverContext, animation, secondary) {
      final child = Material(
        type: MaterialType.transparency,
        child: Builder(builder: builder),
      );
      if (card != null) {
        return CustomSingleChildLayout(
          delegate: _PanelLayout(anchor, card),
          child: _PanelMode(
            child: _CardExtension(
              color: popoverContext.palette.sheet,
              // Where the card's bottom edge is, measured from the panel top.
              cardBottom: card.bottom - (anchor.bottom + _PanelLayout._gap),
              child: child,
            ),
          ),
        );
      }
      return CustomSingleChildLayout(
        delegate: _PopoverLayout(anchor),
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondary, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: motion.ease),
      child: child,
    ),
  );
}

/// When an attached panel is taller than what is left of the card, the card
/// grows with it: this paints the card's colour from its bottom edge down to
/// 12 points under the panel, with the card's rounded bottom corners, so the
/// panel never looks stuck on to something that ends above it.
class _CardExtension extends StatelessWidget {
  const _CardExtension({
    required this.color,
    required this.cardBottom,
    required this.child,
  });

  final Color color;
  final double cardBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(
        child: CustomPaint(
          painter: _ExtensionPainter(color: color, cardBottom: cardBottom),
        ),
      ),
      child,
    ],
  );
}

class _ExtensionPainter extends CustomPainter {
  _ExtensionPainter({required this.color, required this.cardBottom});

  final Color color;
  final double cardBottom;

  static const _inset = _PanelLayout._inset;
  static const _below = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height + _below;
    if (bottom <= cardBottom) return;
    // Start inside the card's own rounded corner so the two join.
    final top = cardBottom - TodoRadius.xl;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        -_inset,
        top,
        size.width + _inset,
        bottom,
        bottomLeft: const Radius.circular(TodoRadius.xl),
        bottomRight: const Radius.circular(TodoRadius.xl),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ExtensionPainter old) =>
      old.color != color || old.cardBottom != cardBottom;
}

/// An attached panel: [_inset] inside the card on both sides, [_gap] under the
/// button that opened it, and never past the bottom of the screen.
class _PanelLayout extends SingleChildLayoutDelegate {
  _PanelLayout(this.anchor, this.card);

  final Rect anchor;
  final Rect card;

  static const _inset = 12.0;
  static const _gap = 8.0;
  static const _margin = 12.0;

  double get _top => anchor.bottom + _gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = card.width - _inset * 2;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight - _top - _margin,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(card.left + _inset, _top);

  @override
  bool shouldRelayout(_PanelLayout old) =>
      old.anchor != anchor || old.card != card;
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout(this.anchor);

  final Rect anchor;

  static const _gap = 12.0;
  static const _margin = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - _margin * 2,
        maxHeight: constraints.maxHeight - _margin * 2,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = size.width - _margin - childSize.width;
    final x = (anchor.center.dx - childSize.width / 2).clamp(
      _margin,
      maxX < _margin ? _margin : maxX,
    );

    var y = anchor.bottom + _gap;
    if (y + childSize.height > size.height - _margin) {
      y = anchor.top - _gap - childSize.height;
    }
    final maxY = size.height - _margin - childSize.height;
    return Offset(x, y.clamp(_margin, maxY < _margin ? _margin : maxY));
  }

  @override
  bool shouldRelayout(_PopoverLayout old) => old.anchor != anchor;
}

/// One choice in a popover menu: 36 tall, 15-point medium text, a check in a
/// leading slot when it is the current choice, and an optional chevron.
class PopoverMenuItem extends StatelessWidget {
  const PopoverMenuItem({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.chevron = false,
    this.reserveCheck = false,
    this.trailing,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool chevron;

  /// Keeps room for a check at the start. Only a list that can show a current
  /// choice needs it; elsewhere an empty gutter just pushes the text in.
  final bool reserveCheck;

  /// An icon at the far end, e.g. an arrow for "Tomorrow".
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                children: [
                  if (reserveCheck)
                    SizedBox(
                      width: 30,
                      child: selected
                          ? Icon(Icons.check_rounded, size: 20, color: p.ink)
                          : null,
                    ),
                  Expanded(child: Text(label, style: context.type.menuItem)),
                  if (chevron)
                    Icon(Icons.chevron_right_rounded, size: 20, color: p.ink),
                  if (trailing != null) Icon(trailing, size: 20, color: p.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The hairline that separates a menu's first choice from the rest.
class PopoverDivider extends StatelessWidget {
  const PopoverDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: TodoSpace.m,
      vertical: TodoSpace.xs,
    ),
    child: SizedBox(
      height: 1,
      child: ColoredBox(
        color: context.palette.ink15,
        child: const SizedBox.expand(),
      ),
    ),
  );
}
