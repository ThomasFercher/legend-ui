import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_state_overlays.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

/// The design tokens — the only global theme (DESIGN.md §2.1).
///
/// Written once, by hand. Every component default derives from an instance
/// of this class (the `t` in `@Style<T>.resolve` tear-offs).
class LegendTokens {
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

  LegendTokens copyWith({
    LegendColors? colors,
    LegendSizes? sizes,
    LegendTypography? typography,
    LegendShadows? shadows,
    LegendStateOverlays? states,
  }) {
    return LegendTokens(
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      typography: typography ?? this.typography,
      shadows: shadows ?? this.shadows,
      states: states ?? this.states,
    );
  }

  /// Lerp the whole token set — the one lerp a theme switch pays
  /// (DESIGN.md §2.4), instead of tweening every component class.
  static LegendTokens lerp(LegendTokens a, LegendTokens b, double t) {
    return LegendTokens(
      colors: LegendColors.lerp(a.colors, b.colors, t),
      sizes: LegendSizes.lerp(a.sizes, b.sizes, t),
      typography: LegendTypography.lerp(a.typography, b.typography, t),
      shadows: LegendShadows.lerp(a.shadows, b.shadows, t),
      states: LegendStateOverlays.lerp(a.states, b.states, t),
    );
  }
}
