import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_card.theme.g.dart';

/// A shadowed content container for grouping related content.
///
/// Composes [LegendSurface] (and [LegendInteractive] when [onTap] is set).
///
/// Replaces the legacy card, which shipped one shadow system too many and
/// a non-null `elevation` default that made its theme values unreachable
/// (legacy-docs 01 §4.2).
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

  /// Fill color of the card surface.
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  /// Corner rounding of the card surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;
  static BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusLg;

  /// Inner padding around [child].
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  /// Drop shadow lifting the card off the background.
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
