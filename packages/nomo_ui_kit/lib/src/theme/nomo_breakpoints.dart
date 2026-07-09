import 'package:flutter/widgets.dart';

/// Responsive tier — decoupled from theming (DESIGN.md §2.4): window
/// resizes flip the tier, never the theme.
enum NomoTier { compact, medium, expanded }

/// Exposes the current [NomoTier] and raw width. Installed by `NomoApp`;
/// widgets read `NomoBreakpoints.of(context)`.
class NomoBreakpoints extends InheritedWidget {
  const NomoBreakpoints({
    required this.tier,
    required this.width,
    required super.child,
    super.key,
  });

  final NomoTier tier;
  final double width;

  static NomoBreakpoints of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No NomoBreakpointScope/NomoApp found in context.');
    return scope!;
  }

  static NomoBreakpoints? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NomoBreakpoints>();
  }

  @override
  bool updateShouldNotify(NomoBreakpoints oldWidget) =>
      tier != oldWidget.tier || width != oldWidget.width;
}

/// Computes the tier from `MediaQuery` width and provides [NomoBreakpoints].
class NomoBreakpointScope extends StatelessWidget {
  const NomoBreakpointScope({
    required this.child,
    super.key,
    this.compactBelow = 600,
    this.expandedFrom = 1080,
  });

  final Widget child;

  /// Widths below this are [NomoTier.compact].
  final double compactBelow;

  /// Widths at or above this are [NomoTier.expanded].
  final double expandedFrom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tier = switch (width) {
      _ when width < compactBelow => NomoTier.compact,
      _ when width >= expandedFrom => NomoTier.expanded,
      _ => NomoTier.medium,
    };
    return NomoBreakpoints(tier: tier, width: width, child: child);
  }
}
