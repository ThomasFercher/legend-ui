import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/shell/legend_nav_item.dart';
import 'package:legend_ui/src/theme/legend_states.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_sider.theme.g.dart';

/// Wide-tier side navigation; `LegendScaffold` shows it at medium/expanded
/// tiers.
///
/// Composes [LegendInteractive] (item activation) + [LegendSurface];
/// destinations come from the shared [LegendNavItem] model.
@LegendThemeable()
class LegendSider extends StatelessWidget {
  /// The [background] color lifts into the `normal` member of the
  /// per-state theme field (RFC-002 R6).
  LegendSider({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.header,
    this.footer,
    Color? background,
    this.width,
    this.selectedColor,
    this.unselectedColor,
    this.itemPadding,
  }) : background = background?.states;

  final List<LegendNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;

  /// Fill of the sider surface and its items, per interaction state —
  /// `normal` paints the whole rail, `hovered`/`pressed`/`focused`
  /// highlight the item under the pointer (a selected item uses the
  /// `primaryContainer` token instead).
  @Style<LegendStates<Color>>.resolve(_background)
  final LegendStates<Color>? background;

  /// Width of the rail.
  @Style<double>(240)
  final double? width;

  /// Label/icon color of the selected item.
  @Style<Color>.resolve(LegendColorsRef.primary, lerp: true)
  final Color? selectedColor;

  /// Label/icon color of unselected items.
  @Style<Color>.resolve(LegendColorsRef.foreground2, lerp: true)
  final Color? unselectedColor;

  /// Inner padding of each item row.
  @Style<EdgeInsetsGeometry>.resolve(_itemPadding)
  final EdgeInsetsGeometry? itemPadding;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;

    return LegendSurface(
      color: theme.background.normal,
      duration: const Duration(milliseconds: 120),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: theme.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header!,
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(tokens.sizes.sm),
                  children: [
                    for (final (index, item) in items.indexed)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.sizes.xs),
                        child: LegendInteractive(
                          semanticLabel: item.label,
                          onTap: () => onSelected(index),
                          builder: (context, states) {
                            final selected = index == selectedIndex;
                            final color = selected
                                ? theme.selectedColor
                                : theme.unselectedColor;
                            return LegendSurface(
                              color: selected
                                  ? tokens.colors.primaryContainer
                                  : theme.background.pick(states.effective),
                              borderRadius: tokens.sizes.borderRadiusMd,
                              padding: theme.itemPadding,
                              duration: const Duration(milliseconds: 120),
                              child: Row(
                                spacing: tokens.sizes.sm,
                                children: [
                                  ?item.buildIcon(color, tokens.sizes.iconMd),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: tokens.typography.b2.copyWith(
                                        color: color,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

LegendStates<Color> _background(LegendTokens t) => LegendStates(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

EdgeInsetsGeometry _itemPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
