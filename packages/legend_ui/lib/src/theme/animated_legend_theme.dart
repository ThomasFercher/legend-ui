import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

/// Tween over the whole token set — the single lerp a theme switch pays
/// (DESIGN.md §2.4).
class LegendTokensTween extends Tween<LegendTokens> {
  LegendTokensTween({super.begin, super.end});

  @override
  LegendTokens lerp(double t) => LegendTokens.lerp(begin!, end!, t);
}

/// Provides [LegendTheme] and implicitly animates token changes (light/dark/
/// brand switches). Component themes re-derive from the animating tokens;
/// nothing else is tweened — this replaces legacy's 400 ms lerp of all
/// ~48 generated theme classes.
///
/// The [LegendThemeData.components] registry is intentionally NOT animated:
/// if the new theme carries a different components map it snaps at the
/// start of the transition (review I6, deferred — token-derived defaults,
/// the common case, still animate smoothly).
class AnimatedLegendTheme extends ImplicitlyAnimatedWidget {
  const AnimatedLegendTheme({
    required this.data,
    required this.child,
    super.key,
    super.duration = const Duration(milliseconds: 250),
    super.curve = Curves.easeOutCubic,
  });

  final LegendThemeData data;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedLegendTheme> createState() =>
      _AnimatedLegendThemeState();
}

class _AnimatedLegendThemeState
    extends AnimatedWidgetBaseState<AnimatedLegendTheme> {
  LegendTokensTween? _tokens;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tokens =
        visitor(
              _tokens,
              widget.data.tokens,
              (value) => LegendTokensTween(begin: value as LegendTokens),
            )
            as LegendTokensTween?;
  }

  @override
  Widget build(BuildContext context) {
    return LegendTheme(
      data: LegendThemeData(
        tokens: _tokens?.evaluate(animation) ?? widget.data.tokens,
        components: widget.data.components,
      ),
      child: widget.child,
    );
  }
}
