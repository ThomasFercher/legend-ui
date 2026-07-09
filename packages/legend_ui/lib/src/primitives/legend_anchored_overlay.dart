import 'package:flutter/widgets.dart';

/// The anchored-overlay primitive (DESIGN.md §3): positions [overlay]
/// relative to [child] via `OverlayPortal` + `CompositedTransform*`, with
/// outside-tap dismissal through `TapRegion` groups.
///
/// This is the seed of the unified overlay engine; dropdowns, context
/// menus and tooltips all build on it — legacy shipped three unrelated
/// overlay systems (legacy-docs 06).
class LegendAnchoredOverlay extends StatefulWidget {
  const LegendAnchoredOverlay({
    required this.controller,
    required this.overlay,
    required this.child,
    super.key,
    this.anchorAlignment = Alignment.bottomLeft,
    this.overlayAlignment = Alignment.topLeft,
    this.offset = Offset.zero,
    this.onDismiss,
  });

  final OverlayPortalController controller;
  final WidgetBuilder overlay;
  final Widget child;

  /// Point on the anchor the overlay attaches to.
  final Alignment anchorAlignment;

  /// Point on the overlay that touches [anchorAlignment].
  final Alignment overlayAlignment;

  final Offset offset;

  /// Called on taps outside both anchor and overlay; typically hides the
  /// [controller].
  final VoidCallback? onDismiss;

  @override
  State<LegendAnchoredOverlay> createState() => _LegendAnchoredOverlayState();
}

class _LegendAnchoredOverlayState extends State<LegendAnchoredOverlay> {
  final _link = LayerLink();
  final Object _tapGroup = Object();

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapGroup,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: widget.controller,
          overlayChildBuilder: (context) {
            return Align(
              alignment: Alignment.topLeft,
              child: CompositedTransformFollower(
                link: _link,
                targetAnchor: widget.anchorAlignment,
                followerAnchor: widget.overlayAlignment,
                offset: widget.offset,
                showWhenUnlinked: false,
                child: TapRegion(
                  groupId: _tapGroup,
                  onTapOutside: (_) => widget.onDismiss?.call(),
                  child: widget.overlay(context),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
