import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_popover.dart';

enum MoreAction {
  tomorrow('Tomorrow', Icons.arrow_forward_rounded),
  nextWeek('Next week', Icons.keyboard_double_arrow_right_rounded),
  someday('Move to Someday', Icons.south_rounded),
  duplicate('Duplicate', Icons.content_copy_rounded);

  const MoreAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The "…" menu of the task card. A null result means it was dismissed.
Future<MoreAction?> showMoreMenu(BuildContext context, {required Rect anchor}) {
  return showTodoPopover<MoreAction>(
    context,
    anchor: anchor,
    builder: (popoverContext) => PopoverSurface(
      width: 240,
      fill: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in MoreAction.values) ...[
            if (action == MoreAction.duplicate) const PopoverDivider(),
            PopoverMenuItem(
              label: action.label,
              trailing: action.icon,
              onTap: () => Navigator.of(popoverContext).pop(action),
            ),
          ],
        ],
      ),
    ),
  );
}
