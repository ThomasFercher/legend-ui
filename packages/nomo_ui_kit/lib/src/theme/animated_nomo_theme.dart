import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_tokens.dart';

/// Tween over the whole token set — the single lerp a theme switch pays
/// (DESIGN.md §2.4).
class NomoTokensTween extends Tween<NomoTokens> {
  NomoTokensTween({super.begin, super.end});

  @override
  NomoTokens lerp(double t) => NomoTokens.lerp(begin!, end!, t);
}

/// Provides [NomoTheme] and implicitly animates token changes (light/dark/
/// brand switches). Component themes re-derive from the animating tokens;
/// nothing else is tweened — this replaces legacy's 400 ms lerp of all
/// ~48 generated theme classes.
///
/// The [NomoThemeData.components] registry is intentionally NOT animated:
/// if the new theme carries a different components map it snaps at the
/// start of the transition (review I6, deferred — token-derived defaults,
/// the common case, still animate smoothly).
class AnimatedNomoTheme extends ImplicitlyAnimatedWidget {
  const AnimatedNomoTheme({
    required this.data,
    required this.child,
    super.key,
    super.duration = const Duration(milliseconds: 250),
    super.curve = Curves.easeOutCubic,
  });

  final NomoThemeData data;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedNomoTheme> createState() =>
      _AnimatedNomoThemeState();
}

class _AnimatedNomoThemeState
    extends AnimatedWidgetBaseState<AnimatedNomoTheme> {
  NomoTokensTween? _tokens;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tokens =
        visitor(
              _tokens,
              widget.data.tokens,
              (value) => NomoTokensTween(begin: value as NomoTokens),
            )
            as NomoTokensTween?;
  }

  @override
  Widget build(BuildContext context) {
    return NomoTheme(
      data: NomoThemeData(
        tokens: _tokens?.evaluate(animation) ?? widget.data.tokens,
        components: widget.data.components,
      ),
      child: widget.child,
    );
  }
}
