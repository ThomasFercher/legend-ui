import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_card.theme.g.dart';

/// A content surface on [LegendSurface] — one shadow system, and theme
/// values are always reachable (legacy's non-null `elevation` default
/// made them unreachable).
@LegendThemeable()
class LegendCard extends StatelessWidget {
  const LegendCard({
    required this.child,
    super.key,
    this.onTap,
    this.background,
    this.borderRadius,
    this.padding,
    this.shadows,
  });

  final Widget child;

  /// Makes the card interactive when set.
  final VoidCallback? onTap;

  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusLg;

  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  @Style<List<BoxShadow>>.resolve(_shadows)
  final List<BoxShadow>? shadows;
  static List<BoxShadow> _shadows(LegendTokens t) => t.shadows.low;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final surface = LegendSurface(
      color: theme.background,
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      shadows: theme.shadows,
      duration: const Duration(milliseconds: 120),
      child: child,
    );
    if (onTap == null) return surface;
    return LegendInteractive(
      onTap: onTap,
      builder: (context, states) => surface,
    );
  }
}
