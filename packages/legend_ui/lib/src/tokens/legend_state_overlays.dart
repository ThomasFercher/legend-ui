import 'dart:ui';

import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_state_overlays.tokens.g.dart';

/// Token-level interaction-state derivation (RFC-002 R6): how a base color
/// turns into its hovered/pressed/disabled variants when a state variant
/// was not named explicitly.
///
/// Components (and `LegendStates<Color>` fields, via their color-bound
/// extension) derive state colors from one base value through these
/// overlays, so a brand restyle automatically restyles hover/press
/// everywhere and components stop inventing their own hover math.
/// Hand-naming a state variant always wins over this derivation.
@LegendTokenData(mountedAt: 'states')
class LegendStateOverlays with _$LegendStateOverlays {
  /// Sensible defaults: hover shifts ~6% toward the contrast pole, pressed
  /// ~12%, disabled keeps the color at half opacity.
  const LegendStateOverlays({
    this.hoverAmount = 0.06,
    this.pressAmount = 0.12,
    this.disabledOpacity = 0.5,
  });

  /// How far [hovered] shifts the base toward black/white (0–1).
  final double hoverAmount;

  /// How far [pressed] shifts the base toward black/white (0–1).
  final double pressAmount;

  /// Opacity multiplier [disabled] applies to the base color (0–1).
  final double disabledOpacity;

  /// The hovered variant of [base]: darkened for light colors, lightened
  /// for dark ones (by relative luminance), by [hoverAmount].
  Color hovered(Color base) => _shift(base, hoverAmount);

  /// The pressed variant of [base] — same direction as [hovered], stronger
  /// ([pressAmount]).
  Color pressed(Color base) => _shift(base, pressAmount);

  /// The disabled variant of [base]: the same color at
  /// `alpha * disabledOpacity`.
  Color disabled(Color base) =>
      base.withValues(alpha: base.a * disabledOpacity);

  Color _shift(Color base, double amount) {
    final target = base.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return Color.lerp(base, target, amount)!;
  }

  /// Member-wise lerp (generated, RFC-002 R5).
  static LegendStateOverlays lerp(
    LegendStateOverlays a,
    LegendStateOverlays b,
    double t,
  ) => _$LegendStateOverlaysLerp(a, b, t);
}
