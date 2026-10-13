import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todo_app/features/todo/theme/todo_theme.dart';
import 'package:todo_app/features/todo/theme/todo_tokens.dart';

/// The spare ruled row at the bottom of a day: tap it and type.
///
/// There is no "add" button. Enter saves the task and the field stays focused
/// on the next empty line, so a list can be typed in one go. The line does not
/// change while it has focus (Tweek's phone app is flat too); the caret is the
/// only sign.
///
/// The field only clears itself after [onSubmit] reports success, so a failed
/// save never loses what was typed.
class InlineComposer extends StatefulWidget {
  const InlineComposer({
    required this.onSubmit,
    required this.semanticsLabel,
    this.controller,
    this.focusNode,
    super.key,
  });

  /// Called with the trimmed, non-empty title. Return whether it was saved.
  final FutureOr<bool> Function(String title) onSubmit;

  /// Spoken by screen readers, e.g. "Add a task on Wednesday".
  final String semanticsLabel;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<InlineComposer> createState() => _InlineComposerState();
}

class _InlineComposerState extends State<InlineComposer> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final saved = await widget.onSubmit(title);
    if (saved && mounted) _controller.clear();
    if (mounted) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    // The line stays exactly where it is while you type: no card, no shadow.
    // Only the caret says it has focus.
    return Semantics(
      label: widget.semanticsLabel,
      textField: true,
      child: SizedBox(
        height: TodoSize.row,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: p.rule, width: TodoSize.hairline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: TodoSize.pillPad),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: type.taskText,
              cursorColor: p.ink,
              cursorWidth: 2,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              // Keep focus after Enter so the next line is ready.
              onEditingComplete: _commit,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
