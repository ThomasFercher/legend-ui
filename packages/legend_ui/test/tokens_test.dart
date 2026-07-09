import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

void main() {
  group('LegendTokens', () {
    test('lerp at t=0 and t=1 returns the endpoints', () {
      final at0 = LegendTokens.lerp(LegendTokens.light, LegendTokens.dark, 0);
      final at1 = LegendTokens.lerp(LegendTokens.light, LegendTokens.dark, 1);
      expect(at0.colors.primary, LegendColors.light.primary);
      expect(at1.colors.primary, LegendColors.dark.primary);
      expect(at0.typography.h1.fontSize, at1.typography.h1.fontSize);
    });

    test('lerp interpolates colors and sizes', () {
      const a = LegendTokens.light;
      final b = LegendTokens.light.copyWith(
        colors: LegendColors.light.copyWith(primary: const Color(0xFF000000)),
        sizes: const LegendSizes(md: 32),
      );
      final mid = LegendTokens.lerp(a, b, 0.5);
      expect(mid.sizes.md, 24);
      expect(
        mid.colors.primary,
        Color.lerp(a.colors.primary, const Color(0xFF000000), 0.5),
      );
    });

    test('copyWith replaces only the given group', () {
      final t = LegendTokens.light.copyWith(sizes: const LegendSizes(md: 20));
      expect(t.sizes.md, 20);
      expect(t.colors.primary, LegendColors.light.primary);
      expect(t.shadows.low, LegendTokens.light.shadows.low);
    });
  });

  group('LegendThemeData', () {
    test('component<T>() returns registered entry or null', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {String: 'sparse-theme-stand-in'},
      );
      expect(data.component<String>(), 'sparse-theme-stand-in');
      expect(data.component<int>(), isNull);
    });
  });
}
