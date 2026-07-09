import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';

part 'legend_sizes.tokens.g.dart';

/// Spacing, radii, border and icon scales.
@LegendTokenData()
class LegendSizes with _$LegendSizes {
  const LegendSizes({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
    this.radiusSm = 4,
    this.radiusMd = 8,
    this.radiusLg = 16,
    this.borderWidth = 1,
    this.iconSm = 16,
    this.iconMd = 20,
    this.iconLg = 28,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double borderWidth;
  final double iconSm;
  final double iconMd;
  final double iconLg;

  BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendSizes lerp(LegendSizes a, LegendSizes b, double t) =>
      _$LegendSizesLerp(a, b, t);
}
