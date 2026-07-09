import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/shell/legend_nav_item.dart';
import 'package:legend_ui/src/shell/legend_sider.theme.g.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// Wide-tier side navigation; `LegendScaffold` shows it at medium/expanded
/// tiers.
@LegendThemeable()
class LegendSider extends StatelessWidget {
  const LegendSider({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.header,
    this.footer,
    this.background,
    this.width,
    this.selectedColor,
    this.unselectedColor,
    this.itemPadding,
  });

  final List<LegendNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;

  @Themed(defaultsTo: '240.0')
  final double? width;

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? selectedColor;

  @Themed(defaultsTo: 't.colors.foreground2', lerp: true)
  final Color? unselectedColor;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? itemPadding;

  @override
  Widget build(BuildContext context) {
    final theme = LegendSiderTheme.of(
      context,
      LegendSiderThemeNullable(
        background: background,
        width: width,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        itemPadding: itemPadding,
      ),
    );
    final tokens = LegendTheme.of(context).tokens;

    return LegendSurface(
      color: theme.background,
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
                                  : states.hovered || states.focused
                                  ? tokens.colors.background2
                                  : theme.background,
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
