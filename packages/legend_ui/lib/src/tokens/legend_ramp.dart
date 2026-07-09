import 'package:flutter/painting.dart';

/// A 10-stop color ramp derived from one seed color (RFC-002 R4), adapting
/// the idea of Ant Design v5's `generate()`: hue-rotation, saturation and
/// value stepping in HSV space.
///
/// **Internal** (Fluent's rule): never exported through the barrel. The
/// public theme surface is the semantic pairs `LegendTokens.fromSeed` maps
/// from these stops — consumers never see raw ramp indices.
///
/// Stop semantics (1-based, matching the AntD convention):
///
/// - stops **1–4** — light surface tints (backgrounds, containers),
/// - stop **5** — hover,
/// - stop **6** — the seed itself, unchanged (the base brand color),
/// - stop **7** — active/pressed,
/// - stops **8–10** — dark accents.
///
/// [LegendRamp.dark] re-generates the same seed blended against a dark
/// background — one algorithm for both modes, not a second hand-authored
/// palette. Its stops run background-most (1) to accent-most (10), so the
/// *roles* stay stable across modes while the lightness direction flips.
final class LegendRamp {
  LegendRamp._(this.stops) : assert(stops.length == 10, 'a ramp has 10 stops');

  /// Generates the light-mode ramp for [seed].
  factory LegendRamp.of(Color seed) {
    final hsv = HSVColor.fromColor(seed);
    return LegendRamp._(
      List.unmodifiable(<Color>[
        for (var i = _lightStops; i >= 1; i--) _shifted(hsv, i, lighter: true),
        seed,
        for (var i = 1; i <= _darkStops; i++) _shifted(hsv, i, lighter: false),
      ]),
    );
  }

  /// Generates the dark-mode ramp for [seed]: each stop blends a light-ramp
  /// stop into [background] with a fixed weight ([_darkBlend]) — the AntD
  /// dark-theme mapping.
  factory LegendRamp.dark(
    Color seed, {
    Color background = defaultDarkBackground,
  }) {
    final light = LegendRamp.of(seed);
    return LegendRamp._(
      List.unmodifiable(<Color>[
        for (final (index, weight) in _darkBlend)
          Color.lerp(background, light.stop(index), weight)!,
      ]),
    );
  }

  /// The background the dark ramp blends against by default (AntD's
  /// dark-theme canvas).
  static const defaultDarkBackground = Color(0xFF141414);

  /// The 10 stops; index 0 is stop 1.
  final List<Color> stops;

  /// The 1-based [n]th stop (1–10).
  Color stop(int n) => stops[n - 1];

  // ── Derivation constants (adapted from @ant-design/colors) ─────────

  /// Degrees of hue rotated per step away from the seed.
  static const _hueStep = 2.0;

  /// Saturation removed per light step / added at the last dark step.
  static const _saturationStepLight = 0.16;

  /// Saturation added per dark step (except the last, which uses the
  /// light step for a stronger final accent).
  static const _saturationStepDark = 0.05;

  /// Value added per light step.
  static const _valueStepLight = 0.05;

  /// Value removed per dark step.
  static const _valueStepDark = 0.15;

  /// Number of stops lighter than the seed (stops 1–5).
  static const _lightStops = 5;

  /// Number of stops darker than the seed (stops 7–10).
  static const _darkStops = 4;

  /// Dark-mode blend table: `(lightStopIndex, weightOfLightStop)` per dark
  /// stop 1–10. Weights grow toward the accent end, so dark stop 1 is
  /// mostly background (a tinted canvas) and dark stop 10 is nearly the
  /// lightest light stop.
  static const _darkBlend = <(int, double)>[
    (7, 0.15),
    (6, 0.25),
    (5, 0.30),
    (5, 0.45),
    (5, 0.65),
    (5, 0.85),
    (4, 0.90),
    (3, 0.95),
    (2, 0.97),
    (1, 0.98),
  ];

  static Color _shifted(HSVColor seed, int i, {required bool lighter}) {
    return HSVColor.fromAHSV(
      1,
      _hue(seed, i, lighter: lighter),
      _saturation(seed, i, lighter: lighter),
      _value(seed, i, lighter: lighter),
    ).toColor();
  }

  /// Cool hues (60°–240°: green through blue) rotate toward cooler when
  /// lightening and warmer when darkening; warm hues the opposite — this
  /// keeps tints airy and shades rich instead of muddy.
  static double _hue(HSVColor seed, int i, {required bool lighter}) {
    final h = seed.hue;
    final double rotated;
    if (h >= 60 && h <= 240) {
      rotated = lighter ? h - _hueStep * i : h + _hueStep * i;
    } else {
      rotated = lighter ? h + _hueStep * i : h - _hueStep * i;
    }
    return rotated % 360;
  }

  static double _saturation(HSVColor seed, int i, {required bool lighter}) {
    // Greys stay grey — no saturation is invented for achromatic seeds.
    if (seed.hue == 0 && seed.saturation == 0) return seed.saturation;
    double s;
    if (lighter) {
      s = seed.saturation - _saturationStepLight * i;
    } else if (i == _darkStops) {
      s = seed.saturation + _saturationStepLight;
    } else {
      s = seed.saturation + _saturationStepDark * i;
    }
    if (s > 1) s = 1;
    // The lightest tint stays a whisper of the brand, never a pastel wash.
    if (lighter && i == _lightStops && s > 0.1) s = 0.1;
    if (s < 0.06) s = 0.06;
    return s;
  }

  static double _value(HSVColor seed, int i, {required bool lighter}) {
    final v = lighter
        ? seed.value + _valueStepLight * i
        : seed.value - _valueStepDark * i;
    return v.clamp(0.0, 1.0);
  }
}
