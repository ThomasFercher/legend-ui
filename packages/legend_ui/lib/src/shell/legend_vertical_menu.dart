import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_caret.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/shell/legend_nav_item.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_vertical_menu.theme.g.dart';

/// A vertical navigation menu with expandable sections and a selected
/// state — the improved port of legacy `NomoVerticalMenu`.
///
/// Composes [LegendInteractive] (row activation + hover/press states),
/// [LegendSurface] (row fill and rounding) and [LegendCaret] (the
/// section disclosure indicator); destinations are the shared
/// [LegendNavItem] model — an item with [LegendNavItem.children] is an
/// expandable section (one item model, no per-surface types — DESIGN.md
/// §3 consolidation).
///
/// Replaces legacy `NomoVerticalMenu` + `NomoVerticalListTile`, whose
/// selection/expansion animation ran through per-tile `AnimationController`s
/// driven imperatively inside `build`, plus a `Scrollable.ensureVisible`
/// fired from a post-frame callback in `didChangeDependencies` — a
/// setState/reveal storm on every dependency change (legacy-docs 01 §4.2).
/// This version keeps expansion in a single [State] `Set` and animates
/// declaratively with [AnimatedSize]; it needs no `addPostFrameCallback`
/// and no per-row controllers.
@LegendThemeable()
class LegendVerticalMenu extends StatefulWidget {
  /// The [background] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendVerticalMenu({
    required this.items,
    super.key,
    this.selected,
    this.onSelected,
    this.initiallyExpanded,
    this.duration = const Duration(milliseconds: 200),
    Color? background,
    this.selectedColor,
    this.unselectedColor,
    this.selectedBackground,
    this.itemPadding,
    this.itemSpacing,
    this.borderRadius,
  }) : itemColors = background == null
           ? null
           : InteractiveColors(normal: background);

  /// The destinations; an item with [LegendNavItem.children] renders as an
  /// expandable section whose leaves are selectable.
  final List<LegendNavItem> items;

  /// The currently selected item, compared by identity/equality; a section
  /// parent is never itself selected.
  final LegendNavItem? selected;

  /// Called when a leaf destination is activated (section parents toggle
  /// their expansion instead of reporting selection).
  final ValueChanged<LegendNavItem>? onSelected;

  /// Sections listed here start expanded; null expands none. Expansion is
  /// owned by the menu thereafter.
  final Set<LegendNavItem>? initiallyExpanded;

  /// Expand/collapse (and caret) animation duration.
  final Duration duration;

  /// Fill of each row per interaction state — `normal` is the resting row,
  /// `hovered`/`pressed`/`focused` tint the row under the pointer (a
  /// selected row uses [selectedBackground] instead).
  @Style<InteractiveColors>.resolve(_itemColors)
  final InteractiveColors? itemColors;

  /// Label/icon color of the selected item.
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? selectedColor;

  /// Label/icon color of unselected items.
  @Style<Color>.resolve(ColorRef.foreground2, lerp: true)
  final Color? unselectedColor;

  /// Fill behind the selected row.
  @Style<Color>.resolve(ColorRef.primaryContainer, lerp: true)
  final Color? selectedBackground;

  /// Inner padding of each row.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  /// Vertical gap between rows.
  @Style<double>.resolve(SizeRef.xs)
  final double? itemSpacing;

  /// Corner rounding of each row surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  @override
  State<LegendVerticalMenu> createState() => _LegendVerticalMenuState();
}

class _LegendVerticalMenuState extends State<LegendVerticalMenu> {
  /// Expanded sections, by item identity — the whole expansion model,
  /// updated only by plain setState (no controllers, no post-frame work).
  late final Set<LegendNavItem> _expanded = {...?widget.initiallyExpanded};

  void _toggle(LegendNavItem item) => setState(() {
    if (!_expanded.remove(item)) _expanded.add(item);
  });

  bool _isSelected(LegendNavItem item) => item == widget.selected;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    return LegendSurface(
      color: theme.itemColors.normal,
      duration: const Duration(milliseconds: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in widget.items)
            Padding(
              padding: EdgeInsets.only(bottom: theme.itemSpacing),
              child: _node(item, tokens, depth: 0),
            ),
        ],
      ),
    );
  }

  /// One item and (if a section) its animated children. Depth drives the
  /// leading indent so nesting reads at a glance.
  Widget _node(LegendNavItem item, LegendTokens tokens, {required int depth}) {
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final expanded = _expanded.contains(item);

    final row = _row(
      item,
      tokens,
      depth: depth,
      expandable: hasChildren,
      expanded: expanded,
    );

    if (!hasChildren) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        AnimatedSize(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(top: theme.itemSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final child in item.children!)
                        Padding(
                          padding: EdgeInsets.only(bottom: theme.itemSpacing),
                          child: _node(child, tokens, depth: depth + 1),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _row(
    LegendNavItem item,
    LegendTokens tokens, {
    required int depth,
    required bool expandable,
    required bool expanded,
  }) {
    final theme = this.theme;
    final selected = _isSelected(item);
    final foreground = selected ? theme.selectedColor : theme.unselectedColor;
    final indent = tokens.sizes.md * depth;

    return LegendInteractive(
      semanticLabel: item.label,
      toggled: expandable ? expanded : null,
      onTap: () {
        if (expandable) {
          _toggle(item);
        } else {
          widget.onSelected?.call(item);
        }
      },
      builder: (context, states) {
        return LegendSurface(
          color: selected
              ? theme.selectedBackground
              : theme.itemColors.resolve(states.effective, tokens.states),
          borderRadius: theme.borderRadius,
          padding: theme.itemPadding.add(EdgeInsets.only(left: indent)),
          duration: const Duration(milliseconds: 120),
          child: Row(
            spacing: tokens.sizes.sm,
            children: [
              ?item.buildIcon(foreground, tokens.sizes.iconMd),
              Expanded(
                child: Text(
                  item.label,
                  style: tokens.typography.b2.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (expandable)
                LegendCaret(
                  color: foreground,
                  open: expanded,
                  duration: widget.duration,
                ),
            ],
          ),
        );
      },
    );
  }
}

InteractiveColors _itemColors(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;
