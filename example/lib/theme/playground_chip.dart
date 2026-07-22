import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// A small selectable pill built from kit primitives — the theme
/// explorer's component picker (the theme panel keeps its private twin
/// for the preset row).
class PlaygroundChip extends StatelessWidget {
  const PlaygroundChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendInteractive(
      semanticLabel: label,
      toggled: selected,
      onTap: onTap,
      builder: (context, states) => LegendSurface(
        color: selected
            ? tokens.colors.primary
            : states.hovered
            ? tokens.colors.background2
            : tokens.colors.background1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? tokens.colors.primary : tokens.colors.background3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.sizes.sm,
          vertical: tokens.sizes.xs,
        ),
        duration: const Duration(milliseconds: 120),
        child: Text(
          label,
          style: tokens.typography.b3.copyWith(
            color: selected
                ? tokens.colors.onPrimary
                : tokens.colors.foreground1,
          ),
        ),
      ),
    );
  }
}
