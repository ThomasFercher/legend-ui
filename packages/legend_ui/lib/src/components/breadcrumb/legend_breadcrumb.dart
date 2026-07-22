import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_breadcrumb.theme.g.dart';

/// One level of a [LegendBreadcrumb] trail.
class LegendBreadcrumbItem {
  const LegendBreadcrumbItem({required this.label, this.onTap});

  final String label;

  /// Navigates to this level. Null renders the item as plain text; the
  /// last item (the current page) never activates regardless.
  final VoidCallback? onTap;
}

/// An inline trail of ancestor links ending in the current page — every
/// item but the last is a tappable link, the last renders muted and inert
/// with selected semantics.
///
/// Composes [LegendInteractive] (per-link activation, hover/press/focus)
/// and [LegendCaret] (the painted chevron separator, pointing along the
/// text direction).
///
/// A long trail collapses through [maxVisible]: the first item stays, a
/// non-tappable middle ellipsis stands in for the hidden levels, and the
/// trail's tail keeps the remaining slots. Labels are plain [Text], so the
/// trail participates in web text selection.
@LegendThemeable()
class LegendBreadcrumb extends StatelessWidget {
  const LegendBreadcrumb({
    required this.items,
    super.key,
    this.maxVisible,
    this.semanticLabel,
    this.separator,
    this.linkStyle,
    this.currentStyle,
    this.separatorColor,
    this.itemPadding,
    this.spacing,
  }) : assert(items.length > 0, 'items must not be empty.'),
       assert(
         maxVisible == null || maxVisible >= 3,
         'maxVisible must be at least 3 (first item, ellipsis, current '
         'page).',
       );

  /// The trail, root first; the last item is the current page.
  final List<LegendBreadcrumbItem> items;

  /// Most items shown before the middle collapses into an ellipsis; null
  /// never collapses.
  final int? maxVisible;

  /// What this trail locates (e.g. 'You are here') — announced on the
  /// trail itself; each link is labeled by its item.
  final String? semanticLabel;

  /// Custom separator between items, replacing the painted chevron.
  final Widget? separator;

  /// Text style of the tappable ancestor links.
  @Style<TextStyle>.resolve(_linkStyle)
  final TextStyle? linkStyle;

  /// Text style of the trailing current-page item.
  @Style<TextStyle>.resolve(_currentStyle)
  final TextStyle? currentStyle;

  /// Color of the chevron separator between items.
  @Style<Color>.resolve(ColorRef.foreground3, lerp: true)
  final Color? separatorColor;

  /// Inner padding of each item, around its label.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Gap between an item and its separator.
  @Style<double>.resolve(SizeRef.xs)
  final double? spacing;

  Widget _link(
    LegendBreadcrumbItem item,
    LegendBreadcrumbTheme theme,
    LegendTokens tokens,
  ) {
    return LegendInteractive(
      onTap: item.onTap,
      builder: (context, states) {
        var style = theme.linkStyle;
        if (states.hovered || states.pressed) {
          style = style.copyWith(color: tokens.colors.foreground1);
        }
        // Link-ish affordance: hover (and keyboard focus) underlines.
        if (states.hovered || states.pressed || states.focused) {
          style = style.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: style.color,
          );
        }
        return Padding(
          padding: theme.itemPadding,
          child: Text(item.label, style: style),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    // The chevron points forward along the reading direction.
    final forwardTurns = Directionality.of(context) == TextDirection.rtl
        ? 1
        : 3;

    final visible = _collapse(items, maxVisible);
    final children = <Widget>[];
    for (final (index, item) in visible.indexed) {
      final last = index == visible.length - 1;
      final Widget cell;
      if (item == null || (!last && item.onTap == null)) {
        // The ellipsis stand-in, or a link-less ancestor: plain text.
        cell = ExcludeSemantics(
          excluding: item == null,
          child: Padding(
            padding: theme.itemPadding,
            child: Text(item?.label ?? '…', style: theme.linkStyle),
          ),
        );
      } else if (last) {
        cell = Semantics(
          selected: true,
          child: Padding(
            padding: theme.itemPadding,
            child: Text(item.label, style: theme.currentStyle),
          ),
        );
      } else {
        cell = _link(item, theme, tokens);
      }
      if (last) {
        children.add(cell);
      } else {
        // Each separator rides in its item's cell so a wrapping trail
        // never opens a run with a dangling chevron.
        children.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.spacing,
            children: [
              cell,
              ExcludeSemantics(
                child:
                    separator ??
                    RotatedBox(
                      quarterTurns: forwardTurns,
                      child: LegendCaret(
                        color: theme.separatorColor,
                        open: false,
                      ),
                    ),
              ),
            ],
          ),
        );
      }
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Wrap(
        spacing: theme.spacing,
        runSpacing: tokens.sizes.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// The rendered trail: every item, or — once [maxVisible] is exceeded —
/// the first item, a null ellipsis marker, and the trailing items filling
/// the remaining slots.
List<LegendBreadcrumbItem?> _collapse(
  List<LegendBreadcrumbItem> items,
  int? maxVisible,
) {
  if (maxVisible == null || items.length <= maxVisible) return items;
  return [items.first, null, ...items.sublist(items.length - maxVisible + 2)];
}

TextStyle _linkStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground2);

TextStyle _currentStyle(LegendTokens t) => t.typography.b2.copyWith(
  color: t.colors.foreground1,
  fontWeight: FontWeight.w600,
);

EdgeInsetsGeometry _itemPadding(LegendTokens t) => EdgeInsets.all(t.sizes.xs);
