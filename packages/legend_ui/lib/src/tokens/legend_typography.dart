import 'package:flutter/painting.dart';

/// The six-style type scale (headings h1–h3, body b1–b3).
///
/// Colors are not baked in here — text color resolves from the color
/// tokens (`LegendColors`) at the component level.
class LegendTypography {
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

  LegendTypography copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? b1,
    TextStyle? b2,
    TextStyle? b3,
  }) {
    return LegendTypography(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      b1: b1 ?? this.b1,
      b2: b2 ?? this.b2,
      b3: b3 ?? this.b3,
    );
  }

  static LegendTypography lerp(
    LegendTypography a,
    LegendTypography b,
    double t,
  ) {
    return LegendTypography(
      h1: TextStyle.lerp(a.h1, b.h1, t)!,
      h2: TextStyle.lerp(a.h2, b.h2, t)!,
      h3: TextStyle.lerp(a.h3, b.h3, t)!,
      b1: TextStyle.lerp(a.b1, b.b1, t)!,
      b2: TextStyle.lerp(a.b2, b.b2, t)!,
      b3: TextStyle.lerp(a.b3, b.b3, t)!,
    );
  }
}
