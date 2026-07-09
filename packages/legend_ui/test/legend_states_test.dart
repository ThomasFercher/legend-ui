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

  group('LegendStates<T>', () {
    test('== and hashCode are member-wise', () {
      const a = LegendStates<Color>(normal: _navy, pressed: _red);
      const b = LegendStates<Color>(normal: _navy, pressed: _red);
      const c = LegendStates<Color>(normal: _navy, hovered: _red);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('merge is member-wise sparse — set members win, unset inherit', () {
      const lower = LegendStates<Color>(normal: _navy, hovered: _red);
      const upper = LegendStates<Color>(pressed: _green);
      final merged = LegendStates.merge(lower, upper)!;
      expect(merged.normal, _navy);
      expect(merged.hovered, _red);
      expect(merged.pressed, _green);
      expect(merged.focused, isNull);
    });

    test('merge passes null containers through', () {
      const only = LegendStates<double>(normal: 4);
      expect(LegendStates.merge<double>(only, null), same(only));
      expect(LegendStates.merge<double>(null, only), same(only));
      expect(LegendStates.merge<double>(null, null), isNull);
    });

    test('lerpWith applies the lerper member-wise', () {
      const a = LegendStates<Color>(normal: _red, hovered: _red);
      const b = LegendStates<Color>(normal: _green);
      final mid = LegendStates.lerpWith(a, b, 0.5, Color.lerp);
      expect(mid.normal, Color.lerp(_red, _green, 0.5));
      // Color.lerp fades against null — member-wise, not whole-value.
      expect(mid.hovered, Color.lerp(_red, null, 0.5));
      expect(mid.pressed, isNull);
    });

    test('pick returns the member, else normal', () {
      const states = LegendStates<double>(normal: 1, pressed: 3);
      expect(states.pick(const LegendStatePressed()), 3);
      expect(states.pick(const LegendStateHovered()), 1);
      expect(states.pick(const LegendStateNormal()), 1);
      expect(
        const LegendStates<double>().pick(const LegendStatePressed()),
        isNull,
      );
    });

    test('.states lifts a raw Color to a normal-only container', () {
      expect(_navy.states, const LegendStates<Color>(normal: _navy));
    });
  });

  group('LegendStates<Color>.resolve with overlays', () {
    const overlays = LegendStateOverlays();

    test('named member always wins over derivation', () {
      const states = LegendStates<Color>(normal: _navy, hovered: _red);
      expect(states.resolve(const LegendStateHovered(), overlays), _red);
    });

    test('unset members derive from normal via the overlays', () {
      const states = LegendStates<Color>(normal: _navy);
      expect(
        states.resolve(const LegendStateHovered(), overlays),
        overlays.hovered(_navy),
      );
      expect(
        states.resolve(const LegendStatePressed(), overlays),
        overlays.pressed(_navy),
      );
      expect(
        states.resolve(const LegendStateDisabled(), overlays),
        overlays.disabled(_navy),
      );
      expect(states.resolve(const LegendStateFocused(), overlays), _navy);
      expect(states.resolve(const LegendStateNormal(), overlays), _navy);
    });

    test('nothing set resolves to null', () {
      const states = LegendStates<Color>();
      expect(states.resolve(const LegendStatePressed(), overlays), isNull);
    });

    test('withDerived fills only the unset members', () {
      const states = LegendStates<Color>(normal: _navy, pressed: _red);
      final derived = states.withDerived(overlays);
      expect(derived.normal, _navy);
      expect(derived.pressed, _red);
      expect(derived.hovered, overlays.hovered(_navy));
      expect(derived.disabled, overlays.disabled(_navy));
      expect(derived.focused, _navy);
      // No normal — nothing to derive from.
      const sparse = LegendStates<Color>(pressed: _red);
      expect(sparse.withDerived(overlays), same(sparse));
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
    const byWidget = LegendStates<Color>(normal: _red);
    const byNullable = LegendStates<Color>(normal: _green);

    test('widget-type key resolves', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: byWidget},
      );
      expect(
        data.componentOf<LegendStates<Color>>(LegendSwitch),
        same(byWidget),
      );
    });

    test('legacy value-type key still resolves as the fallback', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendStates<Color>: byNullable},
      );
      expect(
        data.componentOf<LegendStates<Color>>(LegendSwitch),
        same(byNullable),
      );
    });

    test('when both keys are registered the widget type wins', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: byWidget, LegendStates<Color>: byNullable},
      );
      expect(
        data.componentOf<LegendStates<Color>>(LegendSwitch),
        same(byWidget),
      );
    });

    test('mismatched value type asserts in debug', () {
      const data = LegendThemeData(
        tokens: LegendTokens.light,
        components: {LegendSwitch: 'not a theme'},
      );
      expect(
        () => data.componentOf<LegendStates<Color>>(LegendSwitch),
        throwsAssertionError,
      );
    });
  });
}
