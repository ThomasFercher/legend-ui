import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

const _appTheme = Color(0xFF111111);
const _subtree = Color(0xFF222222);
const _param = Color(0xFF333333);

Widget _app({
  Map<Type, Object> components = const {},
  Color? subtreeOverride,
  Color? param,
}) {
  Widget button = PrimaryNomoButton(
    onPressed: () {},
    text: 'Save',
    background: param,
  );
  if (subtreeOverride != null) {
    button = PrimaryNomoButtonThemeOverride(
      data: PrimaryNomoButtonThemeNullable(background: subtreeOverride),
      child: button,
    );
  }
  return NomoTheme(
    data: NomoThemeData(tokens: NomoTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: button),
    ),
  );
}

Color _backgroundOf(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(PrimaryNomoButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  group('five-level resolution (DESIGN §1 goal 3)', () {
    testWidgets('level 5: token-derived default', (tester) async {
      await tester.pumpWidget(_app());
      expect(_backgroundOf(tester), NomoTokens.light.colors.primary);
    });

    testWidgets('level 3: app-theme registry beats defaults', (tester) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryNomoButtonThemeNullable:
                const PrimaryNomoButtonThemeNullable(background: _appTheme),
          },
        ),
      );
      expect(_backgroundOf(tester), _appTheme);
    });

    testWidgets('level 2: subtree override beats app theme', (tester) async {
      await tester.pumpWidget(
        _app(
          components: {
            PrimaryNomoButtonThemeNullable:
                const PrimaryNomoButtonThemeNullable(background: _appTheme),
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
            PrimaryNomoButtonThemeNullable:
                const PrimaryNomoButtonThemeNullable(background: _appTheme),
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
      expect(text.style?.fontSize, NomoTokens.light.typography.b2.fontSize);
    });
  });

  group('interaction', () {
    testWidgets('tap invokes onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        NomoTheme(
          data: const NomoThemeData(tokens: NomoTokens.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PrimaryNomoButton(onPressed: () => taps++, text: 'Go'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryNomoButton));
      expect(taps, 1);
    });

    testWidgets('disabled button is genuinely inert (legacy regression)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        NomoTheme(
          data: const NomoThemeData(tokens: NomoTokens.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PrimaryNomoButton(
                onPressed: () => taps++,
                enabled: false,
                text: 'Go',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PrimaryNomoButton));
      await tester.pump();
      expect(taps, 0);
      expect(_backgroundOf(tester), NomoTokens.light.colors.disabled);
    });
  });
}
