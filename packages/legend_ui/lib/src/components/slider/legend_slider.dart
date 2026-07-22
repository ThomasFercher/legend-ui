import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_slider.theme.g.dart';

/// A draggable value selector: a horizontal track whose thumb picks a
/// [value] between [min] and [max], optionally snapped to [divisions].
///
/// Composes [LegendInteractive] (hover/press/focus tracking, focus node,
/// disabled inertness) with custom track/thumb painting; the drag and
/// tap-to-position gestures layer inside it — no Material Slider or
/// InkWell involved. Announced to assistive tech as a real slider — a
/// value label ([semanticFormatter], percent of the range by default)
/// plus increase/decrease actions — so the primitive's button vocabulary
/// is excluded from the semantics tree rather than misrepresenting the
/// control.
///
/// Arrow keys step the value while focused ([divisions] steps when set,
/// 5% of the range otherwise; left/right follow the text direction) and
/// Home/End jump to [min]/[max]. A [value] outside the range is clamped
/// for painting and announcement.
///
/// The track fills the available width (same bounded-parent contract as
/// a horizontal `LegendDivider`).
@LegendThemeable()
class LegendSlider extends StatefulWidget {
  const LegendSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.enabled = true,
    this.semanticLabel,
    this.semanticFormatter,
    this.focusNode,
    this.track,
    this.activeTrack,
    this.thumb,
    this.trackHeight,
    this.thumbSize,
  }) : assert(min < max, 'min must be less than max.'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be null or positive.',
       );

  /// The currently selected value, nominally within [min]..[max].
  final double value;

  /// Called with the new value as the thumb moves (drag, tap, keyboard,
  /// or the semantic increase/decrease actions). Null disables the
  /// slider.
  final ValueChanged<double>? onChanged;

  /// Lower bound of the selectable range.
  final double min;

  /// Upper bound of the selectable range.
  final double max;

  /// Number of discrete steps between [min] and [max]; every delivered
  /// value snaps to the nearest step. Null keeps the range continuous.
  final int? divisions;

  /// Called with the value the interaction started from, before the
  /// first [onChanged] of a drag or tap.
  final ValueChanged<double>? onChangeStart;

  /// Called with the final value when a drag or tap completes.
  final ValueChanged<double>? onChangeEnd;

  /// Whether the slider accepts input at all. False makes it fully inert.
  final bool enabled;

  /// What this slider adjusts (e.g. 'Volume') — the current value itself
  /// is announced via slider semantics, never baked into the label.
  final String? semanticLabel;

  /// Formats a value for assistive tech (the announced value label and
  /// its increase/decrease previews). Defaults to the percentage of the
  /// range.
  final String Function(double value)? semanticFormatter;

  final FocusNode? focusNode;

  /// Color of the unfilled portion of the track.
  @Style<Color>.resolve(ColorRef.background3, lerp: true)
  final Color? track;

  /// Color of the filled portion, from the start edge to the thumb.
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? activeTrack;

  /// Fill of the draggable thumb per interaction state — hover/press
  /// tints derive through the state overlays; focus shows as a halo
  /// around the thumb instead of a fill shift.
  @Style<InteractiveColors>.resolve(_thumb, lerp: true)
  final InteractiveColors? thumb;

  /// Height of the track bar.
  @Style<double>(4)
  final double? trackHeight;

  /// Diameter of the thumb (the focus halo and the widget's own height
  /// scale from it).
  @Style<double>(20)
  final double? thumbSize;

  @override
  State<LegendSlider> createState() => _LegendSliderState();
}

InteractiveColors _thumb(LegendTokens t) =>
    InteractiveColors(normal: t.colors.primary, disabled: t.colors.onDisabled);

/// How a keyboard shortcut (or semantic action) moves the value.
enum _SliderAdjustment { increase, decrease, left, right, minimum, maximum }

class _AdjustSliderIntent extends Intent {
  const _AdjustSliderIntent(this.adjustment);

  final _SliderAdjustment adjustment;
}

class _LegendSliderState extends State<LegendSlider> {
  var _dragging = false;

  /// The value most recently delivered through `onChanged` — what
  /// `onChangeEnd` must report even before the parent rebuilds us with it.
  double? _latest;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  double get _range => widget.max - widget.min;

  double get _fraction =>
      ((widget.value - widget.min) / _range).clamp(0.0, 1.0);

  /// One keyboard/semantic step: a division when snapping, 5% of the
  /// range otherwise.
  double get _step {
    final divisions = widget.divisions;
    return divisions == null ? _range / 20 : _range / divisions;
  }

  @override
  void didUpdateWidget(LegendSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling mid-drag nulls the drag callbacks, so the release never
    // clears _dragging — reset here (mirrors LegendInteractive).
    if (!_enabled) _dragging = false;
  }

  /// Clamps to the range and snaps to the nearest division when set.
  double _snap(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions == null) return clamped;
    final steps = ((clamped - widget.min) / _range * divisions).round();
    return widget.min + steps * _range / divisions;
  }

  void _change(double value) {
    final next = _snap(value);
    _latest = next;
    if (next != widget.value) widget.onChanged?.call(next);
  }

  /// The value under a pointer at [dx] on a track [width] wide: the thumb
  /// center travels between the half-thumb insets, mirrored under RTL.
  double _valueAt(double dx, double width, double thumbSize) {
    final travel = width - thumbSize;
    var fraction = travel <= 0
        ? 0.0
        : ((dx - thumbSize / 2) / travel).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) {
      fraction = 1 - fraction;
    }
    return widget.min + fraction * _range;
  }

  void _dragStart(double dx, double width, double thumbSize) {
    widget.onChangeStart?.call(widget.value);
    setState(() => _dragging = true);
    _change(_valueAt(dx, width, thumbSize));
  }

  void _dragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    widget.onChangeEnd?.call(_latest ?? widget.value);
    _latest = null;
  }

  void _tap(double dx, double width, double thumbSize) {
    widget.onChangeStart?.call(widget.value);
    _change(_valueAt(dx, width, thumbSize));
    widget.onChangeEnd?.call(_latest ?? widget.value);
    _latest = null;
  }

  void _adjust(_SliderAdjustment adjustment) {
    if (!_enabled) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    switch (adjustment) {
      case _SliderAdjustment.increase:
        _change(widget.value + _step);
      case _SliderAdjustment.decrease:
        _change(widget.value - _step);
      case _SliderAdjustment.left:
        _change(widget.value + (rtl ? _step : -_step));
      case _SliderAdjustment.right:
        _change(widget.value + (rtl ? -_step : _step));
      case _SliderAdjustment.minimum:
        _change(widget.min);
      case _SliderAdjustment.maximum:
        _change(widget.max);
    }
  }

  String _format(double value) {
    final formatter = widget.semanticFormatter;
    if (formatter != null) return formatter(value);
    final clamped = value.clamp(widget.min, widget.max);
    return '${((clamped - widget.min) / _range * 100).round()}%';
  }

  /// Present so the primitive tracks press/focus and joins the focus
  /// traversal; pointer taps never reach it (the inner drag/tap detector
  /// sits deeper in the gesture arena) and Enter/Space deliberately do
  /// nothing — a slider is adjusted with arrows, not activated.
  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final enabled = _enabled;
    final thumbSize = theme.thumbSize;
    final height = math.max(theme.trackHeight, thumbSize * 2);
    final value = widget.value.clamp(widget.min, widget.max);

    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _format(value),
      increasedValue: _format(_snap(value + _step)),
      decreasedValue: _format(_snap(value - _step)),
      onIncrease: enabled ? () => _adjust(_SliderAdjustment.increase) : null,
      onDecrease: enabled ? () => _adjust(_SliderAdjustment.decrease) : null,
      // The slider node above is the whole story for assistive tech; the
      // primitive's inner button node would only misrepresent it.
      child: ExcludeSemantics(
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowUp): _AdjustSliderIntent(
              _SliderAdjustment.increase,
            ),
            SingleActivator(LogicalKeyboardKey.arrowDown): _AdjustSliderIntent(
              _SliderAdjustment.decrease,
            ),
            SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustSliderIntent(
              _SliderAdjustment.left,
            ),
            SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustSliderIntent(
              _SliderAdjustment.right,
            ),
            SingleActivator(LogicalKeyboardKey.home): _AdjustSliderIntent(
              _SliderAdjustment.minimum,
            ),
            SingleActivator(LogicalKeyboardKey.end): _AdjustSliderIntent(
              _SliderAdjustment.maximum,
            ),
          },
          child: Actions(
            actions: {
              _AdjustSliderIntent: CallbackAction<_AdjustSliderIntent>(
                onInvoke: (intent) {
                  _adjust(intent.adjustment);
                  return null;
                },
              ),
            },
            child: LegendInteractive(
              enabled: enabled,
              onTap: _noop,
              focusNode: widget.focusNode,
              builder: (context, states) {
                final state = LegendInteractionStates(
                  hovered: states.hovered,
                  pressed: states.pressed || _dragging,
                  focused: states.focused,
                  disabled: states.disabled,
                ).effective;
                final activeTrack = states.disabled
                    ? tokens.colors.disabled
                    : theme.activeTrack;
                final showHalo =
                    !states.disabled && (_dragging || states.focused);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: enabled
                          ? (d) =>
                                _dragStart(d.localPosition.dx, width, thumbSize)
                          : null,
                      onHorizontalDragUpdate: enabled
                          ? (d) => _change(
                              _valueAt(d.localPosition.dx, width, thumbSize),
                            )
                          : null,
                      onHorizontalDragEnd: enabled ? (_) => _dragEnd() : null,
                      onHorizontalDragCancel: enabled ? _dragEnd : null,
                      onTapUp: enabled
                          ? (d) => _tap(d.localPosition.dx, width, thumbSize)
                          : null,
                      child: SizedBox(
                        width: double.infinity,
                        height: height,
                        child: CustomPaint(
                          painter: _SliderPainter(
                            track: theme.track,
                            activeTrack: activeTrack,
                            thumb: theme.thumb.resolve(state, tokens.states),
                            halo: showHalo
                                ? activeTrack.withValues(alpha: 0.12)
                                : null,
                            trackHeight: theme.trackHeight,
                            thumbSize: thumbSize,
                            fraction: _fraction,
                            shadows: states.disabled
                                ? const []
                                : tokens.shadows.low,
                            direction: Directionality.of(context),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the track, its active fill up to the thumb center, the focus
/// halo, and the thumb circle with its shadows.
class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.track,
    required this.activeTrack,
    required this.thumb,
    required this.halo,
    required this.trackHeight,
    required this.thumbSize,
    required this.fraction,
    required this.shadows,
    required this.direction,
  });

  final Color track;
  final Color activeTrack;

  /// Resolved thumb fill for the current interaction state (null paints
  /// no thumb — an explicitly transparent theme).
  final Color? thumb;

  /// Focus/drag halo behind the thumb, or null for none.
  final Color? halo;

  final double trackHeight;
  final double thumbSize;

  /// Position of the thumb in `0..1` of the travel, start-relative.
  final double fraction;

  final List<BoxShadow> shadows;

  /// Which edge the active fill grows from.
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = thumbSize / 2;
    final travel = math.max(size.width - thumbSize, 0);
    final visual = direction == TextDirection.rtl ? 1 - fraction : fraction;
    final center = Offset(radius + travel * visual, size.height / 2);

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, center.dy - trackHeight / 2, size.width, trackHeight),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(trackRect, Paint()..color = track);

    final active = direction == TextDirection.rtl
        ? Rect.fromLTRB(center.dx, trackRect.top, size.width, trackRect.bottom)
        : Rect.fromLTRB(0, trackRect.top, center.dx, trackRect.bottom);
    canvas
      ..save()
      ..clipRRect(trackRect)
      ..drawRect(active, Paint()..color = activeTrack)
      ..restore();

    final halo = this.halo;
    if (halo != null) {
      canvas.drawCircle(center, thumbSize * 0.75, Paint()..color = halo);
    }

    final thumb = this.thumb;
    if (thumb == null) return;
    for (final shadow in shadows) {
      canvas.drawCircle(
        center + shadow.offset,
        radius + shadow.spreadRadius,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      track != oldDelegate.track ||
      activeTrack != oldDelegate.activeTrack ||
      thumb != oldDelegate.thumb ||
      halo != oldDelegate.halo ||
      trackHeight != oldDelegate.trackHeight ||
      thumbSize != oldDelegate.thumbSize ||
      fraction != oldDelegate.fraction ||
      shadows != oldDelegate.shadows ||
      direction != oldDelegate.direction;
}
