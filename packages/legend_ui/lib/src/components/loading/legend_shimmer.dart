import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_shimmer.theme.g.dart';

/// A looping gradient sweep over [child] — a `ShaderMask` sliding a
/// `LinearGradient` across the subtree (skeleton-loading effect).
///
/// [LegendShimmer.box] is the convenience placeholder: a base-colored
/// rounded box (a [LegendSurface]) that shimmers, for skeleton layouts
/// without content.
@LegendThemeable()
class LegendShimmer extends StatefulWidget {
  const LegendShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
  }) : width = null,
       height = null,
       boxBorderRadius = null;

  /// A shimmering placeholder box of [width]×[height], painted in the
  /// resolved base color.
  const LegendShimmer.box({
    super.key,
    this.width,
    this.height,
    BorderRadius? borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : child = null,
       boxBorderRadius = borderRadius;

  final Widget? child;

  /// Placeholder box width (only for [LegendShimmer.box]).
  final double? width;

  /// Placeholder box height (only for [LegendShimmer.box]).
  final double? height;

  /// Placeholder box corner radius (only for [LegendShimmer.box]).
  final BorderRadius? boxBorderRadius;

  /// Resting color of the sweep (and the fill of [LegendShimmer.box]).
  @Style<Color>.resolve(ColorRef.background2)
  final Color? baseColor;

  /// Color of the moving highlight band.
  @Style<Color>.resolve(ColorRef.background1)
  final Color? highlightColor;

  @override
  State<LegendShimmer> createState() => _LegendShimmerState();
}

class _LegendShimmerState extends State<LegendShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget._theme(context);
    final content =
        widget.child ??
        LegendSurface(
          color: theme.baseColor,
          borderRadius: widget.boxBorderRadius,
          child: SizedBox(width: widget.width, height: widget.height),
        );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [theme.baseColor, theme.highlightColor, theme.baseColor],
          stops: const [0.25, 0.5, 0.75],
          transform: _SlidingGradientTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: content,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1) * 1.5, 0, 0);
}
