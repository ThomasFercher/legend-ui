import 'package:flutter/widgets.dart';

/// Responsive tier — decoupled from theming (DESIGN.md §2.4): window
/// resizes flip the tier, never the theme.
enum LegendTier { compact, medium, expanded }

/// Exposes the current [LegendTier] and raw width. Installed by `LegendApp`;
/// widgets read `LegendBreakpoints.of(context)`.
class LegendBreakpoints extends InheritedWidget {
  const LegendBreakpoints({
    required this.tier,
    required this.width,
    required super.child,
    super.key,
  });

  final LegendTier tier;
  final double width;

  static LegendBreakpoints of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'No LegendBreakpointScope/LegendApp found in context.',
    );
    return scope!;
  }

  static LegendBreakpoints? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LegendBreakpoints>();
  }

  @override
  bool updateShouldNotify(LegendBreakpoints oldWidget) =>
      tier != oldWidget.tier || width != oldWidget.width;
}

/// Computes the tier from `MediaQuery` width and provides [LegendBreakpoints].
class LegendBreakpointScope extends StatelessWidget {
  const LegendBreakpointScope({
    required this.child,
    super.key,
    this.compactBelow = 600,
    this.expandedFrom = 1080,
  });

  final Widget child;

  /// Widths below this are [LegendTier.compact].
  final double compactBelow;

  /// Widths at or above this are [LegendTier.expanded].
  final double expandedFrom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tier = switch (width) {
      _ when width < compactBelow => LegendTier.compact,
      _ when width >= expandedFrom => LegendTier.expanded,
      _ => LegendTier.medium,
    };
    return LegendBreakpoints(tier: tier, width: width, child: child);
  }
}
