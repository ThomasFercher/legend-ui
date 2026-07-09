import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// WCAG 2.x contrast ratio, computed independently of the kit's
/// implementation (both sides use the standard relative-luminance
/// definition, which [Color.computeLuminance] implements).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // A deliberate spread: mid blue, very light saturated, near-black,
  // low-saturation, pure white, pure grey, warm red.
  const brands = <Color>[
    Color(0xFF0059FF),
    Color(0xFFFFEB3B),
    Color(0xFF06070A),
    Color(0xFF8A8D91),
    Color(0xFFFFFFFF),
    Color(0xFF808080),
    Color(0xFFDC2626),
  ];

  group('LegendTokens.fromSeed (RFC-002 R4)', () {
    test('is deterministic: the same seed yields value-equal tokens', () {
      for (final brightness in Brightness.values) {
        const brand = Color(0xFF0059FF);
        final a = LegendTokens.fromSeed(
          LegendSeed(brand: brand, brightness: brightness),
        );
        final b = LegendTokens.fromSeed(
          LegendSeed(brand: brand, brightness: brightness),
        );
        expect(a, b, reason: 'generated value == makes this checkable');
        expect(a.colors.primary, b.colors.primary);
        expect(a.hashCode, b.hashCode);
      }
    });

    test('light mode: primary is the seed itself (ramp stop 6)', () {
      const brand = Color(0xFF0059FF);
      final tokens = LegendTokens.fromSeed(const LegendSeed(brand: brand));
      expect(tokens.colors.primary, brand);
    });

    test('every guaranteed surface/on pair clears 4.5:1 for a spread of '
        'seeds, both brightnesses (documented threshold: WCAG AA)', () {
      for (final brand in brands) {
        for (final brightness in Brightness.values) {
          final c = LegendTokens.fromSeed(
            LegendSeed(brand: brand, brightness: brightness),
          ).colors;
          final pairs = <String, (Color, Color)>{
            'primary/onPrimary': (c.primary, c.onPrimary),
            'primaryContainer/onPrimaryContainer': (
              c.primaryContainer,
              c.onPrimaryContainer,
            ),
            'secondary/onSecondary': (c.secondary, c.onSecondary),
            'error/onError': (c.error, c.onError),
            'surface/onSurface': (c.surface, c.onSurface),
            'surface/foreground1': (c.surface, c.foreground1),
          };
          for (final MapEntry(key: name, value: pair) in pairs.entries) {
            expect(
              _contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '$name for brand $brand ($brightness)',
            );
          }
        }
      }
    });

    test('dark brightness produces dark surfaces with legible pairs', () {
      for (final brand in brands) {
        final c = LegendTokens.fromSeed(
          LegendSeed(brand: brand, brightness: Brightness.dark),
        ).colors;
        for (final surface in [
          c.surface,
          c.background1,
          c.background2,
          c.background3,
        ]) {
          expect(
            surface.computeLuminance(),
            lessThan(0.1),
            reason: 'dark surfaces stay dark for brand $brand',
          );
        }
        // Backgrounds are darker than the surface (elevation order).
        expect(
          c.background1.computeLuminance(),
          lessThan(c.surface.computeLuminance()),
        );
        expect(_contrast(c.background1, c.onSurface), greaterThan(4.5));
      }
    });

    test('light and dark from the same seed differ', () {
      const seed = LegendSeed(brand: Color(0xFF0059FF));
      const darkSeed = LegendSeed(
        brand: Color(0xFF0059FF),
        brightness: Brightness.dark,
      );
      final light = LegendTokens.fromSeed(seed);
      final dark = LegendTokens.fromSeed(darkSeed);
      expect(light, isNot(equals(dark)));
      expect(
        light.colors.surface.computeLuminance(),
        greaterThan(dark.colors.surface.computeLuminance()),
      );
    });

    test('sizeUnit scales the whole size scale as documented', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF), sizeUnit: 5),
      );
      final s = tokens.sizes;
      expect(s.xs, 5);
      expect(s.sm, 10);
      expect(s.md, 20);
      expect(s.lg, 30);
      expect(s.xl, 40);
      expect(s.xxl, 60);
      expect(s.iconSm, 20);
      expect(s.iconMd, 25);
      expect(s.iconLg, 35);
      expect(s.borderWidth, 1.25);
    });

    test('radius derives small = half, large = double', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF), radius: 12),
      );
      expect(tokens.sizes.radiusSm, 6);
      expect(tokens.sizes.radiusMd, 12);
      expect(tokens.sizes.radiusLg, 24);
    });

    test('the default seed scales reproduce the hand-authored sizes', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF)),
      );
      expect(tokens.sizes, const LegendSizes());
    });

    test('fontFamily lands on every derived text style', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF), fontFamily: 'Inter'),
      );
      final t = tokens.typography;
      for (final style in [t.h1, t.h2, t.h3, t.b1, t.b2, t.b3]) {
        expect(style.fontFamily, 'Inter');
      }
      // The scale itself is the kit default.
      expect(t.h1.fontSize, 32);
      expect(t.b3.fontSize, 12);
    });

    test('an explicit neutral tints the surfaces', () {
      final plain = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF)),
      );
      final tinted = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF), neutral: Color(0xFF806040)),
      );
      expect(tinted.colors.background1, isNot(plain.colors.background1));
    });

    test('copyWith still applies on top (derivation is a constructor, '
        'not a resolution level)', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF0059FF)),
      );
      final adjusted = tokens.copyWith(
        colors: tokens.colors.copyWith(primary: const Color(0xFF112233)),
      );
      expect(adjusted.colors.primary, const Color(0xFF112233));
      expect(adjusted.colors.surface, tokens.colors.surface);
    });

    test('LegendTokens.light/.dark are untouched by R4 (pinned)', () {
      expect(LegendTokens.light.colors.primary, const Color(0xFF1A80F4));
      expect(LegendTokens.light.colors.surface, const Color(0xFFFFFFFF));
      expect(LegendTokens.dark.colors.primary, const Color(0xFF3B94F6));
      expect(LegendTokens.dark.colors.surface, const Color(0xFF23262D));
      // The audit-added pair matches current usage: primary on container.
      expect(LegendColors.light.onPrimaryContainer, LegendColors.light.primary);
      expect(LegendColors.dark.onPrimaryContainer, LegendColors.dark.primary);
    });
  });

  group('LegendSeed', () {
    test('value equality over all fields', () {
      const a = LegendSeed(brand: Color(0xFF0059FF), radius: 10);
      const b = LegendSeed(brand: Color(0xFF0059FF), radius: 10);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const LegendSeed(brand: Color(0xFF0059FF), radius: 12)));
      expect(
        a,
        isNot(
          const LegendSeed(
            brand: Color(0xFF0059FF),
            radius: 10,
            brightness: Brightness.dark,
          ),
        ),
      );
    });
  });
}
