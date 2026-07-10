import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

import 'balance_card.dart';

const _appTheme = Color(0xFF101010);
const _subtree = Color(0xFF202020);
const _param = Color(0xFF303030);

Color _cardColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(BalanceCard),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('consumer widgets get identical theming support (DESIGN §1.4)', () {
    testWidgets('token-derived default', (tester) async {
      await tester.pumpWidget(_wrap(const BalanceCard(amount: '12')));
      expect(_cardColor(tester), LegendTokens.light.colors.surface);
    });

    testWidgets('registers in the SAME components map as kit widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BalanceCard(amount: '12'),
          components: {
            // Kit component and consumer component, side by side.
            PrimaryLegendButtonThemeNullable:
                const PrimaryLegendButtonThemeNullable(),
            BalanceCardThemeNullable: const BalanceCardThemeNullable(
              background: _appTheme,
            ),
          },
        ),
      );
      expect(_cardColor(tester), _appTheme);
    });

    testWidgets('subtree override and constructor param behave identically', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BalanceCardThemeOverride(
            data: BalanceCardThemeNullable(background: _subtree),
            child: BalanceCard(amount: '12', background: _param),
          ),
          components: {
            BalanceCardThemeNullable: const BalanceCardThemeNullable(
              background: _appTheme,
            ),
          },
        ),
      );
      // Param (level 1) wins over subtree (2) wins over app theme (3).
      expect(_cardColor(tester), _param);
    });

    testWidgets('a consumer-defined @Style class resolves member-wise '
        '(RFC-002 R6 amendment 7)', (tester) async {
      Color textColor(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;

      // Defaults: both members from the consumer tear-off.
      await tester.pumpWidget(_wrap(const BalanceCard(amount: '12')));
      expect(textColor('12'), LegendTokens.light.colors.secondary);
      expect(textColor('Balance'), LegendTokens.light.colors.foreground2);

      // A registry override naming ONLY `amount` keeps `caption`
      // resolving through the defaults — member-wise sparse merge via the
      // GENERATED BalanceAccent.merge.
      await tester.pumpWidget(
        _wrap(
          const BalanceCard(amount: '12'),
          components: {
            BalanceCard: const BalanceCardThemeNullable(
              accent: BalanceAccent(amount: _appTheme),
            ),
          },
        ),
      );
      expect(textColor('12'), _appTheme);
      expect(textColor('Balance'), LegendTokens.light.colors.foreground2);

      // Generated value equality on the style class.
      expect(
        const BalanceAccent(amount: _appTheme),
        const BalanceAccent(amount: _appTheme),
      );
      // Generated member-wise lerp through the hand-written redirect.
      final mid = BalanceAccent.lerp(
        const BalanceAccent(amount: _subtree),
        const BalanceAccent(amount: _param),
        0.5,
      )!;
      expect(mid.amount, Color.lerp(_subtree, _param, 0.5));
    });
  });
}
