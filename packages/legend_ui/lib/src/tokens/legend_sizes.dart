import 'dart:ui';

import 'package:flutter/painting.dart';

/// Spacing, radii, border and icon scales.
class LegendSizes {
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

  LegendSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? borderWidth,
    double? iconSm,
    double? iconMd,
    double? iconLg,
  }) {
    return LegendSizes(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      borderWidth: borderWidth ?? this.borderWidth,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
    );
  }

  static LegendSizes lerp(LegendSizes a, LegendSizes b, double t) {
    return LegendSizes(
      xs: lerpDouble(a.xs, b.xs, t)!,
      sm: lerpDouble(a.sm, b.sm, t)!,
      md: lerpDouble(a.md, b.md, t)!,
      lg: lerpDouble(a.lg, b.lg, t)!,
      xl: lerpDouble(a.xl, b.xl, t)!,
      xxl: lerpDouble(a.xxl, b.xxl, t)!,
      radiusSm: lerpDouble(a.radiusSm, b.radiusSm, t)!,
      radiusMd: lerpDouble(a.radiusMd, b.radiusMd, t)!,
      radiusLg: lerpDouble(a.radiusLg, b.radiusLg, t)!,
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t)!,
      iconSm: lerpDouble(a.iconSm, b.iconSm, t)!,
      iconMd: lerpDouble(a.iconMd, b.iconMd, t)!,
      iconLg: lerpDouble(a.iconLg, b.iconLg, t)!,
    );
  }
}
