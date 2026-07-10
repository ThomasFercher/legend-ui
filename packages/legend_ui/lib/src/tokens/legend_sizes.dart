import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_sizes.tokens.g.dart';

/// Spacing, radii, border and icon scales.
@LegendTokenData(mountedAt: 'sizes', refName: 'SizeRef')
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

  /// Extra-small spacing step (tight gaps, chip padding).
  final double xs;

  /// Small spacing step (row gaps, compact padding).
  final double sm;

  /// Medium spacing step — the default content padding.
  final double md;

  /// Large spacing step (section padding).
  final double lg;

  /// Extra-large spacing step (page gutters).
  final double xl;

  /// Largest spacing step (hero spacing).
  final double xxl;

  /// Small corner radius (text buttons, chips).
  final double radiusSm;

  /// Medium corner radius — the default component rounding.
  final double radiusMd;

  /// Large corner radius (cards, dialogs).
  final double radiusLg;

  /// Hairline width for borders and dividers.
  final double borderWidth;

  /// Small icon size.
  final double iconSm;

  /// Medium icon size — the default inline icon.
  final double iconMd;

  /// Large icon size.
  final double iconLg;

  /// [radiusSm] as a circular [BorderRadius].
  BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);

  /// [radiusMd] as a circular [BorderRadius].
  BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);

  /// [radiusLg] as a circular [BorderRadius].
  BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendSizes lerp(LegendSizes a, LegendSizes b, double t) =>
      _$LegendSizesLerp(a, b, t);
}
