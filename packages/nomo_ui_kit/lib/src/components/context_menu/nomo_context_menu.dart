import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/context_menu/nomo_context_menu.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_anchored_overlay.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// One action in a [NomoContextMenu].
///
/// The kit is icon-agnostic (DESIGN.md §4), so [icon] is any widget —
/// typically an `Icon` from the app's own icon set.
class NomoContextMenuEntry {
  const NomoContextMenuEntry({
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
/// Built on [NomoAnchoredOverlay] + [NomoSurface]: the menu sizes itself
/// to its entries (no magic size constants), dismisses on outside tap, and
/// closes itself after a selection — legacy handed callers a raw
/// `OverlayEntry` to manage by hand (legacy-docs 01 §4.2).
@NomoThemeable()
class NomoContextMenu extends StatefulWidget {
  const NomoContextMenu({
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

  final List<NomoContextMenuEntry> entries;
  final Widget child;

  /// When false, secondary taps and long-presses do nothing.
  final bool enabled;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? menuBackground;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? menuBorderRadius;

  @Themed(defaultsTo: 't.shadows.medium')
  final List<BoxShadow>? menuShadows;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? itemPadding;

  @Themed(defaultsTo: 't.typography.b2')
  final TextStyle? textStyle;

  @override
  State<NomoContextMenu> createState() => _NomoContextMenuState();
}

class _NomoContextMenuState extends State<NomoContextMenu> {
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

  void _select(NomoContextMenuEntry entry) {
    _close();
    entry.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NomoContextMenuTheme.of(
      context,
      NomoContextMenuThemeNullable(
        menuBackground: widget.menuBackground,
        menuBorderRadius: widget.menuBorderRadius,
        menuShadows: widget.menuShadows,
        itemPadding: widget.itemPadding,
        textStyle: widget.textStyle,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;

    return NomoAnchoredOverlay(
      controller: _controller,
      anchorAlignment: Alignment.topLeft,
      offset: _anchorOffset,
      onDismiss: _close,
      overlay: (context) => NomoSurface(
        color: theme.menuBackground,
        borderRadius: theme.menuBorderRadius,
        shadows: theme.menuShadows,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in widget.entries)
              NomoInteractive(
                semanticLabel: entry.label,
                onTap: () => _select(entry),
                builder: (context, states) => NomoSurface(
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
