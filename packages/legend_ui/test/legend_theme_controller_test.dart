import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

void main() {
  group('LegendThemeController (RFC-002 R8)', () {
    test('defaults to the kit light preset; dark flag swaps the preset', () {
      final controller = LegendThemeController();
      expect(controller.data.tokens, same(LegendTokens.light));
      expect(controller.data.components, isEmpty);

      controller.setDark(value: true);
      expect(controller.data.tokens, same(LegendTokens.dark));
    });

    test('seed swap regenerates tokens through fromSeed', () {
      final controller = LegendThemeController();
      const brand = Color(0xFF059669);

      controller.setSeed(const LegendSeed(brand: brand));
      // Light mode: primary is ramp stop 6 — the seed itself.
      expect(controller.data.tokens.colors.primary, brand);
      expect(
        controller.data.tokens,
        LegendTokens.fromSeed(const LegendSeed(brand: brand)),
      );

      // The controller's dark flag re-runs the derivation — one seed,
      // both modes; LegendSeed.brightness is overridden by the flag.
      controller.setDark(value: true);
      expect(
        controller.data.tokens,
        LegendTokens.fromSeed(
          const LegendSeed(brand: brand, brightness: Brightness.dark),
        ),
      );

      // Back to the presets when the seed clears.
      controller.setSeed(null);
      expect(controller.data.tokens, same(LegendTokens.dark));
    });

    test('explicit baseTokens win over seed and dark flag', () {
      final tokens = LegendTokens.fromSeed(
        const LegendSeed(brand: Color(0xFF8B5CF6)),
      );
      final controller = LegendThemeController(
        seed: const LegendSeed(brand: Color(0xFF059669)),
        tokens: tokens,
        dark: true,
      );
      expect(controller.data.tokens, same(tokens));

      // Clearing the explicit tokens falls back to the seed — with the
      // controller's dark flag deciding the brightness of the derivation.
      controller.setTokens(null);
      expect(
        controller.data.tokens,
        LegendTokens.fromSeed(
          const LegendSeed(
            brand: Color(0xFF059669),
            brightness: Brightness.dark,
          ),
        ),
      );
    });

    test('override registration reflects in data; removal restores', () {
      final controller = LegendThemeController();
      const override = LegendCardThemeNullable(background: Color(0xFF0D9488));

      controller.setOverride(LegendCard, override);
      expect(controller.data.components[LegendCard], override);
      expect(controller.components[LegendCard], override);

      // Sparse overrides live under the widget type (RFC-002 R3), so the
      // generated resolution chain picks them up as level 3.
      expect(
        controller.data.componentOf<LegendCardThemeNullable>(LegendCard),
        override,
      );

      // Null removes — unset members resume resolving to defaults.
      controller.setOverride(LegendCard, null);
      expect(controller.data.components, isEmpty);
      expect(
        controller.data.componentOf<LegendCardThemeNullable>(LegendCard),
        isNull,
      );

      // clearOverride and clearOverrides do the same, typed.
      controller
        ..setOverride(LegendCard, override)
        ..clearOverride(LegendCard);
      expect(controller.data.components, isEmpty);

      controller
        ..setOverride(LegendCard, override)
        ..setOverride(LegendSwitch, const LegendSwitchThemeNullable(width: 40))
        ..clearOverrides();
      expect(controller.data.components, isEmpty);
    });

    test('typed mutators notify; equal values are no-ops', () {
      final controller = LegendThemeController();
      var notified = 0;
      controller
        ..addListener(() => notified++)
        ..setDark(value: true)
        ..setSeed(const LegendSeed(brand: Color(0xFF059669)))
        ..setOverride(
          LegendCard,
          const LegendCardThemeNullable(background: Color(0xFFDC2626)),
        );
      expect(notified, 3);

      // Value-equal writes must not invalidate listeners (RFC-002 R2).
      controller
        ..setDark(value: true)
        ..setSeed(const LegendSeed(brand: Color(0xFF059669)))
        ..setOverride(
          LegendCard,
          const LegendCardThemeNullable(background: Color(0xFFDC2626)),
        )
        ..clearOverride(LegendSwitch);
      expect(notified, 3, reason: 'nothing above changed any state');

      controller.clearOverrides();
      expect(notified, 4, reason: 'only the clear changed anything');
    });

    test('reset returns to the untouched defaults and notifies once', () {
      final controller = LegendThemeController(
        seed: const LegendSeed(brand: Color(0xFF059669)),
        dark: true,
        components: const {
          LegendCard: LegendCardThemeNullable(background: Color(0xFF0D9488)),
        },
      );
      var notified = 0;
      controller
        ..addListener(() => notified++)
        ..reset();
      expect(notified, 1);
      expect(controller.seed, isNull);
      expect(controller.dark, isFalse);
      expect(controller.data.tokens, same(LegendTokens.light));
      expect(controller.data.components, isEmpty);

      // Resetting an untouched controller is a no-op.
      controller.reset();
      expect(notified, 1);
    });

    test('data snapshots the override map', () {
      final controller = LegendThemeController();
      const override = LegendCardThemeNullable(background: Color(0xFF0D9488));
      controller.setOverride(LegendCard, override);

      final snapshot = controller.data;
      controller.clearOverride(LegendCard);
      expect(snapshot.components[LegendCard], override);
    });
  });
}
