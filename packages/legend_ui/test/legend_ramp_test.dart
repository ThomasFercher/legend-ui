import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
// The ramp is internal (not exported through the barrel — RFC-002 R4,
// Fluent's rule); the kit's own tests reach it via the src import.
import 'package:legend_ui/src/tokens/legend_ramp.dart';

void main() {
  const seeds = <Color>[
    Color(0xFF0059FF), // the RFC's example brand blue
    Color(0xFF1A80F4), // the kit's light primary
    Color(0xFFDC2626), // warm red (hue < 60: opposite rotation branch)
    Color(0xFF10B981), // green
    Color(0xFFFFEB3B), // very light, saturated yellow
    Color(0xFF06070A), // near-black brand
    Color(0xFF8A8D91), // low-saturation grey-blue
    Color(0xFF808080), // pure grey (achromatic guard)
  ];

  group('LegendRamp (RFC-002 R4)', () {
    test('produces 10 stops with the seed unchanged at stop 6', () {
      for (final seed in seeds) {
        final ramp = LegendRamp.of(seed);
        expect(ramp.stops, hasLength(10));
        expect(ramp.stop(6), seed, reason: 'stop 6 is the seed itself');
      }
    });

    test('HSV value progresses monotonically from stop 1 to stop 10', () {
      for (final seed in seeds) {
        final ramp = LegendRamp.of(seed);
        final values = [
          for (final stop in ramp.stops) HSVColor.fromColor(stop).value,
        ];
        for (var i = 1; i < values.length; i++) {
          expect(
            values[i],
            lessThanOrEqualTo(values[i - 1] + 0.01),
            reason:
                'stop ${i + 1} of $seed must not be brighter than '
                'stop $i (8-bit rounding tolerance 0.01)',
          );
        }
        // Light tints really are lighter than dark shades overall.
        expect(values.first, greaterThan(values.last));
      }
    });

    test('achromatic seeds stay grey (no invented saturation)', () {
      final ramp = LegendRamp.of(const Color(0xFF808080));
      for (final stop in ramp.stops) {
        expect(HSVColor.fromColor(stop).saturation, 0);
      }
    });

    test('dark variant differs from the light ramp and starts near the '
        'background', () {
      const seed = Color(0xFF0059FF);
      final light = LegendRamp.of(seed);
      final dark = LegendRamp.dark(seed);
      expect(dark.stops, hasLength(10));
      expect(dark.stops, isNot(equals(light.stops)));
      // Dark stop 1 is a tinted canvas: mostly the dark background.
      expect(
        dark.stop(1).computeLuminance(),
        lessThan(0.05),
        reason:
            'dark stop 1 blends only 15% of a light stop into the '
            'background',
      );
      // The accent end is far lighter than the canvas end (direction
      // flips relative to the light ramp, roles stay stable).
      expect(
        dark.stop(10).computeLuminance(),
        greaterThan(dark.stop(1).computeLuminance()),
      );
    });

    test('dark variant is generated, not hand-flipped: blends light stops '
        'into the given background', () {
      const seed = Color(0xFF10B981);
      const background = Color(0xFF0A0A10);
      final light = LegendRamp.of(seed);
      final dark = LegendRamp.dark(seed, background: background);
      // Dark stop 2 = lerp(background, light stop 6, 0.25) per the
      // documented blend table.
      expect(dark.stop(2), Color.lerp(background, light.stop(6), 0.25));
    });
  });
}
