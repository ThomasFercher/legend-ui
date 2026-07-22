import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_split_pane.theme.g.dart';

/// A resizable two-pane workspace layout: [first] and [second] share the
/// available extent along [axis], split by a divider the user drags to
/// adjust the [fraction] given to [first].
///
/// Composes [LegendInteractive] (hover/press/focus tracking for the
/// divider handle) with [LegendSurface] (the divider line itself); the
/// drag gesture and resize cursor layer inside it — no Material involved.
///
/// Uncontrolled by default: the widget owns the fraction, starting at
/// [initialFraction]. Pass [fraction] to control it yourself — the split
/// then only moves when the parent rebuilds with a new value —
/// [onFractionChanged] reports every user adjustment in both modes.
/// [minFirst] and [minSecond] bound the panes in logical pixels; when the
/// available extent cannot honor both, it is divided proportionally to
/// them.
///
/// The divider is announced to assistive tech as an adjustable
/// slider-style node valued at the current fraction. While it holds
/// focus, arrow keys nudge the fraction 5% per press (main-axis arrows
/// follow the text direction; increase always grows [first]) and
/// Home/End collapse to the [minFirst]/[minSecond] bounds.
///
/// Below [collapseBreakpoint] of available width — or whenever
/// [collapsed] is true — only [first] renders, filling the whole extent.
/// Auto-collapse is off by default (the breakpoint defaults to 0); apps
/// that stack or swap panes per tier instead drive [collapsed] from
/// `LegendBreakpoints.tierOf` (responsiveness stays out of the theme).
///
/// Needs a bounded [axis] extent from its parent (same contract as a
/// vertical `LegendDivider`).
@LegendThemeable()
class LegendSplitPane extends StatefulWidget {
  const LegendSplitPane({
    required this.first,
    required this.second,
    super.key,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.5,
    this.fraction,
    this.onFractionChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.collapsed,
    this.semanticLabel,
    this.focusNode,
    this.divider,
    this.dividerThickness,
    this.handle,
    this.hitTarget,
    this.collapseBreakpoint,
  }) : assert(
         initialFraction >= 0 && initialFraction <= 1,
         'initialFraction must be within 0..1.',
       ),
       assert(
         fraction == null || (fraction >= 0 && fraction <= 1),
         'fraction must be null or within 0..1.',
       ),
       assert(minFirst >= 0, 'minFirst must not be negative.'),
       assert(minSecond >= 0, 'minSecond must not be negative.');

  /// The start pane — the left (LTR) or top one, and the only pane shown
  /// while collapsed.
  final Widget first;

  /// The end pane, taking whatever extent [first] does not.
  final Widget second;

  /// The direction the panes are laid along: [Axis.horizontal] places
  /// them side by side (a vertical divider line), [Axis.vertical] stacks
  /// them.
  final Axis axis;

  /// Where the divider starts in uncontrolled mode, as the share of the
  /// available extent given to [first].
  final double initialFraction;

  /// Controlled-mode split: non-null pins the divider to this share and
  /// the widget stops moving it itself — rebuild with the value reported
  /// through [onFractionChanged] to follow the user's drags.
  final double? fraction;

  /// Called with the new (already min-clamped) fraction on every drag,
  /// keyboard nudge, and semantic adjustment.
  final ValueChanged<double>? onFractionChanged;

  /// Smallest extent of [first] along [axis], in logical pixels.
  final double minFirst;

  /// Smallest extent of [second] along [axis], in logical pixels.
  final double minSecond;

  /// Forces the collapsed (first-pane-only) presentation: true always
  /// collapses, false never does, and null (the default) collapses below
  /// the themed [collapseBreakpoint] of available width.
  final bool? collapsed;

  /// What this divider resizes (e.g. 'Sources panel') — the current
  /// fraction is announced through slider semantics, never baked in.
  final String? semanticLabel;

  final FocusNode? focusNode;

  /// Color of the divider line at rest.
  @Style<Color>.resolve(ColorRef.background3, lerp: true)
  final Color? divider;

  /// Stroke width of the divider line — the layout gap between the panes.
  @Style<double>.resolve(SizeRef.borderWidth)
  final double? dividerThickness;

  /// Fill of the divider line while interacting (hover/drag/focus) —
  /// unset states derive from `normal` through the state overlays; at
  /// rest the line falls back to [divider].
  @Style<InteractiveColors>.resolve(_handle, lerp: true)
  final InteractiveColors? handle;

  /// Width of the invisible grab region centered on the divider line.
  @Style<double>.resolve(SizeRef.sm)
  final double? hitTarget;

  /// Available width below which a null [collapsed] shows only [first];
  /// 0 (the default) disables auto-collapse.
  @Style<double>(0)
  final double? collapseBreakpoint;

  @override
  State<LegendSplitPane> createState() => _LegendSplitPaneState();
}

InteractiveColors _handle(LegendTokens t) =>
    InteractiveColors(normal: t.colors.primary);

/// The raw key pressed while the divider holds focus; [_LegendSplitPaneState]
/// resolves it against the axis and text direction.
enum _SplitPaneKey { up, down, left, right, home, end }

class _AdjustSplitPaneIntent extends Intent {
  const _AdjustSplitPaneIntent(this.key);

  final _SplitPaneKey key;
}

class _LegendSplitPaneState extends State<LegendSplitPane> {
  /// One keyboard/semantic nudge, as a share of the available extent.
  static const _step = 0.05;

  /// The widget-owned fraction (uncontrolled mode); shadows the last
  /// user adjustment while [LegendSplitPane.fraction] controls the split.
  late double _fraction = widget.fraction ?? widget.initialFraction;

  var _dragging = false;

  /// The pointer's virtual first-pane extent during a drag — accumulated
  /// raw so an overshoot past a min bound must be dragged back before the
  /// divider moves again.
  var _dragPosition = 0.0;

  double get _effective => widget.fraction ?? _fraction;

  @override
  void didUpdateWidget(LegendSplitPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fraction = widget.fraction;
    if (fraction != null && fraction != oldWidget.fraction) {
      _fraction = fraction;
    }
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// The fraction range the min extents leave over [available]; when they
  /// cannot both be honored the range degenerates to the proportional
  /// split between them.
  (double, double) _bounds(double available) {
    if (available <= 0) return (0, 1);
    final lo = widget.minFirst / available;
    final hi = 1 - widget.minSecond / available;
    if (lo > hi) {
      final total = widget.minFirst + widget.minSecond;
      final mid = total <= 0 ? 0.5 : widget.minFirst / total;
      return (mid, mid);
    }
    return (lo.clamp(0.0, 1.0), hi.clamp(0.0, 1.0));
  }

  void _change(double target, (double, double) bounds) {
    final (lo, hi) = bounds;
    final next = target.clamp(lo, hi);
    if (next == _effective) return;
    setState(() => _fraction = next);
    widget.onFractionChanged?.call(next);
  }

  void _dragStart(double firstExtent) {
    _dragPosition = firstExtent;
    setState(() => _dragging = true);
  }

  void _dragUpdate(double delta, double available, (double, double) bounds) {
    _dragPosition += delta;
    if (available <= 0) return;
    _change(_dragPosition / available, bounds);
  }

  void _dragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
  }

  /// Resolves a raw arrow/Home/End press against the axis and text
  /// direction; increase always means growing the first pane.
  void _adjust(_SplitPaneKey key, double clamped, (double, double) bounds) {
    final horizontal = widget.axis == Axis.horizontal;
    final target = switch (key) {
      // Cross-axis arrows follow the slider convention (up increases);
      // main-axis arrows move the divider the way it looks.
      _SplitPaneKey.up => clamped + (horizontal ? _step : -_step),
      _SplitPaneKey.down => clamped + (horizontal ? -_step : _step),
      _SplitPaneKey.left => clamped + (horizontal && _rtl ? _step : -_step),
      _SplitPaneKey.right => clamped + (horizontal && _rtl ? -_step : _step),
      _SplitPaneKey.home => bounds.$1,
      _SplitPaneKey.end => bounds.$2,
    };
    _change(target, bounds);
  }

  String _format(double fraction) => '${(fraction * 100).round()}%';

  /// Present so the primitive tracks press/focus and joins the focus
  /// traversal; Enter/Space deliberately do nothing — a divider is
  /// adjusted with arrows, not activated.
  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final horizontal = widget.axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed =
            widget.collapsed ??
            (theme.collapseBreakpoint > 0 &&
                constraints.maxWidth < theme.collapseBreakpoint);
        if (collapsed) return widget.first;

        final extent = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        assert(
          extent.isFinite,
          'LegendSplitPane needs a bounded ${widget.axis} extent from its '
          'parent.',
        );
        // The double annotation binds math.max's T (and its 0) to double.
        final double available = math.max(extent - theme.dividerThickness, 0);
        final bounds = _bounds(available);
        final clamped = _effective.clamp(bounds.$1, bounds.$2);
        final firstExtent = available * clamped;

        return Stack(
          children: [
            Positioned.fill(
              child: Flex(
                direction: widget.axis,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: horizontal ? firstExtent : null,
                    height: horizontal ? null : firstExtent,
                    child: widget.first,
                  ),
                  // The layout gap the divider line paints into (the line
                  // itself lives in the handle overlay, where it can take
                  // the interaction state's color).
                  SizedBox(
                    width: horizontal ? theme.dividerThickness : null,
                    height: horizontal ? null : theme.dividerThickness,
                  ),
                  Expanded(child: widget.second),
                ],
              ),
            ),
            PositionedDirectional(
              start: horizontal
                  ? firstExtent + (theme.dividerThickness - theme.hitTarget) / 2
                  : 0,
              top: horizontal
                  ? 0
                  : firstExtent +
                        (theme.dividerThickness - theme.hitTarget) / 2,
              bottom: horizontal ? 0 : null,
              end: horizontal ? null : 0,
              width: horizontal ? theme.hitTarget : null,
              height: horizontal ? null : theme.hitTarget,
              child: Semantics(
                slider: true,
                label: widget.semanticLabel,
                value: _format(clamped),
                increasedValue: _format(
                  (clamped + _step).clamp(bounds.$1, bounds.$2),
                ),
                decreasedValue: _format(
                  (clamped - _step).clamp(bounds.$1, bounds.$2),
                ),
                onIncrease: () => _change(clamped + _step, bounds),
                onDecrease: () => _change(clamped - _step, bounds),
                // The slider node above is the whole story for assistive
                // tech; the primitive's inner button node would only
                // misrepresent the divider.
                child: ExcludeSemantics(
                  child: Shortcuts(
                    shortcuts: const {
                      SingleActivator(LogicalKeyboardKey.arrowUp):
                          _AdjustSplitPaneIntent(_SplitPaneKey.up),
                      SingleActivator(LogicalKeyboardKey.arrowDown):
                          _AdjustSplitPaneIntent(_SplitPaneKey.down),
                      SingleActivator(LogicalKeyboardKey.arrowLeft):
                          _AdjustSplitPaneIntent(_SplitPaneKey.left),
                      SingleActivator(LogicalKeyboardKey.arrowRight):
                          _AdjustSplitPaneIntent(_SplitPaneKey.right),
                      SingleActivator(LogicalKeyboardKey.home):
                          _AdjustSplitPaneIntent(_SplitPaneKey.home),
                      SingleActivator(LogicalKeyboardKey.end):
                          _AdjustSplitPaneIntent(_SplitPaneKey.end),
                    },
                    child: Actions(
                      actions: {
                        _AdjustSplitPaneIntent:
                            CallbackAction<_AdjustSplitPaneIntent>(
                              onInvoke: (intent) {
                                _adjust(intent.key, clamped, bounds);
                                return null;
                              },
                            ),
                      },
                      child: LegendInteractive(
                        onTap: _noop,
                        focusNode: widget.focusNode,
                        builder: (context, states) {
                          final interacting =
                              _dragging ||
                              states.hovered ||
                              states.pressed ||
                              states.focused;
                          final state = LegendInteractionStates(
                            hovered: states.hovered,
                            pressed: states.pressed || _dragging,
                            focused: states.focused,
                            disabled: false,
                          ).effective;
                          final color = interacting
                              ? theme.handle.resolve(state, tokens.states) ??
                                    theme.divider
                              : theme.divider;
                          // The inner region wins cursor resolution over
                          // the primitive's click cursor.
                          return MouseRegion(
                            cursor: horizontal
                                ? SystemMouseCursors.resizeColumn
                                : SystemMouseCursors.resizeRow,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // Track from the pointer-down position so the
                              // divider follows without a touch-slop jump.
                              dragStartBehavior: DragStartBehavior.down,
                              onHorizontalDragStart: horizontal
                                  ? (_) => _dragStart(firstExtent)
                                  : null,
                              onHorizontalDragUpdate: horizontal
                                  ? (d) => _dragUpdate(
                                      _rtl ? -d.delta.dx : d.delta.dx,
                                      available,
                                      bounds,
                                    )
                                  : null,
                              onHorizontalDragEnd: horizontal
                                  ? (_) => _dragEnd()
                                  : null,
                              onHorizontalDragCancel: horizontal
                                  ? _dragEnd
                                  : null,
                              onVerticalDragStart: horizontal
                                  ? null
                                  : (_) => _dragStart(firstExtent),
                              onVerticalDragUpdate: horizontal
                                  ? null
                                  : (d) => _dragUpdate(
                                      d.delta.dy,
                                      available,
                                      bounds,
                                    ),
                              onVerticalDragEnd: horizontal
                                  ? null
                                  : (_) => _dragEnd(),
                              onVerticalDragCancel: horizontal
                                  ? null
                                  : _dragEnd,
                              child: Center(
                                child: SizedBox(
                                  width: horizontal
                                      ? theme.dividerThickness
                                      : double.infinity,
                                  height: horizontal
                                      ? double.infinity
                                      : theme.dividerThickness,
                                  child: LegendSurface(color: color),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
