import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/model/todo_settings.dart';
import 'package:todo_app/features/todo/reminders/reminder_service.dart';
import 'package:todo_app/features/todo/theme/todo_motion.dart';
import 'package:todo_app/features/todo/theme/todo_palette.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/controls/round_button.dart';
import 'package:todo_app/features/todo/ui/controls/segmented_control.dart';
import 'package:todo_app/features/todo/ui/controls/todo_toggle.dart';

/// Opens the menu panel under the profile button: a bento of shortcuts that
/// lead to the settings pages. Settings apply the moment they change.
///
/// [settings] is the app's live value; the panel rebuilds when it changes and
/// reports edits through [onChanged].
Future<void> showMenuPanel(
  BuildContext context, {
  required ValueListenable<TodoSettings> settings,
  required ValueChanged<TodoSettings> onChanged,
  ValueListenable<ReminderPermission>? reminderPermission,
  VoidCallback? onOpenSystemSettings,
  MenuPage page = MenuPage.home,
}) {
  final motion = TodoMotion.of(context);

  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: context.palette.scrim,
    transitionDuration: motion.medium,
    pageBuilder: (panelContext, animation, secondary) => _PanelLayout(
      child: MenuPanel(
        settings: settings,
        onChanged: onChanged,
        reminderPermission: reminderPermission,
        onOpenSystemSettings: onOpenSystemSettings,
        page: page,
      ),
    ),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: motion.ease);
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -motion.panelDrop * (1 - curved.value)),
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}

class _PanelLayout extends StatelessWidget {
  const _PanelLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top + TodoSize.dialogSide + TodoSize.minTap;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TodoSize.dialogSide,
        top,
        TodoSize.dialogSide,
        TodoSize.dialogSide + media.viewInsets.bottom,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.infinity,
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

enum MenuPage { home, appearance, calendar, notifications, about }

class MenuPanel extends StatefulWidget {
  const MenuPanel({
    required this.settings,
    required this.onChanged,
    this.reminderPermission,
    this.onOpenSystemSettings,
    this.page = MenuPage.home,
    super.key,
  });

  final ValueListenable<TodoSettings> settings;
  final ValueChanged<TodoSettings> onChanged;

  /// Whether the system allows notifications; shown on the Notifications page.
  final ValueListenable<ReminderPermission>? reminderPermission;

  /// Opens the phone's notification settings for this app, if it can.
  final VoidCallback? onOpenSystemSettings;
  final MenuPage page;

  @override
  State<MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<MenuPanel> {
  late MenuPage _page = widget.page;
  bool _forward = true;

  void _go(MenuPage page) => setState(() {
    _forward = page != MenuPage.home;
    _page = page;
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.sheet,
        borderRadius: BorderRadius.circular(TodoRadius.xl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TodoRadius.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TodoSize.dialogPad),
            child: AnimatedSwitcher(
              // Back navigation must not retain an outgoing page for a frame:
              // that is what produced the Calendar/Menu text ghosting.
              duration: _forward ? motion.medium : Duration.zero,
              switchInCurve: motion.ease,
              switchOutCurve: motion.ease,
              // Keep only the active page in the layout. Keeping the
              // outgoing page here while also fading both pages caused
              // text from Calendar and Menu to be composited together on
              // the same frame during a back navigation.
              layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
              transitionBuilder: (child, animation) {
                final direction = _forward ? 1 : -1;
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      direction * motion.pageSlide * (1 - animation.value),
                      0,
                    ),
                    child: child,
                  ),
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_page),
                child: ValueListenableBuilder<TodoSettings>(
                  valueListenable: widget.settings,
                  builder: (context, settings, _) => switch (_page) {
                    MenuPage.home => _Home(onGo: _go),
                    MenuPage.appearance => _Appearance(
                      settings: settings,
                      onChanged: widget.onChanged,
                      onBack: () => _go(MenuPage.home),
                    ),
                    MenuPage.calendar => _Calendar(
                      settings: settings,
                      onChanged: widget.onChanged,
                      onBack: () => _go(MenuPage.home),
                    ),
                    MenuPage.notifications => _Notifications(
                      settings: settings,
                      onChanged: widget.onChanged,
                      permission: widget.reminderPermission,
                      onOpenSystemSettings: widget.onOpenSystemSettings,
                      onBack: () => _go(MenuPage.home),
                    ),
                    MenuPage.about => _About(onBack: () => _go(MenuPage.home)),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- home

class _Home extends StatelessWidget {
  const _Home({required this.onGo});

  final ValueChanged<MenuPage> onGo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.palette_outlined,
                label: 'Appearance',
                onTap: () => onGo(MenuPage.appearance),
              ),
            ),
            const SizedBox(width: TodoSpace.s),
            Expanded(
              child: _Tile(
                icon: Icons.calendar_today_outlined,
                label: 'Calendar',
                onTap: () => onGo(MenuPage.calendar),
              ),
            ),
          ],
        ),
        const SizedBox(height: TodoSpace.s),
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => onGo(MenuPage.notifications),
              ),
            ),
            const SizedBox(width: TodoSpace.s),
            Expanded(
              child: _Tile(
                icon: Icons.info_outline_rounded,
                label: 'About',
                onTap: () => onGo(MenuPage.about),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: context.motion.fast,
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.all(TodoSpace.m),
            decoration: BoxDecoration(
              color: _pressed ? p.ink10 : p.ink5,
              borderRadius: BorderRadius.circular(TodoRadius.l),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, size: TodoSize.icon, color: p.ink),
                const SizedBox(height: TodoSpace.s),
                Text(
                  widget.label,
                  style: context.type.menuItem,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- page shell

class _PageShell extends StatelessWidget {
  const _PageShell({
    required this.title,
    required this.onBack,
    required this.children,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RoundButton(
              icon: Icons.chevron_left_rounded,
              label: 'Back',
              variant: RoundButtonVariant.soft,
              size: TodoSize.controlS,
              onPressed: onBack,
            ),
            const SizedBox(width: TodoSpace.xs),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.type.heading),
              ),
            ),
          ],
        ),
        const SizedBox(height: TodoSpace.m),
        ...children,
      ],
    );
  }
}

/// The small heading above a group or a control on a settings page.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TodoSpace.xs,
      TodoSpace.s,
      0,
      TodoSpace.s,
    ),
    child: Text(text, style: context.type.sectionLabel),
  );
}

/// A rounded group of settings rows.
class _Group extends StatelessWidget {
  const _Group({required this.children, this.label});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) _SectionLabel(label!),
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.ink5,
            borderRadius: BorderRadius.circular(TodoRadius.l),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(color: p.ink10, indent: TodoSpace.l, height: 1),
                children[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: TodoSpace.m),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
  });

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TodoSpace.l,
            vertical: TodoSpace.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.type.rowLabel),
                    if (caption != null)
                      Text(caption!, style: context.type.caption),
                  ],
                ),
              ),
              const SizedBox(width: TodoSpace.m),
              TodoToggle(value: value, onChanged: onChanged, label: label),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- appearance

class _Appearance extends StatelessWidget {
  const _Appearance({
    required this.settings,
    required this.onChanged,
    required this.onBack,
  });

  final TodoSettings settings;
  final ValueChanged<TodoSettings> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: 'Appearance',
      onBack: onBack,
      children: [
        SegmentedControl<ThemeMode>(
          options: const [
            SegmentedOption(
              value: ThemeMode.system,
              label: 'System',
              icon: Icons.brightness_auto_outlined,
            ),
            SegmentedOption(
              value: ThemeMode.light,
              label: 'Light',
              icon: Icons.light_mode_outlined,
            ),
            SegmentedOption(
              value: ThemeMode.dark,
              label: 'Dark',
              icon: Icons.dark_mode_outlined,
            ),
          ],
          value: settings.themeMode,
          onChanged: (mode) => onChanged(settings.copyWith(themeMode: mode)),
        ),
        const SizedBox(height: TodoSpace.m),
        _Group(
          label: 'Theme',
          children: [
            for (final family in TodoThemes.all)
              _ThemeRow(
                family: family,
                selected: family.id == settings.themeId,
                onTap: () => onChanged(settings.copyWith(themeId: family.id)),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final TodoThemeFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Preview in the palette that is on screen (light or dark).
    final preview = family.forBrightness(p.brightness);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: family.name,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TodoSpace.l),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: preview.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: preview.ink, width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: preview.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TodoSpace.m),
                  Expanded(
                    child: Text(family.name, style: context.type.rowLabel),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_rounded,
                      size: TodoSize.icon,
                      color: p.ink,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ calendar

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.settings,
    required this.onChanged,
    required this.onBack,
  });

  final TodoSettings settings;
  final ValueChanged<TodoSettings> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: 'Calendar',
      onBack: onBack,
      children: [
        const _SectionLabel('Week starts on'),
        SegmentedControl<int>(
          options: const [
            SegmentedOption(value: DateTime.monday, label: 'Monday'),
            SegmentedOption(value: DateTime.sunday, label: 'Sunday'),
          ],
          value: settings.weekStartsOn,
          onChanged: (day) => onChanged(settings.copyWith(weekStartsOn: day)),
        ),
        const SizedBox(height: TodoSpace.m),
        _Group(
          label: 'Tasks',
          children: [
            _ToggleRow(
              label: 'Carry over unfinished',
              caption: 'Move open tasks from past days to today',
              value: settings.moveToNextDay,
              onChanged: (v) => onChanged(settings.copyWith(moveToNextDay: v)),
            ),
            _ToggleRow(
              label: 'Finished tasks last',
              caption: 'Show completed tasks below the open ones',
              value: settings.sortCompletedDown,
              onChanged: (v) =>
                  onChanged(settings.copyWith(sortCompletedDown: v)),
            ),
            _ToggleRow(
              label: 'Hide finished tasks',
              caption: 'Take a task off its day once it is done',
              value: settings.hideAfterComplete,
              onChanged: (v) =>
                  onChanged(settings.copyWith(hideAfterComplete: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- about

// --------------------------------------------------------- notifications

class _Notifications extends StatelessWidget {
  const _Notifications({
    required this.settings,
    required this.onChanged,
    required this.permission,
    required this.onOpenSystemSettings,
    required this.onBack,
  });

  final TodoSettings settings;
  final ValueChanged<TodoSettings> onChanged;
  final ValueListenable<ReminderPermission>? permission;
  final VoidCallback? onOpenSystemSettings;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return _PageShell(
      title: 'Notifications',
      onBack: onBack,
      children: [
        _Group(
          children: [
            _ToggleRow(
              label: 'Reminders',
              caption: "Get a notification when a task's reminder time arrives",
              value: settings.notificationsEnabled,
              onChanged: (v) =>
                  onChanged(settings.copyWith(notificationsEnabled: v)),
            ),
          ],
        ),
        if (permission != null)
          ValueListenableBuilder<ReminderPermission>(
            valueListenable: permission!,
            builder: (context, value, _) {
              if (value == ReminderPermission.granted ||
                  !settings.notificationsEnabled) {
                return const SizedBox.shrink();
              }
              return Semantics(
                liveRegion: true,
                container: true,
                child: Container(
                  margin: const EdgeInsets.only(bottom: TodoSpace.m),
                  padding: const EdgeInsets.all(TodoSpace.l),
                  decoration: BoxDecoration(
                    color: p.alert,
                    borderRadius: BorderRadius.circular(TodoRadius.l),
                    border: Border.all(
                      color: p.ink25,
                      width: TodoSize.hairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your phone is blocking notifications from this app, '
                        'so reminders will not show.',
                        style: type.taskText,
                      ),
                      if (onOpenSystemSettings != null) ...[
                        const SizedBox(height: TodoSpace.m),
                        PillButton(
                          label: 'Open phone settings',
                          variant: PillVariant.outlined,
                          onPressed: onOpenSystemSettings,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return _PageShell(
      title: 'About',
      onBack: onBack,
      children: [
        Text(
          'A weekly planner that works without a connection.',
          style: type.taskText,
        ),
        const SizedBox(height: TodoSpace.s),
        Text(
          'Your tasks are saved on this device. There is no account to make '
          'and nothing leaves your phone.',
          style: type.caption,
        ),
      ],
    );
  }
}
