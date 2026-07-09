import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/expandable/nomo_expandable.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_caret.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// A header that expands and collapses its [child] with an animated size
/// change and a rotating [NomoCaret].
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
@NomoThemeable()
class NomoExpandable extends StatefulWidget {
  const NomoExpandable({
    required this.child,
    super.key,
    this.title,
    this.header,
    this.expanded,
    this.onToggle,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 200),
    this.headerPadding,
    this.backgroundColor,
    this.borderRadius,
  }) : assert(
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

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? headerPadding;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? backgroundColor;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? borderRadius;

  @override
  State<NomoExpandable> createState() => _NomoExpandableState();
}

class _NomoExpandableState extends State<NomoExpandable> {
  late bool _expanded = widget.expanded ?? widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) setState(() => _expanded = next);
    widget.onToggle?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NomoExpandableTheme.of(
      context,
      NomoExpandableThemeNullable(
        headerPadding: widget.headerPadding,
        backgroundColor: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    final expanded = _isExpanded;

    return NomoSurface(
      color: theme.backgroundColor,
      borderRadius: theme.borderRadius,
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NomoInteractive(
            semanticLabel: widget.title,
            onTap: _toggle,
            builder: (context, states) {
              return NomoSurface(
                color: states.hovered || states.focused
                    ? tokens.colors.background2
                    : theme.backgroundColor,
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
                    NomoCaret(
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
