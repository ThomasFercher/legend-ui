import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/shell/legend_nav_item.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_bottom_bar.theme.g.dart';

/// Compact-tier navigation bar; `LegendScaffold` shows it below the
/// compact breakpoint.
///
/// Composes [LegendInteractive] (item activation) + [LegendSurface];
/// destinations come from the shared [LegendNavItem] model.
///
/// Items carry no hover/press tint (selection is the state that matters
/// on touch tiers), so the colors are plain fields (RFC-002 R6 audit
/// note).
@LegendThemeable()
class LegendBottomBar extends StatelessWidget {
  const LegendBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.background,
    this.selectedColor,
    this.unselectedColor,
    this.height,
  });

  final List<LegendNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Fill color of the bar.
  @Style<Color>.resolve(LegendColorsRef.surface)
  final Color? background;

  /// Label/icon color of the selected item.
  @Style<Color>.resolve(LegendColorsRef.primary, lerp: true)
  final Color? selectedColor;

  /// Label/icon color of unselected items.
  @Style<Color>.resolve(LegendColorsRef.foreground3, lerp: true)
  final Color? unselectedColor;

  /// Height of the bar content (excluding any safe-area inset).
  @Style<double>(64)
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;

    return LegendSurface(
      color: theme.background,
      // Token shadows are authored downward for cards; a bottom bar sits
      // below its content, so cast them upward instead.
      shadows: [
        for (final s in tokens.shadows.medium)
          BoxShadow(
            color: s.color,
            offset: Offset(s.offset.dx, -s.offset.dy),
            blurRadius: s.blurRadius,
            spreadRadius: s.spreadRadius,
          ),
      ],
      duration: const Duration(milliseconds: 120),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: theme.height,
          child: Row(
            children: [
              for (final (index, item) in items.indexed)
                Expanded(
                  child: LegendInteractive(
                    semanticLabel: item.label,
                    onTap: () => onSelected(index),
                    builder: (context, states) {
                      final color = index == selectedIndex
                          ? theme.selectedColor
                          : theme.unselectedColor;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: tokens.sizes.xs / 2,
                        children: [
                          ?item.buildIcon(color, tokens.sizes.iconMd),
                          Text(
                            item.label,
                            style: tokens.typography.b3.copyWith(color: color),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
