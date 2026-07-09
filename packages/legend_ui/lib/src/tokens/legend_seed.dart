import 'dart:ui';

import 'package:meta/meta.dart';

/// The input to `LegendTokens.fromSeed` (RFC-002 R4): a coherent theme
/// from 1–4 hand-picked values instead of 17 hand-picked colors.
///
/// Only [brand] is required; everything else has an opinionated default
/// matching the kit's hand-authored scales. The derivation is pure — the
/// same seed always produces the identical `LegendTokens` — and its output
/// is a plain token set, so `copyWith` still applies on top for surgical
/// adjustments (derivation is a constructor, not a resolution level).
///
/// `LegendTokens.fromSeed` documents every derivation rule and constant.
@immutable
class LegendSeed {
  const LegendSeed({
    required this.brand,
    this.neutral,
    this.radius = 8,
    this.sizeUnit = 4,
    this.fontFamily,
    this.brightness = Brightness.light,
  });

  /// The brand color — becomes `colors.primary` and seeds the internal
  /// 10-stop ramp every brand-related color derives from.
  final Color brand;

  /// Tint for the neutral scale (backgrounds, surfaces, foregrounds).
  /// Defaults to the brand hue at low saturation, so neutrals lean subtly
  /// toward the brand instead of dead grey.
  final Color? neutral;

  /// The base corner radius (`sizes.radiusMd`); the small/large radii
  /// derive as half/double of it.
  final double radius;

  /// The base spacing unit; the whole `LegendSizes` scale derives from it
  /// (default 4 reproduces the hand-authored scale exactly).
  final double sizeUnit;

  /// Font family applied to every derived text style; null keeps the
  /// platform default.
  final String? fontFamily;

  /// Light derives from the seed's light ramp on near-white neutrals;
  /// dark re-generates the same seed blended against a dark background —
  /// one seed serves both modes.
  final Brightness brightness;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendSeed &&
          other.brand == brand &&
          other.neutral == neutral &&
          other.radius == radius &&
          other.sizeUnit == sizeUnit &&
          other.fontFamily == fontFamily &&
          other.brightness == brightness;

  @override
  int get hashCode =>
      Object.hash(brand, neutral, radius, sizeUnit, fontFamily, brightness);
}
