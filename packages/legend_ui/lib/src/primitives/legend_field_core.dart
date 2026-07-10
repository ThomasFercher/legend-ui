import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The text-editing primitive (DESIGN.md §3): a thin, theme-free wrapper
/// over Flutter's `EditableText` that owns only text editing, focus,
/// cursor, and selection — no field chrome (no surface, border, title,
/// placeholder, or error; those belong to `LegendTextField`).
///
/// Replaces legacy's 1,535-line CupertinoTextField fork and its broken
/// slotted render box (DESIGN.md §3): the kit stops vendoring Flutter
/// internals and configures the framework's own `EditableText` instead.
///
/// Like `EditableText`, the [controller] and [focusNode] are required and
/// owned by the caller — `LegendTextField` creates, wires, and disposes
/// them (and drives the form lifecycle) so the core stays a pure
/// presentation wrapper.
class LegendFieldCore extends StatelessWidget {
  const LegendFieldCore({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.cursorColor,
    required this.backgroundCursorColor,
    super.key,
    this.selectionColor,
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  /// The edited text; owned by the caller.
  final TextEditingController controller;

  /// The field's focus; owned by the caller.
  final FocusNode focusNode;

  /// Style of the entered text (already resolved — the core reads no
  /// theme).
  final TextStyle style;

  /// Color of the blinking caret.
  final Color cursorColor;

  /// Color of the caret on the platform's background layer (iOS floating
  /// cursor); `EditableText` requires it.
  final Color backgroundCursorColor;

  /// Fill behind selected text; null uses the framework default.
  final Color? selectionColor;

  final bool obscureText;
  final bool autofocus;

  /// When true the text can be selected/copied but not edited.
  final bool readOnly;

  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return EditableText(
      controller: controller,
      focusNode: focusNode,
      style: style,
      cursorColor: cursorColor,
      backgroundCursorColor: backgroundCursorColor,
      selectionColor: selectionColor,
      obscureText: obscureText,
      autofocus: autofocus,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
