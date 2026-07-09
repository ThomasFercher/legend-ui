import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/card/nomo_card.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';

/// A content surface on [NomoSurface] — one shadow system, and theme
/// values are always reachable (legacy's non-null `elevation` default
/// made them unreachable).
@NomoThemeable()
class NomoCard extends StatelessWidget {
  const NomoCard({
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

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 't.sizes.borderRadiusLg')
  final BorderRadius? borderRadius;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.shadows.low')
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final theme = NomoCardTheme.of(
      context,
      NomoCardThemeNullable(
        background: background,
        borderRadius: borderRadius,
        padding: padding,
        shadows: shadows,
      ),
    );
    final surface = NomoSurface(
      color: theme.background,
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      shadows: theme.shadows,
      duration: const Duration(milliseconds: 120),
      child: child,
    );
    if (onTap == null) return surface;
    return NomoInteractive(onTap: onTap, builder: (context, states) => surface);
  }
}
