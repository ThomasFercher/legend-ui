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
      data: PrimaryLegendButtonThemeNullable(background: subtreeOverride),
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
                const PrimaryLegendButtonThemeNullable(background: _appTheme),
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
                const PrimaryLegendButtonThemeNullable(background: _appTheme),
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
                const PrimaryLegendButtonThemeNullable(background: _appTheme),
          },
          subtreeOverride: _subtree,
          param: _param,
        ),
      );
      expect(_backgroundOf(tester), _param);
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
}
