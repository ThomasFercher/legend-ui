import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _appTheme = Color(0xFF111111);
const _subtree = Color(0xFF222222);
const _param = Color(0xFF333333);

Widget _app({
  Map<Type, Object> components = const {},
  Color? subtreeOverride,
  Color? param,
}) {
  Widget button = PrimaryLegendButton(
    onPressed: () {},
    text: 'Save',
    background: param,
  );
  if (subtreeOverride != null) {
    button = PrimaryLegendButtonThemeOverride(
      data: PrimaryLegendButtonThemeNullable(
        background: InteractiveColors(normal: subtreeOverride),
      ),
      child: button,
    );
  }
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: button),
    ),
  );
}

Color _backgroundOf(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(PrimaryLegendButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  group('layered resolution (DESIGN §1 goal 3, four levels per §9.9)', () {
    testWidgets('level 4: token-derived default', (tester) async {
      await tester.pumpWidget(_app());
      expect(_backgroundOf(tester), LegendTokens.light.colors.primary);
    });

    testWidgets('level 3: app-theme registry beats defaults', (tester) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryLegendButtonThemeNullable:
                const PrimaryLegendButtonThemeNullable(
                  background: InteractiveColors(normal: _appTheme),
                ),
          },
        ),
      );
      expect(_backgroundOf(tester), _appTheme);
    });

    testWidgets('level 2: subtree override beats app theme', (tester) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryLegendButtonThemeNullable:
                const PrimaryLegendButtonThemeNullable(
                  background: InteractiveColors(normal: _appTheme),
                ),
          },
          subtreeOverride: _subtree,
        ),
      );
      expect(_backgroundOf(tester), _subtree);
    });

    testWidgets('level 1: constructor param beats everything', (tester) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryLegendButtonThemeNullable:
                const PrimaryLegendButtonThemeNullable(
                  background: InteractiveColors(normal: _appTheme),
                ),
          },
          subtreeOverride: _subtree,
          param: _param,
        ),
      );
      expect(_backgroundOf(tester), _param);
    });

    testWidgets('level 3 accepts the widget type as the key (RFC-002 R3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryLegendButton: const PrimaryLegendButtonThemeNullable(
              background: InteractiveColors(normal: _appTheme),
            ),
          },
        ),
      );
      expect(_backgroundOf(tester), _appTheme);
    });

    testWidgets('when both key styles are registered the widget type wins', (
      tester,
    ) async {
      const byNullable = Color(0xFF444444);
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryLegendButton: const PrimaryLegendButtonThemeNullable(
              background: InteractiveColors(normal: _appTheme),
            ),
            PrimaryLegendButtonThemeNullable:
                const PrimaryLegendButtonThemeNullable(
                  background: InteractiveColors(normal: byNullable),
                ),
          },
        ),
      );
      expect(_backgroundOf(tester), _appTheme);
    });

    testWidgets('unset properties still inherit lower levels', (tester) async {
      await tester.pumpWidget(_app(subtreeOverride: _subtree));
      final text = tester.widget<Text>(find.text('Save'));
      // background overridden, textStyle still token-derived.
      expect(_backgroundOf(tester), _subtree);
      expect(text.style?.fontSize, LegendTokens.light.typography.b2.fontSize);
    });
  });

  group('interaction', () {
    testWidgets('tap invokes onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        LegendTheme(
          data: const LegendThemeData(tokens: LegendTokens.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PrimaryLegendButton(onPressed: () => taps++, text: 'Go'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryLegendButton));
      expect(taps, 1);
    });

    testWidgets('disabled button is genuinely inert (legacy regression)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        LegendTheme(
          data: const LegendThemeData(tokens: LegendTokens.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PrimaryLegendButton(
                onPressed: () => taps++,
                enabled: false,
                text: 'Go',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryLegendButton));
      await tester.pump();
      expect(taps, 0);
      expect(_backgroundOf(tester), LegendTokens.light.colors.disabled);
    });
  });

  group('shared button surface on LegendButtonCore (RFC-002 R7.2)', () {
    const tokens = LegendTokens.light;

    Widget buttons({
      Map<Type, Object> components = const {},
      EdgeInsetsGeometry? constructorPadding,
    }) {
      return LegendTheme(
        data: LegendThemeData(tokens: tokens, components: components),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryLegendButton(
                  onPressed: () {},
                  text: 'Primary',
                  padding: constructorPadding,
                ),
                SecondaryLegendButton(onPressed: () {}, text: 'Secondary'),
                LegendTextButton(onPressed: () {}, text: 'Text'),
              ],
            ),
          ),
        ),
      );
    }

    AnimatedContainer surfaceOf(WidgetTester tester, Type variant) {
      return tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(variant),
          matching: find.byType(AnimatedContainer),
        ),
      );
    }

    testWidgets('defaults reproduce the pre-R7.2 buttons exactly', (
      tester,
    ) async {
      await tester.pumpWidget(buttons());
      final filled = EdgeInsets.symmetric(
        horizontal: tokens.sizes.md,
        vertical: tokens.sizes.sm,
      );
      final tight = EdgeInsets.symmetric(
        horizontal: tokens.sizes.sm,
        vertical: tokens.sizes.xs,
      );
      for (final variant in [PrimaryLegendButton, SecondaryLegendButton]) {
        final surface = surfaceOf(tester, variant);
        expect(surface.padding, filled);
        expect(
          (surface.decoration! as BoxDecoration).borderRadius,
          tokens.sizes.borderRadiusMd,
        );
      }
      final text = surfaceOf(tester, LegendTextButton);
      expect(text.padding, tight);
      expect(
        (text.decoration! as BoxDecoration).borderRadius,
        tokens.sizes.borderRadiusSm,
      );
    });

    testWidgets('a core-level override restyles the filled variants, while '
        'the text button keeps its own variant-level surface', (tester) async {
      const corePadding = EdgeInsets.all(3);
      await tester.pumpWidget(
        buttons(
          components: {
            LegendButtonCore: const LegendButtonCoreThemeNullable(
              padding: corePadding,
            ),
          },
        ),
      );
      expect(surfaceOf(tester, PrimaryLegendButton).padding, corePadding);
      expect(surfaceOf(tester, SecondaryLegendButton).padding, corePadding);
      // Variant-level values win over core-level ones: the text button
      // always passes its own themed padding.
      expect(
        surfaceOf(tester, LegendTextButton).padding,
        EdgeInsets.symmetric(
          horizontal: tokens.sizes.sm,
          vertical: tokens.sizes.xs,
        ),
      );
    });

    testWidgets('a variant constructor param wins over the core theme', (
      tester,
    ) async {
      const corePadding = EdgeInsets.all(3);
      const instancePadding = EdgeInsets.all(9);
      await tester.pumpWidget(
        buttons(
          components: {
            LegendButtonCore: const LegendButtonCoreThemeNullable(
              padding: corePadding,
            ),
          },
          constructorPadding: instancePadding,
        ),
      );
      expect(surfaceOf(tester, PrimaryLegendButton).padding, instancePadding);
      expect(surfaceOf(tester, SecondaryLegendButton).padding, corePadding);
    });
  });
}
