import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_state_overlays.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_tokens.tokens.g.dart';

/// The design tokens — the only global theme (DESIGN.md §2.1).
///
/// Written once, by hand. Every component default derives from an instance
/// of this class (the `t` in `@Style<T>.resolve` tear-offs).
@LegendTokenData()
class LegendTokens with _$LegendTokens {
  const LegendTokens({
    required this.colors,
    this.sizes = const LegendSizes(),
    this.typography = const LegendTypography(),
    this.shadows = const LegendShadows(),
    this.states = const LegendStateOverlays(),
  });

  final LegendColors colors;
  final LegendSizes sizes;
  final LegendTypography typography;
  final LegendShadows shadows;

  /// Interaction-state derivation deltas (RFC-002 R6): how unset
  /// hover/press/disabled variants derive from a base color.
  final LegendStateOverlays states;

  static const light = LegendTokens(colors: LegendColors.light);
  static const dark = LegendTokens(colors: LegendColors.dark);

  /// Lerp the whole token set — the one lerp a theme switch pays
  /// (DESIGN.md §2.4), instead of tweening every component class
  /// (generated, RFC-002 R5).
  static LegendTokens lerp(LegendTokens a, LegendTokens b, double t) =>
      _$LegendTokensLerp(a, b, t);
}
