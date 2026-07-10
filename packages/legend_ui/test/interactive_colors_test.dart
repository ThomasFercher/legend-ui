// Ported from legend_states_test.dart (RFC-002 R6 amendment 7): the
// generic LegendStates<T> container is deleted; InteractiveColors — an
// ordinary @Style() value class with GENERATED merge/lerp/== — replaces
// it one-to-one. Same coverage, new machinery.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _navy = Color(0xFF001F54);
const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);

void main() {
  group('LegendInteractionStates.effective (the ladder, RFC-002 R6)', () {
    LegendInteractionStates snapshot({
      bool hovered = false,
      bool pressed = false,
      bool focused = false,
      bool disabled = false,
    }) {
      return LegendInteractionStates(
        hovered: hovered,
        pressed: pressed,
        focused: focused,
        disabled: disabled,
      );
    }

    test('disabled beats everything', () {
      expect(
        snapshot(
          hovered: true,
          pressed: true,
          focused: true,
          disabled: true,
        ).effective,
        const LegendStateDisabled(),
      );
    });

    test('pressed beats hovered and focused', () {
      expect(
        snapshot(hovered: true, pressed: true, focused: true).effective,
        const LegendStatePressed(),
      );
    });

    test('hovered beats focused', () {
      expect(
        snapshot(hovered: true, focused: true).effective,
        const LegendStateHovered(),
      );
    });

    test('focused beats normal', () {
      expect(snapshot(focused: true).effective, const LegendStateFocused());
    });

    test('nothing set is normal', () {
      expect(snapshot().effective, const LegendStateNormal());
    });
  });

  group('InteractiveColors (generated members, RFC-002 R6 amendment 7)', () {
    test('== and hashCode are member-wise', () {
      const a = InteractiveColors(normal: _navy, pressed: _red);
      const b = InteractiveColors(normal: _navy, pressed: _red);
      const c = InteractiveColors(normal: _navy, hovered: _red);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('merge is member-wise sparse — set members win, unset inherit', () {
      const lower = InteractiveColors(normal: _navy, hovered: _red);
      const upper = InteractiveColors(pressed: _green);
      final merged = lower.merge(upper);
      expect(merged.normal, _navy);
      expect(merged.hovered, _red);
      expect(merged.pressed, _green);
      expect(merged.focused, isNull);
    });

    test('merge(null) passes the receiver through', () {
      const only = InteractiveColors(normal: _navy);
      expect(only.merge(null), same(only));
    });

    test('lerp is member-wise with Color.lerp', () {
      const a = InteractiveColors(normal: _red, hovered: _red);
      const b = InteractiveColors(normal: _green);
      final mid = InteractiveColors.lerp(a, b, 0.5)!;
      expect(mid.normal, Color.lerp(_red, _green, 0.5));
      // Color.lerp fades against null — member-wise, not whole-value.
      expect(mid.hovered, Color.lerp(_red, null, 0.5));
      expect(mid.pressed, isNull);
    });

    test('lerp handles null sides member-wise and only both-null is null', () {
      const only = InteractiveColors(normal: _red);
      final fromNull = InteractiveColors.lerp(null, only, 0.5)!;
      expect(fromNull.normal, Color.lerp(null, _red, 0.5));
      expect(InteractiveColors.lerp(null, null, 0.5), isNull);
    });

    test('lerp short-circuits identical endpoints to the same instance '
        '(R12 amendment: identity-stable through animations)', () {
      const a = InteractiveColors(normal: _navy);
      expect(InteractiveColors.lerp(a, a, 0.37), same(a));
    });

    test('pick returns the member, else normal', () {
      const colors = InteractiveColors(normal: _navy, pressed: _red);
      expect(colors.pick(const LegendStatePressed()), _red);
      expect(colors.pick(const LegendStateHovered()), _navy);
      expect(colors.pick(const LegendStateNormal()), _navy);
      expect(
        const InteractiveColors().pick(const LegendStatePressed()),
        isNull,
      );
    });
  });

  group('InteractiveColors.resolve with overlays', () {
    const overlays = LegendStateOverlays();

    test('named member always wins over derivation', () {
      const colors = InteractiveColors(normal: _navy, hovered: _red);
      expect(colors.resolve(const LegendStateHovered(), overlays), _red);
    });

    test('unset members derive from normal via the overlays', () {
      const colors = InteractiveColors(normal: _navy);
      expect(
        colors.resolve(const LegendStateHovered(), overlays),
        overlays.hovered(_navy),
      );
      expect(
        colors.resolve(const LegendStatePressed(), overlays),
        overlays.pressed(_navy),
      );
      expect(
        colors.resolve(const LegendStateDisabled(), overlays),
        overlays.disabled(_navy),
      );
      expect(colors.resolve(const LegendStateFocused(), overlays), _navy);
      expect(colors.resolve(const LegendStateNormal(), overlays), _navy);
    });

    test('nothing set resolves to null', () {
      const colors = InteractiveColors();
      expect(colors.resolve(const LegendStatePressed(), overlays), isNull);
    });
  });

  group('LegendStateOverlays', () {
    const overlays = LegendStateOverlays();

    test('shifts light colors toward black and dark toward white', () {
      const light = Color(0xFFFFFFFF);
      const dark = Color(0xFF000000);
      expect(
        overlays.hovered(light).computeLuminance(),
        lessThan(light.computeLuminance()),
      );
      expect(
        overlays.hovered(dark).computeLuminance(),
        greaterThan(dark.computeLuminance()),
      );
    });

    test('pressed shifts further than hovered', () {
      const base = Color(0xFF2563EB);
      final hoverDelta =
          (overlays.hovered(base).computeLuminance() - base.computeLuminance())
              .abs();
      final pressDelta =
          (overlays.pressed(base).computeLuminance() - base.computeLuminance())
              .abs();
      expect(pressDelta, greaterThan(hoverDelta));
    });

    test('disabled halves the alpha', () {
      final disabled = overlays.disabled(_navy);
      expect(disabled.a, closeTo(0.5, 0.01));
    });

    test('lerp interpolates the deltas', () {
      const a = LegendStateOverlays();
      const b = LegendStateOverlays(
        hoverAmount: 0.1,
        pressAmount: 0.2,
        disabledOpacity: 0.3,
      );
      final mid = LegendStateOverlays.lerp(a, b, 0.5);
      expect(mid.hoverAmount, closeTo(0.08, 1e-9));
      expect(mid.pressAmount, closeTo(0.16, 1e-9));
      expect(mid.disabledOpacity, closeTo(0.4, 1e-9));
    });

    test('rides along on LegendTokens copyWith/lerp', () {
      const custom = LegendStateOverlays(hoverAmount: 0.5);
      final tokens = LegendTokens.light.copyWith(states: custom);
      expect(tokens.states, custom);
      final mid = LegendTokens.lerp(LegendTokens.light, tokens, 0.5);
      expect(mid.states.hoverAmount, closeTo(0.28, 1e-9));
    });
  });

  group('LegendThemeData.componentOf (RFC-002 R3, both keys)', () {
    const byWidget = InteractiveColors(normal: _red);
    const byNullable = InteractiveColors(normal: _green);

    test('widget-type key resolves', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: byWidget},
      );
      expect(data.componentOf<InteractiveColors>(LegendSwitch), same(byWidget));
    });

    test('legacy value-type key still resolves as the fallback', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {InteractiveColors: byNullable},
      );
      expect(
        data.componentOf<InteractiveColors>(LegendSwitch),
        same(byNullable),
      );
    });

    test('when both keys are registered the widget type wins', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: byWidget, InteractiveColors: byNullable},
      );
      expect(data.componentOf<InteractiveColors>(LegendSwitch), same(byWidget));
    });

    test('mismatched value type asserts in debug', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: 'not a theme'},
      );
      expect(
        () => data.componentOf<InteractiveColors>(LegendSwitch),
        throwsAssertionError,
      );
    });
  });
}
