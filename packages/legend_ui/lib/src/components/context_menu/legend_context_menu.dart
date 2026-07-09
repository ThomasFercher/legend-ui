import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_context_menu.theme.g.dart';

/// One action in a [LegendContextMenu].
///
/// The kit is icon-agnostic (DESIGN.md §4), so [icon] is any widget —
/// typically an `Icon` from the app's own icon set.
class LegendContextMenuEntry {
  const LegendContextMenuEntry({
    required this.label,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final Widget? icon;
  final VoidCallback onSelected;
}

/// Wraps [child] and opens an anchored action menu at the pointer on
/// secondary tap (desktop right-click) or long-press (touch).
///
/// Built on [LegendAnchoredOverlay] + [LegendSurface]: the menu sizes itself
/// to its entries (no magic size constants), dismisses on outside tap, and
/// closes itself after a selection — legacy handed callers a raw
/// `OverlayEntry` to manage by hand (legacy-docs 01 §4.2).
@LegendThemeable()
class LegendContextMenu extends StatefulWidget {
  const LegendContextMenu({
    required this.entries,
    required this.child,
    super.key,
    this.enabled = true,
    this.menuBackground,
    this.menuBorderRadius,
    this.menuShadows,
    this.itemPadding,
    this.textStyle,
  });

  final List<LegendContextMenuEntry> entries;
  final Widget child;

  /// When false, secondary taps and long-presses do nothing.
  final bool enabled;

  @Style<Color>.resolve(_menuBackground)
  final Color? menuBackground;
  static Color _menuBackground(LegendTokens t) => t.colors.surface;

  @Style<BorderRadius>.resolve(_menuBorderRadius)
  final BorderRadius? menuBorderRadius;
  static BorderRadius _menuBorderRadius(LegendTokens t) =>
      t.sizes.borderRadiusMd;

  @Style<List<BoxShadow>>.resolve(_menuShadows)
  final List<BoxShadow>? menuShadows;
  static List<BoxShadow> _menuShadows(LegendTokens t) => t.shadows.medium;

  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;
  static EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
      EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;
  static TextStyle _textStyle(LegendTokens t) => t.typography.b2;

  @override
  State<LegendContextMenu> createState() => _LegendContextMenuState();
}

class _LegendContextMenuState extends State<LegendContextMenu> {
  final _controller = OverlayPortalController();

  /// Where the menu attaches, relative to the child's top-left — set to
  /// the pointer position on each open.
  var _anchorOffset = Offset.zero;

  void _openAt(Offset localPosition) {
    if (!widget.enabled || widget.entries.isEmpty) return;
    setState(() => _anchorOffset = localPosition);
    _controller.show();
  }

  void _close() {
    _controller.hide();
    setState(() {});
  }

  void _select(LegendContextMenuEntry entry) {
    _close();
    entry.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget._theme(context);
    final tokens = LegendTheme.of(context).tokens;

    return LegendAnchoredOverlay(
      controller: _controller,
      anchorAlignment: Alignment.topLeft,
      offset: _anchorOffset,
      onDismiss: _close,
      overlay: (context) => LegendSurface(
        color: theme.menuBackground,
        borderRadius: theme.menuBorderRadius,
        shadows: theme.menuShadows,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in widget.entries)
              LegendInteractive(
                semanticLabel: entry.label,
                onTap: () => _select(entry),
                builder: (context, states) => LegendSurface(
                  color: states.hovered || states.focused
                      ? tokens.colors.background2
                      : theme.menuBackground,
                  padding: theme.itemPadding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.sizes.sm,
                    children: [
                      if (entry.icon != null) entry.icon!,
                      Text(
                        entry.label,
                        style: theme.textStyle.copyWith(
                          color: tokens.colors.foreground1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (details) => _openAt(details.localPosition),
        onLongPressStart: (details) => _openAt(details.localPosition),
        child: widget.child,
      ),
    );
  }
}
