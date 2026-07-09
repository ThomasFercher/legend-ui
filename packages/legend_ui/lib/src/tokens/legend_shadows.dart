import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_shadows.tokens.g.dart';

/// The single elevation system (replaces legacy ElevatedBox + LegendElevation).
@LegendTokenData(mountedAt: 'shadows')
class LegendShadows with _$LegendShadows {
  const LegendShadows({
    this.none = const [],
    this.low = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    this.medium = const [
      BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
    this.high = const [
      BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  });

  /// Flat — no shadow at all.
  final List<BoxShadow> none;

  /// Subtle lift for resting content (cards).
  final List<BoxShadow> low;

  /// Clear separation for floating chrome (menus, toasts, bars).
  final List<BoxShadow> medium;

  /// Strong lift for modal surfaces (dialogs).
  final List<BoxShadow> high;

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendShadows lerp(LegendShadows a, LegendShadows b, double t) =>
      _$LegendShadowsLerp(a, b, t);
}
