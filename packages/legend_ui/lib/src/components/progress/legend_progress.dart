import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_progress.theme.g.dart';

/// Which shape a [LegendProgress] paints — each named constructor is one.
enum _LegendProgressVariant { bar, circle }

/// An inline progress indicator: a linear bar ([LegendProgress.bar]) or a
/// circular ring ([LegendProgress.circle]), determinate when [value] is
/// set and indeterminate (an animated sweep) when it is null.
///
/// Pure [CustomPainter] output over the token palette — no Material
/// `LinearProgressIndicator`/`CircularProgressIndicator` (DESIGN.md §3:
/// no Material service dependencies). Theme values are resolved once per
/// build and passed into the painter as plain values — never read per
/// frame.
///
/// Sibling of `LegendLoading`, not a replacement: Loading is the centered
/// activity spinner ("busy, duration unknown"); Progress is the inline
/// bar/ring that can report a known completion fraction — transaction
/// confirmations, artifact generation.
///
/// When determinate, the fraction (clamped to `0..1`) is announced as a
/// percentage through [Semantics]; [semanticLabel] names what is
/// progressing. The indeterminate sweep animates only while [value] is
/// null and the widget is mounted — a determinate paint schedules no
/// frames.
///
/// A bar fills the available width (same bounded-parent contract as a
/// horizontal `LegendDivider`).
@LegendThemeable()
class LegendProgress extends StatefulWidget {
  /// Linear bar: a full-width track of [thickness] height whose leading
  /// edge fills to [value] (or sweeps while indeterminate).
  const LegendProgress.bar({
    super.key,
    this.value,
    this.semanticLabel,
    this.track,
    this.fill,
    this.thickness,
    this.borderRadius,
  }) : _variant = _LegendProgressVariant.bar,
       size = null;

  /// Circular ring of diameter [size]: a full-circle track of [thickness]
  /// stroke whose arc fills clockwise from the top to [value] (or rotates
  /// while indeterminate).
  const LegendProgress.circle({
    super.key,
    this.value,
    this.semanticLabel,
    this.track,
    this.fill,
    this.thickness,
    this.size,
  }) : _variant = _LegendProgressVariant.circle,
       borderRadius = null;

  final _LegendProgressVariant _variant;

  /// Completion fraction in `0..1`; null paints the indeterminate sweep.
  final double? value;

  /// What is progressing (e.g. 'Sending transaction') — announced together
  /// with the percentage when [value] is set.
  final String? semanticLabel;

  /// Color of the unfilled track.
  @Style<Color>.resolve(ColorRef.background3)
  final Color? track;

  /// Color of the completed fill and the indeterminate sweep.
  @Style<Color>.resolve(ColorRef.primary)
  final Color? fill;

  /// Bar height, or ring stroke width.
  @Style<double>(6)
  final double? thickness;

  /// Corner rounding of the bar's track (the fill is clipped to it).
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Ring diameter ([LegendProgress.circle] only).
  @Style<double>(40)
  final double? size;

  @override
  State<LegendProgress> createState() => _LegendProgressState();
}

BorderRadius _borderRadius(LegendTokens t) =>
    BorderRadius.circular(t.sizes.radiusSm);

class _LegendProgressState extends State<LegendProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(LegendProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  /// Repeats only while indeterminate: a determinate paint is static, so
  /// the ticker must not burn frames. Disposed with the state either way.
  void _syncAnimation() {
    if (widget.value == null) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _paint(
    LegendProgressTheme theme, {
    required double? value,
    required double t,
    required TextDirection direction,
  }) {
    return switch (widget._variant) {
      _LegendProgressVariant.bar => SizedBox(
        width: double.infinity,
        height: theme.thickness,
        child: CustomPaint(
          painter: _BarPainter(
            track: theme.track,
            fill: theme.fill,
            borderRadius: theme.borderRadius,
            value: value,
            t: t,
            direction: direction,
          ),
        ),
      ),
      _LegendProgressVariant.circle => CustomPaint(
        size: Size.square(theme.size),
        painter: _CirclePainter(
          track: theme.track,
          fill: theme.fill,
          strokeWidth: theme.thickness,
          value: value,
          t: t,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final value = widget.value?.clamp(0.0, 1.0);
    final direction = Directionality.of(context);

    final child = value == null
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _paint(
              theme,
              value: null,
              t: _controller.value,
              direction: direction,
            ),
          )
        : _paint(theme, value: value, t: 0, direction: direction);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: child,
    );
  }
}

/// Paints the linear track plus its determinate fill or indeterminate
/// sweep segment, both clipped to the track's rounded rect.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.track,
    required this.fill,
    required this.borderRadius,
    required this.value,
    required this.t,
    required this.direction,
  });

  final Color track;
  final Color fill;
  final BorderRadius borderRadius;

  /// Completion fraction, or null while indeterminate.
  final double? value;

  /// Animation phase in `0..1` (unused when [value] is set).
  final double t;

  /// Which edge the fill grows from.
  final TextDirection direction;

  /// Fractional width of the indeterminate sweep segment.
  static const _segment = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    canvas.drawRRect(rrect, Paint()..color = track);

    final value = this.value;
    final width = value ?? _segment;
    var start = value == null ? t * (1 + _segment) - _segment : 0.0;
    if (direction == TextDirection.rtl) start = 1 - start - width;

    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTWH(start * size.width, 0, width * size.width, size.height),
        Paint()..color = fill,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      track != oldDelegate.track ||
      fill != oldDelegate.fill ||
      borderRadius != oldDelegate.borderRadius ||
      value != oldDelegate.value ||
      t != oldDelegate.t ||
      direction != oldDelegate.direction;
}

/// Paints the circular track plus its determinate arc (clockwise from
/// the top) or indeterminate rotating arc.
class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.track,
    required this.fill,
    required this.strokeWidth,
    required this.value,
    required this.t,
  });

  final Color track;
  final Color fill;
  final double strokeWidth;

  /// Completion fraction, or null while indeterminate.
  final double? value;

  /// Animation phase in `0..1` (unused when [value] is set).
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final value = this.value;
    if (value != null && value <= 0) return;
    final arc = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (value != null) {
      canvas.drawArc(rect, -math.pi / 2, value * 2 * math.pi, false, arc);
    } else {
      canvas.drawArc(
        rect,
        t * 2 * math.pi - math.pi / 2,
        math.pi / 2,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) =>
      track != oldDelegate.track ||
      fill != oldDelegate.fill ||
      strokeWidth != oldDelegate.strokeWidth ||
      value != oldDelegate.value ||
      t != oldDelegate.t;
}
