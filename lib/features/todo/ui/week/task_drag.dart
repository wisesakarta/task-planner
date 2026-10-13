import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/model/todo_task.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// Where a dragged task is let go: a day (null = Someday) and the tasks that
/// end up directly above and below it.
class TaskDrop {
  const TaskDrop({required this.date, this.afterId, this.beforeId});

  final DateTime? date;
  final String? afterId;
  final String? beforeId;
}

typedef TaskDropCallback = void Function(TodoTask task, TaskDrop drop);

/// A press-and-hold this long starts carrying a row (Tweek uses ~120 ms), so a
/// normal scroll, which moves first, is never mistaken for a drag.
const _holdToLift = Duration(milliseconds: 120);

/// The auto-scroller starts when the box around the finger passes the edge of
/// the list, so this is how close to an edge the finger has to be.
const _scrollEdge = 64.0;

/// How far the carried panel reaches past the row on each side.
const _liftedBleed = 8.0;

/// Keeps track of one drag at a time, across every [DropZone] of the screen.
///
/// It works from the finger position and the zones' *current* layout rather
/// than from drag-target callbacks, so the answer stays right while the list
/// scrolls under a finger that is held still.
class TaskDragController extends ChangeNotifier {
  TaskDragController({required this.onDrop});

  final TaskDropCallback onDrop;

  TodoTask? _task;
  Offset? _pointer;
  final List<_ZoneState> _zones = [];
  EdgeDraggingAutoScroller? _scroller;
  ScrollableState? _scrollable;

  TodoTask? get dragging => _task;
  bool get isDragging => _task != null;

  void _attach(_ZoneState zone) {
    if (!_zones.contains(zone)) _zones.add(zone);
  }

  void _detach(_ZoneState zone) => _zones.remove(zone);

  void start(TodoTask task) {
    _task = task;
    _pointer = null;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void update(Offset pointer) {
    if (_task == null) return;
    final before = _spot;
    _pointer = pointer;
    _autoScroll();
    if (_spot != before) HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Lets go: moves the task to where the finger is, if that is on a day.
  void end() {
    final task = _task;
    final drop = task == null ? null : dropFor(task);
    _finish();
    if (task != null && drop != null) {
      HapticFeedback.lightImpact();
      onDrop(task, drop);
    }
  }

  void cancel() => _finish();

  void _finish() {
    _scroller?.stopAutoScroll();
    _scroller = null;
    _scrollable = null;
    _task = null;
    _pointer = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- where

  _Spot? get _spot {
    final pointer = _pointer;
    if (pointer == null) return null;
    for (final zone in _zones) {
      final spot = zone.spotAt(pointer);
      if (spot != null) return spot;
    }
    return null;
  }

  /// The insertion line to draw inside [zone], as a row index, or null.
  int? insertionIn(Object zone) {
    final spot = _spot;
    return spot != null && identical(spot.zone, zone) ? spot.index : null;
  }

  /// What dropping [task] here would do.
  TaskDrop? dropFor(TodoTask task) {
    final spot = _spot;
    if (spot == null) return null;
    final shown = [...spot.zone.widget.tasks];
    var index = spot.index;
    final at = shown.indexWhere((t) => t.id == task.id);
    if (at >= 0) {
      shown.removeAt(at);
      if (at < index) index -= 1;
    }
    return TaskDrop(
      date: spot.zone.widget.date,
      afterId: index > 0 ? shown[index - 1].id : null,
      beforeId: index < shown.length ? shown[index].id : null,
    );
  }

  // ----------------------------------------------------------- autoscroll

  void _autoScroll() {
    final pointer = _pointer;
    final scrollable = _zones
        .map((zone) => zone.scrollable)
        .whereType<ScrollableState>()
        .firstOrNull;
    if (pointer == null || scrollable == null) return;
    if (!identical(scrollable, _scrollable)) {
      _scrollable = scrollable;
      _scroller?.stopAutoScroll();
      _scroller = EdgeDraggingAutoScroller(
        scrollable,
        velocityScalar: 50,
        // The finger has not moved but the list has: measure again, so the
        // scroller keeps going while the finger stays at the edge.
        onScrollViewScrolled: () {
          _autoScroll();
          notifyListeners();
        },
      );
    }
    _scroller!.startAutoScrollIfNecessary(
      // The scroller compares this with the list's place on screen.
      Rect.fromCenter(center: pointer, width: 24, height: 2 * _scrollEdge),
    );
  }

  @override
  void dispose() {
    _scroller?.stopAutoScroll();
    super.dispose();
  }
}

class _Spot {
  const _Spot(this.zone, this.index);

  final _ZoneState zone;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is _Spot && identical(other.zone, zone) && other.index == index;

  @override
  int get hashCode => Object.hash(identityHashCode(zone), index);
}

/// Gives the rows and zones below it one [TaskDragController].
class TaskDragScope extends StatefulWidget {
  const TaskDragScope({required this.onDrop, required this.child, super.key});

  final TaskDropCallback onDrop;
  final Widget child;

  static TaskDragController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_TaskDragInherited>()
      ?.controller;

  @override
  State<TaskDragScope> createState() => _TaskDragScopeState();
}

class _TaskDragScopeState extends State<TaskDragScope> {
  late final TaskDragController _controller = TaskDragController(
    onDrop: (task, drop) => widget.onDrop(task, drop),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _TaskDragInherited(controller: _controller, child: widget.child);
}

class _TaskDragInherited extends InheritedWidget {
  const _TaskDragInherited({required this.controller, required super.child});

  final TaskDragController controller;

  @override
  bool updateShouldNotify(_TaskDragInherited old) =>
      old.controller != controller;
}

/// A day (or Someday) that a row can be dropped on: [header] above its rows,
/// then one [TodoSize.row] per task, then whatever else [child] holds.
class DropZone extends StatefulWidget {
  const DropZone({
    required this.date,
    required this.tasks,
    required this.headerHeight,
    required this.child,
    this.slackBelow = 0,
    super.key,
  });

  /// The day this zone stands for; null is Someday.
  final DateTime? date;

  /// The tasks as shown, top to bottom.
  final List<TodoTask> tasks;
  final double headerHeight;

  /// Extra room under the zone that still counts as it (the gap to the next).
  final double slackBelow;
  final Widget child;

  @override
  State<DropZone> createState() => _ZoneState();
}

class _ZoneState extends State<DropZone> {
  TaskDragController? _controller;
  ScrollableState? scrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = TaskDragScope.maybeOf(context);
    if (!identical(next, _controller)) {
      _controller?._detach(this);
      _controller = next;
      _controller?._attach(this);
    }
    scrollable = Scrollable.maybeOf(context);
  }

  @override
  void dispose() {
    _controller?._detach(this);
    super.dispose();
  }

  _Spot? spotAt(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (local.dy < 0 || local.dy > box.size.height + widget.slackBelow) {
      return null;
    }
    final row = ((local.dy - widget.headerHeight) / TodoSize.row).round();
    return _Spot(this, row.clamp(0, widget.tasks.length));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;

    return ListenableBuilder(
      listenable: controller,
      child: widget.child,
      builder: (context, child) {
        final index = controller.insertionIn(this);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (index != null)
              Positioned(
                left: 0,
                right: 0,
                top: widget.headerHeight + index * TodoSize.row - 1,
                child: IgnorePointer(child: _InsertionLine()),
              ),
          ],
        );
      },
    );
  }
}

/// A 2-point accent line with a dot at its start: "it goes here".
class _InsertionLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accentInk;
    return SizedBox(
      height: 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: ColoredBox(color: accent)),
          Positioned(
            left: -3,
            top: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Makes [row] something to pick up: press and hold, then drag.
///
/// Without a [TaskDragScope] above it, the row is returned as it is.
class DraggableRow extends StatelessWidget {
  const DraggableRow({required this.task, required this.builder, super.key});

  final TodoTask task;

  /// Builds the row; [lifted] is true for the copy that follows the finger.
  final Widget Function(BuildContext context, {required bool lifted}) builder;

  @override
  Widget build(BuildContext context) {
    final controller = TaskDragScope.maybeOf(context);
    if (controller == null) return builder(context, lifted: false);

    return LayoutBuilder(
      builder: (context, constraints) => LongPressDraggable<TodoTask>(
        data: task,
        delay: _holdToLift,
        hapticFeedbackOnStart: false,
        maxSimultaneousDrags: 1,
        feedbackOffset: const Offset(-_liftedBleed, 0),
        onDragStarted: () => controller.start(task),
        onDragUpdate: (details) => controller.update(details.globalPosition),
        onDragEnd: (_) => controller.end(),
        onDraggableCanceled: (_, _) => controller.cancel(),
        feedback: _Lifted(
          width: constraints.maxWidth + 2 * _liftedBleed,
          child: builder(context, lifted: true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: builder(context, lifted: false),
        ),
        child: builder(context, lifted: false),
      ),
    );
  }
}

/// The row as it is carried: a panel of the page colour at 92% (Tweek uses 60%, but then the line underneath shows through the text), a little
/// wider than the row, with rounded corners.
class _Lifted extends StatelessWidget {
  const _Lifted({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.paper.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _liftedBleed),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Screen-reader and keyboard alternatives to dragging.
Map<CustomSemanticsAction, VoidCallback> moveActions({
  required TodoTask task,
  required DateTime? date,
  required List<TodoTask> shown,
  required TaskDropCallback onDrop,
}) {
  final at = shown.indexWhere((t) => t.id == task.id);
  if (at < 0) return const {};
  return {
    if (at > 0)
      const CustomSemanticsAction(label: 'Move up'): () => onDrop(
        task,
        TaskDrop(
          date: date,
          afterId: at > 1 ? shown[at - 2].id : null,
          beforeId: shown[at - 1].id,
        ),
      ),
    if (at < shown.length - 1)
      const CustomSemanticsAction(label: 'Move down'): () => onDrop(
        task,
        TaskDrop(
          date: date,
          afterId: shown[at + 1].id,
          beforeId: at + 2 < shown.length ? shown[at + 2].id : null,
        ),
      ),
    if (date != null) ...{
      const CustomSemanticsAction(label: 'Move to the next day'): () => onDrop(
        task,
        TaskDrop(date: DateTime(date.year, date.month, date.day + 1)),
      ),
      const CustomSemanticsAction(label: 'Move to the previous day'): () =>
          onDrop(
            task,
            TaskDrop(date: DateTime(date.year, date.month, date.day - 1)),
          ),
    },
  };
}
