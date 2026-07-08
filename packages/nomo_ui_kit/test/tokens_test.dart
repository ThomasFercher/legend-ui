import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

void main() {
  group('NomoTokens', () {
    test('lerp at t=0 and t=1 returns the endpoints', () {
      final at0 = NomoTokens.lerp(NomoTokens.light, NomoTokens.dark, 0);
      final at1 = NomoTokens.lerp(NomoTokens.light, NomoTokens.dark, 1);
      expect(at0.colors.primary, NomoColors.light.primary);
      expect(at1.colors.primary, NomoColors.dark.primary);
      expect(at0.typography.h1.fontSize, at1.typography.h1.fontSize);
    });

    test('lerp interpolates colors and sizes', () {
      const a = NomoTokens.light;
      final b = NomoTokens.light.copyWith(
        colors: NomoColors.light.copyWith(primary: const Color(0xFF000000)),
        sizes: const NomoSizes(md: 32),
      );
      final mid = NomoTokens.lerp(a, b, 0.5);
      expect(mid.sizes.md, 24);
      expect(
        mid.colors.primary,
        Color.lerp(a.colors.primary, const Color(0xFF000000), 0.5),
      );
    });

    test('copyWith replaces only the given group', () {
      final t = NomoTokens.light.copyWith(sizes: const NomoSizes(md: 20));
      expect(t.sizes.md, 20);
      expect(t.colors.primary, NomoColors.light.primary);
      expect(t.shadows.low, NomoTokens.light.shadows.low);
    });
  });

  group('NomoThemeData', () {
    test('component<T>() returns registered entry or null', () {
      const data = NomoThemeData(
        tokens: NomoTokens.light,
        components: {String: 'sparse-theme-stand-in'},
      );
      expect(data.component<String>(), 'sparse-theme-stand-in');
      expect(data.component<int>(), isNull);
    });
  });
}
