import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/shell/nomo_nav_item.dart';
import 'package:nomo_ui_kit/src/shell/nomo_sider.theme.g.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// Wide-tier side navigation; `NomoScaffold` shows it at medium/expanded
/// tiers.
@NomoThemeable()
class NomoSider extends StatelessWidget {
  const NomoSider({
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

  final List<NomoNavItem> items;
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
    final theme = NomoSiderTheme.of(
      context,
      NomoSiderThemeNullable(
        background: background,
        width: width,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        itemPadding: itemPadding,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;

    return NomoSurface(
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
                        child: NomoInteractive(
                          semanticLabel: item.label,
                          onTap: () => onSelected(index),
                          builder: (context, states) {
                            final selected = index == selectedIndex;
                            final color = selected
                                ? theme.selectedColor
                                : theme.unselectedColor;
                            return NomoSurface(
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
