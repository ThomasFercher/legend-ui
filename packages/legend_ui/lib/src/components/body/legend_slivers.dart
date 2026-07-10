import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Sugar for dropping a box widget into a sliver context without the
/// `SliverToBoxAdapter` noise (RFC-003 §4) — `header.asSliver` reads as
/// intent where the adapter reads as plumbing.
extension LegendSliverX on Widget {
  /// This widget wrapped in a [SliverToBoxAdapter].
  Widget get asSliver => SliverToBoxAdapter(child: this);
}

/// A sliver that pins its box [child] to the leading edge of the viewport
/// once it reaches it, without a `SliverPersistentHeaderDelegate` subclass
/// or hand-fed min/max extents — the child sizes itself.
///
/// This is the one sliver gap Flutter ≥3.13 left open after absorbing the
/// sliver_tools grouping widgets (RFC-003 §2/§4); it is a self-contained
/// [RenderSliver] with zero dependencies, not a vendored fork.
///
/// Use it directly inside a [CustomScrollView] (or `LegendBody.slivers`),
/// or through [LegendSliverSection]'s `pinHeader` flag for the
/// header-plus-content archetype.
class LegendSliverPinnedHeader extends SingleChildRenderObjectWidget {
  const LegendSliverPinnedHeader({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverPinnedHeader();
}

/// Lays the child out at its natural size and keeps it painted at the
/// leading edge: the sliver occupies its child's extent in the scroll
/// geometry, but its paint origin follows the viewport's leading overlap,
/// so the child stays visible (and stacks under earlier pinned slivers)
/// while the rest of the content scrolls underneath.
class _RenderSliverPinnedHeader extends RenderSliverSingleBoxAdapter {
  @override
  void performLayout() {
    final constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final childExtent = switch (constraints.axis) {
      Axis.vertical => child!.size.height,
      Axis.horizontal => child!.size.width,
    };
    // Paintable room at the leading edge, after any overlap already
    // claimed by earlier pinned slivers.
    final double effectiveRemaining = math.max(
      0,
      constraints.remainingPaintExtent - constraints.overlap,
    );
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      // Painting starts at the current overlap, which is what pins the
      // child: as scrollOffset grows the sliver's layout extent shrinks,
      // but the paint origin keeps the child at the leading edge.
      paintOrigin: constraints.overlap,
      paintExtent: math.min(childExtent, effectiveRemaining),
      layoutExtent: clampDouble(
        childExtent - constraints.scrollOffset,
        0,
        effectiveRemaining,
      ),
      maxPaintExtent: childExtent,
      // Tells the viewport this extent stays obstructed for scroll-into-view
      // calculations (e.g. focus reveals under the pinned header).
      maxScrollObstructionExtent: childExtent,
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: childExtent),
      hasVisualOverflow: true,
    );
    (child!.parentData! as SliverPhysicalParentData).paintOffset = Offset.zero;
  }

  /// The child never moves relative to the sliver's paint origin — that is
  /// the pinning; hit tests resolve against the same fixed position.
  @override
  double childMainAxisPosition(covariant RenderObject child) => 0;
}

/// A titled scroll section: an optional box [header] (pinned to the top of
/// the viewport while its section scrolls when [pinHeader] is true)
/// followed by its content [slivers], grouped so the header and content
/// scroll as one unit.
///
/// Pure composition over Flutter's [SliverMainAxisGroup] +
/// [LegendSliverPinnedHeader] (RFC-003 §4) — sticky section headers
/// without a delegate subclass or a package dependency.
class LegendSliverSection extends StatelessWidget {
  const LegendSliverSection({
    required this.slivers,
    super.key,
    this.header,
    this.pinHeader = false,
  });

  /// Box widget rendered before the section content; null means the
  /// section is just a grouping of [slivers].
  final Widget? header;

  /// Whether [header] pins to the viewport's leading edge while the
  /// section scrolls (a sticky section header).
  final bool pinHeader;

  /// The section content. Must be slivers (use [LegendSliverX.asSliver]
  /// for box children).
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (header != null)
          pinHeader
              ? LegendSliverPinnedHeader(child: header!)
              : SliverToBoxAdapter(child: header),
        ...slivers,
      ],
    );
  }
}
