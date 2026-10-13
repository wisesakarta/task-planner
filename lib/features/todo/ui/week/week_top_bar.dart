import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';

/// The bar above the week: the month and year in large type, and four round
/// buttons (search, menu, previous, next).
class WeekTopBar extends StatelessWidget {
  const WeekTopBar({
    required this.title,
    required this.onSearch,
    required this.onMenu,
    required this.onPrevious,
    required this.onNext,
    this.onTitleTap,
    this.titleTapLabel = 'open month view',
    this.accentTitle = false,
    super.key,
  });

  /// "Oct 2026".
  final String title;

  final VoidCallback onSearch;
  final VoidCallback onMenu;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Makes the title a button when set.
  final VoidCallback? onTitleTap;

  /// What the title button does, for screen readers ("open month view").
  final String titleTapLabel;

  /// Draw the title in the accent colour: you are not on the current week.
  final bool accentTitle;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.type.title.copyWith(
        color: accentTitle ? context.palette.accentInk : null,
      ),
    );

    return Padding(
      // The round buttons are 48-point targets around 40-point circles, so
      // these insets put the circles 16 from the edge.
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onTitleTap == null)
                  titleText
                else
                  Semantics(
                    button: true,
                    label: '$title, $titleTapLabel',
                    onTap: onTitleTap,
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTitleTap,
                        child: titleText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          RoundButton(
            icon: Icons.search_rounded,
            label: 'Search',
            variant: RoundButtonVariant.soft,
            onPressed: onSearch,
          ),
          RoundButton(
            icon: Icons.menu_rounded,
            label: 'Menu',
            variant: RoundButtonVariant.accent,
            onPressed: onMenu,
          ),
          RoundButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous week',
            onPressed: onPrevious,
          ),
          RoundButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next week',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
