import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';

part 'legend_typography.tokens.g.dart';

/// The six-style type scale (headings h1–h3, body b1–b3).
///
/// Colors are not baked in here — text color resolves from the color
/// tokens (`LegendColors`) at the component level.
@LegendTokenData()
class LegendTypography with _$LegendTypography {
  const LegendTypography({
    this.h1 = const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    this.h2 = const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    this.h3 = const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
    this.b1 = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    this.b2 = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    this.b3 = const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle b1;
  final TextStyle b2;
  final TextStyle b3;

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendTypography lerp(
    LegendTypography a,
    LegendTypography b,
    double t,
  ) => _$LegendTypographyLerp(a, b, t);
}
