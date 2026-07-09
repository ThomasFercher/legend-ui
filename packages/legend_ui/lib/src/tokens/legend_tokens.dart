import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_ramp.dart';
import 'package:legend_ui/src/tokens/legend_seed.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_state_overlays.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_tokens.tokens.g.dart';

/// The design tokens — the only global theme (DESIGN.md §2.1).
///
/// Written once, by hand. Every component default derives from an instance
/// of this class (the `t` in `@Style<T>.resolve` tear-offs).
@LegendTokenData()
class LegendTokens with _$LegendTokens {
  const LegendTokens({
    required this.colors,
    this.sizes = const LegendSizes(),
    this.typography = const LegendTypography(),
    this.shadows = const LegendShadows(),
    this.states = const LegendStateOverlays(),
  });

  /// Derives a full token set from one [LegendSeed] (RFC-002 R4) — a pure
  /// function: the same seed always yields the identical (value-equal)
  /// tokens. Additive: [light]/[dark] stay hand-authored; this is the
  /// consumer path from 1–4 seed values to a coherent theme.
  ///
  /// Derivation rules (all constants documented at the private helpers):
  ///
  /// - **Brand**: an internal AntD-adapted 10-stop ramp (`LegendRamp`);
  ///   `primary` is stop 6 (the seed itself in light mode),
  ///   `primaryContainer` stop 2. Dark brightness re-generates the same
  ///   seed blended against a dark background — one algorithm, both modes.
  /// - **Secondary**: the brand hue rotated +120° through the same ramp.
  /// - **Error**: a fixed red seed (`0xFFDC2626`, the kit's hand-authored
  ///   light error) through the same ramp, so it tracks brightness.
  /// - **Foreground pairs**: every `on*` color is picked between pure
  ///   white and pure black by WCAG relative-luminance contrast. The pure
  ///   poles are deliberate: the winning pole clears **≥ 4.5:1 (WCAG AA)**
  ///   against *any* background — the worst case is 4.58:1 at background
  ///   luminance ≈ 0.18 (a near-black pole would dip below 4.5 on
  ///   mid-tone seeds).
  /// - **Neutrals**: surfaces/backgrounds blend the neutral tint
  ///   (default: brand hue at 10% saturation, 50% value) toward white
  ///   (light) or black (dark); `foreground2`/`foreground3` are hint
  ///   shades blended from `onSurface` toward `surface` and, like the
  ///   `disabled` pair, are intentionally muted — they are outside the
  ///   4.5:1 guarantee.
  /// - **Sizes**: the whole scale from [LegendSeed.sizeUnit] (spacing
  ///   1/2/4/6/8/12 units, icons 4/5/7 units, border unit/4) and
  ///   [LegendSeed.radius] (small = half, large = double).
  /// - **Typography**: the default six-style scale with
  ///   [LegendSeed.fontFamily] applied.
  /// - **Shadows/states**: the kit defaults.
  factory LegendTokens.fromSeed(LegendSeed seed) {
    return LegendTokens(
      colors: _colorsFromSeed(seed),
      sizes: _sizesFromSeed(seed),
      typography: _typographyFromSeed(seed),
    );
  }

  final LegendColors colors;
  final LegendSizes sizes;
  final LegendTypography typography;
  final LegendShadows shadows;

  /// Interaction-state derivation deltas (RFC-002 R6): how unset
  /// hover/press/disabled variants derive from a base color.
  final LegendStateOverlays states;

  static const light = LegendTokens(colors: LegendColors.light);
  static const dark = LegendTokens(colors: LegendColors.dark);

  /// Lerp the whole token set — the one lerp a theme switch pays
  /// (DESIGN.md §2.4), instead of tweening every component class
  /// (generated, RFC-002 R5).
  static LegendTokens lerp(LegendTokens a, LegendTokens b, double t) =>
      _$LegendTokensLerp(a, b, t);
}

// ── fromSeed derivation (RFC-002 R4) ──────────────────────────────────

/// The fixed error seed — the kit's hand-authored light error red.
const _errorSeed = Color(0xFFDC2626);

/// Degrees the brand hue rotates to derive the secondary color.
const _secondaryHueRotation = 120.0;

/// Default neutral tint: brand hue at this saturation and value.
const _neutralSaturation = 0.10;
const _neutralValue = 0.50;

/// Neutral blend weights, light mode: white → neutral.
const _lightSurfaceBlend = 0.02;
const _lightBackgroundBlend = (0.05, 0.09, 0.14);

/// Neutral blend weights, dark mode: black → neutral. The surface sits
/// above the backgrounds, so it takes the strongest tint (lightest).
const _darkSurfaceBlend = 0.22;
const _darkBackgroundBlend = (0.08, 0.12, 0.16);

/// Hint-foreground blends: `onSurface` → `surface`.
const _foreground2Blend = 0.35;
const _foreground3Blend = 0.55;

/// Disabled pair blends: `surface` → `onSurface`. Intentionally muted —
/// outside the 4.5:1 guarantee, like every disabled treatment.
const _disabledBlend = 0.16;
const _onDisabledBlend = 0.45;

LegendColors _colorsFromSeed(LegendSeed seed) {
  final dark = seed.brightness == Brightness.dark;
  LegendRamp ramp(Color c) => dark ? LegendRamp.dark(c) : LegendRamp.of(c);

  final brand = ramp(seed.brand);
  final secondary = ramp(_rotateHue(seed.brand, _secondaryHueRotation));
  final error = ramp(_errorSeed);
  final neutral = seed.neutral ?? _defaultNeutral(seed.brand);

  final pole = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color neutralBlend(double weight) => Color.lerp(pole, neutral, weight)!;

  final surface = neutralBlend(dark ? _darkSurfaceBlend : _lightSurfaceBlend);
  final backgroundBlend = dark ? _darkBackgroundBlend : _lightBackgroundBlend;
  final onSurface = _onColor(surface);

  final primary = brand.stop(6);
  final primaryContainer = brand.stop(2);
  final secondaryBase = secondary.stop(6);
  final errorBase = error.stop(6);
  final disabled = Color.lerp(surface, onSurface, _disabledBlend)!;

  return LegendColors(
    primary: primary,
    onPrimary: _onColor(primary),
    primaryContainer: primaryContainer,
    onPrimaryContainer: _onColor(primaryContainer),
    secondary: secondaryBase,
    onSecondary: _onColor(secondaryBase),
    background1: neutralBlend(backgroundBlend.$1),
    background2: neutralBlend(backgroundBlend.$2),
    background3: neutralBlend(backgroundBlend.$3),
    surface: surface,
    onSurface: onSurface,
    error: errorBase,
    onError: _onColor(errorBase),
    disabled: disabled,
    onDisabled: Color.lerp(surface, onSurface, _onDisabledBlend)!,
    foreground1: onSurface,
    foreground2: Color.lerp(onSurface, surface, _foreground2Blend)!,
    foreground3: Color.lerp(onSurface, surface, _foreground3Blend)!,
  );
}

/// Picks the foreground for [background]: pure white or pure black,
/// whichever has the higher WCAG contrast ratio. With pure poles the
/// winner always clears 4.5:1 (worst case 4.58:1 at background relative
/// luminance ≈ 0.18) — the documented `fromSeed` contrast guarantee.
Color _onColor(Color background) {
  final l = background.computeLuminance();
  final contrastWhite = 1.05 / (l + 0.05);
  final contrastBlack = (l + 0.05) / 0.05;
  return contrastWhite >= contrastBlack
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
}

Color _rotateHue(Color color, double degrees) {
  final hsv = HSVColor.fromColor(color);
  return hsv.withHue((hsv.hue + degrees) % 360).toColor();
}

Color _defaultNeutral(Color brand) {
  final hsv = HSVColor.fromColor(brand);
  return HSVColor.fromAHSV(
    1,
    hsv.hue,
    _neutralSaturation,
    _neutralValue,
  ).toColor();
}

LegendSizes _sizesFromSeed(LegendSeed seed) {
  final u = seed.sizeUnit;
  final r = seed.radius;
  return LegendSizes(
    xs: u,
    sm: u * 2,
    md: u * 4,
    lg: u * 6,
    xl: u * 8,
    xxl: u * 12,
    radiusSm: r / 2,
    radiusMd: r,
    radiusLg: r * 2,
    borderWidth: u / 4,
    iconSm: u * 4,
    iconMd: u * 5,
    iconLg: u * 7,
  );
}

LegendTypography _typographyFromSeed(LegendSeed seed) {
  final family = seed.fontFamily;
  return LegendTypography(
    h1: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontFamily: family,
    ),
    h2: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: family,
    ),
    h3: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      fontFamily: family,
    ),
    b1: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: family,
    ),
    b2: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: family,
    ),
    b3: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: family,
    ),
  );
}
