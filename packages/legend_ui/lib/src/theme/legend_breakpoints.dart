import 'package:flutter/widgets.dart';

/// Responsive tier — decoupled from theming (DESIGN.md §2.4): window
/// resizes flip the tier, never the theme.
enum LegendTier { compact, medium, expanded }

/// The two independently-listenable facets of [LegendBreakpoints] —
/// the `aspect` vocabulary of its [InheritedModel]. Use the [LegendBreakpoints.tierOf] /
/// [LegendBreakpoints.widthOf] statics rather than depending manually.
enum LegendBreakpointAspect { tier, width }

/// Exposes the current [LegendTier] and raw width. Installed by `LegendApp`;
/// widgets read [tierOf] / [widthOf].
///
/// An [InheritedModel] with two aspects, so tier consumers don't rebuild
/// on every drag-resize frame (2026-07-10 rebuild audit): [tierOf] only
/// notifies when the tier actually flips; [widthOf] notifies on any width
/// change. [of] depends on both — reach for the aspect statics instead
/// unless you really need the pair.
class LegendBreakpoints extends InheritedModel<LegendBreakpointAspect> {
  const LegendBreakpoints({
    required this.tier,
    required this.width,
    required super.child,
    super.key,
  });

  final LegendTier tier;
  final double width;

  /// The current tier; rebuilds the caller only when the tier changes.
  static LegendTier tierOf(BuildContext context) =>
      _of(context, LegendBreakpointAspect.tier).tier;

  /// The raw window width; rebuilds the caller on any width change.
  static double widthOf(BuildContext context) =>
      _of(context, LegendBreakpointAspect.width).width;

  /// Depends on both tier and width — prefer [tierOf] / [widthOf].
  static LegendBreakpoints of(BuildContext context) => _of(context);

  static LegendBreakpoints? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<LegendBreakpoints>(context);

  static LegendBreakpoints _of(
    BuildContext context, [
    LegendBreakpointAspect? aspect,
  ]) {
    final scope = InheritedModel.inheritFrom<LegendBreakpoints>(
      context,
      aspect: aspect,
    );
    assert(
      scope != null,
      'No LegendBreakpointScope/LegendApp found in context.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(LegendBreakpoints oldWidget) =>
      tier != oldWidget.tier || width != oldWidget.width;

  @override
  bool updateShouldNotifyDependent(
    LegendBreakpoints oldWidget,
    Set<LegendBreakpointAspect> dependencies,
  ) =>
      (dependencies.contains(LegendBreakpointAspect.tier) &&
          tier != oldWidget.tier) ||
      (dependencies.contains(LegendBreakpointAspect.width) &&
          width != oldWidget.width);
}

/// Computes the tier from `MediaQuery` width and provides [LegendBreakpoints].
///
/// Depends on the width aspect only (`MediaQuery.widthOf`), so keyboard
/// insets and height-only resizes never rebuild the scope.
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
    final width = MediaQuery.widthOf(context);
    final tier = switch (width) {
      _ when width < compactBelow => LegendTier.compact,
      _ when width >= expandedFrom => LegendTier.expanded,
      _ => LegendTier.medium,
    };
    return LegendBreakpoints(tier: tier, width: width, child: child);
  }
}
