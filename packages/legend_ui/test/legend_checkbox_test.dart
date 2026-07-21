import 'dart:ui' show CheckedState;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// The box surface — the first LegendSurface under the checkbox.
LegendSurface _surface(WidgetTester tester) =>
    tester.widget<LegendSurface>(find.byType(LegendSurface));

double _markOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

/// The mark's [CustomPaint] inside the checkbox.
Finder _paintFinder() => find.descendant(
  of: find.byType(LegendCheckbox),
  matching: find.byType(CustomPaint),
);

void main() {
  group('LegendCheckbox — behavior', () {
    testWidgets('tap toggles false → true and true → false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: false, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(LegendCheckbox));
      expect(next, isTrue);

      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: true, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(LegendCheckbox));
      expect(next, isFalse);
    });

    testWidgets('tristate cycles false → true → null → false', (tester) async {
      bool? next;
      Future<void> pumpAndTap({required bool? value}) async {
        await tester.pumpWidget(
          _wrap(
            LegendCheckbox(
              value: value,
              tristate: true,
              onChanged: (v) => next = v,
            ),
          ),
        );
        await tester.tap(find.byType(LegendCheckbox));
      }

      await pumpAndTap(value: false);
      expect(next, isTrue);
      await pumpAndTap(value: true);
      expect(next, isNull);
      await pumpAndTap(value: null);
      expect(next, isFalse);
    });

    testWidgets('the inline label is part of the tap target', (tester) async {
      bool? next;
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(
            value: false,
            label: 'Include this source',
            onChanged: (v) => next = v,
          ),
        ),
      );
      await tester.tap(find.text('Include this source'));
      expect(next, isTrue);
    });

    testWidgets('disabled and null-onChanged checkboxes are inert', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(
            value: false,
            enabled: false,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.byType(LegendCheckbox));
      expect(called, isFalse);

      await tester.pumpWidget(
        _wrap(const LegendCheckbox(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(LegendCheckbox));
      // No throw, no callback — nothing to assert beyond arriving here.
    });
  });

  group('LegendCheckbox — visuals', () {
    testWidgets('check mark fades in when checked and out when unchecked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: false, onChanged: (_) {})),
      );
      expect(_markOpacity(tester), 0);
      expect(_surface(tester).color, isNull);
      expect(_surface(tester).border, isNotNull);

      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: true, onChanged: (_) {})),
      );
      expect(_markOpacity(tester), 1);
      expect(_surface(tester).border, isNull);
    });

    testWidgets('checked box fills with the primary token by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: true, onChanged: (_) {})),
      );
      expect(_surface(tester).color, LegendTokens.light.colors.primary);
    });

    testWidgets('indeterminate shows the mark and announces mixed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: null, tristate: true, onChanged: (_) {})),
      );
      expect(_markOpacity(tester), 1);
      expect(
        tester.renderObject(_paintFinder()),
        paints..path(color: LegendTokens.light.colors.onPrimary),
      );
    });

    testWidgets('disabled swaps fill, border and mark to the disabled tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendCheckbox(value: true, onChanged: null)),
      );
      expect(_surface(tester).color, LegendTokens.light.colors.disabled);
      expect(
        tester.renderObject(_paintFinder()),
        paints..path(color: LegendTokens.light.colors.onDisabled),
      );

      await tester.pumpWidget(
        _wrap(const LegendCheckbox(value: false, onChanged: null)),
      );
      final border = _surface(tester).border! as Border;
      expect(border.top.color, LegendTokens.light.colors.disabled);
    });

    testWidgets('themed size and border width apply', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(
            value: false,
            onChanged: (_) {},
            size: 32,
            borderWidth: 3,
          ),
        ),
      );
      final boxSize = tester.getSize(find.byType(CustomPaint).first);
      expect(boxSize, const Size(32, 32));
      final border = _surface(tester).border! as Border;
      expect(border.top.width, 3);
    });
  });

  group('LegendCheckbox — theming', () {
    testWidgets('constructor box param wins over the default fill', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(
            value: true,
            onChanged: (_) {},
            box: const InteractiveColors(normal: navy),
          ),
        ),
      );
      expect(_surface(tester).color, navy);
    });

    testWidgets('level-3 components-map override restyles the fill', (
      tester,
    ) async {
      const green = Color(0xFF059669);
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(value: true, onChanged: (_) {}),
          components: {
            LegendCheckbox: const LegendCheckboxThemeNullable(
              box: InteractiveColors(normal: green),
            ),
          },
        ),
      );
      expect(_surface(tester).color, green);
    });

    testWidgets('subtree override (level 2) restyles the check color', (
      tester,
    ) async {
      const gold = Color(0xFFFFD700);
      await tester.pumpWidget(
        _wrap(
          LegendCheckboxThemeOverride(
            data: const LegendCheckboxThemeNullable(checkColor: gold),
            child: LegendCheckbox(value: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.renderObject(_paintFinder()), paints..path(color: gold));
    });
  });

  group('LegendCheckbox — semantics', () {
    testWidgets('announces checked state and the label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          LegendCheckbox(value: true, label: 'Accept terms', onChanged: (_) {}),
        ),
      );
      final node = tester.getSemantics(find.byType(LegendSelectionControl));
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.label, 'Accept terms');
      // The visual label text is excluded — one announcement, not two.
      expect(find.bySemanticsLabel('Accept terms'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tristate null announces the mixed state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(LegendCheckbox(value: null, tristate: true, onChanged: (_) {})),
      );
      final node = tester.getSemantics(find.byType(LegendSelectionControl));
      expect(node.flagsCollection.isChecked, CheckedState.mixed);
      handle.dispose();
    });
  });

  group('LegendCheckbox — form integration', () {
    testWidgets('works inside LegendFormField<bool> with validation', (
      tester,
    ) async {
      final controller = LegendFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: LegendFormField<bool>(
              name: 'terms',
              initialValue: false,
              validator: (v) =>
                  (v ?? false) ? null : 'Please accept the terms.',
              builder: (context, field) => LegendCheckbox(
                value: field.value ?? false,
                label: 'Accept terms',
                onChanged: (v) => field.didChange(v ?? false),
              ),
            ),
          ),
        ),
      );

      expect(controller.validate(), isFalse);
      expect(controller.values, {'terms': false});

      await tester.tap(find.byType(LegendCheckbox));
      await tester.pump();
      expect(controller.values, {'terms': true});
      expect(controller.validate(), isTrue);
    });
  });
}
