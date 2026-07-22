import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_editing_controller.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_edits.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_source_style.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_syntax.dart';
import 'package:legend_ui/src/primitives/legend_field_core.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_markdown_editor.theme.g.dart';

/// The in-house markdown source editor (RFC-005): a multiline field whose
/// value is always plain markdown source, styled in place while you type —
/// headings grow, emphasis marks mute, fences go mono — never converted
/// into a document model.
///
/// Composes [LegendFieldCore] (the editing primitive over the framework's
/// `EditableText` — selection, IME, and web input stay the framework's)
/// and [LegendSurface] for the field chrome. Highlighting lives in
/// [LegendMarkdownEditingController.buildTextSpan], which styles the
/// unchanged source; custom notations register once through the shared
/// [LegendMarkdownSyntax] registry and both highlight here and render in
/// `LegendMarkdown`.
///
/// Exists because every wrappable editor engine interposes its own
/// document model and input stack (RFC-005 §1) — the fork class of bug
/// DESIGN §3 was written to kill.
///
/// Keyboard conveniences ([LegendMarkdownEdits], all plain text edits):
/// Enter continues a list (an empty item ends it), Tab/Shift-Tab
/// indent/outdent list items, Cmd/Ctrl+B and Cmd/Ctrl+I toggle `**`/`*`
/// around the selection. A live preview is app-level composition — pair
/// the controller's text with a `LegendMarkdown` beside the editor.
@LegendThemeable()
class LegendMarkdownEditor extends StatefulWidget {
  const LegendMarkdownEditor({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.placeholder,
    this.syntaxes = const [],
    this.readOnly = false,
    this.autofocus = false,
    this.minLines,
    this.scrollController,
    this.scrollPhysics,
    this.textStyle,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.syntaxMarkColor,
    this.codeStyle,
    this.codeBackground,
    this.linkColor,
    this.blockquoteColor,
    this.markerColor,
    this.background,
    this.borderRadius,
    this.padding,
    this.borderColor,
    this.focusedBorderColor,
  });

  /// The edited markdown source; when null the editor owns one.
  final LegendMarkdownEditingController? controller;

  /// The editor's focus; when null the editor owns one.
  final FocusNode? focusNode;

  /// Invoked with the full source after every edit, keyboard conveniences
  /// included.
  final ValueChanged<String>? onChanged;

  /// Hint shown while the source is empty.
  final String? placeholder;

  /// Custom notations highlighted in addition to the built-in markdown
  /// syntax — the shared registry of RFC-005 §3.3; a registration's
  /// [LegendMarkdownSyntax.highlight] rule styles its raw source here.
  final List<LegendMarkdownSyntax> syntaxes;

  /// When true the source can be selected and copied but not edited.
  final bool readOnly;

  final bool autofocus;

  /// Minimum visible lines the editor reserves before it grows.
  final int? minLines;

  /// Scroll position of the growing source; owned by the caller.
  final ScrollController? scrollController;

  /// Scroll physics of the growing source.
  final ScrollPhysics? scrollPhysics;

  /// Base style of the markdown source text.
  @Style<TextStyle>.resolve(TextRef.b1)
  final TextStyle? textStyle;

  /// Emphasis style merged over `#` heading lines.
  @Style<TextStyle>.resolve(TextRef.h1)
  final TextStyle? h1Style;

  /// Emphasis style merged over `##` heading lines.
  @Style<TextStyle>.resolve(TextRef.h2)
  final TextStyle? h2Style;

  /// Emphasis style merged over `###` heading lines.
  @Style<TextStyle>.resolve(TextRef.h3)
  final TextStyle? h3Style;

  /// Muted color of the syntax marks themselves — `#`, `**`, backticks,
  /// brackets, and fence delimiters.
  @Style<Color>.resolve(ColorRef.foreground3)
  final Color? syntaxMarkColor;

  /// Monospace style of inline code spans and fenced code lines.
  @Style<TextStyle>.resolve(_codeStyle)
  final TextStyle? codeStyle;

  /// Background tint behind inline code spans and fenced code lines.
  @Style<Color>.resolve(ColorRef.background2)
  final Color? codeBackground;

  /// Color of link text in the source (the URL renders as a syntax mark).
  @Style<Color>.resolve(ColorRef.primary)
  final Color? linkColor;

  /// Color of quoted content on `>` lines.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? blockquoteColor;

  /// Color of list bullets and numbers in the source.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? markerColor;

  /// Fill color of the editor surface.
  @Style<Color>.resolve(ColorRef.background1)
  final Color? background;

  /// Corner rounding of the editor surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding between the border and the source text.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Border color while unfocused.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? borderColor;

  /// Border color while focused — also the caret and selection color.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? focusedBorderColor;

  @override
  State<LegendMarkdownEditor> createState() => _LegendMarkdownEditorState();
}

TextStyle _codeStyle(LegendTokens t) => t.typography.b1.copyWith(
  fontFamily: 'monospace',
  fontFamilyFallback: const ['Menlo', 'Courier'],
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.md);

class _LegendMarkdownEditorState extends State<LegendMarkdownEditor> {
  LegendMarkdownEditingController? _ownController;
  FocusNode? _ownFocusNode;

  LegendMarkdownEditingController get _controller =>
      widget.controller ??
      (_ownController ??= LegendMarkdownEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onStateChange);
    _controller.addListener(_onStateChange);
  }

  @override
  void didUpdateWidget(LegendMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.controller != widget.controller) {
      // Own instances are stable; only external swaps need re-listening.
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onStateChange);
      (oldWidget.controller ?? _ownController)?.removeListener(_onStateChange);
      _focusNode.addListener(_onStateChange);
      _controller.addListener(_onStateChange);
    }
  }

  /// Rebuild on focus flips (border color) and text changes (placeholder).
  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChange);
    _controller.removeListener(_onStateChange);
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  /// The convenience-key hook: transforms are pure edits on the current
  /// value; anything they decline falls through to default handling.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (widget.readOnly) return KeyEventResult.ignored;
    // Never fight the IME while it holds a composing region.
    if (_controller.value.composing.isValid) return KeyEventResult.ignored;

    final keyboard = HardwareKeyboard.instance;
    final shortcut = keyboard.isMetaPressed || keyboard.isControlPressed;
    final key = event.logicalKey;
    TextEditingValue? next;
    if (key == LogicalKeyboardKey.enter &&
        !shortcut &&
        !keyboard.isShiftPressed &&
        !keyboard.isAltPressed) {
      next = LegendMarkdownEdits.continueList(_controller.value);
    } else if (key == LogicalKeyboardKey.tab && !shortcut) {
      next = keyboard.isShiftPressed
          ? LegendMarkdownEdits.outdent(_controller.value)
          : LegendMarkdownEdits.indent(_controller.value);
    } else if (key == LogicalKeyboardKey.keyB && shortcut) {
      next = LegendMarkdownEdits.toggleInline(_controller.value, '**');
    } else if (key == LogicalKeyboardKey.keyI && shortcut) {
      next = LegendMarkdownEdits.toggleInline(_controller.value, '*');
    }
    if (next == null) return KeyEventResult.ignored;
    final changed = next.text != _controller.text;
    _controller.value = next;
    if (changed) widget.onChanged?.call(next.text);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final controller = _controller
      // Imperative consumers: assigned before the next paint builds spans,
      // never a rebuild source.
      ..sourceStyle = LegendMarkdownSourceStyle(
        h1Style: theme.h1Style,
        h2Style: theme.h2Style,
        h3Style: theme.h3Style,
        syntaxMarkColor: theme.syntaxMarkColor,
        codeStyle: theme.codeStyle,
        codeBackground: theme.codeBackground,
        linkColor: theme.linkColor,
        blockquoteColor: theme.blockquoteColor,
        markerColor: theme.markerColor,
      )
      ..syntaxes = widget.syntaxes;
    final focused = _focusNode.hasFocus;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: LegendSurface(
          color: theme.background,
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: focused ? theme.focusedBorderColor : theme.borderColor,
            width: tokens.sizes.borderWidth,
          ),
          padding: theme.padding,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            children: [
              if (controller.text.isEmpty && widget.placeholder != null)
                ExcludeSemantics(
                  child: Text(
                    widget.placeholder!,
                    style: theme.textStyle.copyWith(
                      color: tokens.colors.foreground3,
                    ),
                  ),
                ),
              LegendFieldCore(
                controller: controller,
                focusNode: _focusNode,
                style: theme.textStyle.copyWith(
                  color: tokens.colors.foreground1,
                ),
                cursorColor: theme.focusedBorderColor,
                backgroundCursorColor: theme.borderColor,
                selectionColor: theme.focusedBorderColor.withValues(alpha: 0.3),
                autofocus: widget.autofocus,
                readOnly: widget.readOnly,
                maxLines: null,
                minLines: widget.minLines,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollController: widget.scrollController,
                scrollPhysics: widget.scrollPhysics,
                onChanged: widget.onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
