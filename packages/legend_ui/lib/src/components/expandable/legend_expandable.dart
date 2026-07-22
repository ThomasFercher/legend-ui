import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_expandable.theme.g.dart';

/// A header that expands and collapses its [child] with an animated size
/// change.
///
/// Composes [LegendInteractive] (header activation) + [LegendSurface]
/// (container and hover tint) + [LegendCaret] (rotating disclosure
/// indicator). The header announces its expanded/collapsed state to
/// assistive tech.
///
/// Works in two modes:
/// - **Uncontrolled** (default): leave [expanded] null; the widget owns the
///   state, starting at [initiallyExpanded]. [onToggle] still reports every
///   change.
/// - **Controlled**: pass [expanded]; the widget renders exactly that state
///   and header taps only call [onToggle] — the owner decides.
///
/// Provide either a [title] (styled with the token typography) or a fully
/// custom [header] widget.
@LegendThemeable()
class LegendExpandable extends StatefulWidget {
  /// The [backgroundColor] lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendExpandable({
    required this.child,
    super.key,
    this.title,
    this.header,
    this.expanded,
    this.onToggle,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 200),
    this.headerPadding,
    this.titleStyle,
    Color? backgroundColor,
    this.borderRadius,
    this.caretColor,
  }) : backgroundColor = backgroundColor == null
           ? null
           : InteractiveColors(normal: backgroundColor),
       assert(
         title != null || header != null,
         'Provide a title or a custom header.',
       );

  /// The content revealed when expanded.
  final Widget child;

  /// Header text; ignored when [header] is set.
  final String? title;

  /// Custom header content, laid out before the caret.
  final Widget? header;

  /// Controlled expansion state; null means uncontrolled.
  final bool? expanded;

  /// Called with the requested state whenever the header is activated.
  final ValueChanged<bool>? onToggle;

  /// Initial state in uncontrolled mode.
  final bool initiallyExpanded;

  /// How long the expand/collapse (and caret) animation takes.
  final Duration duration;

  /// Inner padding of the header row.
  @Style<EdgeInsetsGeometry>.resolve(_headerPadding)
  final EdgeInsetsGeometry? headerPadding;

  /// Style of the [title] text; unused when a custom [header] is set.
  @Style<TextStyle>.resolve(_titleStyle)
  final TextStyle? titleStyle;

  /// Fill of the container and its header, per interaction state —
  /// `normal` paints the whole surface, `hovered`/`pressed`/`focused`
  /// tint the header while the pointer is on it.
  @Style<InteractiveColors>.resolve(_backgroundColor)
  final InteractiveColors? backgroundColor;

  /// Corner rounding of the container surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Color of the rotating caret glyph.
  @Style<Color>.resolve(ColorRef.foreground2)
  final Color? caretColor;

  @override
  State<LegendExpandable> createState() => _LegendExpandableState();
}

class _LegendExpandableState extends State<LegendExpandable> {
  late bool _expanded = widget.expanded ?? widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onToggle?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final expanded = _isExpanded;

    return LegendSurface(
      color: theme.backgroundColor.normal,
      borderRadius: theme.borderRadius,
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The expanded flag merges onto the header's button node, so
          // assistive tech announces the disclosure state it toggles.
          Semantics(
            expanded: expanded,
            child: LegendInteractive(
              semanticLabel: widget.title,
              onTap: _toggle,
              builder: (context, states) {
                return LegendSurface(
                  color: theme.backgroundColor.resolve(
                    states.effective,
                    tokens.states,
                  ),
                  padding: theme.headerPadding,
                  duration: widget.duration,
                  child: Row(
                    spacing: tokens.sizes.sm,
                    children: [
                      Expanded(
                        child:
                            widget.header ??
                            Text(widget.title!, style: theme.titleStyle),
                      ),
                      LegendCaret(
                        color: theme.caretColor,
                        open: expanded,
                        duration: widget.duration,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          AnimatedSize(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? SizedBox(width: double.infinity, child: widget.child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

EdgeInsetsGeometry _headerPadding(LegendTokens t) => EdgeInsets.all(t.sizes.md);

TextStyle _titleStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground1);

InteractiveColors _backgroundColor(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;
