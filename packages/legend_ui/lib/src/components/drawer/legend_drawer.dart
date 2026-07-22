import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_modal.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_drawer.theme.g.dart';

/// The window edge a [LegendDrawer] is anchored to.
enum LegendDrawerEdge {
  /// The leading side — left in LTR, right in RTL (resolved with
  /// [Directionality]).
  start,

  /// The trailing side — right in LTR, left in RTL (resolved with
  /// [Directionality]).
  end,

  /// The bottom of the window (a bottom sheet).
  bottom,
}

/// An edge-anchored sheet: a side drawer ([LegendDrawerEdge.start]/
/// [LegendDrawerEdge.end], fixed width, full height) or a bottom sheet
/// ([LegendDrawerEdge.bottom], full width, content height, with an
/// optional drag handle and drag-to-dismiss).
///
/// Composes [LegendSurface] for the sheet itself; [LegendDrawer.show]
/// presents it through [LegendModalRoute], the kit's own modal engine —
/// the sheet slides in from its edge, and a scrim tap or Escape
/// dismisses it.
///
/// Closes the RFC-004 gap that [LegendModalRoute] slides edge sheets but
/// had no drag-handle/drag-dismiss `Drawer`/`Sheet` ergonomics — without
/// a second overlay system, and with none of Material's
/// `Scaffold.drawer`/`showModalBottomSheet` machinery.
///
/// Dragging a bottom drawer past a third of its height (or flinging it
/// downward) dismisses it; a shorter drag animates back. A vertical
/// scrollable inside the sheet wins drags over its own area — the handle
/// and padding regions keep the dismiss gesture.
@LegendThemeable()
class LegendDrawer extends StatefulWidget {
  const LegendDrawer({
    required this.child,
    super.key,
    this.edge = LegendDrawerEdge.start,
    this.showHandle = true,
    this.background,
    this.width,
    this.borderRadius,
    this.handleColor,
    this.padding,
  });

  /// The sheet's content.
  final Widget child;

  /// Which window edge the sheet is anchored to.
  final LegendDrawerEdge edge;

  /// Whether a bottom drawer shows the drag handle; side drawers never
  /// show one.
  final bool showHandle;

  /// Fill color of the sheet surface.
  @Style<Color>.resolve(ColorRef.surface)
  final Color? background;

  /// Fixed width of a side drawer (bottom drawers span the window).
  @Style<double>(320)
  final double? width;

  /// Corner rounding of a bottom drawer's top edge (side drawers stay
  /// square against their edge).
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Color of the bottom drawer's drag handle.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? handleColor;

  /// Inner padding around [child].
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Shows a [LegendDrawer] wrapping [builder]'s content as a modal
  /// anchored to [edge]; returns the value passed to `Navigator.pop`.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    LegendDrawerEdge edge = LegendDrawerEdge.start,
    bool showHandle = true,
    bool dismissible = true,
    String barrierLabel = 'Dismiss',
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      _LegendDrawerRoute<T>(
        edge: edge,
        dismissible: dismissible,
        barrierLabel: barrierLabel,
        builder: (context) => LegendDrawer(
          edge: edge,
          showHandle: showHandle,
          child: builder(context),
        ),
      ),
    );
  }

  @override
  State<LegendDrawer> createState() => _LegendDrawerState();
}

class _LegendDrawerState extends State<LegendDrawer>
    with SingleTickerProviderStateMixin {
  /// Dragging farther than this fraction of the sheet's height dismisses.
  static const _dismissFraction = 1 / 3;

  /// Downward fling speed (px/s) that dismisses regardless of distance.
  static const _flingVelocity = 700.0;

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Animation<double> _settleAnimation = const AlwaysStoppedAnimation(0);
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(
      () => setState(() => _dragOffset = _settleAnimation.value),
    );
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _dragStart(DragStartDetails details) => _settle.stop();

  void _dragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset = math.max(0, _dragOffset + details.delta.dy));
  }

  void _dragEnd(DragEndDetails details) {
    final height = context.size?.height ?? 0;
    final flung = details.velocity.pixelsPerSecond.dy > _flingVelocity;
    if (flung || (height > 0 && _dragOffset > height * _dismissFraction)) {
      Navigator.of(context).maybePop();
      return;
    }
    _springBack();
  }

  void _springBack() {
    _settleAnimation = _settle.drive(
      Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;

    if (widget.edge != LegendDrawerEdge.bottom) {
      return SizedBox(
        width: theme.width,
        height: double.infinity,
        child: LegendSurface(
          color: theme.background,
          shadows: tokens.shadows.high,
          padding: theme.padding,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onVerticalDragStart: _dragStart,
      onVerticalDragUpdate: _dragUpdate,
      onVerticalDragEnd: _dragEnd,
      onVerticalDragCancel: _springBack,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: SizedBox(
          width: double.infinity,
          child: LegendSurface(
            color: theme.background,
            borderRadius: theme.borderRadius,
            shadows: tokens.shadows.high,
            clip: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHandle)
                  Padding(
                    padding: EdgeInsets.only(top: tokens.sizes.sm),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.handleColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const SizedBox(width: 36, height: 4),
                      ),
                    ),
                  ),
                Padding(padding: theme.padding, child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [LegendModalRoute] specialized for edge sheets: it aligns the page to
/// the drawer's edge (resolving [LegendDrawerEdge.start]/`end` against
/// [Directionality]) and slides the transition in from that edge —
/// including the horizontal edges the base route would fade+scale.
class _LegendDrawerRoute<T> extends LegendModalRoute<T> {
  _LegendDrawerRoute({
    required super.builder,
    required this.edge,
    super.dismissible,
    super.barrierLabel,
  });

  final LegendDrawerEdge edge;

  Alignment _alignment(BuildContext context) => switch (edge) {
    LegendDrawerEdge.bottom => Alignment.bottomCenter,
    LegendDrawerEdge.start => AlignmentDirectional.centerStart.resolve(
      Directionality.of(context),
    ),
    LegendDrawerEdge.end => AlignmentDirectional.centerEnd.resolve(
      Directionality.of(context),
    ),
  };

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SafeArea(
      child: Align(alignment: _alignment(context), child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final alignment = _alignment(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset(alignment.x, alignment.y),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}

BorderRadius _borderRadius(LegendTokens t) =>
    BorderRadius.vertical(top: Radius.circular(t.sizes.radiusLg));

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.lg);
