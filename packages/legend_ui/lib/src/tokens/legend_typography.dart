import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_typography.tokens.g.dart';

/// The six-style type scale (headings h1–h3, body b1–b3).
///
/// Colors are not baked in here — text color resolves from the color
/// tokens (`LegendColors`) at the component level.
@LegendTokenData(mountedAt: 'typography')
class LegendTypography with _$LegendTypography {
  const LegendTypography({
    this.h1 = const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    this.h2 = const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    this.h3 = const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
    this.b1 = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    this.b2 = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    this.b3 = const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  });

  /// Page-level heading.
  final TextStyle h1;

  /// Section heading.
  final TextStyle h2;

  /// Subsection heading (dialog titles, card headers).
  final TextStyle h3;

  /// Primary body text.
  final TextStyle b1;

  /// Secondary body text — button labels, menu items, form values.
  final TextStyle b2;

  /// Small text — captions, field titles, error messages.
  final TextStyle b3;

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendTypography lerp(
    LegendTypography a,
    LegendTypography b,
    double t,
  ) => _$LegendTypographyLerp(a, b, t);
}
