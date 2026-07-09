import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_states.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_expandable.theme.g.dart';

/// A header that expands and collapses its [child] with an animated size
/// change.
///
/// Composes [LegendInteractive] (header activation) + [LegendSurface]
/// (container and hover tint) + [LegendCaret] (rotating disclosure
/// indicator).
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
    Color? backgroundColor,
    this.borderRadius,
  }) : backgroundColor = backgroundColor?.states,
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
  static EdgeInsetsGeometry _headerPadding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  /// Fill of the container and its header, per interaction state —
  /// `normal` paints the whole surface, `hovered`/`pressed`/`focused`
  /// tint the header while the pointer is on it.
  @Style<LegendStates<Color>>.resolve(_backgroundColor)
  final LegendStates<Color>? backgroundColor;
  static LegendStates<Color> _backgroundColor(LegendTokens t) => LegendStates(
    normal: t.colors.surface,
    hovered: t.colors.background2,
    pressed: t.colors.background2,
    focused: t.colors.background2,
  );

  /// Corner rounding of the container surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

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
    final theme = widget._theme(context);
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
          LegendInteractive(
            semanticLabel: widget.title,
            onTap: _toggle,
            builder: (context, states) {
              return LegendSurface(
                color: theme.backgroundColor.pick(states.effective),
                padding: theme.headerPadding,
                duration: widget.duration,
                child: Row(
                  spacing: tokens.sizes.sm,
                  children: [
                    Expanded(
                      child:
                          widget.header ??
                          Text(
                            widget.title!,
                            style: tokens.typography.b2.copyWith(
                              color: tokens.colors.foreground1,
                            ),
                          ),
                    ),
                    LegendCaret(
                      color: tokens.colors.foreground2,
                      open: expanded,
                      duration: widget.duration,
                    ),
                  ],
                ),
              );
            },
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
