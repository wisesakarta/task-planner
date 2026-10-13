import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/features/todo/model/recurrence_scope.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';
import 'package:todo_app/features/todo/ui/controls/pill_button.dart';
import 'package:todo_app/features/todo/ui/overlay/todo_dialog.dart';

class ConfirmOption<T> {
  const ConfirmOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A yes/no question in the alert tint: a title, an explanation of what will
/// happen, and two stacked pills. Returns whether the user confirmed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Apply',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showTodoDialog<bool>(
    context,
    color: context.palette.alert,
    builder: (dialogContext) => _ConfirmBody<bool>(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      options: const [],
      initial: null,
      onResult: (_) => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return result ?? false;
}

/// A question with a choice of scope (radio rows). Returns the chosen value,
/// or null if cancelled.
Future<T?> showChoiceConfirm<T>(
  BuildContext context, {
  required String title,
  required String body,
  required List<ConfirmOption<T>> options,
  required T initial,
  String confirmLabel = 'Ok',
  String cancelLabel = 'Cancel',
}) {
  return showTodoDialog<T>(
    context,
    color: context.palette.alert,
    builder: (dialogContext) => _ConfirmBody<T>(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      options: options,
      initial: initial,
      onResult: (value) => Navigator.of(dialogContext).pop(value),
      onCancel: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// "Change recurrence?" — ending a repeat cycle cannot be undone.
Future<bool> confirmChangeRecurrence(BuildContext context) => showConfirm(
  context,
  title: 'Change recurrence?',
  body:
      "Are you sure you want to change this task's repeat settings? This will "
      'end the current cycle and some future tasks may become inaccessible.',
);

/// "Delete repeating task?" — which occurrences to delete.
Future<RecurrenceScope?> confirmDeleteRecurring(BuildContext context) =>
    showChoiceConfirm<RecurrenceScope>(
      context,
      title: 'Delete repeating task?',
      body:
          'This task repeats. Deleting one occurrence can affect the others; '
          'choose which ones to delete.',
      options: [
        for (final scope in RecurrenceScope.values)
          ConfirmOption(value: scope, label: scope.label),
      ],
      initial: RecurrenceScope.onlyThis,
    );

class _ConfirmBody<T> extends StatefulWidget {
  const _ConfirmBody({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.options,
    required this.initial,
    required this.onResult,
    required this.onCancel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final List<ConfirmOption<T>> options;
  final T? initial;
  final ValueChanged<T?> onResult;
  final VoidCallback onCancel;

  @override
  State<_ConfirmBody<T>> createState() => _ConfirmBodyState<T>();
}

class _ConfirmBodyState<T> extends State<_ConfirmBody<T>> {
  late T? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(widget.title, style: type.heading)),
        const SizedBox(height: TodoSpace.s),
        Text(widget.body, style: type.taskText),
        if (widget.options.isNotEmpty) ...[
          const SizedBox(height: TodoSpace.l),
          for (final option in widget.options)
            _RadioRow(
              label: option.label,
              selected: option.value == _selected,
              onTap: () => setState(() => _selected = option.value),
            ),
        ],
        const SizedBox(height: TodoSpace.xl),
        PillButton(
          label: widget.confirmLabel,
          onPressed: () => widget.onResult(_selected),
        ),
        const SizedBox(height: TodoSpace.l),
        PillButton(
          label: widget.cancelLabel,
          variant: PillVariant.outlined,
          onPressed: widget.onCancel,
        ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
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
            constraints: const BoxConstraints(minHeight: TodoSize.minTap),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? p.ink : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.ink, width: 1.68),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 14, color: p.paper)
                      : null,
                ),
                const SizedBox(width: TodoSpace.m),
                Expanded(child: Text(label, style: context.type.taskText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
