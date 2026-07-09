import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/shell/nomo_bottom_bar.theme.g.dart';
import 'package:nomo_ui_kit/src/shell/nomo_nav_item.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// Compact-tier navigation bar; `NomoScaffold` shows it below the
/// compact breakpoint.
@NomoThemeable()
class NomoBottomBar extends StatelessWidget {
  const NomoBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.background,
    this.selectedColor,
    this.unselectedColor,
    this.height,
  });

  final List<NomoNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? selectedColor;

  @Themed(defaultsTo: 't.colors.foreground3', lerp: true)
  final Color? unselectedColor;

  @Themed(defaultsTo: '64.0')
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = NomoBottomBarTheme.of(
      context,
      NomoBottomBarThemeNullable(
        background: background,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        height: height,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;

    return NomoSurface(
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
                  child: NomoInteractive(
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
