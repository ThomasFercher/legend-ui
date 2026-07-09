import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/loading/nomo_shimmer.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';

/// A looping gradient sweep over [child] — a `ShaderMask` sliding a
/// `LinearGradient` across the subtree (skeleton-loading effect).
///
/// [NomoShimmer.box] is the convenience placeholder: a base-colored
/// rounded box that shimmers, for skeleton layouts without content.
@NomoThemeable()
class NomoShimmer extends StatefulWidget {
  const NomoShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
  }) : width = null,
       height = null,
       boxBorderRadius = null;

  /// A shimmering placeholder box of [width]×[height], painted in the
  /// resolved base color.
  const NomoShimmer.box({
    super.key,
    this.width,
    this.height,
    BorderRadius? borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : child = null,
       boxBorderRadius = borderRadius;

  final Widget? child;

  /// Placeholder box width (only for [NomoShimmer.box]).
  final double? width;

  /// Placeholder box height (only for [NomoShimmer.box]).
  final double? height;

  /// Placeholder box corner radius (only for [NomoShimmer.box]).
  final BorderRadius? boxBorderRadius;

  @Themed(defaultsTo: 't.colors.background2')
  final Color? baseColor;

  @Themed(defaultsTo: 't.colors.background1')
  final Color? highlightColor;

  @override
  State<NomoShimmer> createState() => _NomoShimmerState();
}

class _NomoShimmerState extends State<NomoShimmer>
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
    final theme = NomoShimmerTheme.of(
      context,
      NomoShimmerThemeNullable(
        baseColor: widget.baseColor,
        highlightColor: widget.highlightColor,
      ),
    );
    final content =
        widget.child ??
        NomoSurface(
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
      Matrix4.translationValues(
        bounds.width * (percent * 2 - 1) * 1.5,
        0,
        0,
      );
}
