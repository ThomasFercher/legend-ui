import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

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
  /// The [menuBackground] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendContextMenu({
    required this.entries,
    required this.child,
    super.key,
    this.enabled = true,
    Color? menuBackground,
    this.menuBorderRadius,
    this.menuShadows,
    this.itemPadding,
    this.textStyle,
  }) : menuBackground = menuBackground == null
           ? null
           : InteractiveColors(normal: menuBackground);

  final List<LegendContextMenuEntry> entries;
  final Widget child;

  /// When false, secondary taps and long-presses do nothing.
  final bool enabled;

  /// Fill of the menu surface and its entries, per interaction state —
  /// `normal` paints the whole menu, `hovered`/`pressed`/`focused`
  /// highlight the entry under the pointer.
  @Style<InteractiveColors>.resolve(_menuBackground)
  final InteractiveColors? menuBackground;

  /// Corner rounding of the menu surface.
  @Style<BorderRadius>.resolve(_menuBorderRadius)
  final BorderRadius? menuBorderRadius;

  /// Drop shadow lifting the menu off the page.
  @Style<List<BoxShadow>>.resolve(ShadowRef.medium)
  final List<BoxShadow>? menuShadows;

  /// Inner padding of each menu entry row.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Text style of the entry labels.
  @Style<TextStyle>.resolve(TextRef.b2)
  final TextStyle? textStyle;

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
        color: theme.menuBackground.normal,
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
                  color: theme.menuBackground.resolve(
                    states.effective,
                    tokens.states,
                  ),
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

InteractiveColors _menuBackground(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

BorderRadius _menuBorderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
