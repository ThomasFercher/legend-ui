// RFC-002 R13 — all four wiring forms, through the consumer fixtures in
// wiring_forms.dart. The HOOK form (`final theme = _theme(context);`) is
// exercised by balance_card_test.dart and every kit widget test.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

import 'wiring_forms.dart';

const _navy = Color(0xFF001F54);

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 20, height: 20, child: child)),
    ),
  );
}

Color _fillOf(WidgetTester tester, Type type) => tester
    .widget<ColoredBox>(
      find.descendant(of: find.byType(type), matching: find.byType(ColoredBox)),
    )
    .color;

void main() {
  group('R13 wiring forms', () {
    testWidgets('auto-detected State getter resolves all four levels', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const AutoGetterChip()));
      expect(
        _fillOf(tester, AutoGetterChip),
        LegendTokens.light.colors.primary,
      );

      // Constructor param (level 1) through the same getter.
      await tester.pumpWidget(_wrap(const AutoGetterChip(fill: _navy)));
      expect(_fillOf(tester, AutoGetterChip), _navy);
    });

    testWidgets('explicit mixin getter works and wins over the '
        'auto-extension (coexistence)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MixinChip(),
          components: {MixinChip: const MixinChipThemeNullable(fill: _navy)},
        ),
      );
      expect(_fillOf(tester, MixinChip), _navy);
    });

    testWidgets('opt-in base: two-argument build receives the resolved '
        'theme; subclass stays const-able', (tester) async {
      // Const construction proves the base keeps const-ability.
      const chip = BaseChip();
      await tester.pumpWidget(_wrap(chip));
      expect(_fillOf(tester, BaseChip), LegendTokens.light.colors.surface);

      await tester.pumpWidget(
        _wrap(
          const BaseChip(),
          components: {BaseChip: const BaseChipThemeNullable(fill: _navy)},
        ),
      );
      expect(_fillOf(tester, BaseChip), _navy);
    });

    testWidgets('opt-in base rebuilds granularly like the other forms', (
      tester,
    ) async {
      // A BaseChip dependent is not rebuilt by another type's registry
      // change (R12 aspects register inside resolveThemeOf's XTheme.of).
      const chip = BaseChip();
      await tester.pumpWidget(_wrap(chip));
      final element = tester.element(find.byType(BaseChip));
      await tester.pumpWidget(
        _wrap(
          chip,
          components: {MixinChip: const MixinChipThemeNullable(fill: _navy)},
        ),
      );
      expect(tester.element(find.byType(BaseChip)), same(element));
      expect(element.dirty, isFalse);
    });
  });
}
