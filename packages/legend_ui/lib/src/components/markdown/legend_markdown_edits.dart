import 'package:flutter/widgets.dart';

/// The markdown editor's keyboard conveniences as pure
/// `TextEditingValue → TextEditingValue` transforms (RFC-005 §3.5):
/// list continuation on Enter, list indent/outdent on Tab, and
/// wrap/unwrap of inline delimiters for the bold/italic shortcuts.
///
/// Every transform is a plain text edit — no hidden state, no document
/// model — and returns null when it does not apply, so the caller can fall
/// through to the default key handling. `LegendMarkdownEditor` wires them
/// to Enter, Tab/Shift-Tab, and Cmd/Ctrl+B/I; they are public so toolbar
/// buttons can invoke the same edits.
abstract final class LegendMarkdownEdits {
  static final RegExp _marker = RegExp(
    r'^([ \t]*)(?:([-*+])|(\d{1,9})([.)]))([ \t]+)',
  );

  /// Continues a list on Enter: pressed inside a list item, the new line
  /// starts with the same indent and the next marker (bullets repeat,
  /// numbers increment); pressed on an item that is still empty, the
  /// marker is removed instead — the list ends. Null when the cursor is
  /// not in a list item (or the selection is not collapsed).
  static TextEditingValue? continueList(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final text = value.text;
    final lineStart = _lineStart(text, selection.start);
    final newline = text.indexOf('\n', selection.start);
    final lineEnd = newline == -1 ? text.length : newline;
    final line = text.substring(lineStart, lineEnd);
    final match = _marker.firstMatch(line);
    if (match == null) return null;
    // Enter inside the marker itself is a plain newline.
    if (selection.start < lineStart + match.end) return null;

    if (line.substring(match.end).trim().isEmpty) {
      // Empty item: Enter ends the list by clearing the marker.
      return TextEditingValue(
        text: text.replaceRange(lineStart, lineEnd, ''),
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }

    final indent = match.group(1)!;
    final bullet = match.group(2);
    final spacing = match.group(5)!;
    final nextMarker = bullet != null
        ? '$indent$bullet$spacing'
        : '$indent${int.parse(match.group(3)!) + 1}${match.group(4)}$spacing';
    final inserted = '\n$nextMarker';
    return TextEditingValue(
      text: text.replaceRange(selection.start, selection.start, inserted),
      selection: TextSelection.collapsed(
        offset: selection.start + inserted.length,
      ),
    );
  }

  /// Indents every list item the selection touches by two spaces. Null
  /// when no touched line is a list item.
  static TextEditingValue? indent(TextEditingValue value) =>
      _reindent(value, outdent: false);

  /// Outdents every list item the selection touches by up to two leading
  /// spaces. Null when nothing changes.
  static TextEditingValue? outdent(TextEditingValue value) =>
      _reindent(value, outdent: true);

  /// Toggles an inline [delimiter] (`**`, `*`, `` ` ``, …) around the
  /// selection: an unwrapped selection is wrapped, a wrapped one (whether
  /// the delimiters sit inside or just outside the selection) is
  /// unwrapped; a collapsed cursor inserts an empty pair to type into, or
  /// removes the empty pair it sits in. Single-character delimiters never
  /// unwrap half of a doubled delimiter (toggling italic inside `**bold**`
  /// wraps instead of corrupting the bold marks).
  static TextEditingValue? toggleInline(
    TextEditingValue value,
    String delimiter,
  ) {
    final selection = value.selection;
    if (!selection.isValid) return null;
    final text = value.text;
    final width = delimiter.length;
    final start = selection.start;
    final end = selection.end;

    bool delimiterAt(int index) =>
        index >= 0 &&
        index + width <= text.length &&
        text.substring(index, index + width) == delimiter;
    bool edgesClear(int before, int after) {
      if (width != 1) return true;
      final char = delimiter[0];
      final b = before >= 0 ? text[before] : '';
      final a = after < text.length ? text[after] : '';
      return b != char && a != char;
    }

    if (selection.isCollapsed) {
      if (delimiterAt(start - width) &&
          delimiterAt(start) &&
          edgesClear(start - width - 1, start + width)) {
        final stripped = text
            .replaceRange(start, start + width, '')
            .replaceRange(start - width, start, '');
        return TextEditingValue(
          text: stripped,
          selection: TextSelection.collapsed(offset: start - width),
        );
      }
      return TextEditingValue(
        text: text.replaceRange(start, start, delimiter * 2),
        selection: TextSelection.collapsed(offset: start + width),
      );
    }

    final inner = text.substring(start, end);
    if (inner.length >= 2 * width &&
        inner.startsWith(delimiter) &&
        inner.endsWith(delimiter)) {
      final content = inner.substring(width, inner.length - width);
      return TextEditingValue(
        text: text.replaceRange(start, end, content),
        selection: TextSelection(
          baseOffset: start,
          extentOffset: end - 2 * width,
        ),
      );
    }
    if (delimiterAt(start - width) &&
        delimiterAt(end) &&
        edgesClear(start - width - 1, end + width)) {
      final stripped = text
          .replaceRange(end, end + width, '')
          .replaceRange(start - width, start, '');
      return TextEditingValue(
        text: stripped,
        selection: TextSelection(
          baseOffset: start - width,
          extentOffset: end - width,
        ),
      );
    }
    return TextEditingValue(
      text: text
          .replaceRange(end, end, delimiter)
          .replaceRange(start, start, delimiter),
      selection: TextSelection(
        baseOffset: start + width,
        extentOffset: end + width,
      ),
    );
  }

  // --- shared internals ---

  static int _lineStart(String text, int offset) =>
      offset <= 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;

  static TextEditingValue? _reindent(
    TextEditingValue value, {
    required bool outdent,
  }) {
    final selection = value.selection;
    if (!selection.isValid) return null;
    final text = value.text;

    // Line starts touched by the selection (a range ending exactly at a
    // line start leaves that line alone).
    final lineStarts = <int>[_lineStart(text, selection.start)];
    while (true) {
      final newline = text.indexOf('\n', lineStarts.last);
      if (newline == -1 || newline + 1 >= selection.end) break;
      lineStarts.add(newline + 1);
    }

    // (position, +inserted or −removed) edits, applied back-to-front so
    // earlier offsets stay valid.
    final edits = <(int, int)>[];
    var newText = text;
    for (final lineStart in lineStarts.reversed) {
      final newline = newText.indexOf('\n', lineStart);
      final lineEnd = newline == -1 ? newText.length : newline;
      final line = newText.substring(lineStart, lineEnd);
      if (!_marker.hasMatch(line)) continue;
      if (outdent) {
        var removable = 0;
        while (removable < 2 &&
            removable < line.length &&
            line[removable] == ' ') {
          removable++;
        }
        if (removable == 0) continue;
        newText = newText.replaceRange(lineStart, lineStart + removable, '');
        edits.add((lineStart, -removable));
      } else {
        newText = newText.replaceRange(lineStart, lineStart, '  ');
        edits.add((lineStart, 2));
      }
    }
    if (edits.isEmpty) return null;

    int map(int offset) {
      var mapped = offset;
      for (final (position, delta) in edits) {
        if (position > offset) continue;
        if (delta > 0) {
          mapped += delta;
        } else {
          final removed = offset - position < -delta
              ? offset - position
              : -delta;
          mapped -= removed;
        }
      }
      return mapped;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: map(selection.baseOffset),
        extentOffset: map(selection.extentOffset),
      ),
    );
  }
}
