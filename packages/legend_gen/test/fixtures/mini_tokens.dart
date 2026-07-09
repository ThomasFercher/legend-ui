import 'package:flutter/painting.dart';
import 'package:legend_ui/legend_ui.dart';

part 'mini_tokens.tokens.g.dart';

/// Golden-test fixture (RFC-002 R5): covers every lerper category —
/// Color, double (guarded arithmetic), TextStyle, List&lt;BoxShadow&gt;
/// (element-wise `==`/hash), and a nested token class (static-lerp
/// convention) — plus multi-class emission into one part file.
@LegendTokenData()
class MiniTokens with _$MiniTokens {
  const MiniTokens({
    this.accent = const Color(0xFF123456),
    this.gap = 8,
    this.label = const TextStyle(fontSize: 12),
    this.glow = const [],
    this.nested = const MiniNested(),
  });

  /// Accent color drawn behind everything.
  final Color accent;

  /// Gap between items.
  final double gap;

  /// Label style.
  final TextStyle label;

  /// Glow shadow stack.
  final List<BoxShadow> glow;

  /// Nested token group.
  final MiniNested nested;

  /// Member-wise lerp (generated, RFC-002 R5).
  static MiniTokens lerp(MiniTokens a, MiniTokens b, double t) =>
      _$MiniTokensLerp(a, b, t);
}

/// Nested token group of [MiniTokens].
@LegendTokenData()
class MiniNested with _$MiniNested {
  const MiniNested({this.amount = 0.5});

  /// Some derivation amount.
  final double amount;

  /// Member-wise lerp (generated, RFC-002 R5).
  static MiniNested lerp(MiniNested a, MiniNested b, double t) =>
      _$MiniNestedLerp(a, b, t);
}
