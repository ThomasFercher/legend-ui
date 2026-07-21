import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/shell/legend_nav_item.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_tabs.theme.g.dart';

/// A horizontal tab bar switching between peer views — a controlled
/// component: [selectedIndex] names the active tab, [onSelected] reports
/// activation, the selection state lives with the caller (the same idiom
/// as `LegendSider`/`LegendBottomBar`).
///
/// Composes [LegendInteractive] (per-tab activation, hover/press/focus) +
/// [LegendSurface] (tab fill; the active indicator is its animated bottom
/// border); tab entries come from the shared [LegendNavItem] model
/// (nested `children` are ignored — a tab bar is flat).
///
/// Keyboard: arrow keys move focus between tabs (wrapping, mirrored under
/// right-to-left layouts), Home/End jump to the first/last tab, and
/// Enter/Space activates the focused tab. Each tab announces as a
/// [SemanticsRole.tab] with its selected state under a
/// [SemanticsRole.tabBar] bar.
@LegendThemeable()
class LegendTabs extends StatefulWidget {
  /// The [background] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendTabs({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.semanticLabel,
    Color? background,
    this.indicator,
    this.indicatorThickness,
    this.selectedColor,
    this.unselectedColor,
    this.padding,
  }) : background = background == null
           ? null
           : InteractiveColors(normal: background),
       assert(items.isNotEmpty, 'LegendTabs needs at least one tab.'),
       assert(
         selectedIndex >= 0 && selectedIndex < items.length,
         'selectedIndex must be a valid index into items.',
       );

  final List<LegendNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// What this tab bar switches (e.g. 'Wallet sections') — announced on
  /// the bar itself; each tab is labeled by its item.
  final String? semanticLabel;

  /// Fill of each tab per interaction state — an unset `normal` keeps
  /// tabs transparent; `hovered`/`pressed`/`focused` tint the tab under
  /// the pointer (and the keyboard focus).
  @Style<InteractiveColors>.resolve(_background)
  final InteractiveColors? background;

  /// Color of the active-tab indicator line.
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? indicator;

  /// Stroke height of the active-tab indicator line.
  @Style<double>(2)
  final double? indicatorThickness;

  /// Label/icon color of the selected tab.
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? selectedColor;

  /// Label/icon color of unselected tabs.
  @Style<Color>.resolve(ColorRef.foreground2, lerp: true)
  final Color? unselectedColor;

  /// Inner padding of each tab.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  @override
  State<LegendTabs> createState() => _LegendTabsState();
}

class _LegendTabsState extends State<LegendTabs> {
  /// One focus node per tab, grown on demand and never shrunk mid-life —
  /// disposing a node while its Focus widget is still attached asserts,
  /// so nodes of removed tabs idle detached until [dispose].
  final _nodes = <FocusNode>[];

  FocusNode _nodeAt(int index) {
    while (_nodes.length <= index) {
      _nodes.add(FocusNode(debugLabel: 'LegendTabs tab ${_nodes.length}'));
    }
    return _nodes[index];
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Moves focus [delta] tabs over from the currently focused one,
  /// wrapping at both ends.
  void _focusRelative(int delta) {
    final count = widget.items.length;
    final current = _nodes.indexWhere((node) => node.hasFocus);
    if (current < 0) return;
    _nodeAt((current + delta) % count).requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    // Arrows follow the visual order, so they mirror under RTL.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _focusRelative(rtl ? -1 : 1);
      case LogicalKeyboardKey.arrowLeft:
        _focusRelative(rtl ? 1 : -1);
      case LogicalKeyboardKey.home:
        _nodeAt(0).requestFocus();
      case LogicalKeyboardKey.end:
        _nodeAt(widget.items.length - 1).requestFocus();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _tab(
    int index,
    LegendNavItem item,
    LegendTabsTheme theme,
    LegendTokens tokens,
  ) {
    final selected = index == widget.selectedIndex;
    // One merged node per tab: the tab role and selected state fuse with
    // LegendInteractive's activation semantics and the label text, so
    // assistive tech announces (and activates) a single tab.
    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        child: LegendInteractive(
          focusNode: _nodeAt(index),
          onTap: () => widget.onSelected(index),
          builder: (context, states) {
            final color = selected
                ? theme.selectedColor
                : theme.unselectedColor;
            return LegendSurface(
              color: theme.background.resolve(states.effective, tokens.states),
              // The indicator: a bottom border that spans the tab and
              // stays transparent while unselected, so selection changes
              // fade without shifting layout.
              border: Border(
                bottom: BorderSide(
                  color: selected ? theme.indicator : const Color(0x00000000),
                  width: theme.indicatorThickness,
                ),
              ),
              padding: theme.padding,
              duration: const Duration(milliseconds: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.sizes.xs,
                children: [
                  ?item.buildIcon(color, tokens.sizes.iconMd),
                  Text(
                    item.label,
                    style: tokens.typography.b2.copyWith(color: color),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;

    return Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      // The Focus wrapper only routes arrow/Home/End keys bubbling up from
      // the focused tab — it is not itself focusable, traversable, or a
      // semantics node (which would break the tabBar → tab child chain).
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _onKeyEvent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, item) in widget.items.indexed)
              _tab(index, item, theme, tokens),
          ],
        ),
      ),
    );
  }
}

InteractiveColors _background(LegendTokens t) => InteractiveColors(
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
