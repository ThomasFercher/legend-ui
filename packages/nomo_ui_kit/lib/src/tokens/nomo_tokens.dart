import 'package:nomo_ui_kit/src/tokens/nomo_colors.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_shadows.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_sizes.dart';
import 'package:nomo_ui_kit/src/tokens/nomo_typography.dart';

/// The design tokens — the only global theme (DESIGN.md §2.1).
///
/// Written once, by hand. Every component default derives from an instance
/// of this class (the `t` in `@Themed(defaultsTo: 't.…')`).
class NomoTokens {
  const NomoTokens({
    required this.colors,
    this.sizes = const NomoSizes(),
    this.typography = const NomoTypography(),
    this.shadows = const NomoShadows(),
  });

  final NomoColors colors;
  final NomoSizes sizes;
  final NomoTypography typography;
  final NomoShadows shadows;

  static const light = NomoTokens(colors: NomoColors.light);
  static const dark = NomoTokens(colors: NomoColors.dark);

  NomoTokens copyWith({
    NomoColors? colors,
    NomoSizes? sizes,
    NomoTypography? typography,
    NomoShadows? shadows,
  }) {
    return NomoTokens(
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      typography: typography ?? this.typography,
      shadows: shadows ?? this.shadows,
    );
  }

  /// Lerp the whole token set — the one lerp a theme switch pays
  /// (DESIGN.md §2.4), instead of tweening every component class.
  static NomoTokens lerp(NomoTokens a, NomoTokens b, double t) {
    return NomoTokens(
      colors: NomoColors.lerp(a.colors, b.colors, t),
      sizes: NomoSizes.lerp(a.sizes, b.sizes, t),
      typography: NomoTypography.lerp(a.typography, b.typography, t),
      shadows: NomoShadows.lerp(a.shadows, b.shadows, t),
    );
  }
}
